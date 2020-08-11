package com.easemob.im_flutter_sdk;

import android.os.Build;
import android.util.Log;

import androidx.annotation.RequiresApi;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.LinkedList;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.hyphenate.chat.EMBase;
import com.hyphenate.chat.EMChatManager;
import com.hyphenate.chat.EMClient;
import com.hyphenate.chat.EMConversation;
import com.hyphenate.chat.EMMessage;
import com.hyphenate.chat.adapter.EMAConversation;
import com.hyphenate.chat.adapter.message.EMAMessage;
import com.hyphenate.util.EMLog;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import static com.easemob.im_flutter_sdk.EMHelper.convertIntToEMMessageType;
import static com.easemob.im_flutter_sdk.EMHelper.convertIntToEMSearchDirection;

@SuppressWarnings("unchecked")
public class EMConversationWrapper implements MethodCallHandler, EMWrapper{
    private EMChatManager manager;

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        // init manager
        if(manager == null) {
            manager = EMClient.getInstance().chatManager();
        }
        if (EMSDKMethod.getUnreadMsgCount.equals(call.method)) {
            getUnreadMessageCount(call.arguments, result);
        } else if (EMSDKMethod.markAllMessagesAsRead.equals(call.method)) {
            markAllMessagesAsRead(call.arguments, result);
        } else if (EMSDKMethod.loadMoreMsgFromDB.equals(call.method)) {
            loadMoreMsgFromDB(call.arguments, result);
        } else if (EMSDKMethod.searchConversationMsgFromDB.equals(call.method)) {
            searchMsgFromDB(call.arguments, result);
        } else if (EMSDKMethod.searchConversationMsgFromDBByType.equals(call.method)) {
            searchMsgFromDBByType(call.arguments, result);
        } else if (EMSDKMethod.getMessage.equals(call.method)) {
            getMessage(call.arguments, result);
        } else if (EMSDKMethod.loadMessages.equals(call.method)) {
            loadMessages(call.arguments, result);
        } else if (EMSDKMethod.markMessageAsRead.equals((call.method))) {
            markMessageAsRead(call.arguments, result);
        } else if (EMSDKMethod.removeMessage.equals(call.method)) {
            removeMessage(call.arguments, result);
        } else if (EMSDKMethod.getLastMessage.equals(call.method)) {
            getLastMessage(call.arguments, result);
        } else if (EMSDKMethod.getLatestMessageFromOthers.equals(call.method)) {
            getLatestMessageFromOthers(call.arguments, result);
        } else if (EMSDKMethod.clear.equals(call.method)) {
            clear(call.arguments, result);
        } else if (EMSDKMethod.clearAllMessages.equals(call.method)) {
            clearAllMessages(call.arguments, result);
        } else if (EMSDKMethod.insertMessage.equals(call.method)) {
            insertMessage(call.arguments, result);
        } else if (EMSDKMethod.appendMessage.equals(call.method)) {
            appendMessage(call.arguments, result);
        } else if (EMSDKMethod.updateConversationMessage.equals(call.method)) {
            updateMessage(call.arguments, result);
        } else if (EMSDKMethod.getMessageAttachmentPath.equals(call.method)) {
            getMessageAttachmentPath(call.arguments, result);
        }
    }

    private EMConversation getConversation(String id) {
        return manager.getConversation(id);
    }

    private void getUnreadMessageCount(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            int count = getConversation(id).getUnreadMsgCount();
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("count", Integer.valueOf(count));
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void markAllMessagesAsRead(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            getConversation(id).markAllMessagesAsRead();
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private List<EMMessage>  loadMoreMsgFromDBWithSearchDirection(String conversationId, String startMsgId,
                                                                      int pageSize,
                                                                      EMAConversation.EMASearchDirection direction)
    {
        List<EMMessage> list = new ArrayList<EMMessage>();
        EMConversation conversation = getConversation(conversationId);
        try {

            Field emaObjectField = EMBase.class.getDeclaredField("emaObject");
            emaObjectField.setAccessible(true);
            EMAConversation emaConversation = (EMAConversation) emaObjectField.get(conversation);
            emaObjectField.setAccessible(false);

            List<EMAMessage> msgs = emaConversation.loadMoreMessages(startMsgId, pageSize, direction);
            for (EMAMessage msg : msgs) {
                if (msg != null) {
                    list.add(new EMMessage(msg));
                }
            }
        } catch (NoSuchFieldException | IllegalAccessException e) {
            e.printStackTrace();
        }

        return list;
    }


    private void loadMoreMsgFromDB(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            String startMsgId = argMap.getString("startMsgId");
            int pageSize = argMap.getInt("pageSize");

            int direction = 0;
            if(argMap.has("direction")) {
                direction = argMap.getInt("direction");
            }

            EMAConversation.EMASearchDirection searchDirection = direction == 0 ? EMAConversation.EMASearchDirection.UP : EMAConversation.EMASearchDirection.DOWN;


            List<EMMessage> list = loadMoreMsgFromDBWithSearchDirection(id,startMsgId,pageSize,searchDirection);
            List<Map<String, Object>> messages = new LinkedList<Map<String, Object>>();
            list.forEach(message->{
                messages.add(EMHelper.convertEMMessageToStringMap(message));
            });
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("messages", messages);
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    private void searchMsgFromDB(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            String keywords = argMap.getString("keywords");
            String from = null;
            if(argMap.has("from")) {
                from = argMap.getString("from");
            }
            Integer timeStamp = argMap.getInt("timeStamp");
            Integer maxCount = (Integer)argMap.get("maxCount");
            int direction = argMap.getInt("direction");
            List<EMMessage> list = getConversation(id).searchMsgFromDB(keywords,timeStamp,maxCount,from,convertIntToEMSearchDirection(direction));
            List<Map<String, Object>> messages = new LinkedList<Map<String, Object>>();
            list.forEach(message->{
                messages.add(EMHelper.convertEMMessageToStringMap(message));
            });
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("messages", messages);
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void searchMsgFromDBByType(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            int type = argMap.getInt("type");
            String from = null;
            if(argMap.has("from")) {
                from = argMap.getString("from");
            }

            String timeStamp = argMap.getString("timeStamp");
            int maxCount = argMap.getInt("maxCount");
            int direction = argMap.getInt("direction");
            List<EMMessage> list = getConversation(id).searchMsgFromDB(convertIntToEMMessageType(type), Long.parseLong(timeStamp), maxCount, from, convertIntToEMSearchDirection(direction));
            List<Map<String, Object>> messages = new LinkedList<Map<String, Object>>();
//            list.forEach(message->{
//                messages.add(EMHelper.convertEMMessageToStringMap(message));
//            });
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("messages", messages);
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void getMessage(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            String messageId = argMap.getString("messageId");
            Boolean markAsRead = argMap.getBoolean("markAsRead");
            EMMessage message = getConversation(id).getMessage(messageId, markAsRead.booleanValue());
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("message", EMHelper.convertEMMessageToStringMap(message));
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    private void loadMessages(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            JSONArray json_msgIds = argMap.getJSONArray("messages");
            List<String> msgIds = new ArrayList<>();
            for(int i = 0; i < json_msgIds.length(); i++){
                msgIds.add(json_msgIds.getString(i));
            }
            List<EMMessage> list = getConversation(id).loadMessages(msgIds);
            List<Map<String, Object>> messages = new LinkedList<Map<String, Object>>();
            list.forEach(message->{
                messages.add(EMHelper.convertEMMessageToStringMap(message));
            });
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("messages", messages);
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void markMessageAsRead(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            String messageId = argMap.getString("messageId");
            getConversation(id).markMessageAsRead(messageId);
            result.success(new HashMap() {
                {
                    put("id", id);
                    put("msgId",messageId);
                }
            });
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void removeMessage(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            String messageId = argMap.getString("messageId");
            getConversation(id).removeMessage(messageId);
            result.success(new HashMap() {
                {
                    put("id", id);
                    put("msgId",messageId);
                }
            });
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void getLastMessage(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            EMMessage message = getConversation(id).getLastMessage();
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("message", EMHelper.convertEMMessageToStringMap(message));
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void getLatestMessageFromOthers(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            EMMessage message = getConversation(id).getLatestMessageFromOthers();
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("message", EMHelper.convertEMMessageToStringMap(message));
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void clear(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            getConversation(id).clear();
            result.success(new HashMap() {
                {
                    put("id", id);
                }
            });
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void clearAllMessages(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            getConversation(id).clearAllMessages();

            result.success(new HashMap() {
                {
                    put("id", id);
                }
            });
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void insertMessage(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            EMMessage message = EMHelper.convertDataMapToMessage((JSONObject) argMap.get("msg"));
            getConversation(id).insertMessage(message);
            result.success(new HashMap() {
                {
                    put("id", id);
                }
            });
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void appendMessage(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            EMMessage message = EMHelper.convertDataMapToMessage((JSONObject)argMap.get("msg"));
            getConversation(id).appendMessage(message);
            result.success(new HashMap() {
                {
                    put("id", id);
                    put("msgId", message.getMsgId());
                }
            });
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void updateMessage(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            EMMessage message = EMHelper.convertDataMapToMessage((JSONObject)argMap.get("msg"));
            getConversation(id).updateMessage(message);
            result.success(new HashMap() {
                {
                    put("id", id);
                    put("msgId", message.getMsgId());
                }
            });
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }

    private void getMessageAttachmentPath(Object args, Result result) {
        try {
            JSONObject argMap = (JSONObject) args;
            String id = argMap.getString("id");
            String path = getConversation(id).getMessageAttachmentPath();
            Map<String, Object> data = new HashMap<String, Object>();
            data.put("success", Boolean.TRUE);
            data.put("path", path);
            result.success(data);
        }catch (JSONException e){
            EMLog.e("JSONException", e.getMessage());
        }
    }
}
