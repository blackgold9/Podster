//
//  NSDate+Rails.m
//  podster
//
//  Created by Stephen J Vanterpool on 9/10/12.
//
//

#import "NSDate+Rails.h"

@implementation NSDate (Rails)

+ (NSDate *)dateWithISO8601String:(NSString *)dateString
{
    if (!dateString) return nil;
    if ([dateString hasSuffix:@"Z"]) {
        dateString = [[dateString substringToIndex:(dateString.length-1)] stringByAppendingString:@"-0000"];
    }
    return [self dateFromString:dateString
                     withFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
}

+ (NSDate *)dateFromString:(NSString *)dateString
                withFormat:(NSString *)dateFormat
{
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:dateFormat];
        
        NSLocale *locale = [[NSLocale alloc]
                            initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:locale];
    });
    
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}
@end
