import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class MonthlyAttendanceScreen extends StatefulWidget {
  @override
  _MonthlyAttendanceScreenState createState() =>
      _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  List<dynamic> students = [];
  List<String> dates = [];
  bool isLoading = false;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  List<dynamic> classes = [];
  List<dynamic> sections = [];
  String? selectedClass;
  String? selectedSection;
  DateTime? startDate;
  DateTime? endDate;
  @override
  void initState() {
    super.initState();
    _initializeDefaultDates();
    fetchClassesAndSections();
  }

  /// Set default start and end dates to the first and last day of the current month
  void _initializeDefaultDates() {
    DateTime now = DateTime.now();
    selectedStartDate = DateTime(now.year, now.month, 1); // 1st day of month
    selectedEndDate = DateTime(now.year, now.month + 1, 0); // Last day of month
  }

  /// Fetch classes and sections dynamically from the API
  Future<void> fetchClassesAndSections() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://apicjm.cjmambala.co.in/api/monthly-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          classes = data["data"]["classes"];
          sections = data["data"]["sections"];
        });
      } else {
        throw Exception("Failed to load classes and sections");
      }
    } catch (error) {
      print("Error fetching classes and sections: $error");
    }
  }

  Future<void> fetchMonthlyAttendance() async {
    if (selectedClass == null || selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a class and section")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // String startDate =
      //     "${selectedStartDate!.year}-${selectedStartDate!.month.toString().padLeft(2, '0')}-${selectedStartDate!.day.toString().padLeft(2, '0')}";
      // String endDate =
      //     "${selectedEndDate!.year}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.day.toString().padLeft(2, '0')}";

      final response = await http.get(
        Uri.parse(
            'https://apicjm.cjmambala.co.in/api/monthly-attendance?class=$selectedClass&section=$selectedSection&start_date=$startDate&end_date=$endDate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          students = data["data"]["students"];
          dates = List<String>.from(data["data"]["dates"]);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception("Failed to load attendance");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching data: $error");
    }
  }


  String _mapAttendanceStatus(dynamic value) {
    switch (value) {
      case 1:
        return "P"; // Present
      case 2:
        return "A"; // Absent
      case 3:
        return "L"; // Late
      case 4:
        return "H"; // Half-day
      default:
        return "-"; // Unknown or not recorded
    }
  }


  Color _getAttendanceColor(dynamic value) {
    switch (value) {
      case 1:
        return Colors.green; // P - Present
      case 2:
        return Colors.red; // A - Absent
      case 3:
        return Colors.blue; // L - Late
      case 4:
        return Colors.orange; // H - Half-day
      default:
        return Colors.grey; // Default color for unknown values
    }
  }
  Future<void> _selectDateRange(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Date Range", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: SfDateRangePicker(
                  selectionMode: DateRangePickerSelectionMode.range,
                  onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                    if (args.value is PickerDateRange) {
                      setState(() {
                        startDate = args.value.startDate;
                        endDate = args.value.endDate;
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please select a valid date range")),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  fetchMonthlyAttendance();
                },
                icon: Icon(Icons.check),
                label: Text("Apply Date Range"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Dropdowns for Class and Section
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedClass,
                    items: classes.map((item) {
                      return DropdownMenuItem(
                        value: item["id"].toString(),
                        child: Text(item["title"].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                    },
                    decoration: InputDecoration(labelText: "Select Class"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedSection,
                    items: sections.map((item) {
                      return DropdownMenuItem(
                        value: item["id"].toString(),
                        child: Text(item["title"].toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSection = value.toString();
                      });
                    },
                    decoration: InputDecoration(labelText: "Select Section"),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Date Selection Row
            Container(
              padding: EdgeInsets.all(0),
              // color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: Icon(Icons.calendar_today),
                    label: Text("Select Date Range"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 2,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "From: ",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            Text(
                              startDate != null
                                  ? DateFormat('dd-MM-yyyy').format(startDate!)
                                  : "Select Start Date",
                              style: TextStyle(fontSize: 16, color: Colors.black87,fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 5), // Adds spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "To: ",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            Text(
                              endDate != null
                                  ? DateFormat('dd-MM-yyyy').format(endDate!)
                                  : "Select End Date",
                              style: TextStyle(fontSize: 16, color: Colors.black87,fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : students.isEmpty
                  ? Center(child: Text("No attendance records found"))
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  border: TableBorder.all(color: Colors.black, width: 1), // Table Borders
                  columns: [
                    DataColumn(
                      label: Center(
                        child: Text(
                          "Student Name",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...dates.map((date) => DataColumn(
                      label: Center(
                        child: Text(
                          date,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )).toList(),
                  ],
                  rows: students.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Center(
                            child: Text(
                              student["name"] ?? "Unknown",
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        ...dates.map((date) {
                          return DataCell(
                            Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getAttendanceColor(student["attendance"]?[date]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _mapAttendanceStatus(student["attendance"]?[date]),
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
