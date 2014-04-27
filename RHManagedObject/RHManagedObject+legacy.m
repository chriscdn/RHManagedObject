//
//  RHManagedObject+legacy.m
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

#import "RHManagedObject+legacy.h"

@implementation RHManagedObject (legacy)

+(NSEntityDescription *)entityDescription {
	return [self entityDescriptionWithError:nil];
}

+(id)newEntity {
	return [self newEntityWithError:nil];
}

+(id)newOrExistingEntityWithPredicate:(NSPredicate *)predicate {
	return [self newOrExistingEntityWithPredicate:predicate error:nil];
}

+(id)getWithPredicate:(NSPredicate *)predicate {
	return [self getWithPredicate:predicate error:nil];
}

+(id)getWithPredicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)descriptor {
	return [self getWithPredicate:predicate sortDescriptor:descriptor error:nil];
}

+(NSArray *)fetchAll {
	return [self fetchAllWithError:nil];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate {
	return [self fetchWithPredicate:predicate error:nil];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate sortDescriptor:(NSSortDescriptor *)descriptor {
	return [self fetchWithPredicate:predicate sortDescriptor:descriptor error:nil];
}

+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
                sortDescriptor:(NSSortDescriptor *)descriptor
                     withLimit:(NSUInteger)limit {
	return [self fetchWithPredicate:predicate sortDescriptor:descriptor withLimit:limit error:nil];
}

+(NSUInteger)count {
	return [self countWithError:nil];
}

+(NSUInteger)countWithPredicate:(NSPredicate *)predicate {
	return [self countWithPredicate:predicate error:nil];
}

+(NSArray *)distinctValuesWithAttribute:(NSString *)attribute predicate:(NSPredicate *)predicate {
	return [self distinctValuesWithAttribute:attribute predicate:predicate error:nil];
}

+(NSAttributeType)attributeTypeWithKey:(NSString *)key {
	return [self attributeTypeWithKey:key error:nil];
}

+(id)aggregateWithType:(RHAggregate)aggregate key:(NSString *)key predicate:(NSPredicate *)predicate defaultValue:(id)defaultValue {
	return [self aggregateWithType:aggregate key:key predicate:predicate defaultValue:defaultValue error:nil];
}

+(NSUInteger)deleteAll {
	return [self deleteAllWithError:nil];
}

+(NSUInteger)deleteWithPredicate:(NSPredicate *)predicate {
	return [self deleteWithPredicate:predicate error:nil];
}

+(NSManagedObjectContext *)managedObjectContext {
    return [self managedObjectContextForCurrentThreadWithError:nil];
}

+(NSManagedObjectContext *)managedObjectContextForCurrentThread {
	return [self managedObjectContextForCurrentThreadWithError:nil];
}

+(BOOL)doesRequireMigration {
	return [self doesRequireMigrationWithError:nil];
}

@end
