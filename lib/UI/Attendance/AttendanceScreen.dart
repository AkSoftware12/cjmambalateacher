import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import 'attendance_report.dart';
import 'mark_attendance.dart';

class AttendanceTabScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.06),
          // Set AppBar height
          child: AppBar(
            bottom: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: "Mark Attendance"),
                Tab(text: "Report Attendance"),
              ],
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: screenHeight * 0.85, // Set body height
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.00),
          child: TabBarView(
            children: [
              AttendanceScreen(),
              MonthlyAttendanceScreen(),
            ],
          ),
        ),
      ),
    );
  }
}






