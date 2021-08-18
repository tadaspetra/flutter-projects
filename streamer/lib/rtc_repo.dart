import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:creatorstudio/controllers/director_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final rtcRepoProvider = Provider<RtcRepo>((ref) => RtcRepo(ref.read));

class RtcRepo {
  Reader read;
  RtcRepo(this.read);

  Future<AgoraRtmChannel?> joinCallAsDirector(RtcEngine engine, AgoraRtmClient client, String channelName, int uid) async {
    await [Permission.camera, Permission.microphone].request();
    engine.setEventHandler(
      RtcEngineEventHandler(
          error: (code) {
            print(code);
          },
          joinChannelSuccess: (channel, uid, elapsed) {
            print("DIRECTOR $uid");
          },
          leaveChannel: (stats) {},
          userJoined: (uid, elapsed) {
            print("USER JOINED " + uid.toString());
            read(directorController.notifier).addUserToLobby(uid: uid);
          },
          userInfoUpdated: (uid, UserInfo info) {},
          userOffline: (uid, reason) {
            read(directorController.notifier).removeUser(uid: uid);
          },
          remoteAudioStateChanged: (uid, state, reason, elapsed) {
            if ((state == AudioRemoteState.Decoding) && (reason == AudioRemoteStateReason.RemoteUnmuted)) {
              read(directorController.notifier).updateUserAudio(uid: uid, muted: false);
            } else if ((state == AudioRemoteState.Stopped) && (reason == AudioRemoteStateReason.RemoteMuted)) {
              read(directorController.notifier).updateUserAudio(uid: uid, muted: true);
            }
          },
          remoteVideoStateChanged: (uid, state, reason, elapsed) {
            if ((state == VideoRemoteState.Decoding) && (reason == VideoRemoteStateReason.RemoteUnmuted)) {
              read(directorController.notifier).updateUserVideo(uid: uid, videoDisabled: false);
            } else if ((state == VideoRemoteState.Stopped) && (reason == VideoRemoteStateReason.RemoteMuted)) {
              read(directorController.notifier).updateUserVideo(uid: uid, videoDisabled: true);
            }
          },
          streamPublished: (url, error) {
            print("Stream published to $url");
          },
          streamUnpublished: (url) {
            print("Stream unpublished from $url");
          },
          rtmpStreamingStateChanged: (url, state, errorCode) {
            print("Stream State Changed for $url to state $state");
          }),
    );
    engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    engine.setClientRole(ClientRole.Broadcaster);
    engine.enableVideo();

    client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Private Message from " + peerId + ": " + (message.text ?? "null"));
    };
    client.onConnectionStateChanged = (int state, int reason) {
      print('Connection state changed: ' + state.toString() + ', reason: ' + reason.toString());
      if (state == 5) {
        client.logout();
        print('Logout.');
      }
    };

    //join channels
    client.login(null, uid.toString());
    AgoraRtmChannel? _channel = await client.createChannel(channelName);
    _channel?.join();
    engine.joinChannel(null, channelName, null, uid);

    _channel?.onMemberJoined = (AgoraRtmMember member) {
      print("Member joined: " + member.userId + ', channel: ' + member.channelId);
    };
    _channel?.onMemberLeft = (AgoraRtmMember member) {
      print("Member left: " + member.userId + ', channel: ' + member.channelId);
    };
    _channel?.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member) {
      print("Public Message from " + member.userId + ": " + (message.text ?? "null"));
      // List<String> parsedMessage = message.text!.split(" ");
      // switch (parsedMessage[0]) {
      //   case "updateUser":
      //     read(directorController.notifier).updateUsers(message: parsedMessage[1]);
      //     break;
      //   default:
      // }
    };
    return _channel;
  }
}
