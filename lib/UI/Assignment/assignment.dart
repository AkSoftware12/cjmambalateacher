import 'package:cjmambalateacher/UI/Assignment/upload_assignments.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../HexColorCode/HexColor.dart';
import '../../constants.dart';
import '../Auth/login_screen.dart';
import 'package:html/parser.dart' as html_parser;



class AssignmentListScreen extends StatefulWidget {
  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> {

  bool isLoading = true;
  List assignments = []; // Declare a list to hold API data


  @override
  void initState() {
    super.initState();

      DateTime.now().subtract(const Duration(days: 30));

    fetchAssignmentsData();
  }
  void _refresh() {
    setState(() {
      fetchAssignmentsData();
    });
  }

  Future<void> fetchAssignmentsData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("Token: $token");

    if (token == null) {
      _showLoginDialog();
      return;
    }

    final response = await http.get(
      Uri.parse(ApiRoutes.getAssignments),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        assignments = jsonResponse['data']; // Update state with fetched data
      });
    } else {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Please log in again to continue.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,

      appBar: AppBar(
        iconTheme: IconThemeData(color: AppColors.textwhite),
          backgroundColor: AppColors.secondary,

          title: Text('Assignments',
              style: GoogleFonts.montserrat(
              textStyle: Theme.of(context).textTheme.displayLarge,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.normal,
        color: AppColors.textwhite,
      ),
          ),
        actions: [
          Padding(
            padding:  EdgeInsets.only(right: 18.0),
            child: GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  AssignmentUploadScreen(onReturn: _refresh)),
                  );
                },
                child:Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color:Colors.purple.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black, // You can change the color as needed
                      width: 1,
                    ),
                  ),
                  child:  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        'UPLOAD',
                        style: GoogleFonts.montserrat(
                          textStyle: Theme.of(context).textTheme.displayLarge,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          color: AppColors.textwhite,
                        ),
                      ),
                    ),
                  ),
                )

            ),
          ),

        ],
      ),
      body: assignments.isNotEmpty?


      ListView.builder(
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          String description = html_parser.parse(assignment['description']).body?.text ?? '';
          String startDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(assignment['start_date']));
          String endDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(assignment['end_date']));

          return Card(
            margin: EdgeInsets.all(5),
            elevation: 4,
            color: AppColors.secondary,
            shadowColor: Colors.redAccent,


            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Colors.black, // Border color
                width: 1,          // Border width
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                color: AppColors.textwhite,
                                borderRadius: BorderRadius.circular(25)
                            ),
                            child: Center(
                              child: Text('${index+1}',
                                style: GoogleFonts.montserrat(
                                  textStyle: Theme.of(context).textTheme.displayLarge,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.normal,
                                  color: AppColors.textblack,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [


                              Text(
                                assignment['title'].toString().toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  textStyle: Theme.of(context).textTheme.displayLarge,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.normal,
                                  color: AppColors.textwhite,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: MediaQuery.of(context).size.width*0.4,
                                child: Text(
                                  '${description}'.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                                  style: GoogleFonts.montserrat(
                                    textStyle: Theme.of(context).textTheme.displayLarge,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.normal,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Start : ${startDate}',
                            style: GoogleFonts.montserrat(
                              textStyle: Theme.of(context).textTheme.displayLarge,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.normal,
                              color: AppColors.textwhite,
                            ),
                          ),
                          Text(
                            'Due : ${endDate}',
                            style: GoogleFonts.montserrat(
                              textStyle: Theme.of(context).textTheme.displayLarge,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.normal,
                              color: AppColors.textwhite,
                            ),
                          ),
                        ],
                      )



                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final Uri pdfUri = Uri.parse(assignment['attach_url'].toString());
                          if (await canLaunchUrl(pdfUri)) {
                            await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
                          } else {
                            print("Could not launch $pdfUri");
                          }

                          // if (await canLaunchUrl(Uri.parse(assignment['attach'].toString()))) {
                          // await launchUrl(Uri.parse(assignment['attach'].toString()));
                          // } else {
                          // throw 'Could not launch ${assignment['attach']}';
                          // }
                        },
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color:Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.black, // You can change the color as needed
                                width: 1,
                              ),
                            ),
                            child:  Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  'View'.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    textStyle: Theme.of(context).textTheme.displayLarge,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    color: AppColors.textwhite,
                                  ),
                                ),
                              ),
                            ),
                          )

                      ),

                      GestureDetector(
                          onTap: (){

                          },
                          child:Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color:Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.black, // You can change the color as needed
                                width: 1,
                              ),
                            ),
                            child:  Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  'UPDATE',
                                  style: GoogleFonts.montserrat(
                                    textStyle: Theme.of(context).textTheme.displayLarge,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    color: AppColors.textwhite,
                                  ),
                                ),
                              ),
                            ),
                          )

                      ),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showDeleteConfirmationDialog(assignment['id'].toString()), // Call delete confirmation
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.textblack,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  'DELETE'.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    textStyle: Theme.of(context).textTheme.displayLarge,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    color: AppColors.textwhite,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),



                    ],
                  ),


                ],
              ),
            ),
          );
        },
      ):Container(
          height: MediaQuery.of(context).size.height * 0.7, // 90% of screen height

          child: Center(
              child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Image.asset('assets/no_attendance.png',filterQuality: FilterQuality.high,),
                  Text('Assignments  Not Available.',
                    style: GoogleFonts.montserrat(
                      textStyle: Theme.of(context).textTheme.displayLarge,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.normal,
                      color: AppColors.textwhite,
                    ),

                  )
                ],
              )
          )
      ),
    );
  }

  void _showDeleteConfirmationDialog(String assignmentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this assignment?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteAssignment(assignmentId); // Call API
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // Retrieve Token
      print("Token: $token");

      String apiUrl = "${ApiRoutes.deleteAssignment}/$assignmentId"; // API URL

      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token", // Include token
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        print("Assignment Deleted Successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Assignment Deleted Successfully!")),
        );
        _refresh();

        // Refresh List After Deletion
        setState(() {
          assignments.removeWhere((item) => item['id'] == assignmentId);
        });

      } else {
        print("Failed to Delete: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete assignment")),
        );
      }
    } catch (e) {
      print("Error Deleting Assignment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred while deleting")),
      );
    }
  }


}
