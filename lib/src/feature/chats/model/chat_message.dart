import 'package:flutter/foundation.dart';
import 'package:teledesk/src/feature/authentication/model/identity.dart';

enum MessageType { text, photo, video, gif, sticker, document, voice, videoNote, audio, note }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    this.telegramMessageId,
    required this.type,
    this.text,
    this.fileId,
    this.fileName,
    this.fileMimeType,
    this.fileSize,
    required this.isFromBot,
    required this.isNote,
    this.sentByWorkerId,
    this.worker,
    required this.isRead,
    required this.sentAt,
  });

  final int id;
  final int conversationId;
  final int? telegramMessageId;
  final MessageType type;
  final String? text;
  final String? fileId;
  final String? fileName;
  final String? fileMimeType;
  final int? fileSize;
  final bool isFromBot;
  final bool isNote;
  final int? sentByWorkerId;
  final Worker? worker;
  final bool isRead;
  final DateTime sentAt;

  bool get hasMedia => fileId != null;

  String get displayText {
    if (text != null && text!.isNotEmpty) return text!;
    return switch (type) {
      MessageType.photo => '📷 Photo',
      MessageType.video => '🎥 Video',
      MessageType.gif => '🎬 GIF',
      MessageType.sticker => '🎨 Sticker',
      MessageType.document => '📄 ${fileName ?? 'Document'}',
      MessageType.voice => '🎤 Voice message',
      MessageType.videoNote => '📹 Video note',
      MessageType.audio => '🎵 Audio',
      MessageType.note => '📝 Internal note',
      MessageType.text => '',
    };
  }

  ChatMessage copyWith({
    int? id,
    int? conversationId,
    ValueGetter<int?>? telegramMessageId,
    MessageType? type,
    ValueGetter<String?>? text,
    ValueGetter<String?>? fileId,
    ValueGetter<String?>? fileName,
    ValueGetter<String?>? fileMimeType,
    ValueGetter<int?>? fileSize,
    bool? isFromBot,
    bool? isNote,
    ValueGetter<int?>? sentByWorkerId,
    ValueGetter<Worker?>? worker,
    bool? isRead,
    DateTime? sentAt,
  }) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    telegramMessageId: telegramMessageId != null ? telegramMessageId() : this.telegramMessageId,
    type: type ?? this.type,
    text: text != null ? text() : this.text,
    fileId: fileId != null ? fileId() : this.fileId,
    fileName: fileName != null ? fileName() : this.fileName,
    fileMimeType: fileMimeType != null ? fileMimeType() : this.fileMimeType,
    fileSize: fileSize != null ? fileSize() : this.fileSize,
    isFromBot: isFromBot ?? this.isFromBot,
    isNote: isNote ?? this.isNote,
    sentByWorkerId: sentByWorkerId != null ? sentByWorkerId() : this.sentByWorkerId,
    worker: worker != null ? worker() : this.worker,
    isRead: isRead ?? this.isRead,
    sentAt: sentAt ?? this.sentAt,
  );
}
