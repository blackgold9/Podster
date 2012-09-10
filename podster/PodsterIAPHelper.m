//
//  PodsterIAPHelper.m
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import <StoreKit/StoreKit.h>
#import "PodsterIAPHelper.h"
#import "NSData+Base64.h"
#import "BlockAlertView.h"
static int ddLogLevel = LOG_LEVEL_INFO;
@implementation PodsterIAPHelper
{
    BOOL restoring;
    SKPaymentTransaction *lastTransaction;
}

+ (PodsterIAPHelper *)sharedInstance
{
    static PodsterIAPHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            NSSet *identifiers = [NSSet setWithObjects:
                                  @"net.vanterpool.podster.notifications",
                                  nil];
            instance = [[PodsterIAPHelper alloc] initWithProductIdentifiers:identifiers];
            instance->restoring = NO;
        }
    });

    return instance;
}

- (void)restoreTransactions
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    restoring = YES;
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    DDLogInfo(@"Finnished recieving restores");
    restoring = NO;
    if (lastTransaction!=nil) {
        [self recordTransaction:lastTransaction];
    }
}

-(void)provideContent:(NSString *)productIdentifier
{
    [super provideContent:productIdentifier];
    if ([productIdentifier isEqualToString:@"net.vanterpool.podster.notifications"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PremiumPurchased" object:nil];
    }

}


@end
