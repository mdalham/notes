
class Notes {
  final int? id;
  final int? folderId;
  final String dateTime;
  final String title;
  final String description;
  bool isFavorite;

  Notes({
    this.id,
    this.folderId,
    required this.dateTime,
    required this.title,
    required this.description,
    this.isFavorite = false,
  });

  factory Notes.fromMap(Map<String, dynamic> map) {
    return Notes(
      id: map['id'],
      folderId: map['folderId'],
      dateTime: map['dateTime'],
      title: map['title'],
      description: map['description'],
      isFavorite: map['isFavorite'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'dateTime': dateTime,
      'title': title,
      'description': description,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  Notes copyWith({
    int? id,
    int? folderId,
    String? dateTime,
    String? title,
    String? description,
    bool? isFavorite,
  }) {
    return Notes(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      dateTime: dateTime ?? this.dateTime,
      title: title ?? this.title,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
