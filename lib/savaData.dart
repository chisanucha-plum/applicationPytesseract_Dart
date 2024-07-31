import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaveDataWidget extends StatefulWidget {
  final TextEditingController controller;
  final List<Map<String, dynamic>> fields;

  SaveDataWidget({required this.controller, required this.fields});

  @override
  _SaveDataWidgetState createState() => _SaveDataWidgetState();
}

class _SaveDataWidgetState extends State<SaveDataWidget> {
  Future<void> _saveToDatabase(BuildContext context) async {
    final uri = Uri.parse('http://your_flask_api_url/api/save');

    try {
      // Prepare the data payload
      List<Map<String, dynamic>> topicsAndLabels = widget.fields.map((field) {
        return {
          'topic': field['name'].text,
          'label': field['value'].text,
        };
      }).toList();

      // Send POST request
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fields': topicsAndLabels}),
      );

      // Check response status and show appropriate SnackBar
      if (response.statusCode == 200) {
        print('Data saved successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved successfully!')),
        );
      } else {
        print('Failed to save data');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data!')),
        );
      }
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        TextField(
          controller: widget.controller,
          maxLines: null,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Result Text',
          ),
        ),
        SizedBox(height: 20),
        ...widget.fields.asMap().entries.map((entry) {
          int index = entry.key;
          var field = entry.value;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: field['isEditing']
                        ? TextField(
                            controller: field['name'],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            style: TextStyle(fontWeight: FontWeight.bold),
                            onSubmitted: (_) {
                              setState(() {
                                field['isEditing'] = false;
                              });
                            },
                          )
                        : Text(field['name'].text),
                  ),
                  IconButton(
                    icon: Icon(field['isEditing'] ? Icons.check : Icons.edit),
                    color: const Color.fromARGB(255, 21, 108, 24),
                    onPressed: () {
                      setState(() {
                        field['isEditing'] = !field['isEditing'];
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        widget.fields.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              TextField(
                controller: field['value'],
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
            ],
          );
        }).toList(),
        ElevatedButton(
          onPressed: () => _saveToDatabase(context),
          child: Text('Save to Database'),
        ),
      ],
    );
  }
}
