//
//  SVPodcast.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVPodcast : NSObject
+(id)podcastFromDictionary:(NSDictionary *)dictionary;
@property (strong) NSString *title;
@property (strong) NSString *feedURL;
@property (strong) NSString *websiteURL;
@property (strong) NSString *podcastDescription;
@property (strong) NSString *logoURL;
@end
