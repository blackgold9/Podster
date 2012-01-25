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
@synthesize title, summary, feedURL, websiteURL, logoURL, tinyLogoURL,smallLogoURL,thumbLogoURL;
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
    if ([[dictionary objectForKey:@"image"] objectForKey:@"url"] != [NSNull null]) {
        self.logoURL = [[dictionary objectForKey:@"image"] objectForKey:@"url"];
        self.smallLogoURL = [[[dictionary objectForKey:@"image"] objectForKey:@"small"] objectForKey:@"url"];
        self.tinyLogoURL =  [[[dictionary objectForKey:@"image"] objectForKey:@"tiny"] objectForKey:@"url"];
        self.thumbLogoURL =  [[[dictionary objectForKey:@"image"] objectForKey:@"thumb"] objectForKey:@"url"];
    }    
}
@end
