import 'package:canteenlib/src/canteen_2_10_27.dart';
import 'package:canteenlib/src/canteen_2_18_03.dart';
import 'package:canteenlib/src/canteen_2_18_19.dart';
import 'package:canteenlib/src/canteen_2_19_13.dart';

export './canteen_2_18_19.dart';
export './canteen_2_19_13.dart';
export './canteen_2_18_03.dart';
export './canteen_2_10_27.dart';

final Map<String, Function(String)> canteenVersions = {
  '2.18.19': (url) => Canteen2v18v19(url),
  '2.19.13': (url) => Canteen2v19v13(url),
  '2.18.03': (url) => Canteen2v18v03(url),
  '2.10.27': (url) => Canteen2v10v27(url),
};
