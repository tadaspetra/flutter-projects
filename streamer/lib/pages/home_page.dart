import 'package:creatorstudio/pages/director_page.dart';
import 'package:creatorstudio/pages/participant_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _channelName = TextEditingController();
  final _userName = TextEditingController();
  String check = '';
  late int uid;

  @override
  void initState() {
    getUserUid();
    super.initState();
  }

  Future<void> getUserUid() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? storedUid = preferences.getInt("localUid");
    if (storedUid != null) {
      uid = storedUid;
      print("storedUID: $uid");
    } else {
      //should only happen once, unless they delete the app
      int time = DateTime.now().millisecondsSinceEpoch;
      uid = int.parse(time.toString().substring(1, time.toString().length - 3));
      preferences.setInt("localUid", uid);
      print("settingUID: $uid");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset("images/streamer.png"),
              SizedBox(
                height: 5,
              ),
              Text("Multi Streaming with Friends"),
              SizedBox(
                height: 40,
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextFormField(
                  controller: _userName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    hintText: 'User Name',
                  ),
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextFormField(
                  controller: _channelName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    hintText: 'Channel Name',
                  ),
                ),
              ),
              TextButton(
                onPressed: () => joinParticipant(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Participant  ',
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(
                      Icons.live_tv,
                    )
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  primary: Colors.black,
                ),
                onPressed: () => joinDirector(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Director    ',
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.cut)
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Future<void> joinDirector() async {
    await [Permission.camera, Permission.microphone].request();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BroadcastPage(
          channelName: _channelName.text,
          uid: uid,
        ),
      ),
    );
  }

  Future<void> joinParticipant() async {
    await [Permission.camera, Permission.microphone].request();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParticipantPage(
          channelName: _channelName.text,
          uid: uid,
          userName: _userName.text,
        ),
      ),
    );
  }
}
