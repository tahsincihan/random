import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'single_ticket.dart';

class ReservationScreen extends StatefulWidget {
  final int eventId;
  final String eventName;

  const ReservationScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  bool isLoading = false;
  List<dynamic> allTickets = [];
  List<dynamic> filteredTickets = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    setState(() => isLoading = true);

    const url = 'https://mapyourevent.myeenterprises.co.uk/api/reservations';
    final body = {'event_id': widget.eventId};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final reservedTickets = data.where((t) =>
            (t['status']?.toString().toLowerCase() ?? '') == 'reserved');
        setState(() {
          allTickets = reservedTickets.toList();
          filteredTickets = List.from(allTickets);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showError(
            'Oops! Unable to load reservations (Error ${response.statusCode}).');
      }
    } catch (_) {
      setState(() => isLoading = false);
      _showError(
          'An error occurred while loading reservations. Please check your network connection and try again.');
    }
  }

  void _filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() => filteredTickets = List.from(allTickets));
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      filteredTickets = allTickets.where((t) {
        final name = t['additional_info']?['reservation']?['name']
                ?.toString()
                .toLowerCase() ??
            '';
        final comment = t['additional_info']?['reservation']?['comment']
                ?.toString()
                .toLowerCase() ??
            '';
        return name.contains(q) || comment.contains(q);
      }).toList();
    });
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservation List for ${widget.eventName}'),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search reservations...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _filterSearchResults,
                  ),
                ),
                Expanded(
                  child: filteredTickets.isEmpty
                      ? const Center(child: Text('No reserved tickets found.'))
                      : ListView.builder(
                          itemCount: filteredTickets.length,
                          itemBuilder: (_, i) {
                            final t = filteredTickets[i];
                            final resInfo =
                                t['additional_info']?['reservation'] ?? {};
                            final name =
                                resInfo['name']?.toString() ?? 'Unknown';
                            final comment =
                                resInfo['comment']?.toString() ?? '';
                            final status = t['status']?.toString() ?? 'N/A';
                            final uuid = t['uuid']?.toString() ?? '';

                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SingleTicketDetailsScreen(
                                      ticketCode: 'single:$uuid'),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey, width: .5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // left side: name + optional comment
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          if (comment.isNotEmpty)
                                            Text(
                                              comment,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // right side: status + chevron
                                    Text(status,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blueGrey)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
