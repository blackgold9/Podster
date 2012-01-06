//
//  ARCoreDataAction.m
//  Freshpod
//
//  Created by Saul Mora on 2/24/11.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

//#import "ARCoreDataAction.h"
#import "CoreData+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import <dispatch/dispatch.h>

dispatch_queue_t background_save_queue(void);
void cleanup_save_queue(void);

static dispatch_queue_t coredata_background_save_queue;

dispatch_queue_t background_save_queue()
{
    if (coredata_background_save_queue == NULL)
    {
        coredata_background_save_queue = dispatch_queue_create("com.magicalpanda.magicalrecord.backgroundsaves", 0);
    }
    return coredata_background_save_queue;
}

void cleanup_save_queue()
{
	if (coredata_background_save_queue != NULL)
	{
		dispatch_release(coredata_background_save_queue);
        coredata_background_save_queue = NULL;
	}
}

@implementation MRCoreDataAction

+ (void) cleanUp
{
	cleanup_save_queue();
}

#ifdef NS_BLOCKS_AVAILABLE

+ (void) saveDataWithBlock:(void (^)(NSManagedObjectContext *))block
              errorHandler:(void (^)(NSError *))errorHandler
        savesParentContext:(BOOL)shouldSaveParentContext
                  callback:(void (^)(void))callback
{
    NSManagedObjectContext *mainContext  = [NSManagedObjectContext MR_defaultContext];
    NSPersistentStoreCoordinator *defaultCoordinator = [NSPersistentStoreCoordinator MR_defaultStoreCoordinator];
    
    NSManagedObjectContext *localContext = nil;
    if (![NSThread isMainThread]) 
    {
        localContext = [mainContext MR_createChildContext];
        [localContext MR_observeiCloudChangesInCoordinator:defaultCoordinator];
        [mainContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        [localContext setMergePolicy:NSOverwriteMergePolicy];
    } else {
        localContext = mainContext;
    }
    
    block(localContext);
    
    if ([localContext hasChanges]) 
    {
        [localContext MR_saveWithErrorHandler:errorHandler];
        if (localContext.parentContext && shouldSaveParentContext) {
            [localContext.parentContext performBlockAndWait:^{
                [localContext.parentContext MR_saveWithErrorHandler:errorHandler];
            }];
        }
    }
    
    localContext.MR_notifiesMainContextOnSave = NO;
    [localContext MR_stopObservingiCloudChangesInCoordinator:defaultCoordinator];
    [mainContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    if (callback) 
    {
        dispatch_async(dispatch_get_main_queue(), callback);
    }
}

+ (void) saveDataWithBlock:(void (^)(NSManagedObjectContext *))block
      saveParentContext:(BOOL)shouldSaveParentContext
{
    [self saveDataWithBlock:block errorHandler:NULL savesParentContext:shouldSaveParentContext callback:nil];
}

+ (void) saveDataWithBlock:(void(^)(NSManagedObjectContext *localContext))block
{   
    [self saveDataWithBlock:block errorHandler:NULL savesParentContext:YES callback:nil];
}

+ (void) saveDataInBackgroundWithBlock:(void (^)(NSManagedObjectContext *))block
                  saveParentContext:(BOOL)shouldSaveParentContext
{
    dispatch_async(background_save_queue(), ^{
        [self saveDataWithBlock:block saveParentContext:shouldSaveParentContext];
    });
}

+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block
{
    [self saveDataInBackgroundWithBlock:block saveParentContext:YES];
}

+ (void) saveDataInBackgroundWithBlock:(void (^)(NSManagedObjectContext *))block
                            completion:(void (^)())callback
                   saveParentContext:(BOOL)shouldSaveParentContext
{
    dispatch_async(background_save_queue(), ^{
        [self saveDataWithBlock:block errorHandler:NULL savesParentContext:shouldSaveParentContext callback:callback];
        
       
    });
}

+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block
                            completion:(void(^)(void))callback
{
    [self saveDataInBackgroundWithBlock:block completion:callback saveParentContext:YES];
}

+ (void) lookupWithBlock:(void(^)(NSManagedObjectContext *localContext))block
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];

    if (block)
    {
        block(context);
    }
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *localContext))block;
{
    [self saveDataWithOptions:options withBlock:block completion:NULL];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(void(^)(void))callback;
{
    //TODO: add implementation    
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void (^)(NSManagedObjectContext *))block completion:(void (^)(void))callback errorHandler:(void(^)(NSError *))errorCallback
{
    
}

#endif

@end