//
//  RHManagedObject.m
//
//  Copyright (C) 2013 by Christopher Meyer
//  http://schwiiz.org/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "RHManagedObject.h"
#import "RHManagedObjectContextManager.h"

@interface RHManagedObject()
+(NSString *)aggregateToString:(RHAggregate)aggregate;
@end

@implementation RHManagedObject
// http://stackoverflow.com/questions/12510849/ios6-automatic-property-synthesize-not-working
@synthesize didUpdateBlock;
@synthesize didDeleteBlock;

+(NSString *)entityName {
    return NSStringFromClass([self superclass]);
}

// Abstract class.  Implement in your entity subclass to return the name of the model without the .xcdatamodeld extension.
+(NSString *)modelName {
	NSString *modelName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"RHDefaultModelName"];
	if (modelName) {
		return modelName;
	}

    NSLog(@"You must implement a modelName class method in your entity subclass.  Aborting.");
	abort();
}

+(NSEntityDescription *)entityDescriptionWithError:(NSError **)error {
	return [NSEntityDescription entityForName:[self entityName]
                       inManagedObjectContext:[self managedObjectContextForCurrentThreadWithError:error]];
}

+(NSError *)deleteStore {
	NSError *error = [[self managedObjectContextManager] deleteStore];
    if (error) {
        return error;
    }
    return nil;
}

+(NSError *)commit {
	NSError *error = [[self managedObjectContextManager] commit];
    if (error) {
        return error;
    }
    return nil;
}

+(id)newEntityWithError:(NSError **)error {
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                         inManagedObjectContext:[self managedObjectContextForCurrentThreadWithError:error]];
}

+(id)newOrExistingEntityWithPredicate:(NSPredicate *)predicate error:(NSError **)error {
    id existing = [self getWithPredicate:predicate error:error];
    return existing ? existing : [self newEntityWithError:error];
}

+(id)getWithPredicate:(NSPredicate *)predicate
                error:(NSError **)error {

	NSArray *results = [self fetchWithPredicate:predicate error:error];

	if ([results count] > 0) {
		return [results objectAtIndex:0];
	}

	return nil;
}

+(id)getWithPredicate:(NSPredicate *)predicate
       sortDescriptor:(NSSortDescriptor *)descriptor
                error:(NSError **)error {
	
	NSArray *results = [self fetchWithPredicate:predicate sortDescriptor:descriptor error:error];

	if ([results count] > 0) {
		return [results objectAtIndex:0];
	}

	return nil;
}

+(NSArray *)fetchAllWithError:(NSError **)error {
	return [self fetchWithPredicate:nil error:error];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
                         error:(NSError **)error {

	return [self fetchWithPredicate:predicate
					 sortDescriptor:nil
							  error:error];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
                sortDescriptor:(NSSortDescriptor *)descriptor
                         error:(NSError **)error {

	return [self fetchWithPredicate:predicate
					 sortDescriptor:descriptor
						  withLimit:0
							  error:error];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
                sortDescriptor:(NSSortDescriptor *)descriptor
                     withLimit:(NSUInteger)limit
                         error:(NSError **)error {

	NSArray *desciptors = descriptor ? [NSArray arrayWithObject:descriptor] : nil;

	return [self fetchWithPredicate:predicate
					sortDescriptors:desciptors
						  withLimit:limit
							  error:error];

}


+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
               sortDescriptors:(NSArray *)descriptors
                     withLimit:(NSUInteger)limit
                         error:(NSError **)error {

	return [self fetchWithPredicate:predicate
					sortDescriptors:descriptors
						  withLimit:limit
				 includeSubentities:[self shouldFetchRequestsReturnSubentities]
							  error:error];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
               sortDescriptors:(NSArray *)descriptors
                     withLimit:(NSUInteger)limit
			includeSubentities:(BOOL)includeSubentities
                         error:(NSError **)error {

	NSFetchRequest *fetch = [NSFetchRequest new];

	[fetch setEntity:[self entityDescriptionWithError:error]];

	if (predicate) {
		[fetch setPredicate:predicate];
	}

	if (descriptors) {
		[fetch setSortDescriptors:descriptors];
	}

	if (limit > 0) {
		[fetch setFetchLimit:limit];
	}

	[fetch setIncludesSubentities:includeSubentities];

	// system defaults to YES already
	// [fetch setIncludesPendingChanges:YES];

	return [[self managedObjectContextForCurrentThreadWithError:error] executeFetchRequest:fetch error:error];
}

// This can be overridden per subclass
+(BOOL)shouldFetchRequestsReturnSubentities {
    return YES;
}

+(void)fetchInBackgroundWithPredicate:(NSPredicate *)predicate
                      sortDescriptors:(NSArray *)descriptors
                            withLimit:(NSUInteger)limit
                           completion:(void (^)(NSArray* fetchedObjects, NSError* error))completion {

    if ([NSThread isMainThread]) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

            NSError* error = nil;
            NSArray* fetchedObjects = [self fetchWithPredicate:predicate sortDescriptors:descriptors withLimit:limit error:&error];

            dispatch_async(dispatch_get_main_queue(), ^{

                NSArray* convertedFetchedObjects = [self arrayInCurrentThreadContext:fetchedObjects];
                completion(convertedFetchedObjects, error);
            });
        });
	} else {
        NSError* error = nil;
        NSArray* fetchedObjects = [self fetchWithPredicate:predicate sortDescriptors:descriptors withLimit:limit error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray* convertedFetchedObjects = [self arrayInCurrentThreadContext:fetchedObjects];
            completion(convertedFetchedObjects, error);
        });
    }
}

+(NSDictionary*)fetchAllAsDictionaryWithKeyProperty:(NSString*)keyProperty
                                              error:(NSError **)error {

    return [self fetchAsDictionaryWithKeyProperty:keyProperty withPredicate:nil withSortDescriptors:nil withLimit:0 error:error];
}

+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString*)keyProperty
                                   withPredicate:(NSPredicate*)predicate
                                           error:(NSError **)error {

    return [self fetchAsDictionaryWithKeyProperty:keyProperty withPredicate:predicate withSortDescriptors:nil withLimit:0 error:error];
}

+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString*)keyProperty
                                   withPredicate:(NSPredicate*)predicate
                              withSortDescriptor:(NSSortDescriptor*)descriptor
                                           error:(NSError **)error {

    NSArray* descriptors = nil;
    if (descriptor) {
        descriptors = [NSArray arrayWithObject:descriptor];
	}
	
    return [self fetchAsDictionaryWithKeyProperty:keyProperty withPredicate:predicate withSortDescriptors:descriptors withLimit:0 error:error];
}

+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString*)keyProperty
                                   withPredicate:(NSPredicate*)predicate
                             withSortDescriptors:(NSArray*)descriptors
                                       withLimit:(NSUInteger)limit
                                           error:(NSError **)error {

    return [self fetchAsDictionaryWithKeyProperty:keyProperty withPredicate:predicate withSortDescriptors:descriptors withLimit:limit includeSubentities:[self shouldFetchRequestsReturnSubentities] error:error];
}

+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString *)keyProperty
                                   withPredicate:(NSPredicate *)predicate
                             withSortDescriptors:(NSArray *)descriptors
                                       withLimit:(NSUInteger)limit
                              includeSubentities:(BOOL)includeSubentities
                                           error:(NSError **)error {
    
    NSArray *fetchedObjects = [self fetchWithPredicate:predicate sortDescriptors:descriptors withLimit:limit includeSubentities:includeSubentities error:error];
    
    NSMutableDictionary* dictionary = [NSMutableDictionary new];
    
    for (RHManagedObject* managedObject in fetchedObjects) {
        if ([managedObject valueForKey:keyProperty]) {
            [dictionary setObject:managedObject forKey:[managedObject valueForKey:keyProperty]];
        }
    }
    
    return [dictionary copy];
}

+(void)fetchInBackgroundAsDictionaryWithKeyProperty:(NSString*)keyProperty
                                      withPredicate:(NSPredicate*)predicate
                                withSortDescriptors:(NSArray*)descriptors
                                          withLimit:(NSUInteger)limit
                                         completion:(void (^)(NSDictionary* fetchedObjects, NSError* error))completion {

    if ([NSThread isMainThread]) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

            NSError* error = nil;
            NSDictionary* fetchedObjects = [self fetchAsDictionaryWithKeyProperty:keyProperty withPredicate:predicate withSortDescriptors:descriptors withLimit:limit error:&error];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary* convertedFetchedObjects = [self dictionaryInCurrentThreadContext:fetchedObjects];
                completion(convertedFetchedObjects, error);
            });
        });
	} else {
        NSError* error = nil;
        NSDictionary* fetchedObjects = [self fetchAsDictionaryWithKeyProperty:keyProperty withPredicate:predicate withSortDescriptors:descriptors withLimit:limit error:&error];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary* convertedFetchedObjects = [self dictionaryInCurrentThreadContext:fetchedObjects];
            completion(convertedFetchedObjects, error);
        });
    }
}









+(NSUInteger)countWithError:(NSError **)error {
	return [self countWithPredicate:nil error:error];
}

+(NSUInteger)countWithPredicate:(NSPredicate *)predicate error:(NSError **)error {
	NSFetchRequest *fetch = [[NSFetchRequest alloc] init];

	[fetch setEntity:[self entityDescriptionWithError:error]];

	if (predicate) {
		[fetch setPredicate:predicate];
	}

	return [[self managedObjectContextForCurrentThreadWithError:error] countForFetchRequest:fetch error:error];
}

+(NSArray *)distinctValuesWithAttribute:(NSString *)attribute
                              predicate:(NSPredicate *)predicate
                                  error:(NSError **)error {
	NSArray *items = [self fetchWithPredicate:predicate error:error];
	NSString *keyPath = [@"@distinctUnionOfObjects." stringByAppendingString:attribute];
	return [[items valueForKeyPath:keyPath] sortedArrayUsingSelector:@selector(compare:)];
}

+(NSString*)aggregateToString:(RHAggregate)aggregate {
    switch(aggregate) {
        case RHAggregateMax:
            return @"max:";
        case RHAggregateMin:
            return @"min:";
		case RHAggregateAverage:
            return @"average:";
		case RHAggregateSum:
			return @"sum:";
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
}

+(NSAttributeType)attributeTypeWithKey:(NSString *)key error:(NSError **)error {
	NSEntityDescription *entityDescription = [self entityDescriptionWithError:error];
	NSDictionary *properties = [entityDescription propertiesByName];
	NSAttributeDescription *attribute = [properties objectForKey:key];
	return [attribute attributeType];
}

+(id)aggregateWithType:(RHAggregate)aggregate
                   key:(NSString *)key
             predicate:(NSPredicate *)predicate
          defaultValue:(id)defaultValue
                 error:(NSError **)error {
	NSFetchRequest *fetch = [[NSFetchRequest alloc] init];

	if (predicate) {
		[fetch setPredicate:predicate];
	}

	NSString *aggregateString = [self aggregateToString:aggregate];
	NSAttributeType attributeType = [self attributeTypeWithKey:key error:error];

	NSEntityDescription *entity = [self entityDescriptionWithError:error]; // [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
	[fetch setEntity:entity];
	[fetch setResultType:NSDictionaryResultType];

	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:key];
	NSExpression *expression = [NSExpression expressionForFunction:aggregateString arguments:[NSArray arrayWithObject:keyPathExpression]];

	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:key];
	[expressionDescription setExpression:expression];
	[expressionDescription setExpressionResultType:attributeType];

	[fetch setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];

	NSArray *objects = [[self managedObjectContextForCurrentThreadWithError:error] executeFetchRequest:fetch
                                                                                                 error:error];

	id returnValue = nil;

	if ((objects != nil) && ([objects count] > 0) ) {
		returnValue = [[objects lastObject] valueForKey:key];
	}

	if (returnValue == nil) {
		returnValue = defaultValue;
	}

	return returnValue;
}

+(NSUInteger)deleteAllWithError:(NSError **)error {
    return [self deleteWithPredicate:nil error:error];
}

+(NSUInteger)deleteWithPredicate:(NSPredicate *)predicate error:(NSError **)error {
    NSArray *itemsToDelete = [self fetchWithPredicate:predicate error:error];
    [itemsToDelete makeObjectsPerformSelector:@selector(delete)];
    return [itemsToDelete count];
}

// Returns the NSManagedObjectContext for the current thread
+(NSManagedObjectContext *)managedObjectContextForCurrentThreadWithError:(NSError **)error {
	return [[self managedObjectContextManager] managedObjectContextForCurrentThreadWithError:error];
}

+(RHManagedObjectContextManager *)managedObjectContextManager {
    return [RHManagedObjectContextManager sharedInstanceWithModelName:[self modelName]];
}

+(BOOL)doesRequireMigrationWithError:(NSError **)error {
	return [[self managedObjectContextManager] doesRequireMigrationWithError:error];
}

-(void)delete {
	[[self managedObjectContext] deleteObject:self];
}

// perform a shallow copy of a Managed Object and return it - only handle attributes and not relationships
-(id)clone {
	NSEntityDescription *entityDescription = [self entity];
	NSString *entityName = [entityDescription name];
	NSManagedObject *cloned = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                            inManagedObjectContext:[self managedObjectContext]];

    for (NSString *attr in [entityDescription attributesByName]) {
        [cloned setValue:[self valueForKey:attr] forKey:attr];
    }

    return cloned;
}

-(id)objectInCurrentThreadContextWithError:(NSError **)error {
	NSManagedObjectContext *currentMoc = [[self class] performSelector:@selector(managedObjectContextForCurrentThreadWithError:)];
	return [currentMoc existingObjectWithID:self.objectID error:error];
}








+(NSArray*)arrayInCurrentThreadContext:(NSArray *)array {
    if (!array) {
        return nil;
	}

    NSMutableArray* tempArray = [NSMutableArray new];

    for (RHManagedObject *managedObject in array) {
        if ([managedObject isKindOfClass:[RHManagedObject class]]) {

			RHManagedObject *convertedManagedObject = [managedObject objectInCurrentThreadContextWithError:nil];

			if (convertedManagedObject) {
                [tempArray addObject:convertedManagedObject];
			}

        } else {
            // Some other object, don't do anything with it
            [tempArray addObject:managedObject];
        }
    }

    return [tempArray copy];
}

+(NSDictionary *)dictionaryInCurrentThreadContext:(NSDictionary *)dictionary {
    if (!dictionary) {
        return nil;
	}

    NSMutableDictionary* tempDictionary = [NSMutableDictionary new];
    for (NSString* key in [dictionary allKeys]) {
        RHManagedObject* managedObject = [dictionary objectForKey:key];
        if ([managedObject isKindOfClass:[RHManagedObject class]]) {
            RHManagedObject* convertedManagedObject = [managedObject objectInCurrentThreadContextWithError:nil];
            if (convertedManagedObject) {
                [tempDictionary setObject:convertedManagedObject forKey:key];
			}
        } else {
            // Some other object, don't do anything with it
            [tempDictionary setObject:managedObject forKey:key];
        }
    }

    return [NSDictionary dictionaryWithDictionary:tempDictionary];
}

+(NSSet *)setInCurrentThreadContext:(NSSet*)set {
    if (!set) {
        return nil;
	}

    NSArray* array = [self arrayInCurrentThreadContext:[set allObjects]];
    return [NSSet setWithArray:array];
}











// This function needs work
-(NSDictionary *)serialize {
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];

	for (NSString *key in [[self entity] attributesByName]) {
		id value = [self valueForKey:key];

		if (value != nil) {
			[dict setObject:value forKey:key];
		}
	}

	return dict;
}

-(void)didUpdate {
	if (self.didUpdateBlock) {
		self.didUpdateBlock();
	}
}

-(void)didDelete {
	if (self.didDeleteBlock ) {
		self.didDeleteBlock();
	}
}

@end


@implementation ImageToDataTransformer
+(BOOL)allowsReverseTransformation {
	return YES;
}

+(Class)transformedValueClass {
	return [NSData class];
}

-(id)transformedValue:(id)value {
	return UIImagePNGRepresentation(value);
}

-(id)reverseTransformedValue:(id)value {
	return [UIImage imageWithData:value];
}
@end