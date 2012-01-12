//
//  SVPodcastSearchResult.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActsAsPodcast.h"
@interface SVPodcastSearchResult : NSObject<ActsAsPodcast>

-(void)populateWithDictionary:(NSDictionary *)dictionary;
@end
