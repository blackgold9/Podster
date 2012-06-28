//
//  SVSyncLocation.m
//  podster
//
//  Created by Stephen Vanterpool on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSyncLocation.h"

@implementation SVSyncLocation
@synthesize name = _name;
@synthesize location = _location;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.location = [aDecoder decodeObjectForKey:@"location"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.location forKey:@"location"];
}
@end
