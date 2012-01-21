// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVSubscription.m instead.

#import "_SVSubscription.h"

const struct SVSubscriptionAttributes SVSubscriptionAttributes = {
	.autoDownloadCount = @"autoDownloadCount",
	.newestFirst = @"newestFirst",
	.shouldAutoDownload = @"shouldAutoDownload",
};

const struct SVSubscriptionRelationships SVSubscriptionRelationships = {
	.podcast = @"podcast",
};

const struct SVSubscriptionFetchedProperties SVSubscriptionFetchedProperties = {
};

@implementation SVSubscriptionID
@end

@implementation _SVSubscription

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Subscription" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Subscription";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Subscription" inManagedObjectContext:moc_];
}

- (SVSubscriptionID*)objectID {
	return (SVSubscriptionID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"autoDownloadCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"autoDownloadCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"newestFirstValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"newestFirst"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"shouldAutoDownloadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"shouldAutoDownload"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic autoDownloadCount;



- (int)autoDownloadCountValue {
	NSNumber *result = [self autoDownloadCount];
	return [result intValue];
}

- (void)setAutoDownloadCountValue:(int)value_ {
	[self setAutoDownloadCount:[NSNumber numberWithInt:value_]];
}

- (int)primitiveAutoDownloadCountValue {
	NSNumber *result = [self primitiveAutoDownloadCount];
	return [result intValue];
}

- (void)setPrimitiveAutoDownloadCountValue:(int)value_ {
	[self setPrimitiveAutoDownloadCount:[NSNumber numberWithInt:value_]];
}





@dynamic newestFirst;



- (BOOL)newestFirstValue {
	NSNumber *result = [self newestFirst];
	return [result boolValue];
}

- (void)setNewestFirstValue:(BOOL)value_ {
	[self setNewestFirst:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveNewestFirstValue {
	NSNumber *result = [self primitiveNewestFirst];
	return [result boolValue];
}

- (void)setPrimitiveNewestFirstValue:(BOOL)value_ {
	[self setPrimitiveNewestFirst:[NSNumber numberWithBool:value_]];
}





@dynamic shouldAutoDownload;



- (BOOL)shouldAutoDownloadValue {
	NSNumber *result = [self shouldAutoDownload];
	return [result boolValue];
}

- (void)setShouldAutoDownloadValue:(BOOL)value_ {
	[self setShouldAutoDownload:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveShouldAutoDownloadValue {
	NSNumber *result = [self primitiveShouldAutoDownload];
	return [result boolValue];
}

- (void)setPrimitiveShouldAutoDownloadValue:(BOOL)value_ {
	[self setPrimitiveShouldAutoDownload:[NSNumber numberWithBool:value_]];
}





@dynamic podcast;

	





@end
