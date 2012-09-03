//
// Created by j-stevan@interactive.msnbc.com on 7/5/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
@class SVPodcast;
@class PodcastUpdateOperation;
typedef void (^UpdateCompleteBlock)(PodcastUpdateOperation *);

@interface PodcastUpdateOperation : NSOperation
@property (nonatomic, copy) UpdateCompleteBlock onUpdateComplete;

@property NSNumber *podstoreId;
- (id)initWithPodcast:(SVPodcast *)podcast andContext:(NSManagedObjectContext *)theContext;
- (BOOL)completedSuccessfully;
@end