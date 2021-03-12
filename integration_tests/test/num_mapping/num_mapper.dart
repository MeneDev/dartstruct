import 'package:dartstruct/dartstruct.dart';

part 'num_mapper.g.dart';

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
  late num integer$;
  late num nullInteger$;
  late num string$;
  late num nullString$;
  late num number$;
  late num nullNumber$;
  late num double$;
  late num nullDouble$;
  late num true$;
  late num false$;
  late num nullBool$;
}

@Mapper()
abstract class NumMapper {
  static NumMapper get INSTANCE => NumMapperImpl();

  Dto modelToDto(Model model);
}
