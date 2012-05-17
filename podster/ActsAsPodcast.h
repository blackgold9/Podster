//
//  ActsAsPodcast.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ActsAsPodcast <NSObject>
@property (strong) NSDate *lastSynced;
@property (strong) NSDate *lastUpdated;
@property (strong) NSString *title;
@property (strong) NSString *feedURL;
@property (strong) NSString *summary;
@property (strong) NSString *websiteURL;
@property (strong) NSString *logoURL;
@property (strong) NSString *smallLogoURL;
@property (strong) NSString *thumbLogoURL;
@property (strong) NSString *tinyLogoURL;
@property (strong) NSString *subtitle;
@property (strong) NSNumber *podstoreId;
@end
