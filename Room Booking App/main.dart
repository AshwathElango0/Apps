// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Booking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Booking App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Book a Room'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookRoomPage()),
                );
              },
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              child: const Text('View Bookings'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewBookingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BookRoomPage extends StatefulWidget {
  const BookRoomPage({super.key});

  @override
  BookRoomPageState createState() => BookRoomPageState();
}

class BookRoomPageState extends State<BookRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController roomNumberController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController clubNameController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();

  Future<void> createBooking(Booking booking) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.13:5000/bookings'),  // Replace with your actual IP
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(booking.toJson()),
    );

    if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room has already been booked for this time slot!'), backgroundColor: Colors.red,),
      );
    } else if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created successfully'), backgroundColor: Colors.green,),
      );
      _formKey.currentState?.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book, please try again later :('), backgroundColor: Colors.red,),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: roomNumberController,
                decoration: const InputDecoration(labelText: 'Room Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: purposeController,
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the purpose';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: clubNameController,
                decoration: const InputDecoration(labelText: 'Club Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the club name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the start time';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: endTimeController,
                decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the end time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final booking = Booking(
                      id: 0,
                      roomNumber: roomNumberController.text,
                      purpose: purposeController.text,
                      clubName: clubNameController.text,
                      startTime: startTimeController.text,
                      endTime: endTimeController.text,
                    );
                    createBooking(booking).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create booking'), backgroundColor: Colors.red,),
                      );
                    });
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ViewBookingsPage extends StatelessWidget {
  const ViewBookingsPage({super.key});

  Future<List<Booking>> fetchBookings() async {
    final response = await http.get(Uri.parse('http://192.168.1.13:5000/bookings'));  // Replace with your actual IP
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Booking.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Bookings')),
      body: FutureBuilder<List<Booking>>(
        future: fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Failed to load bookings'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found'));
          } else {
            final bookings = snapshot.data!;
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return ListTile(
                  title: Text('Room ${booking.roomNumber} - ${booking.clubName}'),
                  subtitle: Text('Purpose: ${booking.purpose}  Timings: ${booking.startTime} - ${booking.endTime}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Booking {
  final int id;
  final String roomNumber;
  final String purpose;
  final String clubName;
  final String startTime;
  final String endTime;

  Booking({
    required this.id,
    required this.roomNumber,
    required this.purpose,
    required this.clubName,
    required this.startTime,
    required this.endTime,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      roomNumber: json['room_number'],
      purpose: json['purpose'],
      clubName: json['club_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_number': roomNumber,
      'purpose': purpose,
      'club_name': clubName,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

