import 'dart:core';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dartstruct/dartstruct.dart';
import 'package:dartstruct_generator/src/name_provider.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';

import 'extensions/extensions.dart';
import 'mappers/conversions/conversions.dart';
import 'mappers/mappers.dart';
import 'models/input_source.dart';
import 'models/output_source.dart';

class DartStructGenerator extends GeneratorForAnnotation<Mapper> {
  final _emitter = DartEmitter();
  final _formatter = DartFormatter();
  final _logger = Logger('dartstruct');
  Conversions? _conversions;

  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final dartCoreLibrary =
        await buildStep.resolver.findLibraryByName('dart.core');
    // print(await buildStep.resolver.findLibraryByName('package:built_value'));
    await (buildStep.resolver.libraries.forEach((element) {
      print(element);
    }));

    _conversions = Conversions(dartCoreLibrary!);

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          '${element.displayName} cannot be annotated with @Mapper',
          element: element,
          todo: 'Remove @Mapper annotation');
    }

    final classElement = element;

    if (!classElement.constructors.any((c) => c.isDefaultConstructor)) {
      throw InvalidGenerationSourceError(
          '${element.displayName} must provide a default constructor',
          element: element,
          todo: 'Provide a default constructor');
    }

    final nameProvider = NameProvider(classElement);

    final mapperImpl = Class((builder) {
      builder
        ..name = '${classElement.displayName}Impl'
        ..abstract = false
        ..extend = refer(classElement.displayName)
        ..methods.addAll(classElement.methods
            .where((method) => method.isAbstract)
            .map((method) =>
                _generateMethod(method, nameProvider.forMethod(method))));
    });

    final code = '${mapperImpl.accept(_emitter)}';

    return _formatter.format(code);
  }

  Method _generateMethod(MethodElement method, NameProvider nameProvider) {
    if (method.parameters.isEmpty) {
      throw InvalidGenerationSourceError('Method must provide an argument',
          todo: 'add source parameter', element: method);
    }

    if (method.parameters.length != 1) {
      throw InvalidGenerationSourceError(
          'Method must provide only one argument',
          todo: 'provide only one argument',
          element: method);
    }

    final source = method.parameters.first;

    if (source.isNamed) {
      throw InvalidGenerationSourceError('Named parameters are not supported',
          todo: 'provide a positional argument', element: source);
    }

    final sourceType = source.type;
    final returnType = method.returnType;

    if (returnType.nullabilitySuffix != sourceType.nullabilitySuffix) {
      throw InvalidGenerationSourceError(
          'nullability incompatible, return type has $returnType but source has $sourceType',
          element: method);
    }

    if (returnType.isPrimitive || sourceType.isPrimitive) {
      throw InvalidGenerationSourceError('Primitive types are not supported',
          element: method);
    }

    if (sourceType.isFuture || returnType.isFuture) {
      throw InvalidGenerationSourceError('Future types are not supported',
          element: method);
    }

    if (sourceType.isCollection || returnType.isCollection) {
      throw InvalidGenerationSourceError('Collection types are not supported',
          element: method);
    }

    if (sourceType.isDynamic || returnType.isDynamic) {
      throw InvalidGenerationSourceError('Dynamic type is not supported',
          element: method);
    }

    if (returnType.isDynamic) {
      throw InvalidGenerationSourceError('Dynamic type is not supported',
          element: method);
    }

    print('Metadata for $returnType');
    returnType.element!.metadata.forEach((element) {
      print(element.element!.name);
      print(element.runtimeType);
    });

    final isFreezed = returnType.element!.metadata.any((element) {
      return element.element!.name == 'freezed';
    });

    if (!isFreezed && !returnType.hasEmptyConstructor) {
      throw InvalidGenerationSourceError(
          'Return type must provide an empty parameters constructor or have @freezed annotation',
          element: method.returnType.element);
    }

    return Method((builder) {
      builder
        ..annotations.add(CodeExpression(Code('override')))
        ..name = method.displayName
        ..requiredParameters.add(_generateSourceParameter(source))
        ..returns = refer(returnType.element!.displayName +
            _nullability(returnType.nullabilitySuffix))
        ..body = _generateMethodBody(method, nameProvider);
    });
  }

  String _nullability(NullabilitySuffix nullabilitySuffix) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return '?';
      case NullabilitySuffix.star:
        return '*';
      case NullabilitySuffix.none:
        return '';
    }
  }

  Parameter _generateSourceParameter(ParameterElement source) {
    return Parameter((builder) {
      builder
        ..name = source.name
        ..type = refer(source.type.element!.displayName +
            _nullability(source.type.nullabilitySuffix));
    });
  }

  Code _generateMethodBody(
      MethodElement methodElement, NameProvider nameProvider) {
    final firstParameter = methodElement.parameters.first;

    final inputSource =
        InputSource(firstParameter.type, firstParameter.displayName);

    final outputSource = OutputSource(methodElement.returnType,
        nameProvider.provideVariableName(methodElement.returnType));
    var outClass = (outputSource.type.element as ClassElement);

    var outIsBuiltValue = outClass.interfaces.any((element) =>
        element.element.library.identifier ==
        'package:built_value/built_value.dart');

    var outIsFreezed =
        outClass.metadata.any((element) => element.element!.name == 'freezed');

    if (outIsBuiltValue) {
      final getters = outClass.fields.where((field) => field.getter != null);

      final body = BlockBuilder();
      final lambdaParam = Parameter((p) => p.name = 'b');

      for (final getter in getters) {
        final mapperExpression = _getMapperExpression(getter, inputSource);
        if (mapperExpression != null) {
          final assignmentExpression = refer(lambdaParam.name)
              .property(getter.displayName)
              .assign(mapperExpression);
          body.addExpression(assignmentExpression);
        } else {
          final unmappedFieldMessage = InvalidGenerationSourceError(
              'unmapped field \'${getter.displayName}\'',
              element: getter);

          _logger.warning(unmappedFieldMessage.toString());
        }
      }

      final blockBuilder = BlockBuilder();

      print(
          'In builder nullabilitySuffix: ${inputSource.type.nullabilitySuffix}');
      if (inputSource.type.nullabilitySuffix != NullabilitySuffix.none) {
        blockBuilder.addExpression(CodeExpression(
            Code('if (${inputSource.name} == null) return null')));
      }

      blockBuilder.addExpression(
          refer(outputSource.type.element!.displayName).newInstance([
        Method((m) => m
          ..body = (body.build())
          ..requiredParameters.add(lambdaParam)).closure
      ]).returned);

      return blockBuilder.build();
    }

    if (outIsFreezed) {
      print('Constructors of $outClass: ${outClass.constructors}');

      var factories = outClass.methods.where((element) => element.hasFactory);

      print('factories of $outClass: $factories');

      var ctor = outClass.constructors.first;
      final blockBuilder = BlockBuilder();

      print(
          'In builder nullabilitySuffix: ${inputSource.type.nullabilitySuffix}');
      if (inputSource.type.nullabilitySuffix != NullabilitySuffix.none) {
        blockBuilder.addExpression(CodeExpression(
            Code('if (${inputSource.name} == null) return null')));
      }

      var positional =
          ctor.parameters.where((parameter) => parameter.isPositional);
      var named = ctor.parameters.where((parameter) => parameter.isNamed);

      print('positional of $ctor: $positional');
      print('named of $ctor: $named');

      var posExps = positional.map((e) => _getMapperExpression(e, inputSource));

      print('posExps of $ctor: $posExps');

      var namedExps = {
        for (var name in named)
          name.name: _getMapperExpression(name, inputSource)
      };

      print('namedExps of $ctor: $namedExps');

      blockBuilder.addExpression(refer(outputSource.type.element!.displayName)
          .newInstance(posExps, namedExps)
          .assignFinal(outputSource.name));

      blockBuilder.addExpression(refer(outputSource.name).returned);

      return blockBuilder.build();
    }

    final setters = outClass.fields.where((field) => field.setter != null);
    final blockBuilder = BlockBuilder();

    print(
        'In builder nullabilitySuffix: ${inputSource.type.nullabilitySuffix}');
    if (inputSource.type.nullabilitySuffix != NullabilitySuffix.none) {
      blockBuilder.addExpression(
          CodeExpression(Code('if (${inputSource.name} == null) return null')));
    }

    blockBuilder.addExpression(refer(outputSource.type.element!.displayName)
        .newInstance([]).assignFinal(outputSource.name));

    for (final setter in setters) {
      final mapperExpression = _getMapperExpression(setter, inputSource);

      // if (mapperExpression != null) {
      final assignmentExpression = refer(outputSource.name)
          .property(setter.displayName)
          .assign(mapperExpression);
      blockBuilder.addExpression(assignmentExpression);
      // } else {
      //   final unmappedFieldMessage = InvalidGenerationSourceError(
      //       'unmapped field \'${setter.displayName}\'',
      //       element: setter);
      //
      //   _logger.warning(unmappedFieldMessage.toString());
      // }
    }

    blockBuilder.addExpression(refer(outputSource.name).returned);

    return blockBuilder.build();
  }

  Expression _getMapperExpression(
      VariableElement outputField, InputSource inputSource) {
    MapperAdapter? mapper =
        FieldMapperAdapter.create(inputSource, outputField.displayName);

    if (mapper == null) {
      throw ArgumentError('mapper == null');
    }

    if (_conversions!.canConvert(mapper.returnType, outputField.type)) {
      mapper =
          _conversions!.convert(mapper.returnType, outputField.type, mapper);
      return mapper.expression;
    }

    if (mapper.returnType != outputField.type) {
      throw ArgumentError('mapper.returnType != outputField.type');
    }

    return mapper.expression;
  }
}
