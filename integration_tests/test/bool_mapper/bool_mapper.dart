import 'package:dartstruct/dartstruct.dart';

part 'bool_mapper.g.dart';

class Model {
  late int trueInteger$;
  late int falseInteger$;
  late int nullInteger$;
  late String trueString$;
  late String falseString$;
  String? nullString$;
  late num trueNumber$;
  late num falseNumber$;
  num? nullNumber$;
  late double trueDouble$;
  late double falseDouble$;
  double? nullDouble$;
  late bool true$;
  late bool false$;
  bool? nullBool$;
}

class Dto {
  late bool trueInteger$;
  late bool falseInteger$;
  late bool nullInteger$;
  late bool trueString$;
  late bool falseString$;
  late bool nullString$;
  late bool trueNumber$;
  late bool falseNumber$;
  late bool nullNumber$;
  late bool trueDouble$;
  late bool falseDouble$;
  late bool nullDouble$;
  late bool true$;
  late bool false$;
  late bool nullBool$;
}

@Mapper()
abstract class BoolMapper {
  static BoolMapper get INSTANCE => BoolMapperImpl();

  Dto? modelToDto(Model? model);
}
