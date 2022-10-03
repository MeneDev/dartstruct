import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/src/specs/expression.dart';
import 'package:collection/collection.dart';
import 'package:dartstruct_generator/src/models/input_source.dart';

import 'mappers.dart';

class FieldMapperAdapter implements MapperAdapter {
  final VariableElement _fieldElement;
  final MapperAdapter _mapper;

  FieldMapperAdapter(this._mapper, this._fieldElement);

  @override
  Expression get expression {
    // print('_mapper: $_mapper');
    // print('_mapper.expression: ${_mapper.expression}');
    // print('_fieldElement: ${_fieldElement}');
    // print('_fieldElement.displayName: ${_fieldElement.displayName}');

    return _mapper.expression.property(_fieldElement.displayName);
  }

  @override
  DartType get returnType => _fieldElement.type;

  static FieldMapperAdapter? create(InputSource input, String fieldName) {
    MapperAdapter mapper = InputSourceMapperAdapter(input);

    final classElement = input.type.element as ClassElement;

    var isFreezed = classElement.metadata
        .any((element) => element.element!.name == 'freezed');

    // print('isFreezed: ${isFreezed}');
    // print('classElement.fields: ${classElement.fields}');
    // print(
    //     'classElement.unnamedConstructor: ${classElement.unnamedConstructor}');
    // print(
    //     'classElement.constructors.first: ${classElement.constructors.first}');

    final inputFieldElement = !isFreezed
        ? classElement.fields.firstWhereOrNull(
            (field) => field.displayName == fieldName && field.getter != null)
        : classElement.unnamedConstructor!.parameters
            .firstWhereOrNull((param) => param.displayName == fieldName);

    if (inputFieldElement == null) {
      return null;
    }

    return FieldMapperAdapter(mapper, inputFieldElement);
  }
}
