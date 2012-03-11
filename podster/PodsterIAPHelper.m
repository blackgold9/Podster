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
                                  @"net.vanterpool.podster.premium3months",
                                  nil];
            instance = [[PodsterIAPHelper alloc] initWithProductIdentifiers:identifiers];
        }
    });

    return instance;
}
-(void)recordTransaction:(SKPaymentTransaction *)transaction
{
    NSString *receipt = [transaction.transactionReceipt base64EncodedString];
    [[SVPodcatcherClient sharedInstance] updateDeviceReceipt:receipt
                                                onCompletion:^(BOOL isPremium) {
                                                    [[SVSettings sharedInstance] setPremiumMode:isPremium]; 
                                                } onError:^(NSError *error) {
                                                    LOG_GENERAL(0, @"Purchase failed with error: %@", error);
                                                    NSString *title = NSLocalizedString(@"THANK_YOU_REALLY", nil);
                                                    NSString *body = NSLocalizedString(@"PURCHASE_COMPLETE_MESSAGE", nil);
                                                    BlockAlertView *alertView = [BlockAlertView alertWithTitle:title message:body];
                                                    [alertView setCancelButtonWithTitle:@"OK" block:^{
                                                        
                                                    }];
                                                    [alertView show];
                                                }];

}


@end
