// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVDownload.h instead.

#import <CoreData/CoreData.h>


extern const struct SVDownloadAttributes {
	__unsafe_unretained NSString *downloadedBytes;
	__unsafe_unretained NSString *manuallyTriggered;
	__unsafe_unretained NSString *position;
	__unsafe_unretained NSString *progress;
	__unsafe_unretained NSString *state;
	__unsafe_unretained NSString *totalBytes;
} SVDownloadAttributes;

extern const struct SVDownloadRelationships {
	__unsafe_unretained NSString *entry;
} SVDownloadRelationships;

extern const struct SVDownloadFetchedProperties {
} SVDownloadFetchedProperties;

@class SVPodcastEntry;








@interface SVDownloadID : NSManagedObjectID {}
@end

@interface _SVDownload : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SVDownloadID*)objectID;




@property (nonatomic, strong) NSNumber* downloadedBytes;


@property int32_t downloadedBytesValue;
- (int32_t)downloadedBytesValue;
- (void)setDownloadedBytesValue:(int32_t)value_;

//- (BOOL)validateDownloadedBytes:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* manuallyTriggered;


@property BOOL manuallyTriggeredValue;
- (BOOL)manuallyTriggeredValue;
- (void)setManuallyTriggeredValue:(BOOL)value_;

//- (BOOL)validateManuallyTriggered:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* position;


@property int32_t positionValue;
- (int32_t)positionValue;
- (void)setPositionValue:(int32_t)value_;

//- (BOOL)validatePosition:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* progress;


@property float progressValue;
- (float)progressValue;
- (void)setProgressValue:(float)value_;

//- (BOOL)validateProgress:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* state;


@property int16_t stateValue;
- (int16_t)stateValue;
- (void)setStateValue:(int16_t)value_;

//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* totalBytes;


@property int32_t totalBytesValue;
- (int32_t)totalBytesValue;
- (void)setTotalBytesValue:(int32_t)value_;

//- (BOOL)validateTotalBytes:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SVPodcastEntry* entry;

//- (BOOL)validateEntry:(id*)value_ error:(NSError**)error_;





@end

@interface _SVDownload (CoreDataGeneratedAccessors)

@end

@interface _SVDownload (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveDownloadedBytes;
- (void)setPrimitiveDownloadedBytes:(NSNumber*)value;

- (int32_t)primitiveDownloadedBytesValue;
- (void)setPrimitiveDownloadedBytesValue:(int32_t)value_;




- (NSNumber*)primitiveManuallyTriggered;
- (void)setPrimitiveManuallyTriggered:(NSNumber*)value;

- (BOOL)primitiveManuallyTriggeredValue;
- (void)setPrimitiveManuallyTriggeredValue:(BOOL)value_;




- (NSNumber*)primitivePosition;
- (void)setPrimitivePosition:(NSNumber*)value;

- (int32_t)primitivePositionValue;
- (void)setPrimitivePositionValue:(int32_t)value_;




- (NSNumber*)primitiveProgress;
- (void)setPrimitiveProgress:(NSNumber*)value;

- (float)primitiveProgressValue;
- (void)setPrimitiveProgressValue:(float)value_;




- (NSNumber*)primitiveState;
- (void)setPrimitiveState:(NSNumber*)value;

- (int16_t)primitiveStateValue;
- (void)setPrimitiveStateValue:(int16_t)value_;




- (NSNumber*)primitiveTotalBytes;
- (void)setPrimitiveTotalBytes:(NSNumber*)value;

- (int32_t)primitiveTotalBytesValue;
- (void)setPrimitiveTotalBytesValue:(int32_t)value_;





- (SVPodcastEntry*)primitiveEntry;
- (void)setPrimitiveEntry:(SVPodcastEntry*)value;


@end
