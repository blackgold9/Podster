// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to PodcastImage.h instead.

#import <CoreData/CoreData.h>


extern const struct PodcastImageAttributes {
	__unsafe_unretained NSString *imageData;
} PodcastImageAttributes;

extern const struct PodcastImageRelationships {
} PodcastImageRelationships;

extern const struct PodcastImageFetchedProperties {
} PodcastImageFetchedProperties;




@interface PodcastImageID : NSManagedObjectID {}
@end

@interface _PodcastImage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (PodcastImageID*)objectID;




@property (nonatomic, strong) NSData* imageData;


//- (BOOL)validateImageData:(id*)value_ error:(NSError**)error_;






@end

@interface _PodcastImage (CoreDataGeneratedAccessors)

@end

@interface _PodcastImage (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveImageData;
- (void)setPrimitiveImageData:(NSData*)value;




@end
