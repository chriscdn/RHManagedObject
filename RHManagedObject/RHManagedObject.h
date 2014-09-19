//
//  RHManagedObject.h
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

typedef enum {
    RHAggregateMax,
	RHAggregateMin,
	RHAggregateAverage,
	RHAggregateSum
} RHAggregate;

typedef void (^RHDidUpdateBlock)();
typedef void (^RHDidDeleteBlock)();

#import <CoreData/CoreData.h>
@class RHManagedObjectContextManager;


#pragma mark - RHManagedObject interface -
/**
 RHManagedObject is an NSManagedObject subclass that simplifies the use of Core Data. It manages its managed object contexts internally for each thread and automatically merges saved changes. Inserting, deleting, saving and fetching objects can all be done with just 1 line of code. Fetching can be done in a background thread and have its results returned on the main thread. Provides methods to safely transfer Managed Objects between threads.
 
 ## Version information
 
 __Version__: 0.14
 
 __Found__: 2012-04-20
 
 __Last update__: 2014-08-13
 
 __Developer__: Christopher Meyer
 
 */
@interface RHManagedObject : NSManagedObject

#pragma mark - Configuring the RHManagedObject subclass
/**---------------------------------------------------------------------------------------
 * @name Configuring the RHManagedObject subclass
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Return the name for the NSEntityDescription. Override this in the RHManagedObject subclass.
 *
 *  @return The name of the entity.
 */
+(NSString *)entityName;

/**
 *  Return the name of the data model this entity belongs to. Override this method in the RHManagedObject subclass.
 *
 *  @return The name of the data model.
 */
+(NSString *)modelName;

/**
 *  Returns the entity description for this entity. 
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An instance of NSEntityDescription for this entity in the current thread's managed object context.
 */
+(NSEntityDescription *)entityDescriptionWithError:(NSError **)error;

/**
 *  Return the default value of whether or not subentities should also be fetched.
 *
 *  @return Whether or not to fetch subentities by default.
 */
+(BOOL)shouldFetchRequestsReturnSubentities;



#pragma mark - Adding Objects to the Persistent Store
/**---------------------------------------------------------------------------------------
 * @name Adding Objects to the Persistent Store
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Inserts a new instance of this Managed Object subclass entity in the current thread's managed object context. A commit is still required to add the object to the persistent store.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The newly inserted instance of this Managed Object subclass or nil if an error occurs.
 *  @see commit
 */
+(id)newEntityWithError:(NSError **)error;

/**
 *  Fetches an existing object from the persistent store and returns it if it exists. Otherwise inserts a new instance of this Managed Object subclass entity in the current thread's managed object context. A commit is still required to add the object to the persistent store.
 *
 *  @param predicate The predicate used to fetch the existing object.
 *  @param error     If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An existing Managed Object, the newly inserted instance of this Managed Object subclass or nil if an error occurs.
 *  @see commit
 */
+(id)newOrExistingEntityWithPredicate:(NSPredicate *)predicate
                                error:(NSError **)error;

/**
 *  Inserts a shallow copy of this Managed Object in the current thread's managed object context. This only copies attributes, not relationships. A commit is still required to add the object to the persistent store.
 *
 *  @return The newly inserted instance of this Managed Object subclass or nil if an error occurs.
 *  @see commit
 */
-(id)clone;



#pragma mark - Removing Objects from the Persistent Store
/**---------------------------------------------------------------------------------------
 * @name Removing Objects from the Persistent Store
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Deletes this object from the managed object context. A commit is still required to remove the object from the persistent store.
 *
 *  @see commit
 */
-(void)delete;

/**
 *  Deletes all objects for this entity from the managed object context. A commit is still required to remove the objects from the persistent store.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return Returns the number of objects that were deleted.
 *  @see commit
 */
+(NSUInteger)deleteAllWithError:(NSError **)error;

/**
 *  Deletes objects for this entity from the managed object context, that match a specific predicate. A commit is still required to remove the objects from the persistent store.
 *
 *  @param predicate The predicate that should match with the objects. If nil all objects will be returned.
 *  @param error     If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return Returns the number of objects that were deleted.
 *  @see commit
 */
+(NSUInteger)deleteWithPredicate:(NSPredicate *)predicate error:(NSError **)error;

/**
 *  Deletes the persistent store for the data model this entity belongs to.
 *
 *  @return  If an error occurs, this returns an NSError object that describes the problem, otherwise nil.
 */
+(NSError *)deleteStore;



#pragma mark - Save Pending Changes
/**---------------------------------------------------------------------------------------
 * @name Save Pending Changes
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Attempts to commit unsaved changes to the persistent store this entity belongs to.
 *
 *  @return If an error occurs, this returns an NSError object that describes the problem, otherwise nil.
 */
+(NSError *)commit;

/**
 *  This method gets called every time this updated object gets merged in the main thread managed object context. By default this method will execute the didUpdateBlock.
 *
 *  @see didUpdateBlock
 */
-(void)didUpdate;

/**
 *  This block gets executed every time this updated object gets merged in the main thread managed object context.
 */
@property (nonatomic, copy) RHDidUpdateBlock didUpdateBlock;

/**
 *  This method gets called every time this deleted object gets merged in the main thread managed object context. By default this method will execute the didDeleteBlock.
 *  
 *  @see didDeleteBlock
 */
-(void)didDelete;

/**
 *  This block gets executed when this deleted object gets merged in the main thread managed object context.
 */
@property (nonatomic, copy) RHDidDeleteBlock didDeleteBlock;



#pragma mark - Fetching a Single Object
/**---------------------------------------------------------------------------------------
 * @name Fetching a Single Object
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Fetch an object for this entity from the persistent store, that matches a specific predicate.
 *
 *  @param predicate The predicate that should match with the object. If nil the first fetched object will be returned.
 *  @param error     If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The fetched object or nil if none exists or an error occurs.
 */
+(id)getWithPredicate:(NSPredicate *)predicate
                error:(NSError **)error;

/**
 *  Fetch an object for this entity from the persistent store, that matches a specific predicate and sort descriptor.
 *
 *  @param predicate  The predicate that should match with the object. If nil the first fetched object will be returned.
 *  @param descriptor The sort descriptor that is used to sort the fetched objects if multiple objects match the predicate.
 *  @param error      If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The fetched object or nil if none exists or an error occurs.
 */
+(id)getWithPredicate:(NSPredicate *)predicate
       sortDescriptor:(NSSortDescriptor *)descriptor
                error:(NSError **)error;



#pragma mark - Fetching Objects as an Arrays
/**---------------------------------------------------------------------------------------
 * @name Fetching Objects as an Array
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Fetch all objects for this entity from the persistent store. The fetched objects are returned as an array.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An array containing the fetched objects.
 */
+(NSArray *)fetchAllWithError:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate. The fetched objects are returned as an array.
 *
 *  @param predicate The predicate that should match with the objects. If nil all objects will be returned.
 *  @param error     If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An array containing the fetched objects.
 */
+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
                         error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate and sort descriptor. The fetched objects are returned as an array.
 *
 *  @param predicate  The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptor The sort descriptor used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param error      If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An array containing the fetched objects.
 */
+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
				sortDescriptor:(NSSortDescriptor *)descriptor
                         error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate and sort descriptor. The fetched objects are returned as an array.
 *
 *  @param predicate  The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptor The sort descriptor used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param limit      The maximum amount of objects to return. If 0 or higher than the total amount of fetched objects, all objects will be returned.
 *  @param error      If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An array containing the fetched objects.
 */
+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
                sortDescriptor:(NSSortDescriptor *)descriptor
                     withLimit:(NSUInteger)limit
                         error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate and multiple sort descriptors. The fetched objects are returned as an array.
 *
 *  @param predicate   The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptors An array of sort descriptors used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param limit       The maximum amount of objects to return. If 0 or higher than the total amount of fetched objects, all objects will be returned.
 *  @param error       If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An array containing the fetched objects.
 */
+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
               sortDescriptors:(NSArray *)descriptors
                     withLimit:(NSUInteger)limit
                         error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate and multiple sort descriptors. The fetched objects are returned as an array.
 *
 *  @param predicate          The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptors        An array of sort descriptors used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param limit              The maximum amount of objects to return. If 0 or higher than the total amount of fetched objects, all objects will be returned.
 *  @param includeSubentities Whether or not subentities should be included in the fetched objects.
 *  @param error              If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An array containing the fetched objects.
 */
+(NSArray *)fetchWithPredicate:(NSPredicate *)predicate
               sortDescriptors:(NSArray *)descriptors
                     withLimit:(NSUInteger)limit
			includeSubentities:(BOOL)includeSubentities
                         error:(NSError **)error;



#pragma mark - Background Fetching Objects as an Array
/**---------------------------------------------------------------------------------------
 * @name Background Fetching Objects as an Array
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Fetch objects for this entity from the persistent store in a background thread, that match a specific predicate and multiple sort descriptors. The fetched objects are returned as an array in the completion handler.
 *
 *  @param predicate   The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptors An array of sort descriptors used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param limit       The maximum amount of objects to return. If 0 or higher than the total amount of fetched objects, all objects will be returned.
 *  @param completion  The comletion handler that will be executed after the fetch has completed.
 */
+(void)fetchInBackgroundWithPredicate:(NSPredicate *)predicate
                      sortDescriptors:(NSArray *)descriptors
                            withLimit:(NSUInteger)limit
                           completion:(void (^)(NSArray *fetchedObjects, NSError* error))completion;



#pragma mark - Fetching Objects as a Key-Value Dictionary
/**---------------------------------------------------------------------------------------
 * @name Fetching Objects as a Key-Value Dictionary
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Fetch all objects for this entity from the persistent store. The fetched objects are returned as a key-value dictionary with the value of the object's key property as key.
 *
 *  @param keyProperty The name of a property of the managed object. This value of this property is used as the key in the resulting dictionary. If the value is nil, the object is not included in the results.
 *  @param error       If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return A dictionary containing the fetched objects.
 */
+(NSDictionary*)fetchAllAsDictionaryWithKeyProperty:(NSString *)keyProperty
                                              error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate. The fetched objects are returned as a key-value dictionary with the value of the object's key property as key.
 *
 *  @param keyProperty The name of a property of the managed object. This value of this property is used as the key in the resulting dictionary. If the value is nil, the object is not included in the results.
 *  @param predicate   The predicate that should match with the objects. If nil all objects will be returned.
 *  @param error       If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return A dictionary containing the fetched objects.
 */
+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString *)keyProperty
                                   withPredicate:(NSPredicate *)predicate
                                           error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate and sort descriptor. The fetched objects are returned as a key-value dictionary with the value of the object's key property as key.
 *
 *  @param keyProperty The name of a property of the managed object. This value of this property is used as the key in the resulting dictionary. If the value is nil, the object is not included in the results.
 *  @param predicate   The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptor  The sort descriptor used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param error       If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return A dictionary containing the fetched objects.
 */
+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString *)keyProperty
                                   withPredicate:(NSPredicate *)predicate
                              withSortDescriptor:(NSSortDescriptor *)descriptor
                                           error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate and multiple sort descriptors. The fetched objects are returned as a key-value dictionary with the value of the object's key property as key.
 *
 *  @param keyProperty The name of a property of the managed object. This value of this property is used as the key in the resulting dictionary. If the value is nil, the object is not included in the results.
 *  @param predicate   The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptors An array of sort descriptors used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param limit       The maximum amount of objects to return. If 0 or higher than the total amount of fetched objects, all objects will be returned.
 *  @param error       If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return A dictionary containing the fetched objects.
 */
+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString *)keyProperty
                                   withPredicate:(NSPredicate *)predicate
                             withSortDescriptors:(NSArray *)descriptors
                                       withLimit:(NSUInteger)limit
                                           error:(NSError **)error;

/**
 *  Fetch objects for this entity from the persistent store, that match a specific predicate and multiple sort descriptors. The fetched objects are returned as a key-value dictionary with the value of the object's key property as key.
 *
 *  @param keyProperty        The name of a property of the managed object. This value of this property is used as the key in the resulting dictionary. If the value is nil, the object is not included in the results.
 *  @param predicate          The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptors        An array of sort descriptors used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param limit              The maximum amount of objects to return. If 0 or higher than the total amount of fetched objects, all objects will be returned.
 *  @param includeSubentities Whether or not subentities should be included in the fetched objects.
 *  @param error              If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return A dictionary containing the fetched objects.
 */
+(NSDictionary*)fetchAsDictionaryWithKeyProperty:(NSString *)keyProperty
                                   withPredicate:(NSPredicate *)predicate
                             withSortDescriptors:(NSArray *)descriptors
                                       withLimit:(NSUInteger)limit
                              includeSubentities:(BOOL)includeSubentities
                                           error:(NSError **)error;



#pragma mark - Background Fetching Objects as a Key-Value Dictionary
/**---------------------------------------------------------------------------------------
 * @name Background Fetching Objects as a Key-Value Dictionary
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Fetch objects for this entity from the persistent store in a background thread, that match a specific predicate and multiple sort descriptors. The fetched objects are returned as a key-value dictionary with the value of the object's key property as key in the completion handler.
 *
 *  @param keyProperty The name of a property of the managed object. This value of this property is used as the key in the resulting dictionary. If the value is nil, the object is not included in the results.
 *  @param predicate   The predicate that should match with the objects. If nil all objects will be returned.
 *  @param descriptors An array of sort descriptors used to sort the fetched objects. If nil no additional sorting will occur.
 *  @param limit       The maximum amount of objects to return. If 0 or higher than the total amount of fetched objects, all objects will be returned.
 *  @param completion  The comletion handler that will be executed after the fetch has completed.
 */
+(void)fetchInBackgroundAsDictionaryWithKeyProperty:(NSString *)keyProperty
                                      withPredicate:(NSPredicate *)predicate
                                withSortDescriptors:(NSArray *)descriptors
                                          withLimit:(NSUInteger)limit
                                         completion:(void (^)(NSDictionary *fetchedObjects, NSError *error))completion;



#pragma mark - Counting Objects in the Persistent Store
/**---------------------------------------------------------------------------------------
 * @name Counting Objects in the Persistent Store
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Count the number of objects for this entity in the persistent store.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The number of objects for this entity in the persistent store. If an error occurred this will return NSNotFound.
 */
+(NSUInteger)countWithError:(NSError **)error;

/**
 *  Count the number of objects for this entity in the persistent store, that match a specific predicate.
 *
 *  @param predicate The predicate that should match with the objects. If nil all objects will be counted.
 *  @param error     If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The number of objects for this entity in the persistent store matching the predicate. If an error occurred this will return NSNotFound.
 */
+(NSUInteger)countWithPredicate:(NSPredicate *)predicate error:(NSError **)error;




#pragma mark - Managing the Managed Object Context
/**---------------------------------------------------------------------------------------
 * @name Managing the Managed Object Context
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Returns the managed object context for the current thread.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The managed object context used in the current thread.
 */
+(NSManagedObjectContext *)managedObjectContextForCurrentThreadWithError:(NSError **)error;

/**
 *  Returns the managed object context manager for the data model this entity belongs to.
 *
 *  @return The managed object context manager for this entity's data model.
 */
+(RHManagedObjectContextManager *)managedObjectContextManager;

/**
 *  Returns whether or not the data model of the stored database is compatible with the current data model.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return YES if the data models are not compatible and migration is required, otherwise NO.
 */
+(BOOL)doesRequireMigrationWithError:(NSError **)error;



#pragma mark - Lookup Attribute Values
/**---------------------------------------------------------------------------------------
 * @name Lookup Attribute Values
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Get all unique values for a specific attribute, for all objects for this entity in the persistent store that match a specific predicate.
 *
 *  @param attribute The name of the attribute.
 *  @param predicate The predicate that should match with the objects.
 *  @param error     If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An array containing all unique values for the attribute.
 */
+(NSArray *)distinctValuesWithAttribute:(NSString *)attribute
                              predicate:(NSPredicate *)predicate
                                  error:(NSError **)error;

/**
 *  Returns the type of the attribute in the data model.
 *
 *  @param key   The name of the attribute.
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The type of the attribute in the data model.
 */
+(NSAttributeType)attributeTypeWithKey:(NSString *)key
								 error:(NSError **)error;

/**
 *  Compares all values for a specific attribute based on aggregate type, for all objects for this entity in the persistent store that match a specific predicate.
 *
 *  @param aggregate    The aggregate type. Based on this value the minimum, maximum, average or sum of all values is returned.
 *  @param key          The name of the attribute.
 *  @param predicate    The predicate that should match with the objects.
 *  @param defaultValue If this method would normally return nil, defaultValue will be returned instead.
 *  @param error        If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The result of the comparison.
 */
+(id)aggregateWithType:(RHAggregate)aggregate
                   key:(NSString *)key
             predicate:(NSPredicate *)predicate
          defaultValue:(id)defaultValue
                 error:(NSError **)error;



#pragma mark - Transfering Managed Objects Between Threads
/**---------------------------------------------------------------------------------------
 * @name Transfering Managed Objects Between Threads
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Returns an instance for the Managed Object for the current thread. Core Data is not thread safe, use this to access a Managed Object that was created or fetched in a different thread.
 *
 *  @param error     If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return An instance of the Managed Object for the current thread.
 */
-(id)objectInCurrentThreadContextWithError:(NSError **)error;

/**
 *  Takes an array containing Managed Objects and returns an array containing instances for the Managed Objects for the current thread.
 *
 *  @param array An array containing Managed Objects. Any object that is not an RHManagedObject subclass is skipped.
 *
 *  @return An array containing instances of the Managed Objects for the current thread.
 */
+(NSArray*)arrayInCurrentThreadContext:(NSArray *)array;

/**
 *  Takes a dictionary containing Managed Objects and returns a dictionary containing instances for the Managed Objects for the current thread.
 *
 *  @param dictionary A dictionary containing Managed Objects. Any object that is not an RHManagedObject subclass is skipped.
 *
 *  @return A dictionary containing instances of the Managed Objects for the current thread.
 */
+(NSDictionary *)dictionaryInCurrentThreadContext:(NSDictionary *)dictionary;

/**
 *  Takes a set containing Managed Objects and returns a set containing instances for the Managed Objects for the current thread.
 *
 *  @param set A set containing Managed Objects. Any object that is not an RHManagedObject subclass is skipped.
 *
 *  @return A set containing instances of the Managed Objects for the current thread.
 */
+(NSSet *)setInCurrentThreadContext:(NSSet*)set;



#pragma mark - Converting to Foundation Objects
/**---------------------------------------------------------------------------------------
 * @name Converting to Foundation Objects
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Converts the Managed Object to a key-value dictionary with the names of the attributes as key and the values of the attributes as value. Relationships are not included.
 *
 *  @return A dictionary containing the attributes of the Managed Object.
 */
-(NSDictionary *)serialize;

@end

@interface ImageToDataTransformer : NSValueTransformer

@end