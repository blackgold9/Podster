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
@property (nonatomic, strong) SVPodcast *podcast;
@property (nonatomic, copy) UpdateCompleteBlock onUpdateComplete;


- (id)initWithPodcast:(SVPodcast *)podcast andContext:(NSManagedObjectContext *)theContext;
- (BOOL)completedSuccessfully;
@end