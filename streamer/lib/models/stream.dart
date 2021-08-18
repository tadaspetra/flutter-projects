enum StreamPlatform { youtube, twitch, other }

class StreamDestination {
  StreamPlatform platform;
  String url;

  StreamDestination({
    required this.platform,
    required this.url,
  });
}
