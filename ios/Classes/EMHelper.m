//
//  EMHelper.m
//  
//
//  Created by 杜洁鹏 on 2019/10/8.
//

#import "EMHelper.h"
#import <Hyphenate/EMOptions+PrivateDeploy.h>

@implementation EMHelper

#pragma mark - EMOptions
+ (EMOptions *)dictionaryToEMOptions:(NSDictionary *)aDictionary
{
    EMOptions *options = [EMOptions optionsWithAppkey:aDictionary[@"appKey"]];
    if (aDictionary[@"pushConfig"]) {
        NSLog(@"证书名称----%@", aDictionary[@"pushConfig"][@"apnsSenderId"]);
        options.apnsCertName = aDictionary[@"pushConfig"][@"apnsSenderId"];
    }
    if (aDictionary[@"acceptInvitationAlways"]) {
        options.isAutoAcceptFriendInvitation = [aDictionary[@"acceptInvitationAlways"] boolValue];
    }
    
    if (aDictionary[@"autoAcceptGroupInvitation"]) {
        options.isAutoAcceptGroupInvitation = [aDictionary[@"autoAcceptGroupInvitation"] boolValue];
    }
    
    if (aDictionary[@"requireDeliveryAck"]) {
        options.enableDeliveryAck = [aDictionary[@"requireDeliveryAck"] boolValue];
    }
    
    if (aDictionary[@"deleteMessagesAsExitGroup"]) {
        options.isDeleteMessagesWhenExitGroup = [aDictionary[@"deleteMessagesAsExitGroup"] boolValue];
    }
    
    if (aDictionary[@"isChatRoomOwnerLeaveAllowed"]) {
        options.isChatroomOwnerLeaveAllowed = [aDictionary[@"isChatRoomOwnerLeaveAllowed"] boolValue];
    }
    
    if (aDictionary[@"autoLogin"]) {
        options.isAutoLogin = [aDictionary[@"autoLogin"] boolValue];
    }
    
    if (aDictionary[@"sortMessageByServerTime"]) {
        options.sortMessageByServerTime = [aDictionary[@"sortMessageByServerTime"] boolValue];
    }
    
    if (aDictionary[@"enableDNSConfig"]) {
        options.enableDnsConfig = [aDictionary[@"enableDNSConfig"] boolValue];
    }
    
    if (aDictionary[@"dnsUrl"]) {
        options.dnsURL = aDictionary[@"dnsUrl"];
    }
    
    if (aDictionary[@"restServer"]) {
        options.restServer = aDictionary[@"restServer"];
    }
    
    if (aDictionary[@"imServer"]) {
        options.chatServer = aDictionary[@"imServer"];
    }
    
    if (aDictionary[@"imPort"]) {
        options.chatPort = [aDictionary[@"imPort"] intValue];
    }
    
    if (aDictionary[@"usingHttpsOnly"]) {
        options.usingHttpsOnly = [aDictionary[@"usingHttpsOnly"] boolValue];
    }
    
    if (aDictionary[@"serverTransfer"]) {
        options.isAutoTransferMessageAttachments = [aDictionary[@"serverTransfer"] boolValue];
    }
    
    if (aDictionary[@"isAutoDownload"]) {
        options.isAutoDownloadThumbnail = [aDictionary[@"isAutoDownload"] boolValue];
    }

    return options;
}

#pragma mark - Message

+ (EMMessage *)dictionaryToMessage:(NSDictionary *)aDictionary {
    
    EMMessage *ret = nil;
    EMMessageBody *body = nil;
    
    int type = [aDictionary[@"type"] intValue];
    EMChatType chatType;
    if ([aDictionary[@"chatType"] isKindOfClass:[NSNull class]]) {
        chatType = EMChatTypeChat;
    }else {
        chatType = (EMChatType)[aDictionary[@"chatType"] intValue];
    }
    
    NSString *to = aDictionary[@"to"];
    NSString *from = EMClient.sharedClient.currentUsername;
    NSDictionary *ext = aDictionary[@"attributes"];
    
    NSDictionary *msgBodyDict = aDictionary[@"body"];
    switch (type) {
        case 0:
        {
            NSString *content = msgBodyDict[@"message"];
            body = [[EMTextMessageBody alloc] initWithText:content];
            
        }
            break;
        
        case 2:
        {
            NSString *localUrl = msgBodyDict[@"localUrl"];
            int videoDuration = [msgBodyDict[@"videoDuration"] intValue];
            long long fileLength = [msgBodyDict[@"fileLength"] longLongValue];
            body = [[EMVideoMessageBody alloc] initWithLocalPath:localUrl
                                                     displayName:@"video"];
            ((EMVideoMessageBody *)body).fileLength = fileLength;
            ((EMVideoMessageBody *)body).duration = videoDuration;
        }
            break;
        case 3:
        {
            NSString *address = msgBodyDict[@"address"];
            double latitude = [msgBodyDict[@"latitude"] doubleValue];
            double longitude = [msgBodyDict[@"longitude"] doubleValue];
            body = [[EMLocationMessageBody alloc] initWithLatitude:latitude
                                                         longitude:longitude
                                                           address:address];
        }
            break;
        case 4:
        {
            NSString *localUrl = msgBodyDict[@"localUrl"];
            int voiceDuration = [msgBodyDict[@"voiceDuration"] intValue];
            long long fileLength = [msgBodyDict[@"fileLength"] longLongValue];
            body = [[EMVoiceMessageBody alloc] initWithLocalPath:localUrl displayName:@"voice"];
            ((EMVoiceMessageBody *)body).duration = voiceDuration;
            ((EMVoiceMessageBody *)body).fileLength = fileLength;
        }
            break;
        case 5:
        {
            NSString *localUrl = msgBodyDict[@"localUrl"];
            long long fileLength = [msgBodyDict[@"fileLength"] longLongValue];
            NSString* fileName = [msgBodyDict valueForKeyPath:@"displayName"];
            if(!fileName.length)
            {
                fileName =[localUrl pathComponents].lastObject;
            }
 
            body = [[EMFileMessageBody alloc] initWithLocalPath:localUrl displayName:fileName];
            ((EMFileMessageBody *)body).fileLength = fileLength;
        }
            break;
        case 6:
        {
            NSString *action = msgBodyDict[@"action"];
            body = [[EMCmdMessageBody alloc] initWithAction:action];
        }
            break;
            
        default:
            break;
    }
    
    ret = [[EMMessage alloc] initWithConversationID:to
                                               from:from
                                                 to:to
                                               body:body
                                                ext:ext];
    ret.chatType = chatType;

    return ret;
}

+ (NSDictionary *)messageToDictionary:(EMMessage *)aMessage {

    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    ret[@"attributes"] = aMessage.ext;
    ret[@"conversationId"] = aMessage.conversationId;
    ret[@"type"] = @([self getMessageType:aMessage]);
    ret[@"acked"] = @(aMessage.isReadAcked);
    ret[@"body"] = [self messageBodyToDictionary:aMessage.body];
    ret[@"chatType"] = @(aMessage.chatType);
    ret[@"delivered"] = @(aMessage.isDeliverAcked);
    ret[@"direction"] = @([self getMessageDirect:aMessage]);
    ret[@"from"] = aMessage.from;
    ret[@"localTime"] = [@(aMessage.localTime) stringValue];
    ret[@"msgId"] = aMessage.messageId;
    ret[@"msgTime"] = [@(aMessage.timestamp) stringValue];
    ret[@"status"] = @([self getMessageStatus:aMessage]);
    ret[@"to"] = aMessage.to;
    ret[@"unread"] = [NSNumber numberWithBool:!aMessage.isRead];
    
    return ret;
}

+ (NSDictionary *)messageBodyToDictionary:(EMMessageBody *)aBody {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    ret[@"type"] = @([self messageBodyTypeToInt:aBody.type]);
    switch (aBody.type) {
        case EMMessageBodyTypeText:
        {
            ret[@"message"] = ((EMTextMessageBody *)aBody).text;
        }
            break;
        case EMMessageBodyTypeImage:
        {
            EMImageMessageBody* imgBody = (EMImageMessageBody *)aBody;
            ret[@"displayName"] = imgBody.displayName;
            ret[@"downloadStatus"] = @(imgBody.downloadStatus);
            ret[@"localUrl"] = imgBody.localPath;
            ret[@"remoteUrl"] = imgBody.remotePath;
            ret[@"fileLength"] = @(imgBody.fileLength);
            
            
            ret[@"thumbnailLocalPath"] = imgBody.thumbnailLocalPath;
            ret[@"thumbnailUrl"] = imgBody.thumbnailRemotePath;
            
            
            //计算宽高
            if(imgBody.size.width < 1 || imgBody.size.height < 1)
            {
                CGSize size = CGSizeZero;
                
                if ([imgBody.thumbnailLocalPath length] > 0) {
                    size = [UIImage imageWithContentsOfFile:imgBody.thumbnailLocalPath].size;
                }
                else if([imgBody.localPath length] > 0)
                {
                    size = [UIImage imageWithContentsOfFile:imgBody.localPath].size;
                }
                ret[@"height"] = @(size.height);
                ret[@"width"] = @(size.width);
            }
            else
            {
                ret[@"height"] = @(imgBody.size.height);
                ret[@"width"] = @(imgBody.size.width);
            }
            
            
        }
            break;
        case EMMessageBodyTypeVideo:
        {
            ret[@"displayName"] = ((EMVideoMessageBody *)aBody).displayName;
            ret[@"downloadStatus"] = @(((EMVideoMessageBody *)aBody).downloadStatus);
            ret[@"localUrl"] = ((EMVideoMessageBody *)aBody).localPath;
            ret[@"remoteUrl"] = ((EMVideoMessageBody *)aBody).remotePath;
            ret[@"fileLength"] = @(((EMVideoMessageBody *)aBody).fileLength);
            
            ret[@"videoDuration"] = @(((EMVideoMessageBody *)aBody).duration);
            ret[@"localThumb"] = ((EMVideoMessageBody *)aBody).thumbnailLocalPath;
            ret[@"thumbnailHeight"] = @(((EMVideoMessageBody *)aBody).thumbnailSize.height);
            ret[@"thumbnailWidth"] = @(((EMVideoMessageBody *)aBody).thumbnailSize.width);
            ret[@"thumbnailUrl"] = ((EMVideoMessageBody *)aBody).thumbnailRemotePath;
        }
            break;
        case EMMessageBodyTypeLocation:
        {
            ret[@"address"] = ((EMLocationMessageBody *)aBody).address;
            ret[@"latitude"] = @(((EMLocationMessageBody *)aBody).latitude);
            ret[@"longitude"] = @(((EMLocationMessageBody *)aBody).longitude);
        }
            break;
        case EMMessageBodyTypeVoice:
        {
            ret[@"displayName"] = ((EMVoiceMessageBody *)aBody).displayName;
            ret[@"downloadStatus"] = @(((EMVoiceMessageBody *)aBody).downloadStatus);
            ret[@"localUrl"] = ((EMVoiceMessageBody *)aBody).localPath;
            ret[@"remoteUrl"] = ((EMVoiceMessageBody *)aBody).remotePath;
            ret[@"fileLength"] = @(((EMVoiceMessageBody *)aBody).fileLength);
            
            ret[@"voiceDuration"] = @(((EMVoiceMessageBody *)aBody).duration);
        }
            break;
        case EMMessageBodyTypeFile:
        {
            ret[@"displayName"] = ((EMFileMessageBody *)aBody).displayName;
            ret[@"downloadStatus"] = @(((EMFileMessageBody *)aBody).downloadStatus);
            ret[@"localUrl"] = ((EMFileMessageBody *)aBody).localPath;
            ret[@"remoteUrl"] = ((EMFileMessageBody *)aBody).remotePath;
            ret[@"fileSize"] = @(((EMFileMessageBody *)aBody).fileLength);
        }
            break;
        case EMMessageBodyTypeCmd:
        {
            ret[@"action"] = ((EMCmdMessageBody *)aBody).action;
            ret[@"isDeliverOnlineOnly"] = @(((EMCmdMessageBody *)aBody).isDeliverOnlineOnly);
        }
            break;
            
        default:
            break;
    }
    return ret;
}

+ (NSArray *)dictionariesToMessages:(NSArray *)dicts {
    NSMutableArray *ret = [NSMutableArray array];
    for (NSDictionary *dict in dicts) {
        [ret addObject:[self dictionaryToMessage:dict]];
    }
    return ret;
}

+ (NSArray *)messagesToDictionaries:(NSArray *)messages {
    NSMutableArray *ret = [NSMutableArray array];
    for (EMMessage *msg in messages) {
        [ret addObject:[self messageToDictionary:msg]];
    }
    return ret;
}


#pragma mark - Conversation

+ (NSDictionary *)conversationToDictionary:(EMConversation *)aConversation {
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    ret[@"id"] = aConversation.conversationId;
    ret[@"type"] = @([self conversationTypeToInt:aConversation.type]);
    ret[@"ext"] = aConversation.ext;
    ret[@"unreadMessagesCount"] = @(aConversation.unreadMessagesCount);
    return ret;
}


+ (int)conversationTypeToInt:(EMConversationType)aType {
    int ret = 0;
    switch (aType) {
        case EMConversationTypeChat:
            ret = 0;
            break;
        case EMConversationTypeGroupChat:
            ret = 1;
            break;
        case EMConversationTypeChatRoom:
            ret = 2;
            break;
        default:
            break;
    }
    return ret;

}

#pragma mark - Group

+ (NSDictionary *)groupToDictionary:(EMGroup *)aGroup {
    EMGroupOptions *options = aGroup.setting;
    EMGroupStyle style = options.style;
    BOOL isMemberAllowToInvite;
       BOOL isMemberOnly = YES;
       if (style == EMGroupStylePrivateOnlyOwnerInvite) {
           isMemberAllowToInvite = NO;
       } else if (style == EMGroupStylePrivateMemberCanInvite) {
           isMemberAllowToInvite = YES;
       } else if (style == EMGroupStylePublicJoinNeedApproval) {
           isMemberAllowToInvite = NO;
       } else {
           isMemberAllowToInvite = NO;
           isMemberOnly = NO;
       }

       EMGroupPermissionType permissionType = aGroup.permissionType;
       int type;
       if (permissionType == EMGroupPermissionTypeNone) {
           type = -1;
       } else if (permissionType == EMGroupPermissionTypeMember) {
           type = 0;
       } else if (permissionType == EMGroupPermissionTypeAdmin) {
           type = 1;
       } else {
           type = 2;
       }
       
    NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
    if (aGroup.groupId) {
        groupDict[@"groupId"] = aGroup.groupId;
    }
    if (aGroup.subject) {
        groupDict[@"groupName"] = aGroup.subject;
    }
    if (aGroup.description) {
        groupDict[@"description"] = aGroup.description;
    }
    if (aGroup.announcement) {
        groupDict[@"announcement"] = aGroup.announcement;
    }
    if (aGroup.owner) {
        groupDict[@"owner"] = aGroup.owner;
    }
    if (aGroup.adminList) {
        groupDict[@"adminList"] = aGroup.adminList;
    }
    if (aGroup.memberList) {
        groupDict[@"members"] = aGroup.memberList;
    }
    if (aGroup.blacklist) {
        groupDict[@"blacklist"] = aGroup.blacklist;
    }
    if (aGroup.muteList) {
        groupDict[@"muteList"] = aGroup.muteList;
    }
    if (options.ext) {
        groupDict[@"extension"] = options.ext;
    }
    if (aGroup.sharedFileList) {
        groupDict[@"sharedFileList"] = [self groupFileListToDictionaries:aGroup.sharedFileList];
    }
    if (aGroup.occupants) {
        groupDict[@"occupants"] = aGroup.occupants;
    }
    groupDict[@"memberCount"] = [NSNumber numberWithInteger:aGroup.occupantsCount];
    groupDict[@"isMemberAllowToInvite"] = [NSNumber numberWithBool:isMemberAllowToInvite];
    groupDict[@"isMemberOnly"] = [NSNumber numberWithBool:isMemberOnly];
    groupDict[@"maxUserCount"] = [NSNumber numberWithInteger:options.maxUsersCount];
    groupDict[@"isPublic"] = [NSNumber numberWithBool:aGroup.isPublic];
    groupDict[@"isPushNotificationEnabled"] = [NSNumber numberWithBool:aGroup.isPushNotificationEnabled];
    groupDict[@"isMsgBlocked"] = [NSNumber numberWithBool:aGroup.isBlocked];
    groupDict[@"permissionType"] = [NSNumber numberWithInt:type];

       
       return groupDict;
}

+ (NSArray *)groupsToDictionaries:(NSArray *)groups {
    NSMutableArray *ret = [NSMutableArray array];
    for (EMGroup *group in groups) {
        NSDictionary *dict = [self groupToDictionary:group];
        [ret addObject:dict];
    }
    return ret;
}

+ (NSDictionary *)groupSharedFileToDictionary:(EMGroupSharedFile *)sharedFile
{
    NSMutableDictionary *sharedFileDict = [NSMutableDictionary dictionary];
    if (sharedFile.fileId) {
        sharedFileDict[@"fileId"] = sharedFile.fileId;
    }
    if (sharedFile.fileName) {
        sharedFileDict[@"fileName"] = sharedFile.fileName;
    }
    if (sharedFile.fileOwner) {
        sharedFileDict[@"fileOwner"] = sharedFile.fileOwner;
    }
    if (sharedFile.createTime) {
        sharedFileDict[@"createTime"] = [NSNumber numberWithLongLong:sharedFile.createTime];
    }
    if (sharedFile.fileSize) {
        sharedFileDict[@"fileSize"] = [NSNumber numberWithLongLong:sharedFile.fileSize];
    }
    return sharedFileDict;
}

+ (NSArray *)groupFileListToDictionaries:(NSArray *)groupFileList
{
    NSMutableArray *sharedFileMutableArray = [NSMutableArray array];
    for (EMGroupSharedFile *sharedFile in groupFileList) {
        [sharedFileMutableArray addObject:[self groupSharedFileToDictionary:sharedFile]];
    }
    return [NSArray arrayWithArray:sharedFileMutableArray];
}

#pragma mark - pushNotification

+ (NSDictionary *)pushOptionsToDictionary:(EMPushOptions *)options {
    if(options)
    {
        return @{@"nickName":options.displayName ? options.displayName : @"",@"noDisturbOn":[NSNumber numberWithBool:options.noDisturbStatus!=EMPushNoDisturbStatusClose] ,@"startHour":@(options.noDisturbingStartH),@"endHour":@(options.noDisturbingEndH),@"displayStyle":@((int)options.displayStyle)};
    }
    return @{};
}


#pragma mark - ChatRoom

+ (NSDictionary *)chatRoomToDictionary:(EMChatroom *)aChatRoom {
    EMChatroomPermissionType permissionType = aChatRoom.permissionType;
    int type;
    if (permissionType == EMChatroomPermissionTypeNone) {
        type = -1;
    } else if (permissionType == EMChatroomPermissionTypeMember) {
        type = 0;
    } else if (permissionType == EMChatroomPermissionTypeAdmin) {
        type = 1;
    } else if (permissionType == EMChatroomPermissionTypeOwner){
        type = 2;
    }
    
    NSMutableDictionary *chatRoomDitc = [NSMutableDictionary dictionary];
    if (aChatRoom.chatroomId) {
        chatRoomDitc[@"roomId"] = aChatRoom.chatroomId;
    }
    if (aChatRoom.subject) {
        chatRoomDitc[@"roomName"] = aChatRoom.subject;
    }
    if (aChatRoom.description) {
        chatRoomDitc[@"description"] = aChatRoom.description;
    }
    if (aChatRoom.owner) {
        chatRoomDitc[@"owner"] = aChatRoom.owner;
    }
    if (aChatRoom.announcement) {
        chatRoomDitc[@"announcement"] = aChatRoom.announcement;
    }
    if (aChatRoom.adminList) {
        chatRoomDitc[@"administratorList"] = aChatRoom.adminList;
    }
    if (aChatRoom.memberList) {
        chatRoomDitc[@"memberList"] = aChatRoom.memberList;
    }
    if (aChatRoom.blacklist) {
        chatRoomDitc[@"blacklist"] = aChatRoom.blacklist;
    }
    if (aChatRoom.muteList) {
        NSMutableArray *muteList = [NSMutableArray array];
        chatRoomDitc[@"muteList"] = aChatRoom.muteList;
    }
    if (aChatRoom.maxOccupantsCount) {
        chatRoomDitc[@"maxUserCount"] = @(aChatRoom.maxOccupantsCount);
    }
    if (aChatRoom.occupantsCount) {
        chatRoomDitc[@"affiliationsCount"] = @(aChatRoom.occupantsCount);
    }
     
    return chatRoomDitc;
}

+ (NSArray *)chatRoomsToDictionaries:(NSArray *)chatRooms {
    NSMutableArray *ret = [NSMutableArray array];
    for (EMChatroom *chatRoom in chatRooms) {
        NSDictionary *dict = [self chatRoomToDictionary:chatRoom];
        [ret addObject:dict];
    }
    return ret;
}
#pragma mark - Others

+ (NSDictionary *)pageReslutToDictionary:(EMPageResult *)aPageResult {
    NSDictionary *resultDict = @{
        @"data":[self chatRoomsToDictionaries:aPageResult.list],
        @"pageCount":[NSNumber numberWithInteger:aPageResult.count]
    };
    return resultDict;
}


#pragma mark - Private
+ (int)getMessageType:(EMMessage *)aMessage {
    int ret = 0;
    EMMessageBodyType type = aMessage.body.type;
    switch (type) {
        case EMMessageBodyTypeText:
            ret = 0;
            break;
        case EMMessageBodyTypeImage:
            ret = 1;
            break;
        case EMMessageBodyTypeVideo:
            ret = 2;
            break;
        case EMMessageBodyTypeLocation:
            ret = 3;
            break;
        case EMMessageBodyTypeVoice:
            ret = 4;
            break;
        case EMMessageBodyTypeFile:
            ret = 5;
            break;
        case EMMessageBodyTypeCmd:
            ret = 6;
            break;
        default:
            break;
    }
    return ret;
}

+ (int)getMessageDirect:(EMMessage *)aMessage {
    return aMessage.direction == EMMessageDirectionSend ? 0 : 1;
}

+ (int)getMessageStatus:(EMMessage *)aMessage {
    int ret = 0;
    switch (aMessage.status) {
        case EMMessageStatusSucceed:
        {
            ret = 0;
        }
            break;
        case EMMessageStatusFailed:
        {
            ret = 1;
        }
            break;
        case EMMessageStatusPending:
        {
            ret = 2;
        }
            break;
        default:
            ret = 3;
            break;
    }
    return ret;
}

+ (int)messageBodyTypeToInt:(EMMessageBodyType)aType {
    int ret = 0;
    switch (aType) {
        case EMMessageBodyTypeText:
        {
            ret = 0;
        }
            break;
        case EMMessageBodyTypeImage:
        {
            ret = 1;
        }
            break;
        case EMMessageBodyTypeVideo:
        {
            ret = 2;
        }
            break;
        case EMMessageBodyTypeLocation:
        {
            ret = 3;
        }
            break;
        case EMMessageBodyTypeVoice:
        {
            ret = 4;
        }
            break;
        case EMMessageBodyTypeFile:
        {
            ret = 5;
        }
            break;
        case EMMessageBodyTypeCmd:
        {
            ret = 6;
        }
            break;
        default:
            break;
    }
    return ret;
}

@end
