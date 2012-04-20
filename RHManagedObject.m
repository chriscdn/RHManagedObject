//
//  RHManagedObject.m
//  Version: 0.6
//
//  Copyright (C) 2012 by Christopher Meyer
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
//

#import "RHManagedObject.h"
#import "RHManagedObjectContextManager.h"

@implementation RHManagedObject

// Abstract class.  Implement in your entity subclass to return the name of the entity superclass
+(NSString *)entityName {
	NSLog(@"You must implement an entityName class method in your entity subclass.  Aborting.");
	abort();
}

+(NSEntityDescription *)entityDescription {
	return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
}

+(void)commit {
	[[RHManagedObjectContextManager sharedInstance] commit];
}

+(RHManagedObject *)newEntity {
	return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
}

+(RHManagedObject *)getWithPredicate:(NSPredicate *)predicate {
	NSArray *results = [self fetchWithPredicate:predicate];
	
	if ([results count] > 0) {
		return [results objectAtIndex:0];
	}
	
	return nil;
}

+(RHManagedObject *)getWithPredicate:(NSPredicate *)predicate withSortDescriptor:(NSSortDescriptor *)descriptor {
	NSArray *results = [self fetchWithPredicate:predicate withSortDescriptor:descriptor];
	
	if ([results count] > 0) {
		return [results objectAtIndex:0];
	}
	
	return nil;	
}

+(NSArray *)fetchAll {
	return [self fetchWithPredicate:nil];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate {
	return [self fetchWithPredicate:predicate withSortDescriptor:nil];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate withSortDescriptor:(NSSortDescriptor *)descriptor {
	return [self fetchWithPredicate:predicate withSortDescriptor:descriptor withLimit:0];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate withSortDescriptor:(NSSortDescriptor *)descriptor withLimit:(NSUInteger)limit {
	NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];	
	
	[fetch setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]]];
	
	
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
	
	return [[self managedObjectContext] executeFetchRequest:fetch error:nil];
}


+(NSUInteger)count {
	return [self countWithPredicate:nil];
}

+(NSUInteger)countWithPredicate:(NSPredicate *)predicate {
	NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];	
	
	[fetch setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.managedObjectContext]];
	
	if (predicate) {
		[fetch setPredicate:predicate];
	}
	
	// [fetch setIncludesPendingChanges:YES];
	
	return [self.managedObjectContext countForFetchRequest:fetch error:nil];
}

+(NSArray *)distinctValuesForAttribute:(NSString *)attribute withPredicate:(NSPredicate *)predicate {
	NSArray *items = [self fetchWithPredicate:predicate];
	NSString *keyPath = [@"@distinctUnionOfObjects." stringByAppendingString:attribute];
	
	return [[items valueForKeyPath:keyPath] sortedArrayUsingSelector:@selector(compare:)];
}

+(NSDate *)maxDateForKey:(NSString *)key withPredicate:(NSPredicate *)predicate {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	if (predicate) {
		[request setPredicate:predicate];
	}
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
	[request setEntity:entity];
	[request setResultType:NSDictionaryResultType];
	
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:key];
	NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:key];
	[expressionDescription setExpression:maxExpression];
	[expressionDescription setExpressionResultType:NSDateAttributeType];
	
	[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	NSError *error;
	NSArray *objects = [[self managedObjectContext] executeFetchRequest:request error:&error];
	
	NSDate *maxValue = nil;
	
	if (objects != nil) {
		if ([objects count] > 0) {
			maxValue = [[objects objectAtIndex:0] valueForKey:key];
		}
	}
	
	if (maxValue == nil) {
		maxValue = [NSDate dateWithTimeIntervalSince1970:0];	
	}
	
	[expressionDescription release];
	[request release];
	
	return maxValue;
}

+(NSNumber *)averageForKey:(NSString *)key withPredicate:(NSPredicate *)predicate {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	
	if (predicate) {
		[request setPredicate:predicate];
	}
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]];
	[request setEntity:entity];
	[request setResultType:NSDictionaryResultType];
	
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:key];
	NSExpression *avgExpression = [NSExpression expressionForFunction:@"average:" arguments:[NSArray arrayWithObject:keyPathExpression]];
	
	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:key];
	[expressionDescription setExpression:avgExpression];
	[expressionDescription setExpressionResultType:NSFloatAttributeType];
	
	[request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
	
	NSError *error;
	NSArray *objects = [[self managedObjectContext] executeFetchRequest:request error:&error];
	
	NSNumber *average = [NSNumber numberWithInt:0];
	
	if (objects != nil) {
		if ([objects count] > 0) {
			average = [[objects objectAtIndex:0] valueForKey:key];
		}
	}
	
	[expressionDescription release];
	[request release];
	
	return average;
}

+(void)deleteAll {
	NSFetchRequest *fetch = [[[NSFetchRequest alloc] init] autorelease];	
	[fetch setEntity:[NSEntityDescription entityForName:[self entityName] inManagedObjectContext:[self managedObjectContext]]];	
	[fetch setIncludesPendingChanges:YES];
	[fetch setReturnsObjectsAsFaults:YES];
	
	for (RHManagedObject *basket in [self.managedObjectContext executeFetchRequest:fetch error:nil]) {
		[(RHManagedObject *)basket delete];
	}
}

// Returns the NSManagedObjectContext for the current thread
+(NSManagedObjectContext *)managedObjectContext {
	return [[RHManagedObjectContextManager sharedInstance] managedObjectContext];
}

-(void)delete {
	[[self managedObjectContext] deleteObject:self];
}

// perform a shall copy of a Managed Object and return it - only handle attributes and not relationships
-(RHManagedObject *)clone {
	
	NSString *entityName = [[self class] performSelector:@selector(entityName)];
	
	NSManagedObject *cloned = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:[self managedObjectContext]];
	
    //loop through all attributes and assign them to the clone
    NSDictionary *attributes = [[NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContext]] attributesByName];
	
    for (NSString *attr in attributes) {
        [cloned setValue:[self valueForKey:attr] forKey:attr];
    }
	
    return (RHManagedObject *)cloned;
}

-(RHManagedObject *)objectInCurrentThreadContext {
	return (RHManagedObject *)[[self managedObjectContext] objectWithID:self.objectID];
}


+(NSArray *)serialize:(NSArray *)items {
	NSMutableArray *mutArray = [NSMutableArray array];
	for (RHManagedObject *item in items) {
		[mutArray addObject:[item serialize]];
	}
	return mutArray;	
}

-(NSDictionary *)serialize{
	// implement in subclass
	return [NSDictionary dictionary];
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