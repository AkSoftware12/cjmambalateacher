import 'dart:convert';
import 'dart:io';
import 'package:cjmambalateacher/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AssignmentUploadScreen extends StatefulWidget {
  final VoidCallback onReturn;

  const AssignmentUploadScreen({super.key, required this.onReturn});

  @override
  _AssignmentUploadScreenState createState() => _AssignmentUploadScreenState();
}

class _AssignmentUploadScreenState extends State<AssignmentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false; // Add this at the top of the class

  // Dropdown values
  String? selectedClass;
  String? selectedSubject;
  // 📌 **Dropdown Lists with ID and Name**
  List<Map<String, String>> classList = [
    {"id": "1", "name": "Class 10"},
    {"id": "2", "name": "Class 11"},
    {"id": "3", "name": "Class 12"},
  ];

  List<Map<String, String>> subjectList = [
    {"id": "101", "name": "Math"},
    {"id": "102", "name": "Science"},
    {"id": "103", "name": "English"},
  ];



  // Date Pickers
  DateTime? startDate;
  DateTime? endDate;

  // File Upload
  File? selectedImage;
  File? selectedPdf;
  File? selectedFile; // Store the single selected file

  // Controllers
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController totalMarksController = TextEditingController();



  // Image Picker
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  // PDF Picker

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
        });
      } else {
        print("No file selected.");
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File picker is not working properly. Please restart the app.")),
      );
    }
  }



  // Date Picker Function
  Future<void> pickDate(BuildContext context, bool isStartDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }


  Future<void> uploadAssignmentApi() async {
    if (!_formKey.currentState!.validate()) {
      // If form validation fails, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields correctly!")),
      );
      return;
    }

    if (selectedClass == null || selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a Class and Subject")),
      );
      return;
    }

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select start and end date")),
      );
      return;
    }

    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please attach a file before submitting")),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true; // Show loader before API call
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print("Token: $token");

      String apiUrl = '${ApiRoutes.uploadAssignment}';
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add Form Fields
      request.fields['class'] = selectedClass ?? "";
      request.fields['subject'] = selectedSubject ?? "";
      request.fields['title'] = titleController.text;
      request.fields['section'] = '1';
      request.fields['total_marks'] = totalMarksController.text;
      request.fields['start_date'] = startDate?.toString().split(' ')[0] ?? "";
      request.fields['end_date'] = endDate?.toString().split(' ')[0] ?? "";
      request.fields['description'] = descriptionController.text;

      // Attach File
      request.files.add(
        await http.MultipartFile.fromPath(
          'attach',
          selectedFile!.path,
          filename: selectedFile!.path.split('/').last,
        ),
      );

      // Send Request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);


      setState(() {
        isLoading = false; // Hide loader after API call
      });
      if (response.statusCode == 200) {

        widget.onReturn();

        Fluttertoast.showToast(
          msg: "Assignment Uploaded Successfully!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 22.0,
        );

        // Navigate back after a short delay
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pop(context);

        });

      } else {
        print("Failed to Upload: ${response.statusCode} - $jsonResponse");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload assignment: ${jsonResponse['message']}")),
        );
      }
    } catch (e) {
      print("Error Uploading File: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload assignment")),
      );
      setState(() {
        isLoading = false; // Hide loader on error
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      appBar: AppBar(
        title: Text("Upload Assignment",
            style: GoogleFonts.montserrat(
              textStyle: Theme.of(context).textTheme.displayLarge,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              color: AppColors.textblack,
            ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: AppColors.textblack,),
      ),

      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child:Padding(
            padding: EdgeInsets.all(0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 20),

                  // 📌 Class & Subject Dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown("Select Class", classList, selectedClass, (value) {
                          setState(() {
                            selectedClass = value;
                            print(selectedClass);
                          });
                        }),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown("Select Subject", subjectList, selectedSubject, (value) {
                          setState(() {
                            selectedSubject = value;
                            print(selectedSubject);

                          });
                        }),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // 📌 Start & End Date Pickers
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTile("Start Date", startDate, () => pickDate(context, true)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildDateTile("End Date", endDate, () => pickDate(context, false)),
                      ),
                    ],
                  ),
                  SizedBox(height: 20,),
                  // 📌 Title Field
                  _buildTextField("Title", titleController),
                  SizedBox(height: 20,),

                  // 📌 Description Field
                  _buildTextField("Description", descriptionController, maxLines: 3),

                  SizedBox(height: 20),



                  // 📌 Total Marks Field
                  _buildTextField("Total Marks", totalMarksController, keyboardType: TextInputType.number),


                  SizedBox(height: 10),
                  _buildSelectedFile("Attach PDF", Icons.picture_as_pdf, pickFile, selectedPdf != null),

                  SizedBox(height: 20),

                  // 📌 Submit Button
                  // ElevatedButton(
                  //   onPressed: () {
                  //     if (_formKey.currentState!.validate()) {
                  //       uploadAssignmentApi();
                  //     } else {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         SnackBar(content: Text("Please fill all required fields")),
                  //       );
                  //     }
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.orange,
                  //     padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  //   ),
                  //   child: Text("Upload Assignment", style: TextStyle(fontSize: 16, color: Colors.white)),
                  // ),

                  ElevatedButton(
                    onPressed: isLoading ? null : uploadAssignmentApi, // Disable button when loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text("Upload Assignment", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),



                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.textblack),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color:  AppColors.textblack),
        filled: false,
        fillColor:  AppColors.textblack,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) => value!.isEmpty ? "Enter $label" : null,
    );
  }

  Widget _buildDropdown(String label, List<Map<String, String>> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue, // ID is stored here
      decoration: InputDecoration(
        labelText: label,
        filled: false,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dropdownColor: AppColors.textwhite,
      items: items.map((item) => DropdownMenuItem(
        value: item['id'],  // Store the ID
        child: Text(item['name']!, style: TextStyle(color: AppColors.textblack)), // Show the Name
      )).toList(),
      onChanged: onChanged,
    );
  }
  Widget _buildSelectedFile(String label, IconData icon, VoidCallback onTap, bool fileSelected) {
    return selectedFile != null
        ? Card(
      elevation: 3,
      color: AppColors.textwhite,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(Icons.insert_drive_file, color: Colors.orange),
        title: Text(
          selectedFile!.path.split('/').last,
          style: TextStyle(color: Colors.black),
        ),
        subtitle: Text(
          "${(selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB", // Show file size
          style: TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              selectedFile = null;
            });
          },
        ),
      ),
    )
        : Padding(
      padding: EdgeInsets.all(10),
      child: GestureDetector(
        onTap: pickFile,
        child: Container(
          height:150,
            decoration: BoxDecoration(
                color: AppColors.textwhite,
                borderRadius: BorderRadius.circular(10)
            ),
            child: Center(child: Text("No file selected", style: TextStyle(color: Colors.grey)))),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        border: Border.all(
          width: 1,
          color: Colors.black
        )
      ),

      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          date != null ? date.toString().split(' ')[0] : label,
          style: TextStyle(
            color: AppColors.textblack,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.calendar_today, color:AppColors.textblack,),
        onTap: onTap,
      ),
    );
  }


  Widget _buildUploadRow(String label, IconData icon, VoidCallback onTap, bool fileSelected) {
    return Column(
      children: [
        // _buildSelectedFile(), // Display the selected file
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: pickFile,
          child: Text("Pick File"),
        ),
      ],
    );

  }
}
