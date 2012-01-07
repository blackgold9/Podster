//
//  NSDictionary+safeGetters.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+safeGetters.h"

@implementation NSDictionary (safeGetters)
-(NSString *)stringForKey:(NSString *)key
{
    if ([self objectForKey:key] == [NSNull null]) {
        return nil;
    }
    return [self valueForKey:key];
}
@end
