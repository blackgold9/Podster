//
//  SVPodcastSearchResult.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVPodcastSearchResult : NSObject
@property (copy) NSString *title;
@property (copy) NSString *feedURL;
@property (copy) NSString *imageURL;
@property (copy) NSString *summary;
@property (copy) NSString *websiteURL;
@property (copy) NSString *logoURL;
-(void)populateWithDictionary:(NSDictionary *)dictionary;
@end
