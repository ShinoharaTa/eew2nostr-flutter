import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import "package:nostr_core_dart/nostr.dart";
import "nostr/connect.dart";
import "nostr/content.dart";
import "widgets/posts.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<String> relays = [
    "wss://relay-jp.nostr.wirednet.jp/",
    "wss://yabu.me/",
    "wss://r.kojira.io/",
    "wss://relay-jp.shino3.net/",
  ];
  final Map<String, int> _relayStatus = {};

  final _streamController = StreamController<List<EEWItem>>();
  void eewCallback(List<Item> channelMessageList) {
    var postListItems = channelMessageList.map((item) {
      Map<String, dynamic> contentJson = jsonDecode(item.content);
      return EEWItem.fromJson(contentJson);
    }).toList();
    _streamController.add(postListItems);
  }

  @override
  void initState() {
    super.initState();
    _connectRelays();
  }

  void _connectRelays() {
    Connect.sharedInstance.addConnectStatusListener((relay, status) {
      setState(() {
        _relayStatus[relay] = status;
        if (_areAllConnectionsCompleted()) {
          fetchEvent(eewCallback);
        }
      });
    });
    Connect.sharedInstance.connectRelays(relays);
  }

  bool _areAllConnectionsCompleted() {
    return relays.every(
        (relay) => _relayStatus[relay] != null && _relayStatus[relay] != 0);
  }

  void _showConnectionStatusModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: relays.map((relay) {
              final status = _relayStatus[relay];
              return ListTile(
                title: Text(relay),
                subtitle: Text(
                  status == 0
                      ? 'Connecting...'
                      : status == 1
                          ? 'Connected'
                          : 'Failed to connect',
                ),
                trailing: Icon(
                  status == 0
                      ? Icons.help_outline
                      : status == 1
                          ? Icons.check_circle
                          : Icons.error,
                  color: status == 0
                      ? Colors.grey
                      : status == 1
                          ? Colors.green
                          : Colors.red,
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectedCount =
        _relayStatus.values.where((status) => status == 1).length;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('緊急地震速報'),
            Text(
              'Connections: $connectedCount/${relays.length}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showConnectionStatusModal(context),
          ),
        ],
      ),
      body: StreamBuilder<List<EEWItem>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<EEWItem> postItems = snapshot.data!;
          if (postItems.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          EEWItem latestItem = postItems.first;
          return Center(
            // padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '緊急地震速報（第${latestItem.serial}報）',
                  style: const TextStyle(fontSize: 24, color: Colors.yellow),
                ),
                const SizedBox(height: 8),
                Text(
                  latestItem.reportTime,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  '震度 ${latestItem.forecast}',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  'M ${latestItem.magnitude}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  latestItem.place,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  '北緯 ${latestItem.latitude}度、東経 ${latestItem.longitude}度\n深さ ${latestItem.depth}km',
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
