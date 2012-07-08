//
//  PodsterManagedDocument.h
//  podster
//
//  Created by Vanterpool, Stephen on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^ContextBlock)();
@interface PodsterManagedDocument : UIManagedDocument
+ (PodsterManagedDocument *)sharedInstance;
+(NSManagedObjectContext *)defaultContext;

+ (NSManagedObjectContext *)backgroundContext;

// When your callback is called the default context has been set;
- (void)performWhenReady:(ContextBlock)ready;
- (void)save:(void(^)(BOOL))done;
@end
