//
//  PodsterIAPHelper.m
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PodsterIAPHelper.h"

@implementation PodsterIAPHelper

- (NSUInteger)durationInDaysForProduct:(NSString *)productIdentifier
{
    if([productIdentifier isEqualToString:@"net.vanterpool.podster.premium1year"]) {
        return 365;
    } else if ([productIdentifier isEqualToString:@"net.vanterpool.podster.premium1month"]) {
        return 31;
    } else if ([productIdentifier isEqualToString:@"net.vanterpool.podster.premium1week"]) {
        return 7;
    } else {
        NSAssert(false, @"We should never get here. This is a product we don't know about");
        return 0;
    }
}

+ (PodsterIAPHelper *)sharedInstance
{
    static PodsterIAPHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            NSSet *identifiers = [NSSet setWithObjects:
                                  @"net.vanterpool.podster.premium1year",
                                  @"net.vanterpool.podster.premium1month",
                                  nil];
            instance = [[PodsterIAPHelper alloc] initWithProductIdentifiers:identifiers];
        }
    });

    return instance;
}

@end
