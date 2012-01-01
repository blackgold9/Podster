//
//  SVPodcast.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPodcast.h"

@implementation SVPodcast
@synthesize title,podcastDescription, feedURL,websiteURL, logoURL;
+(id)podcastFromDictionary:(NSDictionary *)dictionary
{
    SVPodcast *podcast = [SVPodcast new];
    podcast.title = [dictionary objectForKey:@"title"];
    podcast.title = [podcast.title capitalizedString];
    
    podcast.podcastDescription = [dictionary objectForKey:@"description"];
    podcast.feedURL = [dictionary objectForKey:@"url"];
    podcast.websiteURL = [dictionary objectForKey:@"website"];
    podcast.logoURL = [dictionary objectForKey:@"logo_url"];
    
    return podcast;
}
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], self.title];
}
@end
