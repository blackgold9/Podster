//
//  SVPodcastSearchResult.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastSearchResult.h"
#import "NSDictionary+safeGetters.h"
@implementation SVPodcastSearchResult
@synthesize title, summary, feedURL, websiteURL, logoURL;
// Custom logic goes here.
-(void)populateWithDictionary:(NSDictionary *)dictionary
{
    
    self.title = [dictionary stringForKey:@"title"];
    self.title = [self.title capitalizedString];
    NSParameterAssert(self.title);
    self.summary = [dictionary stringForKey:@"summary"];
    self.feedURL = [dictionary stringForKey:@"feed_url"];
    NSParameterAssert(self.feedURL);
    self.websiteURL = [dictionary stringForKey:@"website_url"];
    self.logoURL = [dictionary stringForKey:@"image_url"];        
    
}
@end
