import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'reservation.dart';
import 'package:hive_flutter/hive_flutter.dart';


class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool isLoading = false;
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  final TextEditingController searchController = TextEditingController();

  @override
  
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);
    const String url = 'https://mapyourevent.myeenterprises.co.uk/api/ticketscan/events';
      final box = Hive.box('secureBox');
      final token = box.get('access_token');

    try {
      final response = await http.get(Uri.parse(url),
          headers: {'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',},
          );
      if (response.statusCode == 200) {
        final data = (jsonDecode(response.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        setState(() {
          events = data;
          filteredEvents = List.from(events);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showError('Unable to load events (Error ${response.statusCode}).');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error loading events. Check your connection ${e.toString()}.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _filterSearch(String q) {
    if (q.isEmpty) {
      setState(() => filteredEvents = List.from(events));
    } else {
      final query = q.toLowerCase();
      setState(() {
        filteredEvents = events.where((e) {
          final name = (e['name'] ?? '').toString().toLowerCase();
          final addr = (e['address_line_1'] ?? '').toString().toLowerCase();
          return name.contains(query) || addr.contains(query);
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredEvents.isEmpty
              ? const Center(child: Text('No events found.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: _filterSearch,
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Which event are the reservations for?',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    Expanded(child: _buildGroupedList()),
                  ],
                ),
    );
  }

  Widget _buildGroupedList() {
    // 1) sort ascending by start_date
    final sorted = List<Map<String, dynamic>>.from(filteredEvents)
      ..sort((a, b) {
        try {
          return DateTime.parse(a['start_date'])
              .compareTo(DateTime.parse(b['start_date']));
        } catch (_) {
          return 0;
        }
      });

    // 2) group into month headers
    final List<Widget> rows = [];
    String? lastMonth;
    for (var e in sorted) {
      DateTime dt;
      try {
        dt = DateTime.parse(e['start_date']);
      } catch (_) {
        dt = DateTime.now();
      }
      final monthLabel = DateFormat('MMMM yyyy').format(dt);
      if (monthLabel != lastMonth) {
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
            child: Text(
              monthLabel,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
        lastMonth = monthLabel;
      }
      rows.add(_buildEventCard(e));
    }

    return ListView(children: rows);
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final int eventId = event['id'] as int;
    final String logo = event['logo'] as String? ?? '';
    final String name = event['name'] as String? ?? 'Unknown Event';
    final String address = event['address_line_1'] as String? ?? '';
    final String start = event['start_date'] as String? ?? '';
    final String end = event['end_date'] as String? ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReservationScreen(
              eventId: eventId,
              eventName: name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: logo.isNotEmpty
                  ? Image.network(logo, width: 60, height: 60, fit: BoxFit.cover)
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey,
                      child: const Icon(Icons.event, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  if (address.isNotEmpty)
                    Text(address,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(_formatDateRange(start, end),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  /// Convert ISO strings to human‐readable date/time.
  String _formatDateRange(String startIso, String endIso) {
    try {
      final s = DateTime.parse(startIso);
      final e = DateTime.parse(endIso);
      final sf = DateFormat('d MMM yyyy HH:mm').format(s);
      final ef = DateFormat('d MMM yyyy HH:mm').format(e);
      return '$sf – $ef';
    } catch (_) {
      return '$startIso – $endIso';
    }
  }
}
