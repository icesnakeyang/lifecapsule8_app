import 'package:lifecapsule8_app/api/base_api.dart';
import 'package:lifecapsule8_app/api/endpoints.dart';

class Api {
  // 游客登录
  static Future<Map<String, dynamic>> apiCreateGuest() {
    return BaseApi.post(Endpoints.createGuest);
  }

  static Future<Map<String, dynamic>> apiTokenLogin() {
    return BaseApi.post(Endpoints.tokenLogin);
  }

  static Future<Map<String, dynamic>> apiSaveNote(Map<String, dynamic> params) {
    return BaseApi.post(Endpoints.saveNote, data: params);
  }

  static Future<Map<String, dynamic>> apiUpsertSendTask(
    Map<String, dynamic> params,
  ) {
    return BaseApi.post(Endpoints.upsertSendTask, data: params);
  }

  static Future<Map<String, dynamic>> apiSnooze(Map<String, dynamic> params) {
    return BaseApi.post(Endpoints.snooze, data: params);
  }
}
