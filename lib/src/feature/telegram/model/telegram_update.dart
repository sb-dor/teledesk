import 'package:flutter/foundation.dart';
import 'package:teledesk/src/feature/telegram/model/telegram_message.dart';
import 'package:teledesk/src/feature/telegram/model/telegram_user.dart';

@immutable
class TelegramUpdate {
  const TelegramUpdate({required this.updateId, this.message, this.callbackQuery});

  factory TelegramUpdate.fromJson(Map<String, dynamic> json) => TelegramUpdate(
    updateId: json['update_id'] as int,
    message: json['message'] != null
        ? TelegramIncomingMessage.fromJson(json['message'] as Map<String, dynamic>)
        : null,
    callbackQuery: json['callback_query'] != null
        ? TelegramCallbackQuery.fromJson(json['callback_query'] as Map<String, dynamic>)
        : null,
  );

  final int updateId;
  final TelegramIncomingMessage? message;
  final TelegramCallbackQuery? callbackQuery;
}

@immutable
class TelegramCallbackQuery {
  const TelegramCallbackQuery({required this.id, required this.from, this.data});
  factory TelegramCallbackQuery.fromJson(Map<String, dynamic> json) => TelegramCallbackQuery(
    id: json['id'] as String,
    from: TelegramUser.fromJson(json['from'] as Map<String, dynamic>),
    data: json['data'] as String?,
  );
  final String id;
  final TelegramUser from;
  final String? data;
}
