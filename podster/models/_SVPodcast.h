// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcast.h instead.

#import <CoreData/CoreData.h>


extern const struct SVPodcastAttributes {
	__unsafe_unretained NSString *author;
	__unsafe_unretained NSString *cachingLastModified;
	__unsafe_unretained NSString *downloadCount;
	__unsafe_unretained NSString *downloadPercentage;
	__unsafe_unretained NSString *downloadsToKeep;
	__unsafe_unretained NSString *etag;
	__unsafe_unretained NSString *feedURL;
	__unsafe_unretained NSString *fullIsizeImageData;
	__unsafe_unretained NSString *gridSizeImageData;
	__unsafe_unretained NSString *hidePlayedEpisodes;
	__unsafe_unretained NSString *isDownloading;
	__unsafe_unretained NSString *isSubscribed;
	__unsafe_unretained NSString *isVideo;
	__unsafe_unretained NSString *lastSynced;
	__unsafe_unretained NSString *lastUpdated;
	__unsafe_unretained NSString *listSizeImageData;
	__unsafe_unretained NSString *logoURL;
	__unsafe_unretained NSString *nextItemDate;
	__unsafe_unretained NSString *podstoreId;
	__unsafe_unretained NSString *shouldNotify;
	__unsafe_unretained NSString *smallLogoURL;
	__unsafe_unretained NSString *sortNewestFirst;
	__unsafe_unretained NSString *subscribedDate;
	__unsafe_unretained NSString *subtitle;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *thumbLogoURL;
	__unsafe_unretained NSString *tinyLogoURL;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *unlistenedSinceSubscribedCount;
	__unsafe_unretained NSString *updating;
	__unsafe_unretained NSString *urlHash;
	__unsafe_unretained NSString *websiteURL;
} SVPodcastAttributes;

extern const struct SVPodcastRelationships {
	__unsafe_unretained NSString *items;
} SVPodcastRelationships;

extern const struct SVPodcastFetchedProperties {
} SVPodcastFetchedProperties;

@class SVPodcastEntry;


































@interface SVPodcastID : NSManagedObjectID {}
@end

@interface _SVPodcast : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SVPodcastID*)objectID;




@property (nonatomic, strong) NSString* author;


//- (BOOL)validateAuthor:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* cachingLastModified;


//- (BOOL)validateCachingLastModified:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* downloadCount;


@property int32_t downloadCountValue;
- (int32_t)downloadCountValue;
- (void)setDownloadCountValue:(int32_t)value_;

//- (BOOL)validateDownloadCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* downloadPercentage;


@property float downloadPercentageValue;
- (float)downloadPercentageValue;
- (void)setDownloadPercentageValue:(float)value_;

//- (BOOL)validateDownloadPercentage:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* downloadsToKeep;


@property int32_t downloadsToKeepValue;
- (int32_t)downloadsToKeepValue;
- (void)setDownloadsToKeepValue:(int32_t)value_;

//- (BOOL)validateDownloadsToKeep:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* etag;


//- (BOOL)validateEtag:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* feedURL;


//- (BOOL)validateFeedURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSData* fullIsizeImageData;


//- (BOOL)validateFullIsizeImageData:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSData* gridSizeImageData;


//- (BOOL)validateGridSizeImageData:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* hidePlayedEpisodes;


@property BOOL hidePlayedEpisodesValue;
- (BOOL)hidePlayedEpisodesValue;
- (void)setHidePlayedEpisodesValue:(BOOL)value_;

//- (BOOL)validateHidePlayedEpisodes:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* isDownloading;


@property BOOL isDownloadingValue;
- (BOOL)isDownloadingValue;
- (void)setIsDownloadingValue:(BOOL)value_;

//- (BOOL)validateIsDownloading:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* isSubscribed;


@property BOOL isSubscribedValue;
- (BOOL)isSubscribedValue;
- (void)setIsSubscribedValue:(BOOL)value_;

//- (BOOL)validateIsSubscribed:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* isVideo;


@property BOOL isVideoValue;
- (BOOL)isVideoValue;
- (void)setIsVideoValue:(BOOL)value_;

//- (BOOL)validateIsVideo:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* lastSynced;


//- (BOOL)validateLastSynced:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* lastUpdated;


//- (BOOL)validateLastUpdated:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSData* listSizeImageData;


//- (BOOL)validateListSizeImageData:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* logoURL;


//- (BOOL)validateLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* nextItemDate;


//- (BOOL)validateNextItemDate:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* podstoreId;


@property int32_t podstoreIdValue;
- (int32_t)podstoreIdValue;
- (void)setPodstoreIdValue:(int32_t)value_;

//- (BOOL)validatePodstoreId:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* shouldNotify;


@property BOOL shouldNotifyValue;
- (BOOL)shouldNotifyValue;
- (void)setShouldNotifyValue:(BOOL)value_;

//- (BOOL)validateShouldNotify:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* smallLogoURL;


//- (BOOL)validateSmallLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* sortNewestFirst;


@property BOOL sortNewestFirstValue;
- (BOOL)sortNewestFirstValue;
- (void)setSortNewestFirstValue:(BOOL)value_;

//- (BOOL)validateSortNewestFirst:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate* subscribedDate;


//- (BOOL)validateSubscribedDate:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* subtitle;


//- (BOOL)validateSubtitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* thumbLogoURL;


//- (BOOL)validateThumbLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* tinyLogoURL;


//- (BOOL)validateTinyLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* unlistenedSinceSubscribedCount;


@property int32_t unlistenedSinceSubscribedCountValue;
- (int32_t)unlistenedSinceSubscribedCountValue;
- (void)setUnlistenedSinceSubscribedCountValue:(int32_t)value_;

//- (BOOL)validateUnlistenedSinceSubscribedCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* updating;


@property BOOL updatingValue;
- (BOOL)updatingValue;
- (void)setUpdatingValue:(BOOL)value_;

//- (BOOL)validateUpdating:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* urlHash;


//- (BOOL)validateUrlHash:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* websiteURL;


//- (BOOL)validateWebsiteURL:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* items;

- (NSMutableSet*)itemsSet;





@end

@interface _SVPodcast (CoreDataGeneratedAccessors)

- (void)addItems:(NSSet*)value_;
- (void)removeItems:(NSSet*)value_;
- (void)addItemsObject:(SVPodcastEntry*)value_;
- (void)removeItemsObject:(SVPodcastEntry*)value_;

@end

@interface _SVPodcast (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAuthor;
- (void)setPrimitiveAuthor:(NSString*)value;




- (NSString*)primitiveCachingLastModified;
- (void)setPrimitiveCachingLastModified:(NSString*)value;




- (NSNumber*)primitiveDownloadCount;
- (void)setPrimitiveDownloadCount:(NSNumber*)value;

- (int32_t)primitiveDownloadCountValue;
- (void)setPrimitiveDownloadCountValue:(int32_t)value_;




- (NSNumber*)primitiveDownloadPercentage;
- (void)setPrimitiveDownloadPercentage:(NSNumber*)value;

- (float)primitiveDownloadPercentageValue;
- (void)setPrimitiveDownloadPercentageValue:(float)value_;




- (NSNumber*)primitiveDownloadsToKeep;
- (void)setPrimitiveDownloadsToKeep:(NSNumber*)value;

- (int32_t)primitiveDownloadsToKeepValue;
- (void)setPrimitiveDownloadsToKeepValue:(int32_t)value_;




- (NSString*)primitiveEtag;
- (void)setPrimitiveEtag:(NSString*)value;




- (NSString*)primitiveFeedURL;
- (void)setPrimitiveFeedURL:(NSString*)value;




- (NSData*)primitiveFullIsizeImageData;
- (void)setPrimitiveFullIsizeImageData:(NSData*)value;




- (NSData*)primitiveGridSizeImageData;
- (void)setPrimitiveGridSizeImageData:(NSData*)value;




- (NSNumber*)primitiveHidePlayedEpisodes;
- (void)setPrimitiveHidePlayedEpisodes:(NSNumber*)value;

- (BOOL)primitiveHidePlayedEpisodesValue;
- (void)setPrimitiveHidePlayedEpisodesValue:(BOOL)value_;




- (NSNumber*)primitiveIsDownloading;
- (void)setPrimitiveIsDownloading:(NSNumber*)value;

- (BOOL)primitiveIsDownloadingValue;
- (void)setPrimitiveIsDownloadingValue:(BOOL)value_;




- (NSNumber*)primitiveIsSubscribed;
- (void)setPrimitiveIsSubscribed:(NSNumber*)value;

- (BOOL)primitiveIsSubscribedValue;
- (void)setPrimitiveIsSubscribedValue:(BOOL)value_;




- (NSNumber*)primitiveIsVideo;
- (void)setPrimitiveIsVideo:(NSNumber*)value;

- (BOOL)primitiveIsVideoValue;
- (void)setPrimitiveIsVideoValue:(BOOL)value_;




- (NSDate*)primitiveLastSynced;
- (void)setPrimitiveLastSynced:(NSDate*)value;




- (NSDate*)primitiveLastUpdated;
- (void)setPrimitiveLastUpdated:(NSDate*)value;




- (NSData*)primitiveListSizeImageData;
- (void)setPrimitiveListSizeImageData:(NSData*)value;




- (NSString*)primitiveLogoURL;
- (void)setPrimitiveLogoURL:(NSString*)value;




- (NSDate*)primitiveNextItemDate;
- (void)setPrimitiveNextItemDate:(NSDate*)value;




- (NSNumber*)primitivePodstoreId;
- (void)setPrimitivePodstoreId:(NSNumber*)value;

- (int32_t)primitivePodstoreIdValue;
- (void)setPrimitivePodstoreIdValue:(int32_t)value_;




- (NSNumber*)primitiveShouldNotify;
- (void)setPrimitiveShouldNotify:(NSNumber*)value;

- (BOOL)primitiveShouldNotifyValue;
- (void)setPrimitiveShouldNotifyValue:(BOOL)value_;




- (NSString*)primitiveSmallLogoURL;
- (void)setPrimitiveSmallLogoURL:(NSString*)value;




- (NSNumber*)primitiveSortNewestFirst;
- (void)setPrimitiveSortNewestFirst:(NSNumber*)value;

- (BOOL)primitiveSortNewestFirstValue;
- (void)setPrimitiveSortNewestFirstValue:(BOOL)value_;




- (NSDate*)primitiveSubscribedDate;
- (void)setPrimitiveSubscribedDate:(NSDate*)value;




- (NSString*)primitiveSubtitle;
- (void)setPrimitiveSubtitle:(NSString*)value;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;




- (NSString*)primitiveThumbLogoURL;
- (void)setPrimitiveThumbLogoURL:(NSString*)value;




- (NSString*)primitiveTinyLogoURL;
- (void)setPrimitiveTinyLogoURL:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSNumber*)primitiveUnlistenedSinceSubscribedCount;
- (void)setPrimitiveUnlistenedSinceSubscribedCount:(NSNumber*)value;

- (int32_t)primitiveUnlistenedSinceSubscribedCountValue;
- (void)setPrimitiveUnlistenedSinceSubscribedCountValue:(int32_t)value_;




- (NSNumber*)primitiveUpdating;
- (void)setPrimitiveUpdating:(NSNumber*)value;

- (BOOL)primitiveUpdatingValue;
- (void)setPrimitiveUpdatingValue:(BOOL)value_;




- (NSString*)primitiveUrlHash;
- (void)setPrimitiveUrlHash:(NSString*)value;




- (NSString*)primitiveWebsiteURL;
- (void)setPrimitiveWebsiteURL:(NSString*)value;





- (NSMutableSet*)primitiveItems;
- (void)setPrimitiveItems:(NSMutableSet*)value;


@end
