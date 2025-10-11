// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

class Constants {
  Constants._();

  static final Random _random = Random();
  static final int _maxColor = 256;

  static const int hoursADay = 24;
  static const int minutesADay = 1440;
  static final List<String> weekTitles = ["Su", "M", "T", "W", "Th", "F", "Sa"];
  
  /// Maps weekday number to correct index for Sunday-Saturday format
  /// date.weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
  /// weekTitles: ["S", "M", "T", "W", "T", "F", "S"] (Sunday to Saturday)
  static int getWeekTitleIndex(int weekday) {
    if (weekday == 7) {
      // Sunday -> index 0
      return 0;
    } else {
      // Monday-Saturday -> index 1-6
      return weekday;
    }
  }

  static const Color defaultLiveTimeIndicatorColor = Color(0xff444444);
  static const Color black = Color(0xff000001);
  static const Color white = Color(0xffffffff);
  static const Color headerBackground = Color(0xFFDCF0FF);

  static Color get randomColor {
    return Color.fromRGBO(_random.nextInt(_maxColor),
        _random.nextInt(_maxColor), _random.nextInt(_maxColor), 1);
  }
}
