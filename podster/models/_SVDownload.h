// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVDownload.h instead.

#import <CoreData/CoreData.h>


extern const struct SVDownloadAttributes {
	__unsafe_unretained NSString *downloadedBytes;
	__unsafe_unretained NSString *path;
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




@property (nonatomic, strong) NSString *path;


//- (BOOL)validatePath:(id*)value_ error:(NSError**)error_;





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




- (NSString*)primitivePath;
- (void)setPrimitivePath:(NSString*)value;





- (SVPodcastEntry*)primitiveEntry;
- (void)setPrimitiveEntry:(SVPodcastEntry*)value;


@end
