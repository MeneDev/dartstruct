import 'package:dartstruct/dartstruct.dart';

class Model {
  late String field;
}

class Dto {
  late String field;
}

@Mapper()
abstract class PostMapper {
  Dto modelToDto(Model post);
}
