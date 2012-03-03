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
    [array addObject:@"Awww Shucks!"];
    [array addObject:@"So Sorry!"];
    [array addObject:@"Oh No!"];
    [array addObject:@"An Error Has Occured"];
    [array addObject:@"Ooops!"];
    
    return [array objectAtIndex:arc4random() % array.count];
}
@end
