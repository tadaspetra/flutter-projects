import 'package:creatorstudio/controllers/director_controller.dart';
import 'package:creatorstudio/models/director_model.dart';
import 'package:creatorstudio/models/stream.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:circular_menu/circular_menu.dart';

class BroadcastPage extends StatefulWidget {
  final String channelName;
  final int uid;

  const BroadcastPage({
    Key? key,
    required this.channelName,
    required this.uid,
  }) : super(key: key);

  @override
  _BroadcastPageState createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  String? streamUrl;

  @override
  void initState() {
    context.read(directorController.notifier).joinCall(channelName: widget.channelName, uid: widget.uid);
    super.initState();
  }

  Future<dynamic> showYoutubeBottomSheet(BuildContext context, Object value, DirectorController directorNotifier) {
    TextEditingController streamUrl = TextEditingController();
    TextEditingController streamKey = TextEditingController();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Your Stream Destination",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                autofocus: true,
                controller: streamUrl,
                decoration: InputDecoration(hintText: "Stream Url"),
              ),
              TextField(
                controller: streamKey,
                decoration: InputDecoration(hintText: "Stream Key"),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        directorNotifier.addPublishDestination(
                            value as StreamPlatform, streamUrl.text.trim() + "/" + streamKey.text.trim());
                        Navigator.pop(context);
                      },
                      child: Text("Add"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<dynamic> showTwitchBottomSheet(BuildContext context, Object value, DirectorController directorNotifier) {
    TextEditingController streamUrl = TextEditingController();
    TextEditingController streamKey = TextEditingController();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add Your Stream Destination",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(
                height: 20,
              ),
              TextField(
                autofocus: true,
                controller: streamUrl,
                decoration: InputDecoration(hintText: "Injest Url"),
              ),
              TextField(
                controller: streamKey,
                decoration: InputDecoration(hintText: "Stream Key"),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        directorNotifier.addPublishDestination(
                            value as StreamPlatform, "rtmp://" + streamUrl.text.trim() + "/app/" + streamKey.text.trim());
                        Navigator.pop(context);
                      },
                      child: Text("Add"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _deleteButton(StreamDestination destination) {
    switch (destination.platform) {
      case StreamPlatform.youtube:
        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.red),
          child: Text(
            "Youtube",
            style: TextStyle(color: Colors.white),
          ),
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(right: 4),
        );
      case StreamPlatform.twitch:
        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.purple),
          child: Text(
            "Twitch",
            style: TextStyle(color: Colors.white),
          ),
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(right: 4),
        );
      case StreamPlatform.other:
        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black),
          child: Text(
            "Other",
            style: TextStyle(color: Colors.white),
          ),
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(right: 4),
        );
      default:
        return Text("Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (BuildContext context, T Function<T>(ProviderBase<Object?, T>) watch, Widget? child) {
      DirectorController directorNotifier = watch(directorController.notifier);
      DirectorModel directorData = watch(directorController);
      Size size = MediaQuery.of(context).size;
      return Scaffold(
          body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircularMenu(
          alignment: Alignment.bottomRight,
          toggleButtonColor: Colors.black87,
          toggleButtonBoxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          items: [
            CircularMenuItem(
                icon: Icons.call_end,
                color: Colors.red,
                onTap: () {
                  directorNotifier.leaveCall();
                  Navigator.pop(context);
                }),
            directorData.isLive
                ? CircularMenuItem(
                    icon: Icons.cancel,
                    color: Colors.orange,
                    onTap: () {
                      directorNotifier.endStream();
                    },
                  )
                : CircularMenuItem(
                    icon: Icons.videocam,
                    color: Colors.orange,
                    onTap: () {
                      if (directorData.destinations.isNotEmpty) {
                        directorNotifier.startStream();
                      } else {
                        throw ("Invalid URL");
                      }
                    },
                  ),
          ],
          backgroundWidget: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PopupMenuButton(
                            itemBuilder: (context) {
                              List<PopupMenuEntry<Object>> list = [];
                              list.add(PopupMenuItem(
                                child: ListTile(leading: Icon(Icons.add), title: Text("Youtube")),
                                value: StreamPlatform.youtube,
                              ));
                              list.add(PopupMenuDivider());
                              list.add(PopupMenuItem(
                                child: ListTile(leading: Icon(Icons.add), title: Text("Twitch")),
                                value: StreamPlatform.twitch,
                              ));
                              list.add(PopupMenuDivider());
                              list.add(PopupMenuItem(
                                child: ListTile(leading: Icon(Icons.add), title: Text("Other")),
                                value: StreamPlatform.other,
                              ));
                              return list;
                            },
                            icon: Icon(Icons.add),
                            onCanceled: () {
                              print("You have canceled the menu");
                            },
                            onSelected: (value) {
                              if (value == StreamPlatform.twitch) {
                                showTwitchBottomSheet(context, value!, directorNotifier);
                              } else {
                                showYoutubeBottomSheet(context, value!, directorNotifier);
                              }
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          for (int i = 0; i < directorData.destinations.length; i++)
                            PopupMenuButton(
                              itemBuilder: (context) {
                                List<PopupMenuEntry<Object>> list = [];
                                list.add(
                                    PopupMenuItem(child: ListTile(leading: Icon(Icons.remove), title: Text("Remove Stream")), value: 0));
                                return list;
                              },
                              child: _deleteButton(directorData.destinations[i]),
                              onCanceled: () {
                                print("You have canceled the menu");
                              },
                              onSelected: (value) {
                                directorNotifier.removePublishDestination(directorData.destinations[i].url);
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              if (directorData.activeUsers.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("Empty Stage"),
                        ),
                      ),
                    ],
                  ),
                ),
              SliverGrid(
                gridDelegate:
                    SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: size.width / 2, crossAxisSpacing: 20, mainAxisSpacing: 20),
                delegate: SliverChildBuilderDelegate((BuildContext ctx, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: directorData.activeUsers.elementAt(index).videoDisabled
                                    ? Stack(children: [
                                        Container(
                                          color: Colors.black,
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            "Video Off",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        )
                                      ])
                                    : Stack(children: [
                                        RtcRemoteView.SurfaceView(uid: directorData.activeUsers.elementAt(index).uid),
                                        Align(
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                                                color: directorData.activeUsers.elementAt(index).backgroundColor!.withOpacity(1)),
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                              directorData.activeUsers.elementAt(index).name ?? "name error",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                          alignment: Alignment.bottomRight,
                                        ),
                                      ]),
                              ),
                              Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black54),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (directorData.activeUsers.elementAt(index).muted) {
                                          directorNotifier.toggleUserAudio(index: index, muted: true);
                                        } else {
                                          directorNotifier.toggleUserAudio(index: index, muted: false);
                                        }
                                      },
                                      icon: Icon(Icons.mic_off),
                                      color: directorData.activeUsers.elementAt(index).muted ? Colors.red : Colors.white,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (directorData.activeUsers.elementAt(index).videoDisabled) {
                                          directorNotifier.toggleUserVideo(index: index, enable: false);
                                        } else {
                                          directorNotifier.toggleUserVideo(index: index, enable: true);
                                        }
                                      },
                                      icon: Icon(Icons.videocam_off),
                                      color: directorData.activeUsers.elementAt(index).videoDisabled ? Colors.red : Colors.white,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        directorNotifier.demoteToLobbyUser(uid: directorData.activeUsers.elementAt(index).uid);
                                      },
                                      icon: Icon(Icons.arrow_downward),
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }, childCount: directorData.activeUsers.length),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Divider(
                        thickness: 3,
                        indent: 80,
                        endIndent: 80,
                      ),
                    ),
                  ],
                ),
              ),
              if (directorData.lobbyUsers.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text("Empty Lobby"),
                        ),
                      ),
                    ],
                  ),
                ),
              SliverGrid(
                gridDelegate:
                    SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: size.width / 2, crossAxisSpacing: 20, mainAxisSpacing: 20),
                delegate: SliverChildBuilderDelegate((BuildContext ctx, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: directorData.lobbyUsers.elementAt(index).videoDisabled
                                    ? Stack(children: [
                                        Container(
                                          color: (directorData.lobbyUsers.elementAt(index).backgroundColor != null)
                                              ? directorData.lobbyUsers.elementAt(index).backgroundColor!.withOpacity(1)
                                              : Colors.black,
                                        ),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            directorData.lobbyUsers.elementAt(index).name ?? "error name",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        )
                                      ])
                                    : RtcRemoteView.SurfaceView(
                                        uid: directorData.lobbyUsers.elementAt(index).uid,
                                      ),
                              ),
                              Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black54),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        directorNotifier.promoteToActiveUser(uid: directorData.lobbyUsers.elementAt(index).uid);
                                      },
                                      icon: Icon(Icons.arrow_upward),
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }, childCount: directorData.lobbyUsers.length),
              ),
            ],
          ),
        ),
      ));
    });
  }
}
