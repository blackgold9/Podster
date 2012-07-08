//
// Created by j-stevan@interactive.msnbc.com on 7/5/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
@class PodcastUpdateOperation;
typedef void (^UpdateCompleteBlock)(PodcastUpdateOperation *);

@interface PodcastUpdateOperation : NSOperation
@property (nonatomic, strong) NSNumber *podcastId;
@property (nonatomic, copy) UpdateCompleteBlock onUpdateComplete;


- (id)initWithPodcastId:(NSNumber *)podcastId andContext:(NSManagedObjectContext *)theContext;
- (BOOL)completedSuccessfully;
@end