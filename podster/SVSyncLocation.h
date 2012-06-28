//
//  SVSyncLocation.h
//  podster
//
//  Created by Stephen Vanterpool on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface SVSyncLocation : NSObject <NSCoding>
@property(nonatomic, copy) NSString *name;
@property(nonatomic, strong) CLLocation *location;
@end
