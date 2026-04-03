// seed_data.dart — Run this once to seed Firestore with test location data
// Usage: Add a button in the app or call seedData() from main() in debug mode

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedCampusData() async {
  final db = FirebaseFirestore.instance;

  // Sample campus locations around New Delhi (28.6139°N, 77.2090°E)
  final locations = [
    {
      'name': 'Main Library',
      'category': 'library',
      'building': 'Building A',
      'floor': 1,
      'description':
          'The main campus library with over 50,000 books, digital resources, and quiet study zones.',
      'latitude': 28.6145,
      'longitude': 77.2085,
      'imageUrl': '',
      'tags': ['study', 'books', 'research', 'wifi'],
      'isIndoor': true,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Computer Science Lab',
      'category': 'lab',
      'building': 'Building B',
      'floor': 2,
      'description':
          'State-of-the-art CS lab with 80 workstations, high-speed internet, and specialized software.',
      'latitude': 28.6135,
      'longitude': 77.2095,
      'imageUrl': '',
      'tags': ['computers', 'programming', 'lab', 'coding'],
      'isIndoor': true,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Admin Office',
      'category': 'office',
      'building': 'Building C',
      'floor': 1,
      'description':
          'Administrative offices for admissions, registrar, and student affairs.',
      'latitude': 28.6150,
      'longitude': 77.2100,
      'imageUrl': '',
      'tags': ['administration', 'admissions', 'registrar', 'records'],
      'isIndoor': true,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Main Cafeteria',
      'category': 'cafeteria',
      'building': 'Building D',
      'floor': 0,
      'description':
          'The central dining area serving breakfast, lunch and dinner with multiple cuisine options.',
      'latitude': 28.6128,
      'longitude': 77.2088,
      'imageUrl': '',
      'tags': ['food', 'dining', 'lunch', 'breakfast'],
      'isIndoor': true,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Lecture Hall 101',
      'category': 'classroom',
      'building': 'Building A',
      'floor': 1,
      'description':
          'Large lecture hall accommodating 300 students with smart board and audio-visual equipment.',
      'latitude': 28.6142,
      'longitude': 77.2080,
      'imageUrl': '',
      'tags': ['lecture', 'classroom', 'hall', 'seminar'],
      'isIndoor': true,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Lecture Hall 205',
      'category': 'classroom',
      'building': 'Building B',
      'floor': 2,
      'description':
          'Medium-sized classroom with modern seating and projector setup for 120 students.',
      'latitude': 28.6133,
      'longitude': 77.2092,
      'imageUrl': '',
      'tags': ['lecture', 'classroom', 'projector', 'seminar'],
      'isIndoor': true,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Main Parking',
      'category': 'parking',
      'building': 'Outside',
      'floor': 0,
      'description':
          'Multi-level parking facility with 500+ spaces for students, faculty and visitors.',
      'latitude': 28.6120,
      'longitude': 77.2105,
      'imageUrl': '',
      'tags': ['parking', 'car', 'vehicle', 'covered'],
      'isIndoor': false,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Main Entrance',
      'category': 'entrance',
      'building': 'Gate 1',
      'floor': 0,
      'description':
          'The main entrance gate to the campus with security check and visitor registration.',
      'latitude': 28.6115,
      'longitude': 77.2090,
      'imageUrl': '',
      'tags': ['gate', 'entrance', 'security', 'main'],
      'isIndoor': false,
      'indoorFloorPlanUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  // Seed locations
  final batch = db.batch();
  for (final loc in locations) {
    final ref = db.collection('locations').doc();
    batch.set(ref, loc);
  }

  // Seed sample announcements
  final announcements = [
    {
      'title': 'Campus Wi-Fi Upgrade',
      'body': 'Campus-wide Wi-Fi will be upgraded this weekend. Expect brief downtime.',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Library Extended Hours',
      'body': 'Main Library will be open until midnight during examination week.',
      'timestamp': FieldValue.serverTimestamp(),
    },
    {
      'title': 'New Lab Equipment',
      'body': 'CS Lab has been upgraded with 40 new workstations. Available from Monday.',
      'timestamp': FieldValue.serverTimestamp(),
    },
  ];

  for (final ann in announcements) {
    final ref = db.collection('announcements').doc();
    batch.set(ref, ann);
  }

  await batch.commit();
  print('✅ Seed data written to Firestore successfully!');
}
