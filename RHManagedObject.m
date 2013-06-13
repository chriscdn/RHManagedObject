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

+(NSString *)entityName {
    return NSStringFromClass([self superclass]);
	/*
	 NSLog(@"You must implement an entityName class method in your entity subclass.  Aborting.");
	 abort();
	 */
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

+(void)deleteStore {
	[[self managedObjectContextManager] deleteStore];
}

+(NSEntityDescription *)entityDescription {
	return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContextForCurrentThread]];
}

+(void)commit {
	[[self managedObjectContextManager] commit];
}

+(id)newEntity {
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[self managedObjectContextForCurrentThread]];
}

+(id)newOrExistingEntityWithPredicate:(NSPredicate *)predicate {
    id existing = [self getWithPredicate:predicate];
    return existing ? existing : [self newEntity];
}

+(id)getWithPredicate:(NSPredicate *)predicate {
	NSArray *results = [self fetchWithPredicate:predicate];
	
	if ([results count] > 0) {
		return [results objectAtIndex:0];
	}
	
	return nil;
}

+(id)getWithPredicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)descriptor {
	NSArray *results = [self fetchWithPredicate:predicate sortDescriptor:descriptor];
	
	if ([results count] > 0) {
		return [results objectAtIndex:0];
	}
	
	return nil;
}

+(NSArray *)fetchAll {
	return [self fetchWithPredicate:nil];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate {
	return [self fetchWithPredicate:predicate sortDescriptor:nil];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)descriptor {
	return [self fetchWithPredicate:predicate sortDescriptor:descriptor withLimit:0];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)descriptor withLimit:(NSUInteger)limit {
	NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
	
	[fetch setEntity:[self entityDescription]];
	
	if (predicate) {
		[fetch setPredicate:predicate];
	}
	
	if (descriptor) {
		[fetch setSortDescriptors:[NSArray arrayWithObject:descriptor]];
	}
	
	if (limit > 0) {
		[fetch setFetchLimit:limit];
	}
	
	[fetch setIncludesPendingChanges:YES];
	
	return [[self managedObjectContextForCurrentThread] executeFetchRequest:fetch error:nil];
}

+(NSUInteger)count {
	return [self countWithPredicate:nil];
}

+(NSUInteger)countWithPredicate:(NSPredicate *)predicate {
	NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
	
	[fetch setEntity:[self entityDescription]];
	
	if (predicate) {
		[fetch setPredicate:predicate];
	}
	
	return [[self managedObjectContextForCurrentThread] countForFetchRequest:fetch error:nil];
}

+(NSArray *)distinctValuesWithAttribute:(NSString *)attribute predicate:(NSPredicate *)predicate {
	NSArray *items = [self fetchWithPredicate:predicate];
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

+(NSAttributeType)attributeTypeWithKey:(NSString *)key {
	NSEntityDescription *entityDescription = [self entityDescription];
	NSDictionary *properties = [entityDescription propertiesByName];
	NSAttributeDescription *attribute = [properties objectForKey:key];
	return [attribute attributeType];
}

+(id)aggregateWithType:(RHAggregate)aggregate key:(NSString *)key predicate:(NSPredicate *)predicate defaultValue:(id)defaultValue {
	NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
	
	if (predicate) {
		[fetch setPredicate:predicate];
	}
	
	NSString *aggregateString = [self aggregateToString:aggregate];
	NSAttributeType attributeType = [self attributeTypeWithKey:key];
	
	NSEntityDescription *entity = [self entityDescription]; // [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
	[fetch setEntity:entity];
	[fetch setResultType:NSDictionaryResultType];
	
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:key];
	NSExpression *expression = [NSExpression expressionForFunction:aggregateString arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:key];
	[expressionDescription setExpression:expression];
	[expressionDescription setExpressionResultType:attributeType];
	
	[fetch setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	NSError *error;
	NSArray *objects = [[self managedObjectContextForCurrentThread] executeFetchRequest:fetch error:&error];
	
	id returnValue = nil;
	
	if ((objects != nil) && ([objects count] > 0) ) {
		returnValue = [[objects lastObject] valueForKey:key];
	}
	
	if (returnValue == nil) {
		returnValue = defaultValue;
	}
		
	return returnValue;
}

+(void)deleteAll {
    [self deleteWithPredicate:nil];
}

+(NSUInteger)deleteWithPredicate:(NSPredicate *)predicate {
    NSArray *itemsToDelete = [self fetchWithPredicate:predicate];
    [itemsToDelete makeObjectsPerformSelector:@selector(delete)];
    return [itemsToDelete count];
}

// deprecated = use managedObjectContextForCurrentThread instead
+(NSManagedObjectContext *)managedObjectContext {
    return [self managedObjectContextForCurrentThread];
}

// Returns the NSManagedObjectContext for the current thread
+(NSManagedObjectContext *)managedObjectContextForCurrentThread {
	return [[self managedObjectContextManager] managedObjectContextForCurrentThread];
}

+(RHManagedObjectContextManager *)managedObjectContextManager {
    return [RHManagedObjectContextManager sharedInstanceWithModelName:[self modelName]];
}

+(BOOL)doesRequireMigration {
	return [[self managedObjectContextManager] doesRequireMigration];
}

-(void)delete {
	[[self managedObjectContext] deleteObject:self];
}

// perform a shallow copy of a Managed Object and return it - only handle attributes and not relationships
-(id)clone {
	NSEntityDescription *entityDescription = [self entity];
	NSString *entityName = [entityDescription name];
	NSManagedObject *cloned = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:[self managedObjectContext]];
	
    for (NSString *attr in [entityDescription attributesByName]) {
        [cloned setValue:[self valueForKey:attr] forKey:attr];
    }
	
    return cloned;
}

-(id)objectInCurrentThreadContext {
	NSManagedObjectContext *currentMoc = [[self class] performSelector:@selector(managedObjectContextForCurrentThread)];
	return [currentMoc objectWithID:self.objectID];
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