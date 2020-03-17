
import 'package:flutter/services.dart';

class AudioRecorder {
  static const _channelPrefix = 'com.easemob.im';
  static const MethodChannel _emAudioRecorderChannel = const MethodChannel
    ('$_channelPrefix/em_voice_recorder', JSONMethodCodec());

  static AudioRecorder _instance;
  AudioRecorder._internal() {
  }
  /// @nodoc
  factory AudioRecorder.getInstance() {
    return _instance = _instance ?? AudioRecorder._internal();
  }

  /// 开始录音
  Future<bool> start() async{
    Map info = await _emAudioRecorderChannel.invokeMethod(
        'startRecorder');
    if(info['success'])
      {
        return true;
      }
    return false;
  }

  /// 停止录音
  Future<Map> stop() async{

    Map info = await _emAudioRecorderChannel.invokeMethod(
        'stopRecorder');
    if(info['success'])
    {
      return info;
    }

    return {"code":info['code'],"msg":info['desc']};
  }

  /// 取消录音
  void cancel() async{
    _emAudioRecorderChannel.invokeMethod(
        'cancelRecorder');
  }


  ///播放录音
  Future<bool> playVoice(String path) async
  {
    Map info = await _emAudioRecorderChannel.invokeMethod(
        'playVoice',path);

    if(info['success'])
    {
      return true;
    }
    return false;
  }

  ///停止播放录音
  void stopPlay()
  {
    _emAudioRecorderChannel.invokeMethod(
        'stopPlay');
  }

}

