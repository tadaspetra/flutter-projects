import 'dart:math';

import 'package:agora_rtm/agora_rtm.dart';
import 'package:creatorstudio/message.dart';
import 'package:creatorstudio/models/user.dart';
import 'package:creatorstudio/utils/app_id.dart';
import 'package:flutter/material.dart';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class ParticipantPage extends StatefulWidget {
  final String channelName;
  final int uid;
  final String userName;

  const ParticipantPage({
    Key? key,
    required this.channelName,
    required this.uid,
    required this.userName,
  }) : super(key: key);

  @override
  _BroadcastPageState createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<ParticipantPage> {
  List<AgoraUser> _users = <AgoraUser>[];
  late RtcEngine _engine;
  AgoraRtmClient? _client;
  AgoraRtmChannel? _channel;
  bool muted = false;
  bool videoDisabled = false;
  bool activeUser = false;

  @override
  void dispose() {
    _channel?.leave();
    _client?.logout();
    _client?.destroy();
    _users.clear();
    _engine.destroy();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initializeAgora();
  }

  Future<void> initializeAgora() async {
    await _initAgora();

    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          print('onJoinChannel: $channel, uid: $uid');
          int randomColor = (Random().nextDouble() * 0xFFFFFFFF).toInt();
          Map<String, String> name = {
            'key': 'name',
            'value': widget.userName,
          };
          Map<String, String> color = {
            'key': 'color',
            'value': randomColor.toString(),
          };
          _client!.addOrUpdateLocalUserAttributes([name, color]);
        });
        if (widget.uid != uid) {
          throw ("How can this happen?!?");
        }
      },
      leaveChannel: (stats) {
        setState(() {
          print('onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          print('userJoined: $uid');

          //_users.add(uid);
        });
      },
      userOffline: (uid, elapsed) {
        setState(() {
          print('userOffline: $uid');
          //_users.remove(uid);
        });
      },
    ));

    _client?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Private Message from " + peerId + ": " + (message.text ?? "null"));
    };
    _client?.onConnectionStateChanged = (int state, int reason) {
      print('Connection state changed: ' + state.toString() + ', reason: ' + reason.toString());
      if (state == 5) {
        _channel?.leave();
        _client?.logout();
        _client?.destroy();
        print('Logout.');
      }
    };
    await _client?.login(null, widget.uid.toString());

    _channel = await _client?.createChannel(widget.channelName);
    await _channel?.join();
    print("UID when joining int ${widget.uid} and string ${widget.uid.toString()}");
    await _engine.joinChannel(null, widget.channelName, null, widget.uid, ChannelMediaOptions(false, false));

    _channel?.onMemberJoined = (AgoraRtmMember member) {
      print("Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    _channel?.onMemberLeft = (AgoraRtmMember member) {
      print("Member left: " + member.userId + ', channel: ' + member.channelId);
    };
    _channel?.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) {
      List<String> parsedMessage = message.text!.split(" ");
      switch (parsedMessage[0]) {
        case "mute":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              muted = true;
            });
            _engine.muteLocalAudioStream(true);
          }
          break;
        case "unmute":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              muted = false;
            });
            _engine.muteLocalAudioStream(false);
          }
          break;
        case "disable":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              videoDisabled = true;
            });
            _engine.muteLocalVideoStream(true);
          }
          break;
        case "enable":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              videoDisabled = false;
            });
            _engine.muteLocalVideoStream(false);
          }
          break;
        case "activeUsers":
          _users = Message().parseActiveUsers(uids: parsedMessage[1]);
          setState(() {});
          break;
        default:
      }
      print("Public Message from " + member.userId + ": " + (message.text ?? "null"));
    };
  }

  Future<void> _initAgora() async {
    _engine = await RtcEngine.createWithConfig(RtcEngineConfig(appId));
    _client = await AgoraRtmClient.createInstance(appId);

    await _engine.enableVideo();
    await _engine.muteLocalAudioStream(true);
    await _engine.muteLocalVideoStream(true);
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: <Widget>[
            _broadcastView(),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          activeUser
              ? RawMaterialButton(
                  onPressed: _onToggleMute,
                  child: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: muted ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                )
              : SizedBox(),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          activeUser
              ? RawMaterialButton(
                  onPressed: _onToggleVideoDisabled,
                  child: Icon(
                    videoDisabled ? Icons.videocam_off : Icons.videocam,
                    color: videoDisabled ? Colors.white : Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: videoDisabled ? Colors.blueAccent : Colors.white,
                  padding: const EdgeInsets.all(12.0),
                )
              : SizedBox(),
          activeUser
              ? RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  child: Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20.0,
                  ),
                  shape: CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<Widget> list = [];
    bool checkIfLocalActive = false;
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].uid == widget.uid) {
        list.add(Stack(children: [
          RtcLocalView.SurfaceView(),
          Align(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(10)), color: Colors.white),
              child: Text(widget.userName),
            ),
            alignment: Alignment.bottomRight,
          ),
        ]));
        checkIfLocalActive = true;
      } else {
        list.add(Stack(children: [
          RtcRemoteView.SurfaceView(uid: _users[i].uid),
          Align(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(10)), color: Colors.white),
              child: Text(_users[i].name ?? "name error"),
            ),
            alignment: Alignment.bottomRight,
          ),
        ]));
      }
    }

    if (checkIfLocalActive) {
      activeUser = true;
    } else {
      activeUser = false;
    }
    return list;
  }

  /// Video view row wrapper
  Widget _expandedVideoView(List<Widget> views) {
    final wrappedViews = views.map<Widget>((view) => Expanded(child: Container(child: view))).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout wrapper
  Widget _broadcastView() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoView([views[0]])
          ],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoView([views[0]]),
            _expandedVideoView([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[_expandedVideoView(views.sublist(0, 2)), _expandedVideoView(views.sublist(2, 3))],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[_expandedVideoView(views.sublist(0, 2)), _expandedVideoView(views.sublist(2, 4))],
        ));
      default:
    }
    return Container();
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleVideoDisabled() {
    setState(() {
      videoDisabled = !videoDisabled;
    });
    _engine.muteLocalVideoStream(videoDisabled);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }
}
