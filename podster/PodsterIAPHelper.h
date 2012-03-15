//
//  PodsterIAPHelper.h
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IAPHelper.h"

@interface PodsterIAPHelper : IAPHelper
- (NSUInteger)durationInDaysForProduct:(NSString *)productIdentifier;

+ (PodsterIAPHelper *)sharedInstance;
- (void)restoreTransactions;

@end
