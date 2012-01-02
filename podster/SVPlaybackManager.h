//
//  SVPlaybackManager.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVPodcast.h"
#import "SVPodcastEpisode.h"
@interface SVPlaybackManager : NSObject
@property (strong) SVPodcast *currentPodcast;
@property (strong) SVPodcastEpisode *currentEpisode;
+ (SVPlaybackManager *)sharedInstance;
- (BOOL)startedPlayback;
- (void)playEpisode:(SVPodcastEpisode *)episode ofPodcast:(SVPodcast *)podcast;
@end
