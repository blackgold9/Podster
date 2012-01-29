//
//  SVPodcastModalView.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UAModalPanel.h"
#import "UATitledModalPanel.h"
#import "ActsAsPodcast.h"
@interface SVPodcastModalView : UAModalPanel
@property (nonatomic, strong) id<ActsAsPodcast> podcast;
@end
