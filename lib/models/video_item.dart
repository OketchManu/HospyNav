class VideoItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoId;
  final String duration;
  final String views;
  final List<String> relatedConditions;
  final DateTime uploadDate;

  VideoItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoId,
    required this.duration,
    required this.views,
    required this.relatedConditions,
    required this.uploadDate,
  });
}
