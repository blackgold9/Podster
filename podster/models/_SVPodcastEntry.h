// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcastEntry.h instead.

#import <CoreData/CoreData.h>


extern const struct SVPodcastEntryAttributes {
	__unsafe_unretained NSString *downloadComplete;
	__unsafe_unretained NSString *guid;
	__unsafe_unretained NSString *imageURL;
	__unsafe_unretained NSString *isVideo;
	__unsafe_unretained NSString *markedForDownload;
	__unsafe_unretained NSString *mediaURL;
	__unsafe_unretained NSString *positionInSeconds;
	__unsafe_unretained NSString *sanitizedSummary;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *totalBytes;
} SVPodcastEntryAttributes;

extern const struct SVPodcastEntryRelationships {
	__unsafe_unretained NSString *podcast;
} SVPodcastEntryRelationships;

extern const struct SVPodcastEntryFetchedProperties {
} SVPodcastEntryFetchedProperties;

@class SVPodcast;













@interface SVPodcastEntryID : NSManagedObjectID {}
@end

@interface _SVPodcastEntry : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SVPodcastEntryID*)objectID;




@property (nonatomic, strong) NSNumber *downloadComplete;


@property BOOL downloadCompleteValue;
- (BOOL)downloadCompleteValue;
- (void)setDownloadCompleteValue:(BOOL)value_;

//- (BOOL)validateDownloadComplete:(id*)value_ error:(NSError**)error_;




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




@property (nonatomic, strong) NSNumber *positionInSeconds;


@property int positionInSecondsValue;
- (int)positionInSecondsValue;
- (void)setPositionInSecondsValue:(int)value_;

//- (BOOL)validatePositionInSeconds:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *sanitizedSummary;


//- (BOOL)validateSanitizedSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *totalBytes;


@property int totalBytesValue;
- (int)totalBytesValue;
- (void)setTotalBytesValue:(int)value_;

//- (BOOL)validateTotalBytes:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SVPodcast* podcast;

//- (BOOL)validatePodcast:(id*)value_ error:(NSError**)error_;




@end

@interface _SVPodcastEntry (CoreDataGeneratedAccessors)

@end

@interface _SVPodcastEntry (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveDownloadComplete;
- (void)setPrimitiveDownloadComplete:(NSNumber*)value;

- (BOOL)primitiveDownloadCompleteValue;
- (void)setPrimitiveDownloadCompleteValue:(BOOL)value_;




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




- (NSNumber*)primitivePositionInSeconds;
- (void)setPrimitivePositionInSeconds:(NSNumber*)value;

- (int)primitivePositionInSecondsValue;
- (void)setPrimitivePositionInSecondsValue:(int)value_;




- (NSString*)primitiveSanitizedSummary;
- (void)setPrimitiveSanitizedSummary:(NSString*)value;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSNumber*)primitiveTotalBytes;
- (void)setPrimitiveTotalBytes:(NSNumber*)value;

- (int)primitiveTotalBytesValue;
- (void)setPrimitiveTotalBytesValue:(int)value_;





- (SVPodcast*)primitivePodcast;
- (void)setPrimitivePodcast:(SVPodcast*)value;


@end
