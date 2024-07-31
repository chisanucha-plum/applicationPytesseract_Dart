import 'dart:io';
import 'dart:convert';
import 'package:TextScan/csvViewerScreen.dart';
//import 'package:TextScan/scanBarcode.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'config.dart';

class OcrScan extends StatefulWidget {
  const OcrScan({Key? key}) : super(key: key);

  @override
  State<OcrScan> createState() => _OcrScanState();
}

class _OcrScanState extends State<OcrScan> {
  String selectedLanguage = 'tha+eng'; 
  bool isLoading = false;
  late ImagePicker imagePicker;
  TextEditingController ipAddressController = TextEditingController();
  TextEditingController ocrTextController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    ipAddressController.text = '172.16.0.236'; // Default IP address
  }

  @override
  void dispose() {
    ipAddressController.dispose();
    ocrTextController.dispose();
    super.dispose();
  }

  Future<void> _uploadFile(File file, String fileType) async {
  setState(() {
    isLoading = true;
    _imageFile = file;
  });

  final uri = Uri.parse('${Config.ipAddressUrl}/api/ocr');

  try {
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path))
      ..fields['language'] = selectedLanguage
      ..fields['fileType'] = fileType;

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var text = jsonDecode(responseData)['text'];
      setState(() {
        isLoading = false;
        ocrTextController.text = text;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return RecognizeScreen(text, ocrTextController, file);
        }),
      );
    } else {
      var responseData = await response.stream.bytesToString();
      print('Response data: $responseData');
      setState(() {
        isLoading = false;
      });
      print('Failed to upload file');
    }
  } catch (e) {
    print('Error uploading file: $e');
    setState(() {
      isLoading = false;
    });
  }
}

  void _showLanguageSelectionDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Select OCR Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Thai + English'),
              onTap: () {
                setState(() {
                  selectedLanguage = 'tha+eng';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Thai Only'),
              onTap: () {
                setState(() {
                  selectedLanguage = 'tha';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('English Only'),
              onTap: () {
                setState(() {
                  selectedLanguage = 'eng';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}
  void _showSetIpAddressDialog() {
  TextEditingController ipController = TextEditingController(text: Config.ipAddress);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Set IP Address'),
        content: TextField(
          controller: ipController,
          decoration: InputDecoration(hintText: 'Enter IP address'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                Config.setIpAddress(ipController.text);
              });
              Navigator.of(context).pop();
            },
            child: Text('Set'),
          ),
        ],
      );
    },
  );
}

CropController _cropController = CropController();
File? _imageFile;
  File? _pdfFile;

 

void _cropImage(XFile xfile) async {
  setState(() {
    _imageFile = File(xfile.path);
  });
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Column(
        children: [
          Expanded(
            child: Crop(
              controller: _cropController,
              image: File(xfile.path).readAsBytesSync(),
              onCropped: (Uint8List value) async {
                File croppedFile = File('${Directory.systemTemp.path}/cropped.png');
                await croppedFile.writeAsBytes(value);
                Navigator.pop(context);

                setState(() {
                  _imageFile = croppedFile;
                });

                await _uploadFile(_imageFile!, 'image');

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return RecognizeScreen(
                      ocrTextController.text,
                      ocrTextController,
                      _imageFile!,
                    );
                  }),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  _cropController.crop();
                },
                child: Text('Crop'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}



void _uploadFiles() async {
  if (_imageFile != null) {
    await _uploadFile(_imageFile!, 'image');
  } else if (_pdfFile != null) {
    await _uploadFile(_pdfFile!, 'pdf');
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(
              child: SpinKitCircle(
                color: Color.fromARGB(255, 119, 4, 4),
                size: 50.0,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [  Color.fromARGB(210, 218, 88, 76),Color.fromARGB(255, 215, 127, 101)])
                  ),
                    padding: EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 20),
                        Card(
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // กำหนดขอบโค้งที่ต้องการ
                          ),
                            child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                            gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                          Color.fromARGB(255, 185, 39, 26),
                          Color.fromARGB(255, 232, 140, 112),
                        ],
                      ),
                                    borderRadius: BorderRadius.circular(15.0), // กำหนดขอบโค้งให้กับ Container
                                  ),
                                child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                            InkWell(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Icon(
                          Icons.change_circle_outlined
                          ,
                            size: 25,
                            color: Colors.white,
                            ),
                            Text(
                          "Language",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                            ),
                        onTap: () {
                               _showLanguageSelectionDialog();
                            },
                          ),
                        InkWell(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.data_saver_off_outlined, 
                            size: 25, color: Colors.white),
                            Text("Database", style: TextStyle(
                            color: Colors.white)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (ctx) => CsvViewerScreen(),
                          ));
                        },
                      ),
                      InkWell(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Icon(
                          Icons.wifi_find_outlined,
                            size: 25,
                            color: Colors.white,
                            ),
                            Text(
                          "IP Address",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                            ),
                        onTap: () {
                              _showSetIpAddressDialog();
                            },
                           ),
                          ],
                        ),
                      ),
                    ),              
                  Card(
                    color: Color.fromARGB(255, 36, 35, 35),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 210,
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0), // กำหนดขอบโค้งที่ต้องการ
                    ),
                       child: Container(
                       height: 70,
                       decoration: BoxDecoration(
                      gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                     Color.fromARGB(255, 185, 39, 26),
                     Color.fromARGB(255, 232, 140, 112),
                       ],
                      ),
                        borderRadius: BorderRadius.circular(15.0), // กำหนดขอบโค้งให้กับ Container
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [   
                          InkWell(
                          child: const Icon(
                          Icons.attach_file,
                          size: 25,
                          color: Colors.white,
                               ),
                            onTap: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              );
    
                            if (result != null) {
                             File file = File(result.files.single.path!);
                              String fileName = result.files.single.name;
                              String fileExtension = fileName.split('.').last.toLowerCase();
                              
                              String fileType;
                              switch (fileExtension) {
                              case 'pdf':
                              fileType = 'pdf';
                              break;
                              case 'jpg':
                              case 'jpeg':
                              case 'png':
                              fileType = 'image';
                              break;
                              default:
                              // แสดงข้อความแจ้งเตือนว่าไม่รองรับไฟล์ประเภทนี้
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Unsupported file type')),
                                );
                                  return;
                            }

                                await _uploadFile(file, fileType);
                            }
                              //เลือกไฟล์มาใส่ได้
                            },
                          ),

                          InkWell(
                            child: const Icon(
                              Icons.camera_outlined,
                              size: 40,
                              color: Colors.white
                            ),
                            onTap: () async {
                              XFile? xfile = await imagePicker.pickImage(source: ImageSource.camera);
                              if (xfile != null) {
                                _cropImage(xfile);
                              }
                            },
                          ),
                          InkWell(
                            child: const Icon(
                              Icons.image_outlined,
                              size: 25,
                              color: Colors.white,
                            ),
                            onTap: () async {
                              XFile? xfile = await imagePicker.pickImage(source: ImageSource.gallery);
                              if (xfile != null) {
                                setState(() {
                                  _imageFile = File(xfile.path);
                                });
                                _cropImage(xfile);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class RecognizeScreen extends StatefulWidget {
  final String text;
  final TextEditingController controller;
  final File imageFile;
  
  RecognizeScreen(this.text, this.controller,this.imageFile);

  @override
  _RecognizeScreenState createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends State<RecognizeScreen> {
  final List<Map<String, dynamic>> fields = [];
  late File imageFile;
  late TextEditingController controller;
  

  
  @override
  void initState() {
    super.initState();
    imageFile = widget.imageFile;
    controller = widget.controller;
    parseAndCategorize(widget.text);
  }

  @override
  void didUpdateWidget(RecognizeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFile != oldWidget.imageFile) {
      setState(() {
        imageFile = widget.imageFile;
      });
    }
    if (widget.text != oldWidget.text) {
      parseAndCategorize(widget.text);
    }
  }

  void parseAndCategorize(String ocrText) {
    String cleanedText = ocrText.replaceAll(' ', '');

    RegExp fieldRegex = RegExp(r'([ก-๙a-zA-Z]+[:])(.*)');
    RegExp dateRegex1 = RegExp(r'(\d{2}\.\d{2}\.\d{4})');
    RegExp dateRegex2 = RegExp(r'(\d{2} [a-zA-Z]{3} \d{4})');
    RegExp fieldRegex4 = RegExp(r'\b\d{6,8}\b');
    RegExp idRegex = RegExp(r'\d{11,}'); // 11 หลักขึ้นไป
    RegExp currencyRegex = RegExp(r'(?<!\d)(\d{1,3}(,\d{3})*\.\d{2})');
    

    Iterable<RegExpMatch> fieldMatches = fieldRegex.allMatches(cleanedText);
    Iterable<RegExpMatch> dateMatches1 = dateRegex1.allMatches(cleanedText);
    Iterable<RegExpMatch> dateMatches2 = dateRegex2.allMatches(cleanedText);
    Iterable<RegExpMatch> fieldMatches4 = fieldRegex4.allMatches(cleanedText);
    Iterable<RegExpMatch> idMatches = idRegex.allMatches(cleanedText); // การจับคู่สำหรับ ID
    Iterable<RegExpMatch> currencyMatches = currencyRegex .allMatches(cleanedText); 

    void addField(String name, String value) {
      fields.add({
        'name': TextEditingController(text: name),
        'value': TextEditingController(text: value),
        'isEditing': false,
      });
    }

    fieldMatches.forEach((match) {
      String fieldName = match.group(1)?.replaceAll(':', '') ?? '';
      String fieldValue = match.group(2) ?? '';
      addField(fieldName, fieldValue);
    });

    dateMatches1.forEach((match) {
      String dateValue = match.group(1) ?? '';
      addField('Invoice Date', dateValue);
    });

    dateMatches2.forEach((match) {
      String dateValue = match.group(1) ?? '';
      addField('Invoice Date', dateValue);
    });

    fieldMatches4.forEach((match) {
      String fieldValue = match.group(0) ?? '';
      addField('Invoice No. ', fieldValue);
    });

    idMatches.forEach((match) {
      String idValue = match.group(0) ?? ''; // Group 0 จะเป็นตัวเลขที่จับได้
      addField('Bill Tax ID', idValue);
    });

    currencyMatches.forEach((match) {
  String currencySymbol = match.group(1) ?? '';
  String amountValue = match.group(2) ?? '';
  addField('Amount', '$currencySymbol$amountValue');
});
}

  Future<void> _saveToDatabase(BuildContext context) async {
  final uri = Uri.parse('${Config.ipAddressUrl}/api/save');

   try {
    // Prepare the data payload
    List<Map<String, String>> topicsAndLabels = fields.map<Map<String, String>>((field) {
      return {
        'topic': field['name'].text,
        'label': field['value'].text,
      };
    }).toList();

    Map<String, dynamic> data = {
      'fields': topicsAndLabels,
    };

    // Send POST request
    var response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
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
    widget.controller.text = widget.text;

    return Scaffold(
      
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(18.0),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0), // กำหนดขอบโค้งที่ต้องการ
                    ),
                       child: Container(
                       height: 70,
                       decoration: BoxDecoration(
                      gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                     Color.fromARGB(255, 185, 39, 26),
                     Color.fromARGB(255, 232, 140, 112),
                   ],
                 ),
                  borderRadius: BorderRadius.circular(15.0), // กำหนดขอบโค้งให้กับ Container
                ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, size: 25, color: Colors.white),
                            Text("Delete",
                             style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onTap: () {
                          widget.controller.clear();
                          
                        },
                      ),
                      InkWell(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.data_saver_off_outlined, size:25, color: Colors.white),
                            Text("Database", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (ctx) => CsvViewerScreen(),
                          ));
                        },
                      ),
                      InkWell(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 25, color: Colors.white),
                            Text("Save", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onTap: () {
                          _saveToDatabase(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
               SizedBox(height: 10),
                 Stack(
                children: [
                  TextField(
                    controller: widget.controller,
                    maxLines: null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Result Text',
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.controller.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Text copied to clipboard!')),
                        );
                      },
                      child: Icon(Icons.copy, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
                  Container(
                height: 250,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                    key: ValueKey(imageFile.path),
                  ),
                ),
              ),
              SizedBox(height: 5),
              //ต้องการเอาภาพที่ครอปมาโชว์ตรงนี้
              
              ...fields.asMap().entries.map((entry) {
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
                                    labelText: null,
                                  ),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  onSubmitted: (_) {
                                    setState(() {
                                      field['isEditing'] = false;
                                    });
                                  },
                                )
                                
                              : Text(
                                field['name'].text),         
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
                              fields.removeAt(index);
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
               SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}