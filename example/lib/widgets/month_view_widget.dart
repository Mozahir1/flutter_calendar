import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

import 'draggable_month_view_widget.dart';

class MonthViewWidget extends StatelessWidget {
  final GlobalKey<MonthViewState>? state;
  final double? width;

  const MonthViewWidget({
    super.key,
    this.state,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableMonthViewWidget(
      state: state,
      width: width,
    );
  }
}
