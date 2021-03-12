import 'package:dartstruct/dartstruct.dart';

part 'simple_mapper.g.dart';

class Model {
  late String field;
}

class DifferentModel {
  late String differentField;
}

class DifferentFieldTypeModel {
  late DifferentModel field;
}

class Dto {
  late String field;
}

@Mapper()
abstract class SimpleMapper {
  static SimpleMapper get INSTANCE => SimpleMapperImpl();

  Dto modelToDto(Model? model);

  Dto differentModelToDto(DifferentModel model);

  Dto differentFieldTypeModelToDto(DifferentFieldTypeModel model);
}
