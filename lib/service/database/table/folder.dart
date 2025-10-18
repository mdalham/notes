class Folders {
  int? id;
  final String folderName;
  final String folderDateTime;

  Folders({this.id, required this.folderName, required this.folderDateTime});

  factory Folders.fromMap(Map<String, dynamic> map) {
    return Folders(
      id: map['id'],
      folderName: map['folderName'],
      folderDateTime: map['folderDateTime'],
    );
  }
  Map<String,dynamic> toMap(){
    return {
      'id' : id,
      'folderName' : folderName,
      'folderDateTime' : folderDateTime,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Folders && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

}
