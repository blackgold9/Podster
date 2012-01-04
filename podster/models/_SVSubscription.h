// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVSubscription.h instead.

#import <CoreData/CoreData.h>


extern const struct SVSubscriptionAttributes {
	__unsafe_unretained NSString *autoDownloadCount;
	__unsafe_unretained NSString *newestFirst;
} SVSubscriptionAttributes;

extern const struct SVSubscriptionRelationships {
	__unsafe_unretained NSString *podcast;
} SVSubscriptionRelationships;

extern const struct SVSubscriptionFetchedProperties {
} SVSubscriptionFetchedProperties;

@class SVPodcast;




@interface SVSubscriptionID : NSManagedObjectID {}
@end

@interface _SVSubscription : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SVSubscriptionID*)objectID;




@property (nonatomic, strong) NSNumber *autoDownloadCount;


@property int autoDownloadCountValue;
- (int)autoDownloadCountValue;
- (void)setAutoDownloadCountValue:(int)value_;

//- (BOOL)validateAutoDownloadCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *newestFirst;


@property BOOL newestFirstValue;
- (BOOL)newestFirstValue;
- (void)setNewestFirstValue:(BOOL)value_;

//- (BOOL)validateNewestFirst:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SVPodcast* podcast;

//- (BOOL)validatePodcast:(id*)value_ error:(NSError**)error_;




@end

@interface _SVSubscription (CoreDataGeneratedAccessors)

@end

@interface _SVSubscription (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveAutoDownloadCount;
- (void)setPrimitiveAutoDownloadCount:(NSNumber*)value;

- (int)primitiveAutoDownloadCountValue;
- (void)setPrimitiveAutoDownloadCountValue:(int)value_;




- (NSNumber*)primitiveNewestFirst;
- (void)setPrimitiveNewestFirst:(NSNumber*)value;

- (BOOL)primitiveNewestFirstValue;
- (void)setPrimitiveNewestFirstValue:(BOOL)value_;





- (SVPodcast*)primitivePodcast;
- (void)setPrimitivePodcast:(SVPodcast*)value;


@end
