import 'dart:async';
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
      return EEWItem(
        id: item.id,
        content: item.content,
        datetime: item.datetime,
      );
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
          title: Text('Connection Status'),
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
              child: Text('Close'),
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
            Text('Main Screen'),
            Text(
              'Connections: $connectedCount/${relays.length}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _showConnectionStatusModal(context),
          ),
        ],
      ),
      body: StreamBuilder<List<EEWItem>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          // step 2 タイムラインを表示してみよう
          // データがない場合
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // データがある場合
          List<EEWItem> postItems = snapshot.data!;
          return ListView.builder(
            itemCount: postItems.length,
            itemBuilder: (context, index) {
              EEWItem item = postItems[index];
              return ListTile(
                title: Text(item.content),
                // subtitle: Text(item.text),
              );
            },
          );
        },
      ),
    );
  }
}
