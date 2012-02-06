// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcastEntry.m instead.

#import "_SVPodcastEntry.h"

const struct SVPodcastEntryAttributes SVPodcastEntryAttributes = {
	.content = @"content",
	.datePublished = @"datePublished",
	.downloadComplete = @"downloadComplete",
	.duration = @"duration",
	.guid = @"guid",
	.imageURL = @"imageURL",
	.isVideo = @"isVideo",
	.markedForDownload = @"markedForDownload",
	.mediaURL = @"mediaURL",
	.played = @"played",
	.positionInSeconds = @"positionInSeconds",
	.summary = @"summary",
	.title = @"title",
	.totalBytes = @"totalBytes",
};

const struct SVPodcastEntryRelationships SVPodcastEntryRelationships = {
	.download = @"download",
	.podcast = @"podcast",
};

const struct SVPodcastEntryFetchedProperties SVPodcastEntryFetchedProperties = {
};

@implementation SVPodcastEntryID
@end

@implementation _SVPodcastEntry

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"PodcastEntry" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"PodcastEntry";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"PodcastEntry" inManagedObjectContext:moc_];
}

- (SVPodcastEntryID*)objectID {
	return (SVPodcastEntryID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"downloadCompleteValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"downloadComplete"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"durationValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"duration"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"isVideoValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isVideo"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"markedForDownloadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"markedForDownload"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"playedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"played"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"positionInSecondsValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"positionInSeconds"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"totalBytesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"totalBytes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic content;






@dynamic datePublished;






@dynamic downloadComplete;



- (BOOL)downloadCompleteValue {
	NSNumber *result = [self downloadComplete];
	return [result boolValue];
}

- (void)setDownloadCompleteValue:(BOOL)value_ {
	[self setDownloadComplete:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveDownloadCompleteValue {
	NSNumber *result = [self primitiveDownloadComplete];
	return [result boolValue];
}

- (void)setPrimitiveDownloadCompleteValue:(BOOL)value_ {
	[self setPrimitiveDownloadComplete:[NSNumber numberWithBool:value_]];
}





@dynamic duration;



- (int)durationValue {
	NSNumber *result = [self duration];
	return [result intValue];
}

- (void)setDurationValue:(int)value_ {
	[self setDuration:[NSNumber numberWithInt:value_]];
}

- (int)primitiveDurationValue {
	NSNumber *result = [self primitiveDuration];
	return [result intValue];
}

- (void)setPrimitiveDurationValue:(int)value_ {
	[self setPrimitiveDuration:[NSNumber numberWithInt:value_]];
}





@dynamic guid;






@dynamic imageURL;






@dynamic isVideo;



- (BOOL)isVideoValue {
	NSNumber *result = [self isVideo];
	return [result boolValue];
}

- (void)setIsVideoValue:(BOOL)value_ {
	[self setIsVideo:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsVideoValue {
	NSNumber *result = [self primitiveIsVideo];
	return [result boolValue];
}

- (void)setPrimitiveIsVideoValue:(BOOL)value_ {
	[self setPrimitiveIsVideo:[NSNumber numberWithBool:value_]];
}





@dynamic markedForDownload;



- (BOOL)markedForDownloadValue {
	NSNumber *result = [self markedForDownload];
	return [result boolValue];
}

- (void)setMarkedForDownloadValue:(BOOL)value_ {
	[self setMarkedForDownload:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveMarkedForDownloadValue {
	NSNumber *result = [self primitiveMarkedForDownload];
	return [result boolValue];
}

- (void)setPrimitiveMarkedForDownloadValue:(BOOL)value_ {
	[self setPrimitiveMarkedForDownload:[NSNumber numberWithBool:value_]];
}





@dynamic mediaURL;






@dynamic played;



- (BOOL)playedValue {
	NSNumber *result = [self played];
	return [result boolValue];
}

- (void)setPlayedValue:(BOOL)value_ {
	[self setPlayed:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitivePlayedValue {
	NSNumber *result = [self primitivePlayed];
	return [result boolValue];
}

- (void)setPrimitivePlayedValue:(BOOL)value_ {
	[self setPrimitivePlayed:[NSNumber numberWithBool:value_]];
}





@dynamic positionInSeconds;



- (int)positionInSecondsValue {
	NSNumber *result = [self positionInSeconds];
	return [result intValue];
}

- (void)setPositionInSecondsValue:(int)value_ {
	[self setPositionInSeconds:[NSNumber numberWithInt:value_]];
}

- (int)primitivePositionInSecondsValue {
	NSNumber *result = [self primitivePositionInSeconds];
	return [result intValue];
}

- (void)setPrimitivePositionInSecondsValue:(int)value_ {
	[self setPrimitivePositionInSeconds:[NSNumber numberWithInt:value_]];
}





@dynamic summary;






@dynamic title;






@dynamic totalBytes;



- (int)totalBytesValue {
	NSNumber *result = [self totalBytes];
	return [result intValue];
}

- (void)setTotalBytesValue:(int)value_ {
	[self setTotalBytes:[NSNumber numberWithInt:value_]];
}

- (int)primitiveTotalBytesValue {
	NSNumber *result = [self primitiveTotalBytes];
	return [result intValue];
}

- (void)setPrimitiveTotalBytesValue:(int)value_ {
	[self setPrimitiveTotalBytes:[NSNumber numberWithInt:value_]];
}





@dynamic download;

	

@dynamic podcast;

	





@end
