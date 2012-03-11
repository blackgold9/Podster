// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcast.h instead.

#import <CoreData/CoreData.h>


extern const struct SVPodcastAttributes {
	__unsafe_unretained NSString *author;
	__unsafe_unretained NSString *cachingLastModified;
	__unsafe_unretained NSString *etag;
	__unsafe_unretained NSString *feedURL;
	__unsafe_unretained NSString *hidePlayedEpisodes;
	__unsafe_unretained NSString *isSubscribed;
	__unsafe_unretained NSString *lastSynced;
	__unsafe_unretained NSString *lastUpdated;
	__unsafe_unretained NSString *logoURL;
	__unsafe_unretained NSString *needsReconciling;
	__unsafe_unretained NSString *shouldNotify;
	__unsafe_unretained NSString *smallLogoURL;
	__unsafe_unretained NSString *sortNewestFirst;
	__unsafe_unretained NSString *subtitle;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *thumbLogoURL;
	__unsafe_unretained NSString *tinyLogoURL;
	__unsafe_unretained NSString *title;
	__unsafe_unretained NSString *unseenEpsiodeCount;
	__unsafe_unretained NSString *urlHash;
	__unsafe_unretained NSString *websiteURL;
} SVPodcastAttributes;

extern const struct SVPodcastRelationships {
	__unsafe_unretained NSString *items;
	__unsafe_unretained NSString *subscription;
} SVPodcastRelationships;

extern const struct SVPodcastFetchedProperties {
} SVPodcastFetchedProperties;

@class SVPodcastEntry;
@class SVSubscription;























@interface SVPodcastID : NSManagedObjectID {}
@end

@interface _SVPodcast : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SVPodcastID*)objectID;




@property (nonatomic, strong) NSString *author;


//- (BOOL)validateAuthor:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *cachingLastModified;


//- (BOOL)validateCachingLastModified:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *etag;


//- (BOOL)validateEtag:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *feedURL;


//- (BOOL)validateFeedURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *hidePlayedEpisodes;


@property BOOL hidePlayedEpisodesValue;
- (BOOL)hidePlayedEpisodesValue;
- (void)setHidePlayedEpisodesValue:(BOOL)value_;

//- (BOOL)validateHidePlayedEpisodes:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *isSubscribed;


@property BOOL isSubscribedValue;
- (BOOL)isSubscribedValue;
- (void)setIsSubscribedValue:(BOOL)value_;

//- (BOOL)validateIsSubscribed:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate *lastSynced;


//- (BOOL)validateLastSynced:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate *lastUpdated;


//- (BOOL)validateLastUpdated:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *logoURL;


//- (BOOL)validateLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *needsReconciling;


@property BOOL needsReconcilingValue;
- (BOOL)needsReconcilingValue;
- (void)setNeedsReconcilingValue:(BOOL)value_;

//- (BOOL)validateNeedsReconciling:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *shouldNotify;


@property BOOL shouldNotifyValue;
- (BOOL)shouldNotifyValue;
- (void)setShouldNotifyValue:(BOOL)value_;

//- (BOOL)validateShouldNotify:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *smallLogoURL;


//- (BOOL)validateSmallLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *sortNewestFirst;


@property BOOL sortNewestFirstValue;
- (BOOL)sortNewestFirstValue;
- (void)setSortNewestFirstValue:(BOOL)value_;

//- (BOOL)validateSortNewestFirst:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *subtitle;


//- (BOOL)validateSubtitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *thumbLogoURL;


//- (BOOL)validateThumbLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *tinyLogoURL;


//- (BOOL)validateTinyLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber *unseenEpsiodeCount;


@property int unseenEpsiodeCountValue;
- (int)unseenEpsiodeCountValue;
- (void)setUnseenEpsiodeCountValue:(int)value_;

//- (BOOL)validateUnseenEpsiodeCount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *urlHash;


//- (BOOL)validateUrlHash:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *websiteURL;


//- (BOOL)validateWebsiteURL:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* items;

- (NSMutableSet*)itemsSet;




@property (nonatomic, strong) SVSubscription* subscription;

//- (BOOL)validateSubscription:(id*)value_ error:(NSError**)error_;




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




- (NSString*)primitiveEtag;
- (void)setPrimitiveEtag:(NSString*)value;




- (NSString*)primitiveFeedURL;
- (void)setPrimitiveFeedURL:(NSString*)value;




- (NSNumber*)primitiveHidePlayedEpisodes;
- (void)setPrimitiveHidePlayedEpisodes:(NSNumber*)value;

- (BOOL)primitiveHidePlayedEpisodesValue;
- (void)setPrimitiveHidePlayedEpisodesValue:(BOOL)value_;




- (NSNumber*)primitiveIsSubscribed;
- (void)setPrimitiveIsSubscribed:(NSNumber*)value;

- (BOOL)primitiveIsSubscribedValue;
- (void)setPrimitiveIsSubscribedValue:(BOOL)value_;




- (NSDate*)primitiveLastSynced;
- (void)setPrimitiveLastSynced:(NSDate*)value;




- (NSDate*)primitiveLastUpdated;
- (void)setPrimitiveLastUpdated:(NSDate*)value;




- (NSString*)primitiveLogoURL;
- (void)setPrimitiveLogoURL:(NSString*)value;




- (NSNumber*)primitiveNeedsReconciling;
- (void)setPrimitiveNeedsReconciling:(NSNumber*)value;

- (BOOL)primitiveNeedsReconcilingValue;
- (void)setPrimitiveNeedsReconcilingValue:(BOOL)value_;




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




- (NSNumber*)primitiveUnseenEpsiodeCount;
- (void)setPrimitiveUnseenEpsiodeCount:(NSNumber*)value;

- (int)primitiveUnseenEpsiodeCountValue;
- (void)setPrimitiveUnseenEpsiodeCountValue:(int)value_;




- (NSString*)primitiveUrlHash;
- (void)setPrimitiveUrlHash:(NSString*)value;




- (NSString*)primitiveWebsiteURL;
- (void)setPrimitiveWebsiteURL:(NSString*)value;





- (NSMutableSet*)primitiveItems;
- (void)setPrimitiveItems:(NSMutableSet*)value;



- (SVSubscription*)primitiveSubscription;
- (void)setPrimitiveSubscription:(SVSubscription*)value;


@end
