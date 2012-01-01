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
    NSInteger numberOfSeconds = 1;
    NSString *stringEquivalent = [SVPlaybackController formattedStringRepresentationOfSeconds:numberOfSeconds];
    STAssertTrue([stringEquivalent isEqualToString:@"0:00:01"], @"Expected 0:00:01, Got: %@", stringEquivalent);
}

@end
