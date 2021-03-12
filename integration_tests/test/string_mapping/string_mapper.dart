import 'package:dartstruct/dartstruct.dart';

part 'string_mapper.g.dart';

class Model {
  late int integer$;
  late String string$;
  late num number$;
  late double double$;
  late bool bool$;
}

class Dto {
  late String integer$;
  late String string$;
  late String number$;
  late String double$;
  late String bool$;
}

@Mapper()
abstract class StringMapper {
  static StringMapper get INSTANCE => StringMapperImpl();

  Dto modelToDto(Model model);
}
