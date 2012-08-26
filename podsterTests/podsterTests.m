//
//  PodsterTests.m
//  PodsterTests
//
//  Created by Stephen J Vanterpool on 8/25/12.
//
//

#import "PodsterTests.h"
#import "MagicalRecord.h"
#import "SVPodcast.h"
#import "podster-Prefix.pch"
@implementation PodsterTests
- (void) setUpClass
{
    NSBundle * bundle = [NSBundle bundleForClass:[self class]];
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];
   // [NSManagedObjectModel MR_setDefaultManagedObjectModel:[NSManagedObjectModel MR_managedObjectModelNamed:@"SVPodcastDatastore.momd"]];
    [NSManagedObjectModel MR_setDefaultManagedObjectModel:managedObjectModel];
}

- (void) setUp
{
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void) tearDown
{
    [MagicalRecord cleanUp];
}

-(BOOL)shouldRunOnMainThread
{
    return YES;
}

- (void)testNestedProblem
{
    __block SVPodcast *podcast;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    NSManagedObjectContext *mainContext = [NSManagedObjectContext MR_rootSavingContext];
    NSManagedObjectContext *otherContext = [NSManagedObjectContext MR_contextWithParent:mainContext];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextWillSaveNotification
                                                      object:otherContext
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [otherContext obtainPermanentIDsForObjects:[[otherContext insertedObjects] allObjects] error:nil];
                                                  }];

    [otherContext performBlock:^{
        podcast = [SVPodcast MR_createInContext:otherContext];
        podcast.feedURL = @"";
        podcast.title = @"";
        podcast.podstoreIdValue = 12;
        [otherContext save:nil];
        
        [mainContext performBlock:^{
            SVPodcast *localPodcast = [podcast MR_inContext:mainContext];
            STAssertFalse([localPodcast.objectID isTemporaryID],nil);

            mainContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
            otherContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
         
            [mainContext save:nil];
            STAssertFalse([localPodcast.objectID isTemporaryID],nil);
            [otherContext performBlock:^{
                [otherContext refreshObject:podcast mergeChanges:NO];
                STAssertFalse([podcast.objectID isTemporaryID], nil);
                dispatch_group_leave(group);
                
            }];
        }];
        
    }];
 
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}
@end
