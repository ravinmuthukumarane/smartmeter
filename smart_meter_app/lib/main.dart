import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart'; // for date and time formatting

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Meter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecondScreen()),
            );
          },
          child: Text('Upload The Task'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ),
    );
  }
}

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  final _formKey = GlobalKey<FormState>();
  String _location = 'Unknown';
  String _selectedUser = 'User 1';
  final TextEditingController _oldMeterController = TextEditingController();
  final TextEditingController _newMeterController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<XFile>? _images = [];
  bool _isPreview = false;
  static int _taskNumber = 1;
  DateTime _currentDateTime = DateTime.now();

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = 'Location permissions are permanently denied, we cannot request permissions.';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _location = 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
    });
  }

  Future<void> _pickImagesFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedImages = await picker.pickMultiImage();
    setState(() {
      if (pickedImages != null) {
        _images = pickedImages;
      }
    });
  }

  Future<void> _takePhotoWithCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (photo != null) {
        _images?.add(photo);
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images?.removeAt(index);
    });
  }

  void _togglePreview() {
    setState(() {
      _isPreview = !_isPreview;
    });
  }

  Future<void> _uploadData() async {
    var db = await mongo.Db.create('mongodb://appUser:password@192.46.214.230:27017/smart_meter_app');
    await db.open();

    var collection = db.collection('meter_data');

    var data = {
      'taskNumber': _taskNumber++,
      'location': _location,
      'selectedUser': _selectedUser,
      'oldMeterNumber': _oldMeterController.text,
      'newMeterNumber': _newMeterController.text,
      'notes': _notesController.text,
      'dateTime': DateFormat('yyyy-MM-dd – kk:mm').format(_currentDateTime),
      'images': _images?.map((image) => base64Encode(File(image.path).readAsBytesSync())).toList(),
    };

    await collection.insert(data);
    await db.close();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data uploaded successfully!')),
    );

    _togglePreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit The Task Before Upload'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPreview ? _buildPreview() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _getLocation,
                child: Text('Get the location'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(_location),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedUser,
              items: ['User 1', 'User 2']
                  .map((user) => DropdownMenuItem<String>(
                        value: user,
                        child: Text(user),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUser = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Select User',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _oldMeterController,
              decoration: InputDecoration(
                labelText: 'Old Meter Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter old meter number';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _newMeterController,
              decoration: InputDecoration(
                labelText: 'New Meter Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter new meter number';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter notes';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: _pickImagesFromGallery,
                  child: Text('Upload Photos'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                OutlinedButton(
                  onPressed: _takePhotoWithCamera,
                  child: Text('Take a Photo'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _images != null && _images!.isNotEmpty
                ? Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _images!.asMap().entries.map((entry) {
                      int index = entry.key;
                      XFile image = entry.value;
                      return Stack(
                        children: [
                          Image.file(
                            File(image.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  )
                : Text('No images selected'),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _togglePreview();
                  }
                },
                child: Text('Preview'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Task Number: $_taskNumber'),
          SizedBox(height: 20),
          Text('Location: $_location'),
          SizedBox(height: 20),
          Text('Selected User: $_selectedUser'),
          SizedBox(height: 20),
          Text('Old Meter Number: ${_oldMeterController.text}'),
          SizedBox(height: 20),
          Text('New Meter Number: ${_newMeterController.text}'),
          SizedBox(height: 20),
          Text('Notes: ${_notesController.text}'),
          SizedBox(height: 20),
          Text('Date and Time: ${DateFormat('yyyy-MM-dd – kk:mm').format(_currentDateTime)}'),
          SizedBox(height: 20),
          _images != null && _images!.isNotEmpty
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _images!.map((image) {
                    return Image.file(
                      File(image.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  }).toList(),
                )
              : Text('No images selected'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: _togglePreview,
                child: Text('Back to Edit'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              OutlinedButton(
                onPressed: _uploadData,
                child: Text('Upload'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
