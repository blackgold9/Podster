// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVDownload.h instead.

#import <CoreData/CoreData.h>


extern const struct SVDownloadAttributes {
	__unsafe_unretained NSString *downloadedBytes;
	__unsafe_unretained NSString *filePath;
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




@property (nonatomic, strong) NSNumber *downloadedBytes;


@property int downloadedBytesValue;
- (int)downloadedBytesValue;
- (void)setDownloadedBytesValue:(int)value_;

//- (BOOL)validateDownloadedBytes:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *filePath;


//- (BOOL)validateFilePath:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *manuallyTriggered;


@property BOOL manuallyTriggeredValue;
- (BOOL)manuallyTriggeredValue;
- (void)setManuallyTriggeredValue:(BOOL)value_;

//- (BOOL)validateManuallyTriggered:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *position;


@property int positionValue;
- (int)positionValue;
- (void)setPositionValue:(int)value_;

//- (BOOL)validatePosition:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *progress;


@property float progressValue;
- (float)progressValue;
- (void)setProgressValue:(float)value_;

//- (BOOL)validateProgress:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *state;


@property short stateValue;
- (short)stateValue;
- (void)setStateValue:(short)value_;

//- (BOOL)validateState:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *totalBytes;


@property int totalBytesValue;
- (int)totalBytesValue;
- (void)setTotalBytesValue:(int)value_;

//- (BOOL)validateTotalBytes:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SVPodcastEntry* entry;

//- (BOOL)validateEntry:(id*)value_ error:(NSError**)error_;




@end

@interface _SVDownload (CoreDataGeneratedAccessors)

@end

@interface _SVDownload (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveDownloadedBytes;
- (void)setPrimitiveDownloadedBytes:(NSNumber*)value;

- (int)primitiveDownloadedBytesValue;
- (void)setPrimitiveDownloadedBytesValue:(int)value_;




- (NSString*)primitiveFilePath;
- (void)setPrimitiveFilePath:(NSString*)value;




- (NSNumber*)primitiveManuallyTriggered;
- (void)setPrimitiveManuallyTriggered:(NSNumber*)value;

- (BOOL)primitiveManuallyTriggeredValue;
- (void)setPrimitiveManuallyTriggeredValue:(BOOL)value_;




- (NSNumber*)primitivePosition;
- (void)setPrimitivePosition:(NSNumber*)value;

- (int)primitivePositionValue;
- (void)setPrimitivePositionValue:(int)value_;




- (NSNumber*)primitiveProgress;
- (void)setPrimitiveProgress:(NSNumber*)value;

- (float)primitiveProgressValue;
- (void)setPrimitiveProgressValue:(float)value_;




- (NSNumber*)primitiveState;
- (void)setPrimitiveState:(NSNumber*)value;

- (short)primitiveStateValue;
- (void)setPrimitiveStateValue:(short)value_;




- (NSNumber*)primitiveTotalBytes;
- (void)setPrimitiveTotalBytes:(NSNumber*)value;

- (int)primitiveTotalBytesValue;
- (void)setPrimitiveTotalBytesValue:(int)value_;





- (SVPodcastEntry*)primitiveEntry;
- (void)setPrimitiveEntry:(SVPodcastEntry*)value;


@end
