// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcast.h instead.

#import <CoreData/CoreData.h>


extern const struct SVPodcastAttributes {
	__unsafe_unretained NSString *feedURL;
	__unsafe_unretained NSString *lastUpdated;
	__unsafe_unretained NSString *logoURL;
	__unsafe_unretained NSString *smallLogoURL;
	__unsafe_unretained NSString *summary;
	__unsafe_unretained NSString *thumbLogoURL;
	__unsafe_unretained NSString *tinyLogoURL;
	__unsafe_unretained NSString *title;
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




@property (nonatomic, strong) NSString *feedURL;


//- (BOOL)validateFeedURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSDate *lastUpdated;


//- (BOOL)validateLastUpdated:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *logoURL;


//- (BOOL)validateLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *smallLogoURL;


//- (BOOL)validateSmallLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *summary;


//- (BOOL)validateSummary:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *thumbLogoURL;


//- (BOOL)validateThumbLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *tinyLogoURL;


//- (BOOL)validateTinyLogoURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString *title;


//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;




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


- (NSString*)primitiveFeedURL;
- (void)setPrimitiveFeedURL:(NSString*)value;




- (NSDate*)primitiveLastUpdated;
- (void)setPrimitiveLastUpdated:(NSDate*)value;




- (NSString*)primitiveLogoURL;
- (void)setPrimitiveLogoURL:(NSString*)value;




- (NSString*)primitiveSmallLogoURL;
- (void)setPrimitiveSmallLogoURL:(NSString*)value;




- (NSString*)primitiveSummary;
- (void)setPrimitiveSummary:(NSString*)value;




- (NSString*)primitiveThumbLogoURL;
- (void)setPrimitiveThumbLogoURL:(NSString*)value;




- (NSString*)primitiveTinyLogoURL;
- (void)setPrimitiveTinyLogoURL:(NSString*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




- (NSString*)primitiveWebsiteURL;
- (void)setPrimitiveWebsiteURL:(NSString*)value;





- (NSMutableSet*)primitiveItems;
- (void)setPrimitiveItems:(NSMutableSet*)value;



- (SVSubscription*)primitiveSubscription;
- (void)setPrimitiveSubscription:(SVSubscription*)value;


@end
