import 'package:flutter/material.dart';

import '../../extension.dart';
import '../day_view_page.dart';
import '../month_view_page.dart';
import '../multi_day_view_page.dart';
import '../week_view_page.dart';
import '../json_viewer_page.dart';
import '../../examples/enhanced_event_usage_example.dart';

class MobileHomePage extends StatefulWidget {
  MobileHomePage({
    this.onChangeTheme,
    super.key,
  });

  final void Function(bool)? onChangeTheme;

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Calendar Page"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => context.pushRoute(MonthViewPageDemo()),
              child: Text("Month View"),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () => context.pushRoute(DayViewPageDemo()),
              child: Text("Day View"),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () => context.pushRoute(WeekViewDemo()),
              child: Text("Week View"),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () => context.pushRoute(MultiDayViewDemo()),
              child: Text("Multi-Day View"),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () => context.pushRoute(EnhancedEventUsageExample()),
              child: Text("Enhanced Event System"),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () => context.pushRoute(JsonViewerPage()),
              child: Text("JSON Storage Viewer"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.brightness_auto,
          color: context.appColors.onPrimary,
        ),
        onPressed: () {
          // Show a snackbar to inform user that theme follows system settings
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Theme automatically follows system settings'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
