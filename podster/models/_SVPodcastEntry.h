// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcastEntry.h instead.

#import <CoreData/CoreData.h>


extern const struct SVPodcastEntryAttributes {
	__unsafe_unretained NSString *contentLength;
	__unsafe_unretained NSString *datePublished;
	__unsafe_unretained NSString *downloadComplete;
	__unsafe_unretained NSString *duration;
	__unsafe_unretained NSString *guid;
	__unsafe_unretained NSString *imageURL;
	__unsafe_unretained NSString *isVideo;
	__unsafe_unretained NSString *markedForDownload;
	__unsafe_unretained NSString *mediaURL;
	__unsafe_unretained NSString *played;
	__unsafe_unretained NSString *podstoreId;
	__unsafe_unretained NSString *positionInSeconds;
	__unsafe_unretained NSString *rawSummary;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *totalBytes;
	__unsafe_unretained NSString *webURL;
} SVPodcastEntryAttributes;

extern const struct SVPodcastEntryRelationships {
	__unsafe_unretained NSString *download;
	__unsafe_unretained NSString *podcast;
} SVPodcastEntryRelationships;

extern const struct SVPodcastEntryFetchedProperties {
} SVPodcastEntryFetchedProperties;

@class SVDownload;
@class SVPodcast;



















@interface SVPodcastEntryID : NSManagedObjectID {}
@end

@interface _SVPodcastEntry : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SVPodcastEntryID*)objectID;




@property (nonatomic, strong) NSNumber* contentLength;


@property int32_t contentLengthValue;
- (int32_t)contentLengthValue;
- (void)setContentLengthValue:(int32_t)value_;

//- (BOOL)validateContentLength:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* datePublished;


//- (BOOL)validateDatePublished:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* downloadComplete;


@property BOOL downloadCompleteValue;
- (BOOL)downloadCompleteValue;
- (void)setDownloadCompleteValue:(BOOL)value_;

//- (BOOL)validateDownloadComplete:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* duration;


@property int32_t durationValue;
- (int32_t)durationValue;
- (void)setDurationValue:(int32_t)value_;

//- (BOOL)validateDuration:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* guid;


//- (BOOL)validateGuid:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* imageURL;


//- (BOOL)validateImageURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* isVideo;


@property BOOL isVideoValue;
- (BOOL)isVideoValue;
- (void)setIsVideoValue:(BOOL)value_;

//- (BOOL)validateIsVideo:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* markedForDownload;


@property BOOL markedForDownloadValue;
- (BOOL)markedForDownloadValue;
- (void)setMarkedForDownloadValue:(BOOL)value_;

//- (BOOL)validateMarkedForDownload:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* mediaURL;


//- (BOOL)validateMediaURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* played;


@property BOOL playedValue;
- (BOOL)playedValue;
- (void)setPlayedValue:(BOOL)value_;

//- (BOOL)validatePlayed:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* podstoreId;


@property int32_t podstoreIdValue;
- (int32_t)podstoreIdValue;
- (void)setPodstoreIdValue:(int32_t)value_;

//- (BOOL)validatePodstoreId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* positionInSeconds;


@property int32_t positionInSecondsValue;
- (int32_t)positionInSecondsValue;
- (void)setPositionInSecondsValue:(int32_t)value_;

//- (BOOL)validatePositionInSeconds:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* rawSummary;


//- (BOOL)validateRawSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* totalBytes;


@property int32_t totalBytesValue;
- (int32_t)totalBytesValue;
- (void)setTotalBytesValue:(int32_t)value_;

//- (BOOL)validateTotalBytes:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* webURL;


//- (BOOL)validateWebURL:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SVDownload* download;

//- (BOOL)validateDownload:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) SVPodcast* podcast;

//- (BOOL)validatePodcast:(id*)value_ error:(NSError**)error_;





@end

@interface _SVPodcastEntry (CoreDataGeneratedAccessors)

@end

@interface _SVPodcastEntry (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveContentLength;
- (void)setPrimitiveContentLength:(NSNumber*)value;

- (int32_t)primitiveContentLengthValue;
- (void)setPrimitiveContentLengthValue:(int32_t)value_;




- (NSDate*)primitiveDatePublished;
- (void)setPrimitiveDatePublished:(NSDate*)value;




- (NSNumber*)primitiveDownloadComplete;
- (void)setPrimitiveDownloadComplete:(NSNumber*)value;

- (BOOL)primitiveDownloadCompleteValue;
- (void)setPrimitiveDownloadCompleteValue:(BOOL)value_;




- (NSNumber*)primitiveDuration;
- (void)setPrimitiveDuration:(NSNumber*)value;

- (int32_t)primitiveDurationValue;
- (void)setPrimitiveDurationValue:(int32_t)value_;




- (NSString*)primitiveGuid;
- (void)setPrimitiveGuid:(NSString*)value;




- (NSString*)primitiveImageURL;
- (void)setPrimitiveImageURL:(NSString*)value;




- (NSNumber*)primitiveIsVideo;
- (void)setPrimitiveIsVideo:(NSNumber*)value;

- (BOOL)primitiveIsVideoValue;
- (void)setPrimitiveIsVideoValue:(BOOL)value_;




- (NSNumber*)primitiveMarkedForDownload;
- (void)setPrimitiveMarkedForDownload:(NSNumber*)value;

- (BOOL)primitiveMarkedForDownloadValue;
- (void)setPrimitiveMarkedForDownloadValue:(BOOL)value_;




- (NSString*)primitiveMediaURL;
- (void)setPrimitiveMediaURL:(NSString*)value;




- (NSNumber*)primitivePlayed;
- (void)setPrimitivePlayed:(NSNumber*)value;

- (BOOL)primitivePlayedValue;
- (void)setPrimitivePlayedValue:(BOOL)value_;




- (NSNumber*)primitivePodstoreId;
- (void)setPrimitivePodstoreId:(NSNumber*)value;

- (int32_t)primitivePodstoreIdValue;
- (void)setPrimitivePodstoreIdValue:(int32_t)value_;




- (NSNumber*)primitivePositionInSeconds;
- (void)setPrimitivePositionInSeconds:(NSNumber*)value;

- (int32_t)primitivePositionInSecondsValue;
- (void)setPrimitivePositionInSecondsValue:(int32_t)value_;




- (NSString*)primitiveRawSummary;
- (void)setPrimitiveRawSummary:(NSString*)value;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSNumber*)primitiveTotalBytes;
- (void)setPrimitiveTotalBytes:(NSNumber*)value;

- (int32_t)primitiveTotalBytesValue;
- (void)setPrimitiveTotalBytesValue:(int32_t)value_;




- (NSString*)primitiveWebURL;
- (void)setPrimitiveWebURL:(NSString*)value;





- (SVDownload*)primitiveDownload;
- (void)setPrimitiveDownload:(SVDownload*)value;



- (SVPodcast*)primitivePodcast;
- (void)setPrimitivePodcast:(SVPodcast*)value;


@end
