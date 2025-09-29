import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'instructor_dashboard.dart';

class InstructorForm extends StatefulWidget {
  final String instructorName;

  const InstructorForm({super.key, required this.instructorName});

  @override
  State<InstructorForm> createState() => _InstructorFormState();
}

class _InstructorFormState extends State<InstructorForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // List of certificates with description
  List<Map<String, String>> certificates = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill name from login
    _nameController.text = widget.instructorName;
  }

  Future<void> _pickCertificates() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        for (var file in result.paths) {
          if (file != null) {
            certificates.add({
              "path": file,
              "description": "", // initially empty, will be filled by user
            });
          }
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Collect form data
      final data = {
        "name": _nameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text,
        "specialization": _specializationController.text,
        "experience": _experienceController.text,
        "certificates": certificates,
      };

      // Navigate to dashboard with name
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              InstructorDashboard(instructorName: _nameController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Instructor Form")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your name" : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.contains("@") ? null : "Enter valid email",
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Phone No."),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value!.length == 10 ? null : "Enter 10-digit phone no.",
                ),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(
                    labelText: "Specialization",
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter specialization" : null,
                ),
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: "Experience (years)",
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? "Enter experience" : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickCertificates,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Certificates"),
                ),
                if (certificates.isNotEmpty)
                  Column(
                    children: certificates.asMap().entries.map((entry) {
                      int index = entry.key;
                      var cert = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(cert["path"]!.split('/').last),
                              ),
                              TextFormField(
                                initialValue: cert["description"],
                                decoration: const InputDecoration(
                                  labelText: "Certificate Description",
                                ),
                                onChanged: (value) {
                                  certificates[index]["description"] = value;
                                },
                                validator: (value) => value!.isEmpty
                                    ? "Please add description"
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Submit"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
