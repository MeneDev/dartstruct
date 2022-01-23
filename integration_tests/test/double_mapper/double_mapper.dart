import 'package:dartstruct/dartstruct.dart';

part 'double_mapper.g.dart';

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
  late double? integer$nullable;
  late double? nullInteger$nullable;
  late double? string$nullable;
  late double? nullString$nullable;
  late double? number$nullable;
  late double? nullNumber$nullable;
  late double? double$nullable;
  late double? nullDouble$nullable;
  late double? true$nullable;
  late double? false$nullable;
  late double? nullBool$nullable;
  late double integer$;
  late double nullInteger$;
  late double string$;
  late double nullString$;
  late double number$;
  late double nullNumber$;
  late double double$;
  late double nullDouble$;
  late double true$;
  late double false$;
  late double nullBool$;
}

@Mapper()
abstract class DoubleMapper {
  static DoubleMapper get INSTANCE => DoubleMapperImpl();

  Dto? modelToDto(Model? model);
}
