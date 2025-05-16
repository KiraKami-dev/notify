import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_auth.g.dart';

@riverpod
Future<void> setConnectedStatus(SetConnectedStatusRef ref, {required bool status}) async {
  await prefs()!.setBool('connectedStatus', status);
}

@riverpod
bool getConnectedStatus(GetConnectedStatusRef ref) {
  return prefs()!.getBool('connectedStatus') ?? false;
}

@riverpod
Future<void> setMainTokenId(SetMainTokenIdRef ref, {required String tokenId}) async {
  await prefs()!.setString('mainTokenId', tokenId);
}

@riverpod
String getMainTokenId(GetMainTokenIdRef ref) {
  return prefs()!.getString('mainTokenId') ?? '';
}


@riverpod
Future<void> setTypeUser(SetTypeUserRef ref, {required String typeUser}) async {
  await prefs()!.setString('typeUser', typeUser);
}

@riverpod
String getTypeUser(GetMainTokenIdRef ref) {
  return prefs()!.getString('typeUser') ?? '';
}


class SharedPrefs {
  static SharedPreferences? prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }
}

SharedPreferences? prefs() => SharedPrefs.prefs;
