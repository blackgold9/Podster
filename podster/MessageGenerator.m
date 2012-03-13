//
//  MessageGenerator.m
//  podster
//
//  Created by Vanterpool, Stephen on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageGenerator.h"

@implementation MessageGenerator
+(NSString *)randomErrorAlertTitle
{
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:NSLocalizedString(@"ERROR_TITLE_ONE", @"Awww Shucks!")];
    [array addObject:NSLocalizedString(@"ERROR_TITLE_TWO", @"So Sorry!")];
    [array addObject:NSLocalizedString(@"ERROR_TITLE_THREE", @"Oh No!")];
    [array addObject:NSLocalizedString(@"ERROR_TITLE_FOUR", @"An Error Has Occured")];
    [array addObject:NSLocalizedString(@"ERROR_TITLE_FIVE", @"Ooops!")];
    
    return [array objectAtIndex:arc4random() % array.count];
}
@end
