import 'package:freezed_annotation/freezed_annotation.dart';

part 'model.freezed.dart';

@freezed
class Diary with _$Diary {
  factory Diary({
    String? id,
    String? note,
    String? datetime,
  }) = _Diary;
}

class ResponseModel {
  int? code;
  String? message;
  List<Items>? items;

  ResponseModel({this.code, this.message, this.items});

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    return ResponseModel(
        code: json['code'],
        message: json['message'],
        items: List.from(json['items']).map((e) => Items.fromJson(e)).toList());
  }
}

class Items {
  String? id;
  String? uuid;
  String? note;
  String? dt;
  int? timestamp;

  Items({this.id, this.uuid, this.note, this.dt, this.timestamp});

  factory Items.fromJson(Map<String, dynamic> json) {
    var id = json['id'];
    var uuid = json['uuid'];
    var note = json['note'];
    var dt = json['dt'];
    var timestamp = json['timestamp'];
    return Items(id: id, uuid: uuid, note: note, dt: dt, timestamp: timestamp);
  }
}
