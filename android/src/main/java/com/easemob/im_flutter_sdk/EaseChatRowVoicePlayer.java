package com.easemob.im_flutter_sdk;

import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;

public class EaseChatRowVoicePlayer {

    private static EaseChatRowVoicePlayer instance = null;

    private AudioManager audioManager;
    private MediaPlayer mediaPlayer;
    public static EaseChatRowVoicePlayer getInstance(Context context) {
        if (instance == null) {
            synchronized (EaseChatRowVoicePlayer.class) {
                if (instance == null) {
                    instance = new EaseChatRowVoicePlayer(context);
                }
            }
        }
        return instance;
    }

    public boolean isPlaying() {
        return mediaPlayer.isPlaying();
    }



    public boolean play(final String path, final MediaPlayer.OnCompletionListener listener) {

        if (mediaPlayer.isPlaying()) {
            stop();
        }
        try {
            setSpeaker();
            mediaPlayer.setDataSource(path);
            mediaPlayer.prepare();
            mediaPlayer.setOnCompletionListener(mediaPlayer -> {
                stop();
                listener.onCompletion(mediaPlayer);
            });
            mediaPlayer.start();
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
        return true;
    }

    public void stop() {
        mediaPlayer.stop();
        mediaPlayer.reset();
    }

    private EaseChatRowVoicePlayer(Context cxt) {
        Context baseContext = cxt.getApplicationContext();
        audioManager = (AudioManager) baseContext.getSystemService(Context.AUDIO_SERVICE);
        mediaPlayer = new MediaPlayer();
    }

    private void setSpeaker() {
//        boolean speakerOn = EaseUI.getInstance().getSettingsProvider().isSpeakerOpened();
//        if (speakerOn) {
            audioManager.setMode(AudioManager.MODE_NORMAL);
            audioManager.setSpeakerphoneOn(true);
            mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
//        } else {
//            audioManager.setSpeakerphoneOn(false);// 关闭扬声器
//            // 把声音设定成Earpiece（听筒）出来，设定为正在通话中
//            audioManager.setMode(AudioManager.MODE_IN_CALL);
//            mediaPlayer.setAudioStreamType(AudioManager.STREAM_VOICE_CALL);
//        }
    }
}
