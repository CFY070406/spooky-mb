import 'package:google_sign_in/google_sign_in.dart';
import 'package:spooky/core/api/authentication/google_auth_service.dart';
import 'package:spooky/core/backup/backup_service.dart';
import 'package:spooky/core/base/base_view_model.dart';
import 'package:spooky/core/file_manager/managers/backup_file_manager.dart';
import 'package:spooky/core/file_manager/managers/story_manager.dart';
import 'package:spooky/core/models/backup_model.dart';

class YearCloudModel {
  final int year;
  final bool synced;

  YearCloudModel({
    required this.year,
    required this.synced,
  });
}

class CloudStorageViewModel extends BaseViewModel {
  final GoogleAuthService googleAuth = GoogleAuthService.instance;
  GoogleSignInAccount? googleUser;
  List<YearCloudModel>? years;

  CloudStorageViewModel() {
    load();
  }

  Future<void> load() async {
    await loadYears();
    await loadAuthentication();
    notifyListeners();
  }

  // load year whether it is synced or not
  Future<void> loadYears() async {
    List<YearCloudModel> _years = [];
    Set<int>? intYears = await StoryManager().fetchYears();
    List<BackupModel>? backups = await BackupFileManager().fetchAll();
    List<int> syncedYears = backups.map((e) => e.year).toList();

    if (intYears != null) {
      for (int y in intYears) {
        _years.add(
          YearCloudModel(
            year: y,
            synced: syncedYears.contains(y),
          ),
        );
      }
      years = _years;
    }
  }

  Future<void> loadAuthentication() async {
    await googleAuth.googleSignIn.isSignedIn().then((signedIn) async {
      if (signedIn) {
        await googleAuth.signInSilently();
        googleUser = googleAuth.googleSignIn.currentUser;
      }
    });
  }

  Future<void> signInWithGoogle() async {
    await googleAuth.signIn();
    load();
  }

  Future<void> backup(int year) async {
    turnOnLoading(year);
    await BackupService().backup(year);
    await loadYears();
    turnOffLoading(year);
  }

  // UI
  Set<int> loadingYears = {};
  void turnOnLoading(int year) {
    loadingYears.add(year);
    notifyListeners();
  }

  void turnOffLoading(int year) {
    loadingYears.remove(year);
    notifyListeners();
  }
}