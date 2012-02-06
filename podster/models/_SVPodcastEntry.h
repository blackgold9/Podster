// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcastEntry.h instead.

#import <CoreData/CoreData.h>


extern const struct SVPodcastEntryAttributes {
	__unsafe_unretained NSString *content;
	__unsafe_unretained NSString *datePublished;
	__unsafe_unretained NSString *downloadComplete;
	__unsafe_unretained NSString *duration;
	__unsafe_unretained NSString *guid;
	__unsafe_unretained NSString *imageURL;
	__unsafe_unretained NSString *isVideo;
	__unsafe_unretained NSString *markedForDownload;
	__unsafe_unretained NSString *mediaURL;
	__unsafe_unretained NSString *played;
	__unsafe_unretained NSString *positionInSeconds;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *totalBytes;
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




@property (nonatomic, strong) NSString *content;


//- (BOOL)validateContent:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate *datePublished;


//- (BOOL)validateDatePublished:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *downloadComplete;


@property BOOL downloadCompleteValue;
- (BOOL)downloadCompleteValue;
- (void)setDownloadCompleteValue:(BOOL)value_;

//- (BOOL)validateDownloadComplete:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *duration;


@property int durationValue;
- (int)durationValue;
- (void)setDurationValue:(int)value_;

//- (BOOL)validateDuration:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *guid;


//- (BOOL)validateGuid:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *imageURL;


//- (BOOL)validateImageURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *isVideo;


@property BOOL isVideoValue;
- (BOOL)isVideoValue;
- (void)setIsVideoValue:(BOOL)value_;

//- (BOOL)validateIsVideo:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *markedForDownload;


@property BOOL markedForDownloadValue;
- (BOOL)markedForDownloadValue;
- (void)setMarkedForDownloadValue:(BOOL)value_;

//- (BOOL)validateMarkedForDownload:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *mediaURL;


//- (BOOL)validateMediaURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *played;


@property BOOL playedValue;
- (BOOL)playedValue;
- (void)setPlayedValue:(BOOL)value_;

//- (BOOL)validatePlayed:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *positionInSeconds;


@property int positionInSecondsValue;
- (int)positionInSecondsValue;
- (void)setPositionInSecondsValue:(int)value_;

//- (BOOL)validatePositionInSeconds:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *totalBytes;


@property int totalBytesValue;
- (int)totalBytesValue;
- (void)setTotalBytesValue:(int)value_;

//- (BOOL)validateTotalBytes:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SVDownload* download;

//- (BOOL)validateDownload:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) SVPodcast* podcast;

//- (BOOL)validatePodcast:(id*)value_ error:(NSError**)error_;




@end

@interface _SVPodcastEntry (CoreDataGeneratedAccessors)

@end

@interface _SVPodcastEntry (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveContent;
- (void)setPrimitiveContent:(NSString*)value;




- (NSDate*)primitiveDatePublished;
- (void)setPrimitiveDatePublished:(NSDate*)value;




- (NSNumber*)primitiveDownloadComplete;
- (void)setPrimitiveDownloadComplete:(NSNumber*)value;

- (BOOL)primitiveDownloadCompleteValue;
- (void)setPrimitiveDownloadCompleteValue:(BOOL)value_;




- (NSNumber*)primitiveDuration;
- (void)setPrimitiveDuration:(NSNumber*)value;

- (int)primitiveDurationValue;
- (void)setPrimitiveDurationValue:(int)value_;




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




- (NSNumber*)primitivePositionInSeconds;
- (void)setPrimitivePositionInSeconds:(NSNumber*)value;

- (int)primitivePositionInSecondsValue;
- (void)setPrimitivePositionInSecondsValue:(int)value_;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSNumber*)primitiveTotalBytes;
- (void)setPrimitiveTotalBytes:(NSNumber*)value;

- (int)primitiveTotalBytesValue;
- (void)setPrimitiveTotalBytesValue:(int)value_;





- (SVDownload*)primitiveDownload;
- (void)setPrimitiveDownload:(SVDownload*)value;



- (SVPodcast*)primitivePodcast;
- (void)setPrimitivePodcast:(SVPodcast*)value;


@end
