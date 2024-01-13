import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportedPage extends StatefulWidget {
  const ReportedPage({super.key});

  @override
  State<ReportedPage> createState() => _ReportedPageState();
}

class _ReportedPageState extends State<ReportedPage> {
  final CollectionReference dogreports =
      FirebaseFirestore.instance.collection('dogreports');
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
        child: StreamBuilder<QuerySnapshot>(
          stream: dogreports.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot reportsnap =
                        snapshot.data!.docs[index];
                    DateTime timestamp =
                        (reportsnap['timestamp'] as Timestamp).toDate();
                    String formattedTimestamp = "${timestamp.toLocal()}";

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 15,
                                  spreadRadius: 10)
                            ]),
                        height: 80,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: FileImage(
                                        File(reportsnap['imagePath'])),
                                    fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(reportsnap['address']),
                            subtitle: Text(formattedTimestamp),
                            // subtitle: Text(reportsnap['location']),
                          ),
                        ),
                      ),
                    );
                  });
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
