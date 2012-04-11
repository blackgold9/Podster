//
//  NSString+MD5Addition.m
//  UIDeviceAddition
//
//  Created by Georg Kitz on 20.08.11.
//  Copyright 2011 Aurora Apps. All rights reserved.
//

#import "NSString+MD5Addition.h"
#import <CommonCrypto/CommonDigest.h>
#import "BWGlobal.h"
@implementation NSString(MD5Addition)
- (NSString *) stringFromMD5{
    return BWmd5(self);
}

@end
