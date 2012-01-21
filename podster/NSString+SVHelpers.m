//
//  NSString+SVHelpers.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+SVHelpers.h"

@implementation NSString (SVHelpers)
+(NSString *)formattedStringRepresentationOfSeconds:(NSInteger)totalSeconds
{
    if (totalSeconds == 0) {
        return @"Unavailble";
    }
    NSInteger hourInSeconds = 3600;
    NSInteger hours = totalSeconds / hourInSeconds;
    NSInteger minutes = (totalSeconds % hourInSeconds) / 60;
    NSInteger seconds = totalSeconds % 60;
    if( hours > 0 ) {
        return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes,seconds];
    } else {
        return [NSString stringWithFormat:@"%02d:%02d", minutes,seconds];
        
    }
}
-(NSInteger)secondsFromDurationString
{
    NSInteger output = 0;
    NSArray *components = [[[self componentsSeparatedByString:@":"] reverseObjectEnumerator] allObjects];
    output = [[components objectAtIndex:0] integerValue];
    if (components.count > 1) {
        output += [[components objectAtIndex:1] integerValue] * 60;
    }
    if (components.count >2) {
        output += [[components objectAtIndex:2] integerValue] * 3600;
    }
    return output;
    
}
@end
