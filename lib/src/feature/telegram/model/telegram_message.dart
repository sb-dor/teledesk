import 'package:flutter/foundation.dart';
import 'package:teledesk/src/feature/telegram/model/telegram_user.dart';

@immutable
class TelegramIncomingMessage {
  const TelegramIncomingMessage({
    required this.messageId,
    required this.from,
    required this.chat,
    required this.date,
    this.text,
    this.photo,
    this.video,
    this.document,
    this.sticker,
    this.voice,
    this.videoNote,
    this.audio,
    this.animation,
    this.caption,
  });

  factory TelegramIncomingMessage.fromJson(Map<String, dynamic> json) {
    final fromJson = json['from'] as Map<String, dynamic>?;
    final chatJson = json['chat'] as Map<String, dynamic>?;
    final photoJson = json['photo'] as List<dynamic>?;

    return TelegramIncomingMessage(
      messageId: json['message_id'] as int,
      from: TelegramUser.fromJson(fromJson ?? {}),
      chat: TelegramChat.fromJson(chatJson ?? {}),
      date: DateTime.fromMillisecondsSinceEpoch((json['date'] as int) * 1000),
      text: json['text'] as String?,
      caption: json['caption'] as String?,
      photo: photoJson?.map((p) => TelegramPhotoSize.fromJson(p as Map<String, dynamic>)).toList(),
      video: json['video'] != null
          ? TelegramVideo.fromJson(json['video'] as Map<String, dynamic>)
          : null,
      document: json['document'] != null
          ? TelegramDocument.fromJson(json['document'] as Map<String, dynamic>)
          : null,
      sticker: json['sticker'] != null
          ? TelegramSticker.fromJson(json['sticker'] as Map<String, dynamic>)
          : null,
      voice: json['voice'] != null
          ? TelegramVoice.fromJson(json['voice'] as Map<String, dynamic>)
          : null,
      videoNote: json['video_note'] != null
          ? TelegramVideoNote.fromJson(json['video_note'] as Map<String, dynamic>)
          : null,
      audio: json['audio'] != null
          ? TelegramAudio.fromJson(json['audio'] as Map<String, dynamic>)
          : null,
      animation: json['animation'] != null
          ? TelegramAnimation.fromJson(json['animation'] as Map<String, dynamic>)
          : null,
    );
  }

  final int messageId;
  final TelegramUser from;
  final TelegramChat chat;
  final DateTime date;
  final String? text;
  final List<TelegramPhotoSize>? photo;
  final TelegramVideo? video;
  final TelegramDocument? document;
  final TelegramSticker? sticker;
  final TelegramVoice? voice;
  final TelegramVideoNote? videoNote;
  final TelegramAudio? audio;
  final TelegramAnimation? animation;
  final String? caption;

  String get messageType {
    if (animation != null) return 'gif';
    if (photo != null) return 'photo';
    if (video != null) return 'video';
    if (document != null) return 'document';
    if (sticker != null) return 'sticker';
    if (voice != null) return 'voice';
    if (videoNote != null) return 'video_note';
    if (audio != null) return 'audio';
    return 'text';
  }

  String? get fileId {
    if (animation != null) return animation!.fileId;
    if (photo != null && photo!.isNotEmpty) return photo!.last.fileId;
    if (video != null) return video!.fileId;
    if (document != null) return document!.fileId;
    if (sticker != null) return sticker!.fileId;
    if (voice != null) return voice!.fileId;
    if (videoNote != null) return videoNote!.fileId;
    if (audio != null) return audio!.fileId;
    return null;
  }

  String? get displayText => text ?? caption;
}

@immutable
class TelegramChat {
  const TelegramChat({
    required this.id,
    required this.type,
    this.username,
    this.firstName,
    this.lastName,
  });
  factory TelegramChat.fromJson(Map<String, dynamic> json) => TelegramChat(
    id: json['id'] as int,
    type: json['type'] as String? ?? 'private',
    username: json['username'] as String?,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
  );
  final int id;
  final String type;
  final String? username;
  final String? firstName;
  final String? lastName;
}

@immutable
class TelegramPhotoSize {
  const TelegramPhotoSize({
    required this.fileId,
    required this.fileUniqueId,
    required this.width,
    required this.height,
    this.fileSize,
  });
  factory TelegramPhotoSize.fromJson(Map<String, dynamic> json) => TelegramPhotoSize(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
    fileSize: json['file_size'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final int width;
  final int height;
  final int? fileSize;
}

@immutable
class TelegramVideo {
  const TelegramVideo({
    required this.fileId,
    required this.fileUniqueId,
    this.fileName,
    this.mimeType,
    this.fileSize,
  });
  factory TelegramVideo.fromJson(Map<String, dynamic> json) => TelegramVideo(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    fileName: json['file_name'] as String?,
    mimeType: json['mime_type'] as String?,
    fileSize: json['file_size'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
}

@immutable
class TelegramDocument {
  const TelegramDocument({
    required this.fileId,
    required this.fileUniqueId,
    this.fileName,
    this.mimeType,
    this.fileSize,
  });
  factory TelegramDocument.fromJson(Map<String, dynamic> json) => TelegramDocument(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    fileName: json['file_name'] as String?,
    mimeType: json['mime_type'] as String?,
    fileSize: json['file_size'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
}

@immutable
class TelegramSticker {
  const TelegramSticker({required this.fileId, required this.fileUniqueId, this.fileSize});
  factory TelegramSticker.fromJson(Map<String, dynamic> json) => TelegramSticker(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    fileSize: json['file_size'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final int? fileSize;
}

@immutable
class TelegramVoice {
  const TelegramVoice({
    required this.fileId,
    required this.fileUniqueId,
    this.fileSize,
    this.duration,
  });
  factory TelegramVoice.fromJson(Map<String, dynamic> json) => TelegramVoice(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    fileSize: json['file_size'] as int?,
    duration: json['duration'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final int? fileSize;
  final int? duration;
}

@immutable
class TelegramVideoNote {
  const TelegramVideoNote({
    required this.fileId,
    required this.fileUniqueId,
    this.fileSize,
    this.duration,
  });
  factory TelegramVideoNote.fromJson(Map<String, dynamic> json) => TelegramVideoNote(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    fileSize: json['file_size'] as int?,
    duration: json['duration'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final int? fileSize;
  final int? duration;
}

@immutable
class TelegramAudio {
  const TelegramAudio({
    required this.fileId,
    required this.fileUniqueId,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.duration,
  });
  factory TelegramAudio.fromJson(Map<String, dynamic> json) => TelegramAudio(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    fileName: json['file_name'] as String?,
    mimeType: json['mime_type'] as String?,
    fileSize: json['file_size'] as int?,
    duration: json['duration'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
  final int? duration;
}

@immutable
class TelegramAnimation {
  const TelegramAnimation({
    required this.fileId,
    required this.fileUniqueId,
    this.fileName,
    this.mimeType,
    this.fileSize,
  });
  factory TelegramAnimation.fromJson(Map<String, dynamic> json) => TelegramAnimation(
    fileId: json['file_id'] as String,
    fileUniqueId: json['file_unique_id'] as String,
    fileName: json['file_name'] as String?,
    mimeType: json['mime_type'] as String?,
    fileSize: json['file_size'] as int?,
  );
  final String fileId;
  final String fileUniqueId;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
}
