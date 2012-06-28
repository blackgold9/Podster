//
//  PodsterManagedDocument.m
//  podster
//
//  Created by Vanterpool, Stephen on 3/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "BlockAlertView.h"
#import "PodsterManagedDocument.h"
#import "NSManagedObject+MagicalRecord.h"
#define SharedFileName   @"PodsterData"
#define PrivateName     @"net.vanterpool.podster.data"
#import "CloudHelper.h"
static int ddLogLevel = LOG_LEVEL_INFO;
@implementation PodsterManagedDocument
{
    NSMutableArray *readyCallbacks;
}
+ (BOOL) isICloudEnabled;
{
    NSURL *cloudURL = [NSPersistentStore MR_cloudURLForUbiqutiousContainer:nil];
    return cloudURL != nil;
}


+ (PodsterManagedDocument *)sharedInstance
{
    static PodsterManagedDocument *doc = nil; 
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *docURL = [CloudHelper localFileURL:SharedFileName];

        doc = [[PodsterManagedDocument alloc] initWithFileURL:docURL];

        [doc loadDocument:^{
            [doc executeReadyCallbacks];
            
        }];
    });
    
    return doc;
    
}
+(NSManagedObjectContext *)defaultContext
{
    NSAssert([self sharedInstance].documentState == UIDocumentStateNormal, @"This should only be called after the document is opened");
    return [self sharedInstance].managedObjectContext;
}

+ (NSURL *)applicationDocumentsDirectory
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *url = [NSURL fileURLWithPath:path];
    return url;
}
-(id)initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    if (self) {
        readyCallbacks = [NSMutableArray array];
    }
    
    return self;
}
- (void)executeReadyCallbacks
{
    DDLogInfo(@"Document Ready. Executing Callback");
    dispatch_async(dispatch_get_main_queue(), ^{
        [readyCallbacks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ContextBlock callback = obj;
            callback();
        }];        
        [readyCallbacks removeAllObjects];
    });
//    [[NSNotificationCenter defaultCenter]addObserver:self
//                                            selector:@selector(documentContentsDidUpdate:)
//                                                name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
//                                              object:nil];
//    
    
}
//- (void) documentContentsDidUpdate: (NSNotification *) notification
//{
//    NSDictionary* userInfo = [notification userInfo];
//    [self.managedObjectContext performBlock:^{
//        [self mergeiCloudChanges:userInfo forContext:self.managedObjectContext];}];
//}

#pragma mark Courtesy of Apple. Thank you Apple
// Merge the iCloud changes into the managed context
//- (void)mergeiCloudChanges: (NSDictionary*)userInfo
//                forContext: (NSManagedObjectContext*)managedObjectContext
//{
//    @autoreleasepool
//    
//    {
//        NSMutableDictionary *localUserInfo =
//        [NSMutableDictionary dictionary];
//        
//        // Handle the invalidations
//        NSSet* allInvalidations =
//        [userInfo objectForKey:NSInvalidatedAllObjectsKey];
//        NSString* materializeKeys[] = { NSDeletedObjectsKey,
//            NSInsertedObjectsKey };
//        if (nil == allInvalidations)
//        {
//            int c = (sizeof(materializeKeys) / sizeof(NSString*));
//            for (int i = 0; i < c; i++)
//            {
//                NSSet* set = [userInfo objectForKey:materializeKeys[i]];
//                if ([set count] > 0)
//                {
//                    NSMutableSet* objectSet = [NSMutableSet set];
//                    for (NSManagedObjectID* moid in set)
//                        [objectSet addObject:[managedObjectContext
//                                              objectWithID:moid]];
//                    [localUserInfo setObject:objectSet
//                                      forKey:materializeKeys[i]];
//                }
//            }
//            // Handle the updated and refreshed Items
//            NSString* noMaterializeKeys[] = { NSUpdatedObjectsKey,
//                NSRefreshedObjectsKey, NSInvalidatedObjectsKey };
//            c = (sizeof(noMaterializeKeys) / sizeof(NSString*));
//            
//            for (int i = 0; i < 2; i++)
//            {
//                NSSet* set = [userInfo objectForKey:noMaterializeKeys[i]];
//                if ([set count] > 0)
//                {
//                    NSMutableSet* objectSet = [NSMutableSet set];
//                    for (NSManagedObjectID* moid in set)
//                    {
//                        NSManagedObject* realObj =
//                        [managedObjectContext
//                         objectRegisteredForID:moid];
//                        if (realObj)
//                            [objectSet addObject:realObj];
//                    }
//                    [localUserInfo setObject:objectSet
//                                      forKey:noMaterializeKeys[i]];
//                }
//            }
//            // Fake a save to merge the changes
//            NSNotification *fakeSave = [NSNotification
//                                        notificationWithName:
//                                        NSManagedObjectContextDidSaveNotification
//                                        object:self userInfo:localUserInfo];
//            [managedObjectContext
//             mergeChangesFromContextDidSaveNotification:fakeSave];
//        }
//        else
//            [localUserInfo setObject:allInvalidations
//                              forKey:NSInvalidatedAllObjectsKey];
//        
//        [managedObjectContext processPendingChanges];
//        [self performSelectorOnMainThread:@selector(performFetch)
//                               withObject:nil waitUntilDone:NO];
//    }
//}
- (void)performWhenReady:(ContextBlock)ready
{
    if(self.documentState == UIDocumentStateNormal) {
        ready();
    } else {
        [readyCallbacks addObject:[ready copy]];
    }
}
- (void)loadDocument:(void (^)())opened
{
    NSURL *docURL = [CloudHelper localFileURL:SharedFileName];
   

    // Set the persistent store options to point to the cloud
    NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           
                             [NSNumber numberWithBool:YES],
                             NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES],
                             NSInferMappingModelAutomaticallyOption,
                             nil];
    // Icloud Initialization
//     NSURL *cloudURL = [CloudHelper ubiquityDataFileURL:PrivateName];
//    if (cloudURL) {
//        [options setValue:PrivateName forKey:NSPersistentStoreUbiquitousContentNameKey ];
//        [options setValue:cloudURL forKey:NSPersistentStoreUbiquitousContentURLKey];
//    }

   
    self.persistentStoreOptions = options;
    
    
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[docURL path]]) {
        [self openWithCompletionHandler:^(BOOL success){
            if (!success) {
                // Handle the error.
                [FlurryAnalytics logEvent:@"ERRORCouldNotOpenDataStore"];
            } else {               
                    
                        LOG_GENERAL(2, @"UIMAnagedDocument loaded.");
                            
                        if(opened){
                            opened();
                        }
                    
            }
        }];
    }
    else {
        [self saveToURL:docURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            if (!success) {
                // Handle the error.
                [FlurryAnalytics logEvent:@"ERRORCouldNotCreateDataStore"];
            } else {
               
                    LOG_GENERAL(2, @"UIMAnagedDocument loaded.");
                    [NSManagedObjectContext MR_setDefaultContext:self.managedObjectContext];
                    if(opened){
                        opened();
                    }
               
            }            
        }];
    }
}
-(void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    LOG_GENERAL(0, @"Error opening document %@", error);
    [super handleError:error userInteractionPermitted:userInteractionPermitted];
    
}
- (void)save:(void(^)(BOOL))done
{
    [self saveToURL:self.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:done];
}
@end
