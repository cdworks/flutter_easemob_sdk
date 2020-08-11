//
//  EMPushManagerWrapper.m
//  asset_picker
//
//  Created by 李平 on 2020/3/27.
//

#import "EMPushManagerWrapper.h"
#import "EMSDKMethod.h"
#import "EMHelper.h"

@implementation EMPushManagerWrapper

- (instancetype)initWithChannelName:(NSString *)aChannelName
                          registrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    if(self = [super initWithChannelName:aChannelName
                               registrar:registrar]) {
    }
    return self;
}

#pragma mark - FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall*)call
                  result:(FlutterResult)result {
   if ([EMMethodKeyGetNoPushGroups isEqualToString:call.method]) {
        [self getGroupsWithoutPushNotification:call.arguments result:result];
    } else if ([EMMethodKeyUpdatePushServiceForGroup isEqualToString:call.method]) {
        [self updatePushServiceForGroups:call.arguments result:result];
    }
    else if ([EMMethodKeyUpdatePushNickname isEqualToString:call.method]) {
           [self updatePushNickname:call.arguments result:result];
       }
    else if ([EMMethodKeyGetPushConfigsFromServer isEqualToString:call.method]) {
           [self getPushConfigsFromServer:call.arguments result:result];
       }
    else if ([EMMethodKeyEnableOfflinePush isEqualToString:call.method]) {
           [self enableOfflinePush:call.arguments result:result];
       }
    else if ([EMMethodKeyDisableOfflinePush isEqualToString:call.method]) {
           [self disableOfflinePush:call.arguments result:result];
       }
    else if ([EMMethodKeyGetPushConfigs isEqualToString:call.method]) {
           [self getPushConfigs:call.arguments result:result];
       }
    else if ([EMMethodKeyUpdatePushDisplayStyle isEqualToString:call.method]) {
        [self updatePushDisplayStyle:call.arguments result:result];
    }
    
}

- (void)getGroupsWithoutPushNotification:(NSDictionary *)param result:(FlutterResult)result {
    EMError *aError;
    NSArray *pushGroups = [EMClient.sharedClient.groupManager getGroupsWithoutPushNotification:&aError];
    if(!aError && pushGroups)
    {
        
        [self wrapperCallBack:result
           error:nil
                     userInfo:@{@"value": pushGroups}];
    }
    else
    {
        [self wrapperCallBack:result
           error:aError
        userInfo:nil];
    }
    
}


- (void)updatePushServiceForGroups:(NSDictionary *)param result:(FlutterResult)result {
    NSArray *groupIDs = param[@"groupIds"];
    BOOL isEnable = ![param[@"noPush"] boolValue];
    [EMClient.sharedClient.groupManager updatePushServiceForGroups:groupIDs
                                                     isPushEnabled:isEnable
                                                        completion:^(NSArray *groups, EMError *aError)
     {
        [self wrapperCallBack:result
                        error:aError
                     userInfo:@{@"value":[EMHelper groupsToDictionaries:groups]}];
    }];
}

-(void)updatePushNickname:(NSDictionary *)param result:(FlutterResult)result {
    [[EMClient sharedClient] updatePushNotifiationDisplayName:[param valueForKeyPath:@"nickname"] completion:^(NSString *aDisplayName, EMError *aError) {
        if(!aError)
        {
            [self wrapperCallBack:result
               error:nil
            userInfo:@{@"value":@(YES)}];
        }
        else
        {
            [self wrapperCallBack:result
               error:aError
                         userInfo:nil];
        }
    }];
}
-(void)getPushConfigsFromServer:(NSDictionary *)param result:(FlutterResult)result {
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError* aError;
        EMPushOptions* options = [[EMClient sharedClient] getPushOptionsFromServerWithError:&aError];
        [weakSelf wrapperCallBack:result
           error:aError
                         userInfo:@{@"value":[EMHelper pushOptionsToDictionary:options]}];
    });
}
-(void)enableOfflinePush:(NSDictionary *)param result:(FlutterResult)result {
    EMPushOptions* options = [[EMClient sharedClient] pushOptions];
    options.noDisturbStatus = EMPushNoDisturbStatusClose;
    [[EMClient sharedClient] updatePushNotificationOptionsToServerWithCompletion:^(EMError *aError) {
        if(!aError)
        {
            [self wrapperCallBack:result
               error:nil
            userInfo:@{@"value":@(YES)}];
        }
        else
        {
            [self wrapperCallBack:result
               error:aError
                         userInfo:nil];
        }
    }];
}
-(void)disableOfflinePush:(NSDictionary *)param result:(FlutterResult)result {
    EMPushOptions* options = [[EMClient sharedClient] pushOptions];
    options.noDisturbStatus = EMPushNoDisturbStatusDay;
    [[EMClient sharedClient] updatePushNotificationOptionsToServerWithCompletion:^(EMError *aError) {
        if(!aError)
        {
            [self wrapperCallBack:result
               error:nil
            userInfo:@{@"value":@(YES)}];
        }
        else
        {
            [self wrapperCallBack:result
               error:aError
                         userInfo:nil];
        }
    }];
}
-(void)getPushConfigs:(NSDictionary *)param result:(FlutterResult)result {
   EMPushOptions* options = [[EMClient sharedClient] pushOptions];
    if(options)
    {
        [self wrapperCallBack:result
        error:nil
                      userInfo:@{@"value":[EMHelper pushOptionsToDictionary:options]}];
    }
    else{
        [self wrapperCallBack:result
        error:[EMError errorWithDescription:@"获取推送设置失败!" code:EMErrorGeneral]
                     userInfo:@{@"value":@{}}];
    }
    
}

-(void)updatePushDisplayStyle:(NSNumber *)param result:(FlutterResult)result {
   EMPushOptions* options = [[EMClient sharedClient] pushOptions];
   
    if(options)
    {
         options.displayStyle = param.intValue;
        [[EMClient sharedClient] updatePushOptionsToServer];
        [self wrapperCallBack:result
        error:nil
                      userInfo:@{@"value":@(YES)}];
    }
    else{
        [self wrapperCallBack:result
        error:[EMError errorWithDescription:@"获取推送设置失败!" code:EMErrorGeneral]
                     userInfo:@{@"value":@(NO)}];
    }
    
}



@end
