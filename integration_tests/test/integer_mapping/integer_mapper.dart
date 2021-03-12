import 'package:dartstruct/dartstruct.dart';

part 'integer_mapper.g.dart';

class Model {
  late int integer$;
  late int? nullInteger$;
  late String string$;
  late String? nullString$;
  late num number$;
  late num? nullNumber$;
  late double double$;
  late double? nullDouble$;
  late bool true$;
  late bool false$;
  late bool? nullBool$;
}

class Dto {
  late int integer$;
  late int nullInteger$;
  late int string$;
  late int nullString$;
  late int number$;
  late int nullNumber$;
  late int double$;
  late int nullDouble$;
  late int true$;
  late int false$;
  late int nullBool$;
}

@Mapper()
abstract class IntegerMapper {
  static IntegerMapper get INSTANCE => IntegerMapperImpl();

  Dto modelToDto(Model model);
}
