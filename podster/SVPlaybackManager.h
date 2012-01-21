//
//  SVPlaybackManager.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SVPodcast.h"
#import "SVPodcastEntry.h"
@interface SVPlaybackManager : UIResponder
@property (strong) SVPodcast *currentPodcast;
@property (strong) SVPodcastEntry *currentEpisode;
+ (SVPlaybackManager *)sharedInstance;

- (AVPlayer *)player;

- (BOOL)startedPlayback;
- (void)playEpisode:(SVPodcastEntry *)episode ofPodcast:(SVPodcast *)podcast;
@end
