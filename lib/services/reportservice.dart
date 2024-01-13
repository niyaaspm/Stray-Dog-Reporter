import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  File? slctdimg;
  Position? position;
  String? positionAddress;

  final CollectionReference dogreports =
      FirebaseFirestore.instance.collection('dogreports');
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  @override
  void initState() {
    super.initState();

    _firebaseMessaging.requestPermission();
    _firebaseMessaging.getToken().then((token) {
      print("Firebase Token: $token");
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: $message");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stray Dog Reporter',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                onPressed: () {
                  _pickimagefromcamera();
                },
                color: Colors.cyan,
                child: const Text("Take Photo"),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              child: slctdimg != null
                  ? Image.file(
                      slctdimg!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    )
                  : const Text("Please select image"),
            ),
            const SizedBox(
              height: 20,
            ),
            MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onPressed: () {
                fetchposition();
              },
              color: Colors.cyan,
              child: const Text("Select Location"),
            ),
            const SizedBox(
              height: 20,
            ),
            // Text(position == null ? "Location" : position.toString()),
            Text(
              positionAddress ?? "Click the button to select location",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onPressed: () {
                sendData();
              },
              color: const Color.fromRGBO(0, 212, 18, 1),
              child: const Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _pickimagefromcamera() async {
    var returnedimage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      slctdimg = File(returnedimage!.path);
    });
  }

  fetchposition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Location Service is disabled');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'You denied the permission');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(msg: 'You denied the permission forever');
    }
    Position currentposition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentposition.latitude,
        currentposition.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark firstPlacemark = placemarks.first;

        String street = firstPlacemark.street ?? "";
        String locality = firstPlacemark.locality ?? "";
        String postalCode = firstPlacemark.postalCode ?? "";
        String country = firstPlacemark.country ?? "";
        List<String> addressComponents = [];
        if (street.isNotEmpty) addressComponents.add(street);
        if (locality.isNotEmpty) addressComponents.add(locality);
        if (postalCode.isNotEmpty) addressComponents.add(postalCode);
        if (country.isNotEmpty) addressComponents.add(country);

        String address = addressComponents.join(', ');
        setState(() {
          position = currentposition;
          positionAddress = address;
        });
      } else {
        print("No placemarks found");
      }
    } catch (e) {
      print("Error during reverse geocoding: $e");
    }
  }

  void sendData() {
    if (slctdimg == null || position == null || positionAddress == null) {
      Fluttertoast.showToast(msg: 'Please select image, location, and address');
      return;
    }

    String imagePath = slctdimg!.path;

    Map<String, dynamic> locationMap = {
      'latitude': position!.latitude,
      'longitude': position!.longitude,
    };

    String reportId = DateTime.now().millisecondsSinceEpoch.toString();
    String notificationTitle = 'New Report';
    String notificationBody = 'A new dog report has been submitted.';

    dogreports.doc(reportId).set({
      'imagePath': imagePath,
      'location': locationMap,
      'address': positionAddress,
      'timestamp': FieldValue.serverTimestamp(),
    }).then(
      (value) {
        Fluttertoast.showToast(msg: 'Report submitted successfully');
        Navigator.pop(context);
        _firebaseMessaging
            .subscribeToTopic('dog_reports'); // Subscribe to a topic
        // _firebaseMessaging.sendToTopic('dog_reports', {
        //   'data': {
        //     'reportId': reportId,
        //   },
        //   'notification': {
        //     'title': notificationTitle,
        //     'body': notificationBody,
        //   },
        // });
      },
    ).catchError(
      (error) {
        Fluttertoast.showToast(msg: 'Error submitting report: $error');
      },
    );
  }
}
