import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nostr_core_dart/nostr.dart';
import './connect.dart';
import 'package:synchronized/synchronized.dart';
import 'package:collection/collection.dart';
import 'package:mutex/mutex.dart';

String tagsToChannelId(List<List<String>> tags) {
  for (var tag in tags) {
    if (tag[0] == "e") return tag[1];
  }
  return '';
}

Thread fromTags(List<List<String>> tags) {
  ETags root = ETags('', '', '');
  List<ETags> replys = [];
  List<PTags> ptags = [];
  for (var tag in tags) {
    if (tag[0] == "p") ptags.add(PTags(tag[1], tag.length > 2 ? tag[2] : ''));
    if (tag[0] == "e") {
      if (tag.length > 3 && tag[3] == 'root') {
        root = ETags(tag[1], tag[2], tag[3]);
      } else if (tag.length > 3 && tag[3] == 'reply') {
        replys.add(ETags(tag[1], tag[2], tag[3]));
      }
    }
  }
  return Thread(root, replys, ptags);
}

class Item {
  final String id;
  final String author;
  final String content;
  final int datetime;

  Item(
      {required this.id,
      required this.author,
      required this.content,
      required this.datetime});
}

typedef RecentChanneMessageCallBack = void Function(
    List<Item> channelMessageList);

final channelMessageListMutex = Mutex();

bool _addOrUpdatefetchEvent(
    List<Item> list, Item newItem, String relay) {
  bool updated = false;
  Item? existingItem;
  existingItem = list.firstWhereOrNull((item) => item.id == newItem.id);

  if (existingItem != null) {
    list.remove(existingItem);
    list.add(Item(
      id: existingItem.id,
      author: existingItem.author,
      content: existingItem.content,
      datetime: existingItem.datetime,
    ));
    updated = true;
  } else {
    list.add(newItem);
    updated = true;
  }
  return updated;
}

void fetchEvent(RecentChanneMessageCallBack callback) async {
  var channelMessageList = <Item>[];

  Future<void> eventCallBack(Event event, String relay) async {
    final newItem = Item(
        id: event.id,
        author: event.pubkey,
        content: event.content,
        datetime: event.createdAt);
    await channelMessageListMutex.acquire();
    try {
      if (_addOrUpdatefetchEvent(channelMessageList, newItem, relay)) {
        channelMessageList.sort((a, b) => a.datetime.compareTo(b.datetime));
        callback(channelMessageList);
      }
    } finally {
      channelMessageListMutex.release();
    }
  }

  final filters = [
    Filter(
        kinds: [30078],
        d: ["eew_alert_system_by_shino3"],
        authors: ["0955d4241024ed1fb0fb5f0607741a3b82ceae940413e566322f9d61cc842def"],
        limit: 10)
  ];

  Connect.sharedInstance.addSubscription(filters, eventCallBack: eventCallBack);
}
