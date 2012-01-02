//
//  podsterTests.m
//  podsterTests
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "podsterTests.h"
#import "SVPlaybackController.h"
@implementation podsterTests
- (NSInteger)secondsFromHours:(NSInteger)hours minutes:(NSInteger)minutes andSeconds:(NSInteger)seconds
{
    NSInteger total = 0;
total += hours * 60 * 60;
total += minutes * 60;
total += seconds;
return total;
}
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}


-(void)testCorrectlyFormatsSecondsAsString
{
    // Check 1 second
    NSInteger numberOfSeconds = [self secondsFromHours:0 minutes:0 andSeconds:1];
    NSString *stringEquivalent = [SVPlaybackController formattedStringRepresentationOfSeconds:numberOfSeconds];
    STAssertTrue([stringEquivalent isEqualToString:@"00:01"], @"Expected \"00:01\", Got: \"%@\"", stringEquivalent);
    numberOfSeconds = [self secondsFromHours:0 minutes:12 andSeconds:13];
    stringEquivalent = [SVPlaybackController formattedStringRepresentationOfSeconds:numberOfSeconds];
    STAssertTrue([stringEquivalent isEqualToString:@"12:13"], @"Expected \"12:13\", Got: \"%@\"", stringEquivalent);
    
    numberOfSeconds = [self secondsFromHours:1 minutes:12 andSeconds:13];
    stringEquivalent = [SVPlaybackController formattedStringRepresentationOfSeconds:numberOfSeconds];
    STAssertTrue([stringEquivalent isEqualToString:@"1:12:13"], @"Expected \"1:12:13\", Got: \"%@\"", stringEquivalent);
}

@end
