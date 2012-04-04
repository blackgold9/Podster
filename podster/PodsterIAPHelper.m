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
    LOG_GENERAL(2, @"Finnished recieving restores");
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

//-(void)recordTransaction:(SKPaymentTransaction *)transaction
//{
//    LOG_GENERAL(2, @"Transaction DatE: %@", [[transaction transactionDate] description]);
//    if (restoring) {
//        if(transaction.originalTransaction.transactionState == SKPaymentTransactionStatePurchased) {
////            if (lastTransaction == nil ||
//  //              [lastTransaction.transactionDate compare:transaction.transactionDate] == NSOrderedAscending) {
//                lastTransaction = transaction;            
//    //        }                    
//        } else {
//            LOG_GENERAL(2, @"Original transaction was not  a puchase");
//        }
//
//    } else{
//
//
//        NSString *receipt = [transaction.transactionReceipt base64EncodedString];
//        [[SVPodcatcherClient sharedInstance] updateDeviceReceipt:receipt
//                                                    onCompletion:^(BOOL isPremium) {
//                                                        [[SVSettings sharedInstance] setPremiumMode:isPremium];
//                                                    } onError:^(NSError *error) {
//            LOG_GENERAL(0, @"Purchase failed with error: %@", error);
//            NSString *title = NSLocalizedString(@"PURCHASE_ERROR", nil);
//            NSString *body = NSLocalizedString(@"PURCHASE_VALIDATION_FAILED", nil);
//            BlockAlertView *alertView = [BlockAlertView alertWithTitle:title message:body];
//            [alertView setCancelButtonWithTitle:NSLocalizedString(@"OK", nil)   block:^{
//
//            }];
//            [alertView show];
//        }];
//    }
//}


@end
