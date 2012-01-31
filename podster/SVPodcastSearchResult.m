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
@synthesize title, summary, feedURL, websiteURL, logoURL, tinyLogoURL,smallLogoURL,thumbLogoURL, subtitle;
-(void)populateWithDictionary:(NSDictionary *)dataDict
{
    NSDictionary *dictionary = [dataDict objectForKey:@"feed"];
    self.title = [dictionary stringForKey:@"title"];
    self.title = [self.title capitalizedString];
    NSParameterAssert(self.title);
    self.summary = [dictionary stringForKey:@"summary"];
    self.feedURL = [dictionary stringForKey:@"feed_url"];
    NSParameterAssert(self.feedURL);
    self.subtitle = [dictionary stringForKey:@"subtitle"];
    self.websiteURL = [dictionary stringForKey:@"website_url"];
    
    self.logoURL = [dictionary stringForKey:@"logo"];
    
    self.smallLogoURL = [dictionary stringForKey:@"logo_small"];
    self.tinyLogoURL = [dictionary stringForKey:@"logo_tiny"];
    self.thumbLogoURL = [dictionary stringForKey:@"logo_thumb"];    
}@end
