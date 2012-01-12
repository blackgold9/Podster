//
//  ActsAsPodcast.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ActsAsPodcast <NSObject>
@property (copy) NSString *title;
@property (copy) NSString *feedURL;
@property (copy) NSString *summary;
@property (copy) NSString *websiteURL;
@property (copy) NSString *logoURL;
@end
