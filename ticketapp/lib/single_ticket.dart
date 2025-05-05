import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'punch_error_screen.dart';
import 'event_provider.dart';

class SingleTicketDetailsScreen extends ConsumerStatefulWidget {
  
  final String ticketCode;
  const SingleTicketDetailsScreen({super.key, required this.ticketCode});

  @override
  ConsumerState<SingleTicketDetailsScreen> createState() =>
      _SingleTicketDetailsScreenState();
}

class _SingleTicketDetailsScreenState
    extends ConsumerState<SingleTicketDetailsScreen> {
  bool isLoading = true;
  bool isOutsideScannable = false;
  Map<String, dynamic>? ticket;

  // From API
  int? eventId;
  String? eventName;
  String? dateTime;
  String? location;

  // purchaser (non-reserved tickets)
  String? userName;
  String? userEmail;

  // reservation details (only when status == reserved)
  String? resName;
  String? resEmail;
  String? resPhone;
  String? resComment;

  // Scannable window
  DateTime? scannableFromDt;
  DateTime? scannableUntilDt;
  String scannableFromStr = '';
  String scannableUntilStr = '';

  @override
  void initState() {
    super.initState();
    fetchSingleTicket();
  }

  Future<void> fetchSingleTicket() async {
    const apiUrl = 'https://mapyourevent.myeenterprises.co.uk/api/scan';
    final payload = {'ticket_code': widget.ticketCode};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final t = data[0] as Map<String, dynamic>;
          setState(() {
            ticket = t;

            // ---------- event ----------
            final ev = t['event'] as Map<String, dynamic>?;
            eventId   = ev?['id'] as int?;
            eventName = ev?['name']?.toString() ?? 'Unknown Event';
            dateTime  = buildDateRange(
              ev?['start_date']?.toString() ?? '',
              ev?['end_date']?.toString()   ?? '',
            );
            location  = buildLocation(
              ev?['address_line_1']?.toString() ?? '',
              ev?['city']?.toString()           ?? '',
              ev?['postcode']?.toString()       ?? '',
            );

            // ---------- buyer / reservation ----------
            userName  = t['user']?['name']?.toString()  ?? 'N/A';
            userEmail = t['user']?['email']?.toString() ?? 'N/A';

            if ((t['status']?.toString().toLowerCase() ?? '') == 'reserved') {
              final res = t['additional_info']?['reservation'] as Map?;
              resName    = res?['name']?.toString();
              resEmail   = res?['email']?.toString();
              resPhone   = res?['phone']?.toString();
              resComment = res?['comment']?.toString();
            }

            // ---------- scannable ----------
            parseAndFormatScannableTime(
              t['scannable_from']?.toString() ?? '',
              (fmt) => scannableFromStr = fmt,
              assignTo: (dt) => scannableFromDt = dt,
            );
            parseAndFormatScannableTime(
              t['scannable_until']?.toString() ?? '',
              (fmt) => scannableUntilStr = fmt,
              assignTo: (dt) => scannableUntilDt = dt,
            );
            checkScannableWindow();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No ticket found. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No ticket found. Please try again. (Error ${response.statusCode}).'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String buildDateRange(String startRaw, String endRaw) {
    if (startRaw.isEmpty || endRaw.isEmpty) return 'Date & Time';
    try {
      final s = DateTime.parse(startRaw);
      final e = DateTime.parse(endRaw);
      final sf = DateFormat('d MMM yyyy HH:mm').format(s);
      final ef = DateFormat('d MMM yyyy HH:mm').format(e);
      return '$sf – $ef';
    } catch (_) {
      return 'Date & Time';
    }
  }

  String buildLocation(String a, String c, String p) {
    final parts = [if (a.isNotEmpty) a, if (c.isNotEmpty) c, if (p.isNotEmpty) p];
    return parts.isEmpty ? 'Unknown' : parts.join(', ');
  }

  /// Parses & formats scannable times, and optionally assigns the DateTime.
  void parseAndFormatScannableTime(
    String raw,
    void Function(String) onFormatted, {
    void Function(DateTime)? assignTo,
  }) {
    if (raw.isEmpty) {
      onFormatted('N/A');
      return;
    }
    try {
      final dt = DateTime.parse(raw);
      onFormatted(DateFormat('d MMM yyyy HH:mm').format(dt));
      assignTo?.call(dt);
    } catch (_) {
      onFormatted('N/A');
    }
  }

  void checkScannableWindow() {
    final now = DateTime.now();
    if (scannableFromDt != null && scannableUntilDt != null) {
      setState(() {
        isOutsideScannable =
            now.isBefore(scannableFromDt!) || now.isAfter(scannableUntilDt!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Single Ticket')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Single Ticket')),
        body: const Center(child: Text('No ticket found.')),
      );
    }

    final uuid        = ticket!['uuid']?.toString()   ?? 'N/A';
    final status      = ticket!['status']?.toString() ?? 'N/A';
    final purchasedOn = ticket!['purchased_on']?.toString() ?? 'N/A';
    final price       = ticket!['price']?.toString()  ?? 'N/A';
    final canAdmit = status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'reserved';

    return Scaffold(
      appBar: AppBar(title: const Text('Single Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket type
                Center(
                  child: Text(
                    ticket!['name']?.toString() ?? 'Ticket',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 24),

                // Event
                Text(eventName ?? 'Unknown Event',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Date / time
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(dateTime ?? 'Date & Time')),
                ]),
                const SizedBox(height: 8),

                // Location
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(location ?? 'Unknown')),
                ]),
                const SizedBox(height: 16),

                // ---------- Buyer / Reservation details ----------
                if (status.toLowerCase() == 'reserved')
                  _buildReservationDetails()
                else
                  _buildStandardBuyer(),

                const SizedBox(height: 16),

                // Scannable window
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isOutsideScannable ? Colors.red : Colors.grey),
                  ),
                  child: Text(
                    'Scannable from\n$scannableFromStr – $scannableUntilStr',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                // Purchase date & price
                Row(children: [
                  const Text('Purchase Date: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(purchasedOn)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  const Text('Price: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(price)),
                ]),
                const SizedBox(height: 16),

                // Status
                Row(children: [
                  const Text('Status: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(status),
                ]),
                const SizedBox(height: 16),

                // Ticket Code
                const Text('Ticket Code:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(uuid, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),

                // Cancel & Admit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: canAdmit ? () => confirmAdmit(uuid) : null,
                      child: const Text('Admit',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Standard (non-reserved) buyer information rows
  Widget _buildStandardBuyer() => Column(
        children: [
          Row(children: [
            const Text('Name: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(child: Text(userName ?? 'N/A')),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Text('Email: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(child: Text(userEmail ?? 'N/A')),
          ]),
        ],
      );

  /// Reservation details – show each field only if not null/empty
  Widget _buildReservationDetails() {
    final rows = <Widget>[];

    if (resName != null && resName!.isNotEmpty) {
      rows.add(Row(children: [
        const Text('Name: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(child: Text(resName!)),
      ]));
      rows.add(const SizedBox(height: 4));
    }

    if (resEmail != null && resEmail!.isNotEmpty) {
      rows.add(Row(children: [
        const Text('Email: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(child: Text(resEmail!)),
      ]));
      rows.add(const SizedBox(height: 4));
    }

    if (resPhone != null && resPhone!.isNotEmpty) {
      rows.add(Row(children: [
        const Text('Phone: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(child: Text(resPhone!)),
      ]));
      rows.add(const SizedBox(height: 4));
    }

    if (resComment != null &&
        resComment!.isNotEmpty &&
        resComment!.toLowerCase() != 'null') {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comment: ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(resComment!)),
        ],
      ));
    }

    return Column(children: rows);
  }

  /// Shows the early/late prompt only once per event.
  void confirmAdmit(String uuid) {
    final now = DateTime.now();
    final evId = eventId;
    final already =
        evId != null && ref.read(eventCautionProvider).contains(evId);

    // Early
    if (!already && scannableFromDt != null && now.isBefore(scannableFromDt!)) {
      _showCautionDialog(
        title: 'Admit Ticket Early?',
        message:
            "This ticket isn't scannable until $scannableFromStr.\n\nProceed anyway?",
        onYes: () {
          if (evId != null) {
            ref.read(eventCautionProvider.notifier).markCautioned(evId);
          }
          punchSingleTicket(uuid);
        },
      );
      return;
    }

    // Late
    if (!already && scannableUntilDt != null && now.isAfter(scannableUntilDt!)) {
      _showCautionDialog(
        title: 'Admit Ticket Late?',
        message:
            "This ticket was scannable until $scannableUntilStr.\n\nProceed anyway?",
        onYes: () {
          if (evId != null) {
            ref.read(eventCautionProvider.notifier).markCautioned(evId);
          }
          punchSingleTicket(uuid);
        },
      );
      return;
    }

    // Within window or already confirmed
    punchSingleTicket(uuid);
  }

  void _showCautionDialog({
    required String title,
    required String message,
    required VoidCallback onYes,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.pop(context);
              onYes();
            },
          ),
        ],
      ),
    );
  }

  Future<void> punchSingleTicket(String uuid) async {
    const punchUrl =
        'https://mapyourevent.myeenterprises.co.uk/api/tickets/punch';
    final payload = {"tickets": [uuid]};

    try {
      final resp = await http.post(
        Uri.parse(punchUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final result = (data['data'] as List).first;
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Ticket punched successfully."),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.popUntil(context, (r) => r.isFirst);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PunchErrorScreen(
                  errorMessage:
                      result['message'] ?? "Unable to punch the ticket.",
                  ticketUUID: uuid,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to process request. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Server error (Code: ${resp.statusCode}). Try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("An unexpected error occurred. Please try again later."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}