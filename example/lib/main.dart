import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:npusher/npusher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String connectionState;
  NEvent event;
  NChannel channel;

  String get info => '''
  Connection State: $connectionState
  Last Event Channel: ${event?.channel}
  Last Event Name: ${event?.event}
  Last Event Data: ${event?.data}
  ''';
  final TextEditingController channelController =
      TextEditingController(text: "channel-name");
  final TextEditingController eventController =
      TextEditingController(text: "event-name");
  final TextEditingController triggerController =
      TextEditingController(text: "client-trigger");
  final NPusher nPusher = NPusher();

  @override
  void initState() {
    super.initState();
    initPusher();
  }

  Future<void> initPusher() async {
    try {
      await nPusher.init(
          appKey: 'nhancv',
          authUrl: 'https://nhancv.com/api/mobile/broadcasting/auth',
          headers: <String, String>{
            'Authorization': 'Bearer nhancdeptrai',
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          });
    } on PlatformException catch (e) {
      print('initPusher: ${e.message}');
    }

    // nPusher.connect((previousState, currentState) async {
    //   if (currentState.toLowerCase() == 'connected') {
    //     await nPusher.bindEchoPublic('event.15', 'ChatMessageCreated',
    //         (NEvent event) {
    //       print('event: $event');
    //     });
    //     await nPusher.echoPresencePeriodicStart('event-presence.15',
    //         onEventHere: (NEvent event) {
    //       print('onEventHere: $event');
    //     });
    //   }
    // }, (message, code, exception) {
    //   print('error: $message');
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('NPusher'),
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(info ?? ''),
                  RaisedButton(
                    child: Text("Connect"),
                    onPressed: () {
                      nPusher.connect((previousState, currentState) {
                        if (mounted)
                          setState(() {
                            connectionState = currentState;
                          });
                      }, (message, code, exception) {
                        debugPrint("Error: $message");
                      });
                    },
                  ),
                  RaisedButton(
                    child: Text("Disconnect"),
                    onPressed: () async {
                      await nPusher.disconnect();
                      setState(() {
                        connectionState = null;
                        event = null;
                        channel = null;
                      });
                    },
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 200,
                        child: TextField(
                          autocorrect: false,
                          controller: channelController,
                          decoration: InputDecoration(hintText: "Channel"),
                        ),
                      ),
                      RaisedButton(
                        child: Text("Subscribe"),
                        onPressed: () async {
                          channel =
                              await nPusher.subscribe(channelController.text);
                          print('Subscribe');
                        },
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 200,
                        child: TextField(
                          controller: channelController,
                          decoration: InputDecoration(hintText: "Channel"),
                        ),
                      ),
                      RaisedButton(
                        child: Text("Unsubscribe"),
                        onPressed: () async {
                          await nPusher.unsubscribe(channelController.text);
                          channel = null;
                          print('Unsubscribe');
                        },
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 200,
                        child: TextField(
                          controller: eventController,
                          decoration: InputDecoration(hintText: "Event"),
                        ),
                      ),
                      RaisedButton(
                        child: Text("Bind"),
                        onPressed: () async {
                          await channel.bind(eventController.text,
                              (NEvent _event) {
                            if (mounted)
                              setState(() {
                                event = _event;
                              });
                          });
                          print('Bind');
                        },
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 200,
                        child: TextField(
                          controller: eventController,
                          decoration: InputDecoration(hintText: "Event"),
                        ),
                      ),
                      RaisedButton(
                        child: Text("Unbind"),
                        onPressed: () async {
                          await channel.unbind(eventController.text);
                          if (mounted)
                            setState(() {
                              event = null;
                            });
                          print('Unbind');
                        },
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 200,
                        child: TextField(
                          controller: triggerController,
                          decoration: InputDecoration(hintText: "Trigger"),
                        ),
                      ),
                      RaisedButton(
                        child: Text("Trigger"),
                        onPressed: () async {
                          await channel.trigger(triggerController.text,
                              data:
                                  '{"testValue": 123, "anotherOne": false, "nested": {"w0t": "m8"}}');
                        },
                      )
                    ],
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
