//
//  EMVoiceRecorderWrapper.m
//  asset_picker
//
//  Created by 李平 on 2020/2/7.
//

#import "EMVoiceRecorderWrapper.h"
#import "EMCDDeviceManager.h"
#import "EMHelper.h"

@interface EMVoiceRecorderWrapper ()

@end

@implementation EMVoiceRecorderWrapper
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
    if([call.method isEqualToString:@"startRecorder"])
    {
        int x = arc4random() % 100000;
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
        NSString *fileName = [NSString stringWithFormat:@"%d%d",(int)time,x];
        [[EMCDDeviceManager sharedInstance] asyncStartRecordingWithFileName:fileName completion:^(NSError *error)
        {
            if (error) {
                 [self wrapperCallBack:result
                                 error:[EMError errorWithDescription:error.localizedDescription code:EMErrorGeneral]
                                    userInfo:nil];
//                NSLog(@"%@",NSEaseLocalizedString(@"message.startRecordFail", @"failure to start recording"));
            }
            else{
                [self wrapperCallBack:result
                error:nil
                   userInfo:nil];
            }
        }];
    }
    else if([call.method isEqualToString:@"stopRecorder"])
    {
        [[EMCDDeviceManager sharedInstance] asyncStopRecordingWithCompletion:^(NSString *recordPath, NSInteger aDuration, NSError *error) {
            if (!error) {
                [self wrapperCallBack:result
                error:nil
                             userInfo:@{@"recordPath":recordPath,@"duration":@(aDuration)}];
//                [weakSelf sendVoiceMessageWithLocalPath:recordPath duration:aDuration];
            }
            else {
                [self wrapperCallBack:result
                                error:[EMError errorWithDescription:error.domain code:error.code == -100 ? 1000:EMErrorGeneral]
                   userInfo:nil];
                
            }
        }];
    }
    else if([call.method isEqualToString:@"cancelRecorder"])
    {
        [[EMCDDeviceManager sharedInstance] cancelCurrentRecording];
        [self wrapperCallBack:result
        error:nil userInfo:nil];
    }
    else if([call.method isEqualToString:@"playVoice"])
    {
        NSString* path = call.arguments;
        if(!path.length)
        {
            [self wrapperCallBack:result
            error:[EMError errorWithDescription:@"path error!" code:EMErrorGeneral]
               userInfo:nil];
            return;
        }
        [[EMCDDeviceManager sharedInstance] enableProximitySensor];
        [[EMCDDeviceManager sharedInstance] asyncPlayingWithPath:path completion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(error)
                {
                    [self wrapperCallBack:result
                    error:[EMError errorWithDescription:error.localizedDescription code:EMErrorGeneral]
                       userInfo:nil];
                    return;
                }
                else
                {
                    [self wrapperCallBack:result
                    error:nil userInfo:nil];
                }
                [[EMCDDeviceManager sharedInstance] disableProximitySensor];
            });
        }];
    }
    else if([call.method isEqualToString:@"stopPlay"])
    {
        [[EMCDDeviceManager sharedInstance] stopPlaying];
        [[EMCDDeviceManager sharedInstance] disableProximitySensor];
        [self wrapperCallBack:result
        error:nil userInfo:nil];
    }
}
@end
