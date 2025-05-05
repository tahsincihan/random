import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

import 'single_ticket.dart';
import 'event_provider.dart';     

class MultipleTicketsScreen extends ConsumerStatefulWidget {
  /// Expects ticketCode in the form  "multiple:<group‑code>"
  /// (you *can* still pass "single:<uuid>" – the API returns an array either way)
  final String ticketCode;
  const MultipleTicketsScreen({super.key, required this.ticketCode});

  @override
  ConsumerState<MultipleTicketsScreen> createState() =>
      _MultipleTicketsScreenState();
}

class _MultipleTicketsScreenState
    extends ConsumerState<MultipleTicketsScreen> {
  bool isLoading = true;
  bool isScannedOutsideTime = false;
  List<dynamic> tickets = [];

  // Event‑level fields (come from the first ticket)
  int?    eventId;
  String? eventName;
  String? dateTime;
  String? location;
  String? userName;
  String? userEmail;
  String  scannableFrom = '';
  String  scannableUntil = '';

  /// UUIDs currently ticked in the list
  Set<String> selectedTickets = {};

  @override
  void initState() {
    super.initState();
    fetchTicketDetails();
  }

  /* ───────────────────────── API ───────────────────────── */

  Future<void> fetchTicketDetails() async {
    const apiUrl = 'https://mapyourevent.myeenterprises.co.uk/api/scan';
    final payload = {'ticket_code': widget.ticketCode};

    setState(() => isLoading = true);

    try {
      final resp = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception('status ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body) as List<dynamic>;
      if (data.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final first = data.first as Map<String, dynamic>;

      /* ── auto‑select ACTIVE / RESERVED ─────────────────── */
      final initialSelected = data
          .where((t) {
            final s = (t['status']?.toString() ?? '').toLowerCase();
            return s == 'active' || s == 'reserved';
          })
          .map<String>((t) => t['uuid'].toString())
          .toSet();

      /* ── event + buyer details ─────────────────────────── */
      final ev = first['event'] as Map<String, dynamic>?;
      eventId   = ev?['id'] as int?;
      eventName = ev?['name']?.toString() ?? 'Unknown Event';
      dateTime  = _buildDateRange(
        ev?['start_date']?.toString() ?? '',
        ev?['end_date']?.toString()   ?? '',
      );
      location  = _buildLocation(
        ev?['address_line_1']?.toString() ?? '',
        ev?['city']?.toString()           ?? '',
        ev?['postcode']?.toString()       ?? '',
      );

      userName  = first['user']?['name']?.toString()  ?? 'Unknown';
      userEmail = first['user']?['email']?.toString() ?? 'Unknown';

      scannableFrom  = first['scannable_from']?.toString()  ?? '';
      scannableUntil = first['scannable_until']?.toString() ?? '';

      setState(() {
        tickets         = data;
        selectedTickets = initialSelected;
        isLoading       = false;
      });

      if (scannableFrom.isNotEmpty && scannableUntil.isNotEmpty) {
        _checkOutsideNow(scannableFrom, scannableUntil);
      }

      /* ── one‑off warning for non‑admitable statuses ─────── */
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final invalids = tickets.where((t) {
          final s = (t['status']?.toString() ?? '').toLowerCase();
          return s != 'active' && s != 'reserved';
        }).toList();

        if (invalids.isEmpty) return;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Some tickets cannot be admitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: invalids.map((t) {
                return Text('• ${t['name']}: ${t['status']}');
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      });
    } catch (_) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tickets found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /* ───────────────────── utilities ────────────────────── */

  String _buildDateRange(String s, String e) {
    if (s.isEmpty || e.isEmpty) return 'Date & Time';
    try {
      final start = DateTime.parse(s);
      final end   = DateTime.parse(e);
      return '${DateFormat('d MMM yyyy HH:mm').format(start)} – '
             '${DateFormat('d MMM yyyy HH:mm').format(end)}';
    } catch (_) {
      return 'Date & Time';
    }
  }

  String _buildLocation(String a, String c, String p) {
    final parts = [if (a.isNotEmpty) a, if (c.isNotEmpty) c, if (p.isNotEmpty) p];
    return parts.isEmpty ? 'Unknown' : parts.join(', ');
  }

  String _buildScannableRange(String f, String u) {
    if (f.isEmpty || u.isEmpty) return 'Scannable time not available';
    try {
      return '${DateFormat('d MMM yyyy HH:mm').format(DateTime.parse(f))} – '
             '${DateFormat('d MMM yyyy HH:mm').format(DateTime.parse(u))}';
    } catch (_) {
      return 'Scannable time not available';
    }
  }

  void _checkOutsideNow(String f, String u) {
    try {
      final now = DateTime.now();
      setState(() {
        isScannedOutsideTime =
            now.isBefore(DateTime.parse(f)) || now.isAfter(DateTime.parse(u));
      });
    } catch (_) {}
  }

  /* ───────────────── admission workflow ───────────────── */

  Future<void> admitAll() async {
    if (selectedTickets.isEmpty) return;

    /* ── early / late confirmation (only once per event) ── */
    final evId      = eventId;
    final cautioned = evId != null &&
        ref.read(eventCautionProvider).contains(evId);

    DateTime? fromDt, untilDt;
    try {
      fromDt  = DateTime.parse(scannableFrom);
      untilDt = DateTime.parse(scannableUntil);
    } catch (_) {}

    final now = DateTime.now();
    final needsPrompt = !cautioned &&
        fromDt != null &&
        untilDt != null &&
        (now.isBefore(fromDt) || now.isAfter(untilDt));

    if (needsPrompt) {
      final msg = now.isBefore(fromDt)
          ? "You're admitting BEFORE ${_buildScannableRange(scannableFrom, scannableUntil)}. Continue?"
          : "You're admitting AFTER ${_buildScannableRange(scannableFrom, scannableUntil)}. Continue?";

      final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Confirm Admission'),
              content: Text(msg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ) ??
          false;

      if (!ok) return;

      // mark the event so we don't ask again
      if (evId != null) {
        ref.read(eventCautionProvider.notifier).markCautioned(evId);
      }
    }

    /* ── call punch endpoint ────────────────────────────── */
    const punchUrl = 'https://mapyourevent.myeenterprises.co.uk/api/tickets/punch';
    final payload  = {'tickets': selectedTickets.toList()};

    try {
      final resp = await http.post(
        Uri.parse(punchUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception('status ${resp.statusCode}');
      }

      final data     = jsonDecode(resp.body) as Map<String, dynamic>;
      final anyError = (data['data'] as List).any((r) => r['success'] != true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(anyError
              ? 'Some tickets failed to punch'
              : 'All selected tickets punched successfully'),
          backgroundColor: anyError ? Colors.red : Colors.green,
        ),
      );

      if (!anyError) {
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error punching tickets: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /* ─────────────────────── UI ─────────────────────────── */

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Multiple Tickets')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (tickets.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Multiple Tickets')),
        body: const Center(child: Text('No tickets found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Multiple Tickets')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEventInfo(),
            const SizedBox(height: 16),
            Expanded(child: _buildTicketList()),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isScannedOutsideTime ? Colors.red : Colors.grey,
                ),
              ),
              child: Text(
                'Scannable from\n${_buildScannableRange(scannableFrom, scannableUntil)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tickets Selected: ${selectedTickets.length} out of ${tickets.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: selectedTickets.isNotEmpty ? admitAll : null,
                      child: const Text('Admit Selected',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eventName ?? 'Unknown Event',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(dateTime ?? 'Date & Time')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(location ?? 'Unknown')),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const Text('Name: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(child: Text(userName ?? 'Unknown')),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Text('Email: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(child: Text(userEmail ?? 'Unknown')),
          ]),
        ],
      );

  Widget _buildTicketList() => ListView.separated(
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t      = tickets[i] as Map<String, dynamic>;
          final uuid   = t['uuid']?.toString() ?? '';
          final status = t['status']?.toString() ?? '';
          final admit  = status.toLowerCase() == 'active' ||
                         status.toLowerCase() == 'reserved';
          final checked = selectedTickets.contains(uuid);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2),
            elevation: 1,
            child: ListTile(
              leading: Checkbox(
                value: checked,
                onChanged: admit
                    ? (v) => setState(() {
                          if (v == true) {
                            selectedTickets.add(uuid);
                          } else {
                            selectedTickets.remove(uuid);
                          }
                        })
                    : null,
              ),
              title: Text(t['name'] ?? 'Unknown Ticket',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: status.toLowerCase() == 'reserved'
                  ? Text(
                      'Reserved by: ${t['additional_info']?['reservation']?['name'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status.toLowerCase() == 'reserved'
                            ? Colors.orange
                            : (status.toLowerCase() == 'active'
                                ? Colors.green
                                : Colors.grey),
                      )),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SingleTicketDetailsScreen(ticketCode: 'single:$uuid'),
                ),
              ),
            ),
          );
        },
      );
}
