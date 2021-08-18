import 'package:flutter/material.dart';

class AgoraUser {
  int uid;
  bool muted;
  bool videoDisabled;
  String? name;
  Color? backgroundColor;

  AgoraUser({
    required this.uid,
    this.muted = false,
    this.videoDisabled = false,
    this.name,
    this.backgroundColor,
  });

  AgoraUser copyWith({
    int? uid,
    bool? muted,
    bool? videoDisabled,
    String? name,
    Color? backgroundColor,
  }) {
    return AgoraUser(
      uid: uid ?? this.uid,
      muted: muted ?? this.muted,
      videoDisabled: videoDisabled ?? this.videoDisabled,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
