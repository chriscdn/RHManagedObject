//
//  RHManagedObjectContextManager.h
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

#define kMergePolicy NSMergeByPropertyObjectTrumpMergePolicy
#define RHWillMassUpdateNotification @"RHWillMassUpdateNotification"
#define kPostMassUpdateNotificationThreshold 10 // If more than kPostMassUpdateNotificationThreshold updates are commited at once, post a RHWillMassUpdateNotification notification first

#import <CoreData/CoreData.h>


#pragma mark - RHManagedObjectContextManager interface -
/**
 RHManagedObjectContextManager is an object that manages the lifecycle of the managed object contexts for a specific data model and wraps all boilerplate code within this object.
 
 ## Version information
 
 __Version__: 0.14
 
 __Found__: 2012-04-20
 
 __Last update__: 2014-08-13
 
 __Developer__: Christopher Meyer
 
 */
@interface RHManagedObjectContextManager : NSObject

#pragma mark - Getting the Managed Object Context Manager
/**---------------------------------------------------------------------------------------
 * @name Getting the Managed Object Context Manager
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Returns the shared instance for a specific data model.
 *
 *  @param modelName The name of the data model.
 *
 *  @return The shared instance for the data model.
 */
+(RHManagedObjectContextManager *)sharedInstanceWithModelName:(NSString *)modelName;

/**
 *  Initialize an RHManagedObjectContextManager instance for a specific data model. This method should not be used directly, use sharedInstanceWithModelName: instead.
 *
 *  @param _modelName The name of the data model.
 *
 *  @return An initialized RHManagedObjectContextManager object or nil if an error occurs.
 *  @see sharedInstanceWithModelName:
 */
-(id)initWithModelName:(NSString *)_modelName;



#pragma mark - Getting the Managed Object Context
/**---------------------------------------------------------------------------------------
 * @name Getting the Managed Object Context
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Returns the managed object context for the current thread.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The managed object context used in the current thread.
 */
-(NSManagedObjectContext *)managedObjectContextForCurrentThreadWithError:(NSError **)error;



#pragma mark - Deleting the Persistent Store
/**---------------------------------------------------------------------------------------
 * @name Deleting the Persistent Store
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Deletes the persistent store and the database file(s) that are stored on disk for the data model. This removes this RHManagedObjectContextManager instance.
 *
 *  @return If an error occurs, this returns an NSError object that describes the problem, otherwise nil.
 */
-(NSError *)deleteStore;

/**
 *  Deletes the database file(s) that are stored on disk for the data model.
 *
 *  @param storePath The path of the database .sqlite file.
 *
 *  @return If an error occurs, this returns an NSError object that describes the problem, otherwise nil.
 */
-(NSError *)deleteStoreFiles:(NSString *)storePath;

/**
 *  Deletes a file at a specific path.
 *
 *  @param filePath The path of the file to delete.
 *
 *  @return If an error occurs, this returns an NSError object that describes the problem, otherwise nil.
 */
+(NSError *)deleteFile:(NSString *)filePath;



#pragma mark - Pending Changes
/**---------------------------------------------------------------------------------------
 * @name Pending Changes
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Attempts to commit unsaved changes to the persistent store.
 *
 *  @return If an error occurs, this returns an NSError object that describes the problem, otherwise nil.
 */
-(NSError *)commit;

/**
 *  Returns the number of unsaved changes made in the managed object context.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return The addition of the number of unsaved added, updated and deleted objects in the managed object context.
 */
-(NSUInteger)pendingChangesCountWithError:(NSError **)error;

/**
 *  This method is called when a commit is performed on a specific managed object context.
 *
 *  @param saveNotification The notification responsible for calling this method.
 */
-(void)mocDidSave:(NSNotification *)saveNotification;



#pragma mark - Data Model Migration
/**---------------------------------------------------------------------------------------
 * @name Data Model Migration
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Returns whether or not the data model of the stored database is compatible with the current data model.
 *
 *  @param error If an error occurs, upon return contains an NSError object that describes the problem.
 *
 *  @return YES if the data models are not compatible and migration is required, otherwise NO.
 */
-(BOOL)doesRequireMigrationWithError:(NSError **)error;



#pragma mark - Database Storage
/**---------------------------------------------------------------------------------------
 * @name Database Storage
 *  ---------------------------------------------------------------------------------------
 */

/**
 *  Returns the application's documents directory.
 *
 *  @return The application's documents directory.
 */
-(NSString *)applicationDocumentsDirectory;

/**
 *  Returns the applications's cache directory.
 *
 *  @return The applications's cache directory.
 */
-(NSString *)applicationCachesDirectory;

@end