//
//  SVCustomApplication.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVCustomApplication.h"
#import "SVPlaybackManager.h"
#import <AVFoundation/AVFoundation.h>
@implementation SVCustomApplication
-(void)startListeningForRemoteEvents
{
    [self startListeningForRemoteEvents];
    [self becomeFirstResponder];
}

-(void)stopListeningForRemoteEvents
{
    [self stopListeningForRemoteEvents];
    [self resignFirstResponder];
}
-(BOOL)canBecomeFirstResponder
{
    return YES;
}
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    AVPlayer *_player = [[SVPlaybackManager sharedInstance] player];
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if( _player) {
                    if ( _player.rate != 0) {
                        _player.rate = 0;
                    } else {
                        _player.rate = 1;
                    }
                }
                break;
                
            default:
                break;
        }
    }
}

@end
