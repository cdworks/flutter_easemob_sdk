

import 'package:flutter/services.dart';
import 'package:im_flutter_sdk/src/em_domain_terms.dart';
import 'dart:io';
import 'em_sdk_method.dart';

class EMPushManager{
  static const _channelPrefix = 'com.easemob.im';
  static const MethodChannel _emPushManagerChannel =
  const MethodChannel('$_channelPrefix/em_push_manager', JSONMethodCodec());

  /// 开启离线消息推送
  void enableOfflinePush({
    onSuccess(),
    onError(int errorCode, String desc)}){
    Future<Map<String, dynamic>> result = _emPushManagerChannel
        .invokeMethod(EMSDKMethod.enableOfflinePush);
    result.then((response){
      if(response['success']){
        if(onSuccess != null){
          onSuccess();
        }
      }else{
        if (onError != null) onError(response['code'], response['desc']);
      }
    });
  }

  /// 在指定的时间段(24小时制)内，不推送离线消息
  void disableOfflinePush(
      int startTime,
      int endTime,
      {onSuccess(),
    onError(int errorCode, String desc)}){
    Future<Map<String, dynamic>> result = _emPushManagerChannel
        .invokeMethod(EMSDKMethod.disableOfflinePush, {'startTime' : startTime, 'endTime' : endTime});
    result.then((response){
      if(response['success']){
        if(onSuccess != null){
          onSuccess();
        }
      }else{
        if (onError != null) onError(response['code'], response['desc']);
      }
    });
  }

  /// 从缓存获取推送配置信息
  Future <EMPushConfigs> getPushConfigs() async{
    Map<String, dynamic> result = await _emPushManagerChannel
        .invokeMethod(EMSDKMethod.getPushConfigs);

    if(result['success']){
      Map<String, dynamic> value = result['value'];
      return EMPushConfigs.from(value);
    }
    return null;
  }

  /// 从服务器获取推送配置信息
  void getPushConfigsFromServer({onSuccess(EMPushConfigs pushConfigs),onError(int errorCode, String desc)}){
    Future<Map<String, dynamic>> result = _emPushManagerChannel
        .invokeMethod(EMSDKMethod.getPushConfigsFromServer);
    result.then((response){
      if(response['success']){
        if(onSuccess != null){
          Map<String, dynamic> value = response['value'];
          onSuccess(EMPushConfigs.from(value));
        }
      }else{
        if (onError != null) onError(response['code'], response['desc']);
      }
    });
  }

  /// 设置指定的群组是否接受离线消息推送
  void updatePushServiceForGroup(
      List<String> groupIds,
      bool noPush,
      {onSuccess(),onError(int errorCode, String desc)}){
    Future<Map<String, dynamic>> result = _emPushManagerChannel
        .invokeMethod(EMSDKMethod.updatePushServiceForGroup, {'groupIds' : groupIds, 'noPush' : noPush});
    result.then((response){
      if(response['success']){
        if(onSuccess != null){
          onSuccess();
        }
      }else{
        if (onError != null) onError(response['code'], response['desc']);
      }
    });
  }

  /// 获取关闭了离线消息推送的群组
  Future<List<String>> getNoPushGroups() async{
    Map<String, dynamic> result = await _emPushManagerChannel
        .invokeMethod(EMSDKMethod.getNoPushGroups);

    if(result['success']) {
      List<String> groupIds = [];
      if (result['value'] != null) {
        List s = result['value'] as List<dynamic>;
        s.forEach((element) => groupIds.add(element));
        return groupIds;
      }
    }

    return [];
  }

  /// 更新当前用户的nickname,这样离线消息推送的时候可以显示用户昵称而不是id
  Future<bool> updatePushNickname (String nickname) async{
    Map<String, dynamic> result = await _emPushManagerChannel
        .invokeMethod(EMSDKMethod.updatePushNickname, {'nickname' : nickname});
    if(result['success']){
        return result['value'];
    }
    return false;
  }

  Future<bool> updatePushDisplayStyle(int displayStyle) async
  {
    if(Platform.isIOS)
      {
        Map<String, dynamic> result = await _emPushManagerChannel
            .invokeMethod(EMSDKMethod.updatePushDisplayStyle, displayStyle);
        if(result['success']){
          return result['value'];
        }
      }

    return false;
  }
}