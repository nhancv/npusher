library npusher;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_pusher/pusher.dart';

class NPusher {
  bool _enableLogging = true;

  Future<void> init({
    String appKey = '',
    String authUrl = '',
    Map<String, String> headers,
    String cluster = 'mt1',
    bool enableLogging = true,
  }) {
    _enableLogging = enableLogging;
    return Pusher.init(
      appKey,
      PusherOptions(
        cluster: cluster,
        encrypted: true,
        auth: PusherAuth(
          authUrl,
          headers: headers ?? <String, String>{},
        ),
      ),
      enableLogging: enableLogging,
    );
  }

  Future<void> connect(
    Function(String previousState, String currentState) onConnectionStateChange,
    Function(String message, String code, String exception) onError,
  ) {
    return Pusher.connect(onConnectionStateChange: (ConnectionStateChange x) {
      if (onConnectionStateChange != null) {
        onConnectionStateChange(x.previousState, x.currentState);
      }
    }, onError: (x) {
      if (onError != null) {
        onError(x.message, x.code, x.exception);
      }
    });
  }

  Future<void> disconnect() {
    return Pusher.disconnect();
  }

  Future<NChannel> subscribe(String channelName) async {
    final Channel channel = await Pusher.subscribe(channelName);
    if (_enableLogging) {
      print('subscribe: $channelName');
    }
    return NChannel(channel);
  }

  Future<void> unsubscribe(String channelName) async {
    await Pusher.unsubscribe(channelName);
    if (_enableLogging) {
      print('unsubscribe: $channelName');
    }
  }

  /// Echo bind
  Future<NChannel> bindEchoPublic(
    String channelName,
    String eventName,
    void Function(NEvent event) onEvent,
  ) async {
    final NChannel channel = await subscribe(channelName);
    final String fullEventName = 'App\\Events\\$eventName';
    await channel.bind(fullEventName, onEvent);
    if (_enableLogging) {
      print('bindEchoPublic: $channelName:$fullEventName');
    }
    return channel;
  }

  Future<void> unbindEchoPublic(
    NChannel channel,
    String eventName,
  ) async {
    final String fullEventName = 'App\\Events\\$eventName';
    await channel.unbind(fullEventName);
    if (_enableLogging) {
      print('unbindEchoPublic: ${channel?.channel?.name}:$fullEventName');
    }
  }

  /// Remember the data response is difference between android and ios
  /// pusher:member_added and pusher:member_removed are not work with ios
  /// ==> update periodic in this case
  Future<NChannel> bindEchoPresence(
    String channelName, {
    @required void Function(NEvent event) onEventHere,
    void Function(NEvent event) onEventJoin,
    void Function(NEvent event) onEventLeave,
  }) async {
    final String fullChannelName = 'presence-$channelName';
    final NChannel channel = await subscribe(fullChannelName);

    if (onEventHere != null) {
      await channel.bind('pusher:subscription_succeeded', onEventHere);
    }
    if (onEventJoin != null) {
      await channel.bind('pusher:member_added', onEventJoin);
    }

    if (onEventLeave != null) {
      await channel.bind('pusher:member_removed', onEventLeave);
    }

    if (_enableLogging) {
      print('bindEchoPresence: $fullChannelName');
    }
    return channel;
  }

  Future<Timer> echoPresencePeriodicStart(
    String channelName, {
    @required void Function(NEvent event) onEventHere,
    Duration duration = const Duration(seconds: 5),
  }) async {
    NChannel channel;
    return Timer.periodic(duration, (Timer timer) async {
      if (channel != null) {
        await unsubscribe(channel.channel?.name);
      }
      channel = await bindEchoPresence(channelName, onEventHere: onEventHere);
    });
  }
}

class NChannel {
  NChannel(this.channel);

  final Channel channel;

  /// Bind to listen for events sent on the given channel
  Future<void> bind(
      String eventName, void Function(NEvent event) onEvent) async {
    await channel?.bind(eventName, (Event event) {
      if (onEvent != null) {
        onEvent(NEvent(event));
      }
    });
  }

  Future<void> unbind(String eventName) async {
    await channel?.unbind(eventName);
  }

  /// Trigger [eventName] (will be prefixed with "client-" in case you have not) for [Channel].
  ///
  /// Client events can only be triggered on private and presence channels because they require authentication
  /// You can only trigger a client event once a subscription has been successfully registered with Channels.
  Future<void> trigger(String eventName, {String data}) async {
    if (!eventName.startsWith('client-')) {
      eventName = "client-$eventName";
    }
    await channel?.trigger(eventName, data: data);
  }

  @override
  String toString() {
    return 'NChannel{channel: ${channel?.name}}';
  }
}

class NEvent {
  NEvent(Event event) {
    this.channel = event.channel;
    this.event = event.event;
    this.data = event.data;
  }

  String channel;
  String event;
  String data;

  @override
  String toString() {
    return 'NEvent{channel: $channel, event: $event, data: $data}';
  }
}
