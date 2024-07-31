import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'config.dart';

class CsvViewerScreen extends StatefulWidget {
  @override
  _CsvViewerScreenState createState() => _CsvViewerScreenState();
}

class _CsvViewerScreenState extends State<CsvViewerScreen> {
  List<Map<String, dynamic>> _data = [];
  String _ipAddress = '172.16.0.236'; // Default Flask server IP
  TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCsvData();
  }
 Future<void> _fetchCsvData() async {
  final uri = Uri.parse('${Config.ipAddressUrl}/api/data');

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      setState(() {
        _data = responseData.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      print('Failed to fetch data. Status: ${response.statusCode}, Body: ${response.body}');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}


  Future<void> _saveCsvData(Map<String, dynamic> item) async {
  final uri = Uri.parse('http://$_ipAddress:5000/api/save');

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item),
    );

    if (response.statusCode == 200) {
      await _fetchCsvData(); // Refresh the data to reflect the new changes
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data saved successfully!')));
    } else {
      print('Failed to save data');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save data!')));
    }
  } catch (e) {
    print('Error saving data: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving data!')));
  }
}


  Future<void> _updateCsvData(Map<String, dynamic> item) async {
  final uri = Uri.parse('${Config.ipAddressUrl}/api/update');

  try {
    print('Attempting to update item: $item');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item),
    );

    print('Update response status: ${response.statusCode}');
    print('Update response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        _data = _data.map((e) => e['label'] == item['label'] ? item : e).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data updated successfully!')));
    } else {
      print('Failed to update data. Status: ${response.statusCode}, Body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update data!')));
    }
  } catch (e) {
    print('Error updating data: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating data: $e')));
  }
}

  Future<void> _deleteCsvData(String label) async {
  final uri = Uri.parse('${Config.ipAddressUrl}/api/delete');

  try {
    print('Attempting to delete item with label: $label');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'label': label}),
    );

    print('Delete response status: ${response.statusCode}');
    print('Delete response body: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        _data.removeWhere((item) => item['label'] == label);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data deleted successfully!')));
    } else if (response.statusCode == 404) {
      print('Data not found on server');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data not found on server!')));
    } else {
      print('Failed to delete data. Status: ${response.statusCode}, Body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete data from server!')));
    }
  } catch (e) {
    print('Error deleting data: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting data: $e')));
  }
}
  Future<void> _downloadCsv() async {
    final uri = Uri.parse('http://$_ipAddress:5000/api/download_csv');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/data.csv';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV downloaded successfully!')));
      } else {
        print('Failed to download CSV');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download CSV!')));
      }
    } catch (e) {
      print('Error downloading CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading CSV!')));
    }
  }

 void _editItem(Map<String, dynamic> item) {
  TextEditingController labelController = TextEditingController(text: item['label']);
  TextEditingController topicController = TextEditingController(text: item['topic']);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('edit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(labelText: 'text'),
            ),
            TextField(
              controller: topicController,
              decoration: InputDecoration(labelText: 'label'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Map<String, dynamic> updatedItem = {
                'label': labelController.text,
                'topic': topicController.text,
              };
              _updateCsvData(updatedItem);
              Navigator.pop(context);
            },
            child: Text('Save'),
           ),
           TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}

  void _showIpSettingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        _ipController.text = _ipAddress;
        return AlertDialog(
          title: Text('Set Server IP Address'),
          content: TextField(
            controller: _ipController,
            decoration: InputDecoration(labelText: 'Server IP Address'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _ipAddress = _ipController.text.trim();
                });
                Navigator.pop(context); 
                _fetchCsvData();
              },
              child: Text('Save'),
             ),
             TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
     appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 185, 39, 26),
                     Color.fromARGB(255, 232, 140, 112),
                ],
              ),
            ),
          ),
          title: Text('Database',
          style: TextStyle(
            color: Colors.white
          ),),
          actions: [
            IconButton(
              icon: Icon(Icons.download,
              color: Colors.white,),
              onPressed: _downloadCsv,
            ),  
          ],
          iconTheme: IconThemeData(
        color: Colors.white, // เปลี่ยนสีลูกศรเป็นสีขาว
          ),
        ),
      body: _data.isEmpty
          ? Center(child: Text('No data available'))
          : ListView.builder(
              itemCount: _data.length,
              itemBuilder: (context, index) {
                final item = _data[index];
                return Dismissible(
                key: Key(item['label']),
                background: Container(color: Colors.red),
                onDismissed: (direction) {
                print('Dismissing item with label: ${item['label']}');
                _deleteCsvData(item['label']);
                },

               child: ListTile(
                title: Text('text : ${item['label']}'),
                subtitle: Text('label : ${item['topic']}'),
                 onTap: () => _editItem(item),
              ),
           );
         },
       ),
    );
  }
}