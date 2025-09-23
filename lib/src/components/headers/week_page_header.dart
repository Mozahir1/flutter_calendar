// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../style/header_style.dart';
import '../../typedefs.dart';
import 'calendar_page_header.dart';

class WeekPageHeader extends CalendarPageHeader {
  /// A header widget to display on week view.
  const WeekPageHeader({
    Key? key,
    VoidCallback? onNextDay,
    bool showNextIcon = true,
    AsyncCallback? onTitleTapped,
    VoidCallback? onPreviousDay,
    bool showPreviousIcon = true,
    required DateTime startDate,
    required DateTime endDate,
    @Deprecated("Use HeaderStyle to provide icon color") Color? iconColor,
    @Deprecated("Use HeaderStyle to provide background color")
    Color backgroundColor = Constants.headerBackground,
    StringProvider? headerStringBuilder,
    HeaderStyle headerStyle = const HeaderStyle(),
  }) : super(
          key: key,
          date: startDate,
          secondaryDate: endDate,
          onNextDay: onNextDay,
          showNextIcon: showNextIcon,
          onPreviousDay: onPreviousDay,
          showPreviousIcon: showPreviousIcon,
          onTitleTapped: onTitleTapped,
          // ignore_for_file: deprecated_member_use_from_same_package
          iconColor: iconColor,
          backgroundColor: backgroundColor,
          dateStringBuilder:
              headerStringBuilder ?? WeekPageHeader._weekStringBuilder,
          headerStyle: headerStyle,
        );

  static String _weekStringBuilder(DateTime date, {DateTime? secondaryDate}) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    if (secondaryDate != null) {
      // Check if both dates are in the same month and year
      if (date.month == secondaryDate.month && date.year == secondaryDate.year) {
        // Same month: "September 15-21, 2024"
        final monthName = monthNames[date.month - 1];
        return "$monthName ${date.day}-${secondaryDate.day}, ${date.year}";
      } else {
        // Different months: "September 29, 2024 to October 5, 2024"
        final startMonthName = monthNames[date.month - 1];
        final endMonthName = monthNames[secondaryDate.month - 1];
        final startDateStr = "$startMonthName ${date.day}, ${date.year}";
        final endDateStr = "$endMonthName ${secondaryDate.day}, ${secondaryDate.year}";
        return "$startDateStr to $endDateStr";
      }
    }
    
    // Single date: "September 15, 2024"
    final monthName = monthNames[date.month - 1];
    return "$monthName ${date.day}, ${date.year}";
  }
}
