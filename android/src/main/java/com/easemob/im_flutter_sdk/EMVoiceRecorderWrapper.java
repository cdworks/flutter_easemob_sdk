package com.easemob.im_flutter_sdk;

import android.content.Context;
import android.media.MediaPlayer;
import android.view.View;
import android.widget.Toast;
import com.hyphenate.EMError;
import com.hyphenate.chat.EMClient;
import com.hyphenate.exceptions.HyphenateException;
import com.hyphenate.util.EasyUtils;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.HashMap;
import java.util.Map;

public class EMVoiceRecorderWrapper implements MethodCallHandler, EMWrapper{

    EMVoiceRecorderWrapper(Context context, MethodChannel channel) {
        this.context = context;
        this.channel = channel;
    }

    private Context context;
    private MethodChannel channel;
    private EaseVoiceRecorder voiceRecorder;

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {

        if (call.method.equals("startRecorder")) {
            if(voiceRecorder == null) {
                voiceRecorder = new EaseVoiceRecorder();
            }
            if (!EasyUtils.isSDCardExist()) {
                onError(result, new HyphenateException(1,"发送语音需要sdcard支持!"));
                return;
            }
            if(voiceRecorder.startRecording() == null)
            {
                if (voiceRecorder != null)
                    voiceRecorder.discardRecording();
                onError(result, new HyphenateException(1,"启动录音错误!"));
                return;
            }
            onSuccess(result);

        }else if (call.method.equals("stopRecorder")) {
            if(voiceRecorder == null) {
                onError(result, new HyphenateException(1,"未启动录音"));
                return;
            }
            int duration = voiceRecorder.stopRecoding();  //秒
            if (duration > 0) {
                Map<String, Object> data = new HashMap<String, Object>();
                data.put("success", Boolean.TRUE);
                data.put("recordPath",voiceRecorder.getVoiceFilePath());
                data.put("duration",Integer.valueOf(duration));
               result.success(data);
            } else if (duration == EMError.FILE_INVALID) {
                onError(result, new HyphenateException(1,"无录音权限"));
            } else {
                onError(result, new HyphenateException(1000,"录音时间太短"));
            }
        }
        else if (call.method.equals("cancelRecorder")) {
            if(voiceRecorder != null) {
                if (voiceRecorder.isRecording()) {
                    voiceRecorder.discardRecording();
                }
            }
            result.success(result);

        }
        else if (call.method.equals("playVoice")) {
           String path = (String) call.arguments;
           if(path == null || path.isEmpty())
           {
               onError(result,new HyphenateException(1,"path error!"));
               return;
           }
            if(!EaseChatRowVoicePlayer.getInstance(context).play(path, new MediaPlayer.OnCompletionListener() {
                @Override
                public void onCompletion(MediaPlayer mediaPlayer) {
                    onSuccess(result);
                }
            }))
            {
                onError(result,new HyphenateException(1,"播放错误!"));
            }
        }
        else if (call.method.equals("stopPlay")) {
            EaseChatRowVoicePlayer.getInstance(context).stop();
            onSuccess(result);
        }
    }
}
