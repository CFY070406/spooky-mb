import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:spooky/core/file_manager/base_file_manager.dart';
import 'package:spooky/core/file_manager/base_fm_constructor_mixin.dart';
import 'package:spooky/core/models/base_model.dart';
import 'package:spooky/core/models/story_model.dart';
import 'package:spooky/utils/helpers/date_format_helper.dart';

class DocsManager extends BaseFileManager {
  @override
  FilePath get parentPathEnum => FilePath.docs;

  /// eg. $appPath/$parentPathStr/2022/Jan/7/
  @override
  String constructParentPath(BaseModel model) {
    model as StoryModel;
    String? year = model.createdAt?.year.toString();
    String? month = DateFormatHelper.toNameOfMonth().format(model.createdAt!);
    String? day = model.createdAt!.day.toString();
    return [appPath, parentPath, year, month, day, model.documentId].join("/");
  }

  Future<List<StoryModel>?> fetchAll({
    required int year,
    required int month,
  }) async {
    return beforeExec<List<StoryModel>>(() async {
      String? monthName = DateFormatHelper.toNameOfMonth().format(DateTime(year, month));
      List<dynamic> path = [
        appPath,
        parentPath,
        year,
        monthName,
      ];

      Directory directory = Directory(path.join("/"));
      bool exists = await directory.exists();
      if (!exists) {
        directory.create(recursive: true);
      }
      if (kDebugMode) {
        print("fetchAll: $directory: $exists");
      }

      var result = directory.listSync(recursive: true);

      //
      // {
      //   "7/1641494022922": "1641494022922.json"
      //   "7/1641492326066": "1641492450608.json"
      // }
      Map<String, String> storiesPath = {};

      for (FileSystemEntity e in result) {
        List<String> base = e.absolute.path.replaceFirst(directory.absolute.path + "/", "").split("/");
        if (base.length >= 3 && base[2].endsWith(".json")) {
          String key = base[0] + "/" + base[1];
          storiesPath[key] = base[2];
        }
      }

      List<StoryModel> stories = [];

      for (MapEntry<String, String> e in storiesPath.entries) {
        File file = File(directory.absolute.path + "/" + e.key + "/" + e.value);
        String result = await file.readAsString();
        dynamic json = jsonDecode(result);
        if (json is Map<String, dynamic>) {
          StoryModel story = StoryModel.fromJson(json);
          stories.add(story);
        }
      }

      return stories;
    });
  }

  Future<List<StoryModel>?> fetchChangesHistory({
    required DateTime date,
    required String id,
  }) async {
    return beforeExec<List<StoryModel>>(() async {
      return [];
    });
  }
}
