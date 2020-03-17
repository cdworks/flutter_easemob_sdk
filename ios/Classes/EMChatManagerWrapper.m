//
//  EMChatManagerWrapper.m
//  
//
//  Created by 杜洁鹏 on 2019/10/8.
//

#import "EMChatManagerWrapper.h"
#import "EMSDKMethod.h"
#import "EMHelper.h"
#import <Photos/Photos.h>

@interface EMChatManagerWrapper () <EMChatManagerDelegate> {
    FlutterEventSink _progressEventSink;
    FlutterEventSink _resultEventSink;
}

@end

@implementation EMChatManagerWrapper
- (instancetype)initWithChannelName:(NSString *)aChannelName
                          registrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if(self = [super initWithChannelName:aChannelName
                               registrar:registrar]) {
        [EMClient.sharedClient.chatManager addDelegate:self delegateQueue:nil];
    }
    return self;
}

#pragma mark - FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall*)call
                  result:(FlutterResult)result {
    if ([EMMethodKeySendMessage isEqualToString:call.method]) {
        [self sendMessage:call.arguments result:result];
    }else if ([EMMethodKeyResendMessage isEqualToString:call.method]) {
        [self resendMessage:call.arguments result:result];
    }
    else if ([EMMethodKeyAckMessageRead isEqualToString:call.method]) {
        [self ackMessageRead:call.arguments result:result];
    } else if ([EMMethodKeyRecallMessage isEqualToString:call.method]) {
        [self recallMessage:call.arguments result:result];
    } else if ([EMMethodKeyGetMessage isEqualToString:call.method]) {
        [self getMessage:call.arguments result:result];
    } else if ([EMMethodKeyGetConversation isEqualToString:call.method]) {
        [self getConversation:call.arguments result:result];
    } else if ([EMMethodKeyMarkAllChatMsgAsRead isEqualToString:call.method]) {
        [self markAllMessagesAsRead:call.arguments result:result];
    } else if ([EMMethodKeyGetUnreadMessageCount isEqualToString:call.method]) {
        [self getUnreadMessageCount:call.arguments result:result];
    } else if ([EMMethodKeySaveMessage isEqualToString:call.method]) {
        [self saveMessage:call.arguments result:result];
    } else if ([EMMethodKeyUpdateChatMessage isEqualToString:call.method]) {
        [self updateChatMessage:call.arguments result:result];
    } else if ([EMMethodKeyDownloadAttachment isEqualToString:call.method]) {
        [self downloadAttachment:call.arguments result:result];
    } else if ([EMMethodKeyDownloadThumbnail isEqualToString:call.method]) {
        [self downloadThumbnail:call.arguments result:result];
    } else if ([EMMethodKeyImportMessages isEqualToString:call.method]) {
        [self importMessages:call.arguments result:result];
    } else if ([EMMethodKeyGetConversationsByType isEqualToString:call.method]) {
        [self getConversationsByType:call.arguments result:result];
    } else if ([EMMethodKeyDownloadFile isEqualToString:call.method]) {
        [self downloadFile:call.arguments result:result];
    } else if ([EMMethodKeyGetAllConversations isEqualToString:call.method]) {
        [self getAllConversations:call.arguments result:result];
    } else if ([EMMethodKeyLoadAllConversations isEqualToString:call.method]) {
        [self loadAllConversations:call.arguments result:result];
    } else if ([EMMethodKeyDeleteConversation isEqualToString:call.method]) {
        [self deleteConversation:call.arguments result:result];
    } else if ([EMMethodKeySetVoiceMessageListened isEqualToString:call.method]) {
        [self setVoiceMessageListened:call.arguments result:result];
    } else if ([EMMethodKeyUpdateParticipant isEqualToString:call.method]) {
        [self updateParticipant:call.arguments result:result];
    } else if ([EMMethodKeyFetchHistoryMessages isEqualToString:call.method]) {
        [self fetchHistoryMessages:call.arguments result:result];
    } else if ([EMMethodKeySearchChatMsgFromDB isEqualToString:call.method]) {
        [self searchChatMsgFromDB:call.arguments result:result];
    } else if ([EMMethodKeyGetCursor isEqualToString:call.method]) {
        [self getCursor:call.arguments result:result];
    } else {
        [super handleMethodCall:call result:result];
    }
}

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    
}


#pragma mark - Actions

- (void)sendMessage:(NSDictionary *)param result:(FlutterResult)result {
    
    __block void (^progress)(int progress) = ^(int progress) {
        [self.channel invokeMethod:EMMethodKeyOnMessageStatusOnProgress
                         arguments:@{@"progress":@(progress)}];
    };
    
    __block void (^completion)(EMMessage *message, EMError *error) = ^(EMMessage *message, EMError *error) {
        [self wrapperCallBack:result
                        error:error
                     userInfo:@{@"message":[EMHelper messageToDictionary:message]}];
    };
    
    int type = [param[@"type"] intValue];
    if(type == 1)
    {

        NSDictionary *msgBodyDict = param[@"body"];
        NSString* filePath = msgBodyDict[@"localUrl"];
        BOOL isDirector;
        BOOL isExisListFile = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirector];
       if( isExisListFile && !isDirector)
       {
           EMChatType chatType;
           if ([param[@"chatType"] isKindOfClass:[NSNull class]]) {
               chatType = EMChatTypeChat;
           }else {
               chatType = (EMChatType)[param[@"chatType"] intValue];
           }
           
           NSString *to = param[@"to"];
           NSString *from = EMClient.sharedClient.currentUsername;
           NSDictionary *ext = param[@"attributes"];
           
           
           EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithData:[NSData dataWithContentsOfFile:filePath] displayName:@"image.png"];
           body.compressionRatio = 0.8;
           
//           EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithLocalPath:filePath
//                                                                        displayName:@"image.png"];
//           body.compressionRatio = 0.75;
           
           EMMessage* emsg = [[EMMessage alloc] initWithConversationID:to
                                                      from:from
                                                        to:to
                                                      body:body
                                                       ext:ext];
           
           [EMClient.sharedClient.chatManager sendMessage:emsg
                                                 progress:progress
                                               completion:completion];
           return;
       }
        
        PHImageRequestOptions *phImageRequestOptions = [[PHImageRequestOptions alloc] init];
        phImageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        phImageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        phImageRequestOptions.synchronous = YES;
        phImageRequestOptions.networkAccessAllowed = YES;
        PHFetchResult<PHAsset *>* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[filePath] options:nil];
        if(assets.count)
        {
            [[[PHCachingImageManager alloc] init] requestImageForAsset:assets.firstObject
                                                            targetSize:PHImageManagerMaximumSize
                                                           contentMode:PHImageContentModeAspectFill
                                                               options:phImageRequestOptions
                                                         resultHandler:^(UIImage *result1, NSDictionary *info) {
                                                             if(result1)
                                                             {
                                                                 NSData *data = UIImageJPEGRepresentation(result1, 0.8);
                                                                 EMChatType chatType;
                                                                 if ([param[@"chatType"] isKindOfClass:[NSNull class]]) {
                                                                     chatType = EMChatTypeChat;
                                                                 }else {
                                                                     chatType = (EMChatType)[param[@"chatType"] intValue];
                                                                 }
                                                                 
                                                                 NSString *to = param[@"to"];
                                                                 NSString *from = EMClient.sharedClient.currentUsername;
                                                                 NSDictionary *ext = param[@"attributes"];
                                                                 
                                                                 EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithData:data displayName:@"image.png"];
                                                                 body.compressionRatio = 0.8;
                                                                 
                                                                 EMMessage* emsg = [[EMMessage alloc] initWithConversationID:to
                                                                                                            from:from
                                                                                                              to:to
                                                                                                            body:body
                                                                                                             ext:ext];
                                                                 
                                                                 [EMClient.sharedClient.chatManager sendMessage:emsg
                                                                                                       progress:progress
                                                                                                     completion:completion];
                                                                 
                                                             }
                                                             else
                                                             {
                                                                 NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                                                                 dic[@"success"] = @NO;
                                                                 dic[@"code"] = @(1);
                                                                 dic[@"desc"] = @"无此图片";
                                                                 result(dic);
                                                             }
                                                         }];
        }
        else
        {
            if (result) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                dic[@"success"] = @NO;
                dic[@"code"] = @(1);
                dic[@"desc"] = @"无此图片";
                result(dic);
            }
        }
        
        
        
        
        // TODO: size ?
//        NSString *localUrl = msgBodyDict[@"localUrl"];
//        long long fileLength = [msgBodyDict[@"fileLength"] longLongValue];
        
//                    body = [[EMImageMessageBody alloc] initWithLocalPath:localUrl
//                                                             displayName:@"image"];
        //            ((EMImageMessageBody *)body).fileLength = fileLength;
        
        
        
    }
    else
    {
        EMMessage *msg = [EMHelper dictionaryToMessage:param];
        [EMClient.sharedClient.chatManager sendMessage:msg
                                              progress:progress
                                            completion:completion];
    }
    
    
    
}

- (void)resendMessage:(NSDictionary *)param result:(FlutterResult)result {
    
    NSString* msgId = param[@"msgId"];
    
    if(!msgId.length)
    {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        dic[@"success"] = @NO;
        dic[@"code"] = @(1);
        dic[@"desc"] = @"msgId为空";
        result(dic);
        return;
    }
    
    NSNumber* msgStatusObj = param[@"status"];
    if(msgStatusObj == nil)
    {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        dic[@"success"] = @NO;
        dic[@"code"] = @(1);
        dic[@"desc"] = @"msg status 为空";
        result(dic);
        return;
    }
    
    EMMessageStatus msgStatus = (EMMessageStatus)msgStatusObj.intValue;
    if((msgStatus != EMMessageStatusFailed) && (msgStatus != EMMessageStatusPending))
    {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        dic[@"success"] = @NO;
        dic[@"code"] = @(1000);
        dic[@"desc"] = [NSString stringWithFormat:@"msg status 不正确!#%li",msgStatus];
        result(dic);
        return;
    }
    
    EMMessage* reMsg = [[[EMClient sharedClient] chatManager] getMessageWithMessageId:msgId];
    
    if(reMsg == nil)
    {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        dic[@"success"] = @NO;
        dic[@"code"] = @(1);
        dic[@"desc"] = @"remessage not exsit!";
        result(dic);
        return;
    }
    
    __block void (^progress)(int progress) = ^(int progress) {
        [self.channel invokeMethod:EMMethodKeyOnMessageStatusOnProgress
                         arguments:@{@"progress":@(progress)}];
    };
    
    __block void (^completion)(EMMessage *message, EMError *error) = ^(EMMessage *message, EMError *error) {
        [self wrapperCallBack:result
                        error:error
                     userInfo:@{@"message":[EMHelper messageToDictionary:message]}];
    };
    
    
        
        
        // TODO: size ?
//        NSString *localUrl = msgBodyDict[@"localUrl"];
//        long long fileLength = [msgBodyDict[@"fileLength"] longLongValue];
        
        //            body = [[EMImageMessageBody alloc] initWithLocalPath:localUrl
        //                                                     displayName:@"image"];
        //            ((EMImageMessageBody *)body).fileLength = fileLength;
        
  [[[EMClient sharedClient] chatManager] resendMessage:reMsg progress:progress completion:completion];
}

- (void)ackMessageRead:(NSDictionary *)param result:(FlutterResult)result {
    
}

- (void)recallMessage:(NSDictionary *)param result:(FlutterResult)result {
    
}

- (void)getMessage:(NSDictionary *)param result:(FlutterResult)result {
    
}

- (void)getConversation:(NSDictionary *)param result:(FlutterResult)result {
    NSString *conversationId = param[@"id"];
    EMConversationType type;
    if ([param[@"type"] isKindOfClass:[NSNull class]]){
        type = EMConversationTypeChat;
    }else {
        type = (EMConversationType)[param[@"type"] intValue];
    }
    BOOL isCreateIfNotExists = [param[@"createIfNotExists"] boolValue];
    
    EMConversation *conversation = [EMClient.sharedClient.chatManager getConversation:conversationId
                                                                                 type:type
                                                                     createIfNotExist:isCreateIfNotExists];
    [self wrapperCallBack:result
                    error:nil
                 userInfo:@{@"conversation":[EMHelper conversationToDictionary:conversation]}];
}

// TODO: ios需调添加该实现
- (void)markAllMessagesAsRead:(NSDictionary *)param result:(FlutterResult)result {
    
}

// TODO: ios需调添加该实现
- (void)getUnreadMessageCount:(NSDictionary *)param result:(FlutterResult)result {
    
}

// TODO: 目前这种方式实现后，消息id不一致，考虑如何处理。
- (void)saveMessage:(NSDictionary *)param result:(FlutterResult)result {
    
}

// TODO: 目前这种方式实现后，消息id不一致，考虑如何处理。
- (void)updateChatMessage:(NSDictionary *)param result:(FlutterResult)result {
    
}

- (void)downloadAttachment:(NSDictionary *)param result:(FlutterResult)result {
    
    NSString* msgId = param[@"msgId"];
    
    if(!msgId.length)
    {
        return;
    }
    
    __block void (^progress)(int progress) = ^(int progress) {
        [self.channel invokeMethod:EMMethodKeyOnMessageStatusOnProgress
                         arguments:@{@"success":@(YES),@"localMsgId":msgId,@"progressType":@(1),@"progress":@(progress)}];
    };
    
    EMMessage* reMsg = [[[EMClient sharedClient] chatManager] getMessageWithMessageId:msgId];
    
    if(reMsg == nil)
    {
        return;
    }
    
    EMDownloadStatus status = ((EMFileMessageBody*)reMsg.body).downloadStatus;
    
    if(status != EMDownloadStatusDownloading && status != EMDownloadStatusSucceed)
    {
        [EMClient.sharedClient.chatManager downloadMessageAttachment:reMsg
                                                                progress:progress completion:^(EMMessage *message, EMError *error)
             {
        //        if(!error)
        //        {
        //
        //        }
        //        [self wrapperCallBack:result
        //           error:error
        //        userInfo:@{@"message":[EMHelper messageToDictionary:message]}];
            }];
    }
    
    
}

- (void)downloadThumbnail:(NSDictionary *)param result:(FlutterResult)result {
    
    NSString* msgId = param[@"msgId"];
    
    if(!msgId.length)
    {
        return;
    }
    
    __block void (^progress)(int progress) = ^(int progress) {
        [self.channel invokeMethod:EMMethodKeyOnMessageStatusOnProgress
                         arguments:@{@"success":@(YES),@"localMsgId":msgId,@"progressType":@(1),@"progress":@(progress)}];
    };
    
    EMMessage* reMsg = [[[EMClient sharedClient] chatManager] getMessageWithMessageId:msgId];
    
    if(reMsg == nil)
    {
        return;
    }
    
    [EMClient.sharedClient.chatManager downloadMessageThumbnail:reMsg
                                                       progress:progress completion:^(EMMessage *message, EMError *error)
     {
        
    }];
}

// TODO: 目前这种方式实现后，消息id不一致，考虑如何处理。
- (void)importMessages:(NSDictionary *)param result:(FlutterResult)result {
    
}

// TODO: ios需调添加该实现
- (void)getConversationsByType:(NSDictionary *)param result:(FlutterResult)result {
    //    EMConversationType type = (EMConversationType)[param[@"type"] intValue];
    //    EMClient.sharedClient.chatManager
}

// TODO: ios需调添加该实现
- (void)downloadFile:(NSDictionary *)param result:(FlutterResult)result {
    
}


- (void)getAllConversations:(NSDictionary *)param result:(FlutterResult)result {
    NSArray *conversations = [EMClient.sharedClient.chatManager getAllConversations];
    NSMutableArray *conversationDictList = [NSMutableArray array];
    for (EMConversation *conversation in conversations) {
        [conversationDictList addObject:[EMHelper conversationToDictionary:conversation]];
    }
    [self wrapperCallBack:result error:nil userInfo:@{@"conversations" : conversationDictList}];
}


- (void)loadAllConversations:(NSDictionary *)param result:(FlutterResult)result {
    [self getAllConversations:param result:result];
}

- (void)deleteConversation:(NSDictionary *)param result:(FlutterResult)result {
    __weak typeof(self)weakSelf = self;
    NSString *conversationId = param[@"userName"];
    BOOL deleteMessages = [param[@"deleteMessages"] boolValue];
    [EMClient.sharedClient.chatManager deleteConversation:conversationId
                                         isDeleteMessages:deleteMessages
                                               completion:^(NSString *aConversationId, EMError *aError)
     {
        [weakSelf wrapperCallBack:result
                            error:aError
                         userInfo:@{@"status" : [NSNumber numberWithBool:(aError == nil)]}];
    }];
}

// ??
- (void)setVoiceMessageListened:(NSDictionary *)param result:(FlutterResult)result {
    
}

// ??
- (void)updateParticipant:(NSDictionary *)param result:(FlutterResult)result {
    
}


- (void)fetchHistoryMessages:(NSDictionary *)param result:(FlutterResult)result {
    __weak typeof(self)weakSelf = self;
    NSString *conversationId = param[@"id"];
    EMConversationType type = (EMConversationType)[param[@"type"] intValue];
    int pageSize = [param[@"pageSize"] intValue];
    NSString *startMsgId = param[@"startMsgId"];
    [EMClient.sharedClient.chatManager asyncFetchHistoryMessagesFromServer:conversationId
                                                          conversationType:type
                                                            startMessageId:startMsgId
                                                                  pageSize:pageSize
                                                                completion:^(EMCursorResult *aResult, EMError *aError)
     {
        NSArray *msgAry = aResult.list;
        NSMutableArray *msgList = [NSMutableArray array];
        for (EMMessage *msg in msgAry) {
            [msgList addObject:[EMHelper messageToDictionary:msg]];
        }
        
        [weakSelf wrapperCallBack:result error:aError userInfo:@{@"messages" : msgList,
                                                                 @"cursor" : aResult.cursor}];
    }];
}

- (void)searchChatMsgFromDB:(NSDictionary *)param result:(FlutterResult)result {
    __weak typeof(self) weakSelf = self;
    NSString *keywords = param[@"keywords"];
    long long timeStamp = [param[@"timeStamp"] longLongValue];
    int maxCount = [param[@"maxCount"] intValue];
    NSString *from = param[@"from"];
    EMMessageSearchDirection direction = (EMMessageSearchDirection)[param[@"direction"] intValue];
    [EMClient.sharedClient.chatManager loadMessagesWithKeyword:keywords
                                                     timestamp:timeStamp
                                                         count:maxCount
                                                      fromUser:from
                                               searchDirection:direction
                                                    completion:^(NSArray *aMessages, EMError *aError)
     {
        NSMutableArray *msgList = [NSMutableArray array];
        for (EMMessage *msg in aMessages) {
            [msgList addObject:[EMHelper messageToDictionary:msg]];
        }
        
        [weakSelf wrapperCallBack:result error:aError userInfo:@{@"messages":msgList}];
    }];
}

// ??
- (void)getCursor:(NSDictionary *)param result:(FlutterResult)result {
    
}


#pragma mark - EMChatManagerDelegate

// TODO: 安卓没有参数，是否参数一起返回？
- (void)conversationListDidUpdate:(NSArray *)aConversationList {
    [self.channel invokeMethod:EMMethodKeyOnConversationUpdate
                     arguments:nil];
}

- (void)messagesDidReceive:(NSArray *)aMessages {
    NSMutableArray *msgList = [NSMutableArray array];
    for (EMMessage *msg in aMessages) {
        [msgList addObject:[EMHelper messageToDictionary:msg]];
    }
    NSLog(@"has receive messages -- %@", msgList);
    [self.channel invokeMethod:EMMethodKeyOnMessageReceived arguments:@{@"messages":msgList}];
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages {
    NSMutableArray *cmdMsgList = [NSMutableArray array];
    for (EMMessage *msg in aCmdMessages) {
        [cmdMsgList addObject:[EMHelper messageToDictionary:msg]];
    }
    
    [self.channel invokeMethod:EMMethodKeyOnCmdMessageReceived arguments:@{@"messages":cmdMsgList}];
}

- (void)messagesDidRead:(NSArray *)aMessages {
    NSMutableArray *msgList = [NSMutableArray array];
    for (EMMessage *msg in aMessages) {
        [msgList addObject:[EMHelper messageToDictionary:msg]];
    }
    
    [self.channel invokeMethod:EMMethodKeyOnMessageRead arguments:@{@"messages":msgList}];
}

- (void)messagesDidDeliver:(NSArray *)aMessages {
    NSMutableArray *msgList = [NSMutableArray array];
    for (EMMessage *msg in aMessages) {
        [msgList addObject:[EMHelper messageToDictionary:msg]];
    }
    
    [self.channel invokeMethod:EMMethodKeyOnMessageDelivered arguments:@{@"messages":msgList}];
}

- (void)messagesDidRecall:(NSArray *)aMessages {
    NSMutableArray *msgList = [NSMutableArray array];
    for (EMMessage *msg in aMessages) {
        [msgList addObject:[EMHelper messageToDictionary:msg]];
    }
    
    [self.channel invokeMethod:EMMethodKeyOnMessageRecalled arguments:@{@"messages":msgList}];
}

- (void)messageStatusDidChange:(EMMessage *)aMessage
                         error:(EMError *)aError {
    NSDictionary *msgDict = [EMHelper messageToDictionary:aMessage];
    [self.channel invokeMethod:EMMethodKeyOnMessageChanged arguments:@{@"message":msgDict}];
}

// TODO: 安卓未找到对应回调
- (void)messageAttachmentStatusDidChange:(EMMessage *)aMessage
                                   error:(EMError *)aError {
    NSDictionary *msgDict = [EMHelper messageToDictionary:aMessage];
    [self.channel invokeMethod:EMMethodKeyOnMessageChanged arguments:@{@"message":msgDict}];
}


@end
