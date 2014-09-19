//
//  RHManagedObjectContextManager.m
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

#import "RHManagedObjectContextManager.h"
#import "RHManagedObject.h"

@interface RHManagedObjectContext : NSManagedObjectContext
@property (nonatomic, weak) id observer;
@end

@implementation RHManagedObjectContext

// This subclass is for managing the NSManagedObjectContextDidSaveNotification.  The ManagedObjectContext is deallocated at an undetermined
// time when the thread on which it was allocated cleans up the threadDictionary.  By putting the removeObserver in the dealloc we can be
// certain everything is cleaned up when it's no longer required.
-(void)setObserver:(id)observer {
	if (observer != self.observer) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.observer
														name:NSManagedObjectContextDidSaveNotification
													  object:self];

		_observer = observer;

		[[NSNotificationCenter defaultCenter] addObserver:self.observer
												 selector:@selector(mocDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:self];
	}
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self.observer
													name:NSManagedObjectContextDidSaveNotification
												  object:self];
}

@end


@interface RHManagedObjectContextManager()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContextForMainThread;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) NSString *guid;

+(NSMutableDictionary *)sharedInstances;
-(NSString *)storePath;
-(NSURL *)storeURL;
-(NSString *)databaseName;

@property (nonatomic, strong) id localChangeObserver;
@end

@implementation RHManagedObjectContextManager
@synthesize managedObjectContextForMainThread;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;
@synthesize modelName;
@synthesize guid;

#pragma mark -
#pragma mark Singleton Methods
+(RHManagedObjectContextManager *)sharedInstanceWithModelName:(NSString *)modelName {
    if ([[self sharedInstances] objectForKey:modelName] == nil) {
        RHManagedObjectContextManager *contextManager = [[RHManagedObjectContextManager alloc] initWithModelName:modelName];
        [[self sharedInstances] setObject:contextManager forKey:modelName];
    }

    return [[self sharedInstances] objectForKey:modelName];
}

+(NSMutableDictionary *)sharedInstances {
    static dispatch_once_t once;
    static NSMutableDictionary *sharedInstances;
    dispatch_once(&once, ^{
        sharedInstances = [[NSMutableDictionary alloc] init];
    });
    return sharedInstances;
}

+(NSError *)deleteFile:(NSString *)filePath {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error;

	if ([fm fileExistsAtPath:filePath] && [fm isDeletableFileAtPath:filePath]) {
		[fm removeItemAtPath:filePath error:&error];
	}

	return error;
}

-(id)initWithModelName:(NSString *)_modelName {
    if (self=[super init]) {
        self.modelName = _modelName;
    }
    return self;
}

#pragma mark -
#pragma mark Other useful stuff
// Used to flush and reset the database.
-(NSError *)deleteStore {
	NSError *error = nil;

	if (persistentStoreCoordinator == nil) {
		NSString *storePath = [self storePath];

		[self deleteStoreFiles:storePath];

	} else {

		NSPersistentStoreCoordinator *storeCoordinator = [self persistentStoreCoordinatorWithError:&error];
        if (error) {
            return error;
        }

		for (NSPersistentStore *store in [storeCoordinator persistentStores]) {
			NSURL *storeURL = store.URL;
			NSString *storePath = storeURL.path;
			[storeCoordinator removePersistentStore:store error:&error];

			if (error) {
                return error;
            }

			[self deleteStoreFiles:storePath];
		}
	}

	self.managedObjectContextForMainThread = nil;
	self.managedObjectModel = nil;
	self.persistentStoreCoordinator = nil;
	self.guid = nil;

	[[RHManagedObjectContextManager sharedInstances] removeObjectForKey:[self modelName]];

    return nil;
}


-(NSError *)deleteStoreFiles:(NSString *)storePath {
	NSError *error = [RHManagedObjectContextManager deleteFile:storePath];
	[RHManagedObjectContextManager deleteFile:[storePath stringByAppendingString:@"-shm"]];
	[RHManagedObjectContextManager deleteFile:[storePath stringByAppendingString:@"-wal"]];

	return error;
}

-(NSString *)guid {
	if (guid == nil) {
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
		CFRelease(uuid);

		self.guid = [uuidStr lowercaseString];
	}
	return guid;
}

-(NSUInteger)pendingChangesCountWithError:(NSError **)error {
	NSManagedObjectContext *moc = [self managedObjectContextForCurrentThreadWithError:error];

	NSSet *updated  = [moc updatedObjects];
	NSSet *deleted  = [moc deletedObjects];
	NSSet *inserted = [moc insertedObjects];

	return [updated count] + [deleted count] + [inserted count];
}

// http://stackoverflow.com/questions/5236860/app-freeze-on-coredata-save
-(NSError *)commit {

    NSError *error = nil;
 	NSManagedObjectContext *moc = [self managedObjectContextForCurrentThreadWithError:&error];

    if (error) {
        return error;
    }

	if ([self pendingChangesCountWithError:&error] > kPostMassUpdateNotificationThreshold) {
		[[NSNotificationCenter defaultCenter] postNotificationName:RHWillMassUpdateNotification
                                                            object:nil];
	}

    if (error) {
        return error;
    }

	if ([moc hasChanges] && ![moc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		return error;
	}
    return nil;
}

#pragma mark -
#pragma mark Core Data stack
-(NSManagedObjectContext *)managedObjectContextForMainThreadWithError:(NSError **)error {
	if (managedObjectContextForMainThread == nil) {
		NSAssert([NSThread isMainThread], @"Must be instantiated on main thread.");
		self.managedObjectContextForMainThread = [[NSManagedObjectContext alloc] init];
		[managedObjectContextForMainThread setPersistentStoreCoordinator:[self persistentStoreCoordinatorWithError:error]];
		[managedObjectContextForMainThread setMergePolicy:kMergePolicy];

		self.localChangeObserver = [[NSNotificationCenter defaultCenter]
									addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
									object:managedObjectContextForMainThread
									queue:[NSOperationQueue mainQueue]
									usingBlock:^(NSNotification *notification) {

										NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
										[updatedObjects makeObjectsPerformSelector:@selector(didUpdate)];

										NSSet *deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
										[deletedObjects makeObjectsPerformSelector:@selector(didDelete)];

									}];
	}

	return managedObjectContextForMainThread;
}

-(NSManagedObjectContext *)managedObjectContextForCurrentThreadWithError:(NSError **)error {
	NSThread *thread = [NSThread currentThread];

	if ([thread isMainThread]) {
		return [self managedObjectContextForMainThreadWithError:error];
	}

	// A key to cache the moc for the current thread.
	// 2013-04-10 - Added a GUID to make sure the key is unique if the store is ever reset.  We don't want to access
	// a cached value from a deleted store!
	NSString *threadKey = [NSString stringWithFormat:@"RHManagedObjectContext_%@_%@", self.modelName, self.guid];

	if ( [[thread threadDictionary] objectForKey:threadKey] == nil ) {
		// create a moc for this thread
        RHManagedObjectContext *threadContext = [[RHManagedObjectContext alloc] init];
        [threadContext setPersistentStoreCoordinator:[self persistentStoreCoordinatorWithError:error]];
		[threadContext setMergePolicy:kMergePolicy];
		[threadContext setObserver:self];

		[[thread threadDictionary] setObject:threadContext forKey:threadKey];
    }

	return [[thread threadDictionary] objectForKey:threadKey];
}

/**
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created from the application's model.
 */
-(NSManagedObjectModel *)managedObjectModel {
	if (managedObjectModel == nil) {
		NSString *modelPath = [[NSBundle mainBundle] pathForResource:self.modelName ofType:@"momd"];
		NSURL *modelURL = [NSURL fileURLWithPath:modelPath];

		self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	}

	return managedObjectModel;
}

-(void)mocDidSave:(NSNotification *)saveNotification {
    if ([NSThread isMainThread]) {
		// This ensures no updated object is fault, which would cause the NSFetchedResultsController updates to fail.
		// http://www.mlsite.net/blog/?p=518

		NSDictionary *userInfo = saveNotification.userInfo;

		NSArray *updates = [[userInfo objectForKey:@"updated"] allObjects];
		for (RHManagedObject *item in updates) {
			[[item objectInCurrentThreadContextWithError:nil] willAccessValueForKey:nil];
		}

		// 2013-04-14 - This hack is also required on the "inserted" key to ensure NSFetchedResultsController works properly
		NSArray *inserted = [[userInfo objectForKey:@"inserted"] allObjects];
		for (RHManagedObject *item in inserted) {
			[[item objectInCurrentThreadContextWithError:nil] willAccessValueForKey:nil];
		}

        NSError *error = nil;
        [[self managedObjectContextForMainThreadWithError:&error] mergeChangesFromContextDidSaveNotification:saveNotification];

    } else {
        [self performSelectorOnMainThread:@selector(mocDidSave:) withObject:saveNotification waitUntilDone:NO];
    }
}

-(BOOL)doesRequireMigrationWithError:(NSError **)error {
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self storePath]]) {
		//		NSError *error = nil;
		NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator
                                        metadataForPersistentStoreOfType:NSSQLiteStoreType
                                        URL:[self storeURL]
                                        error:error];
		return ![[self managedObjectModel] isConfiguration:nil
                               compatibleWithStoreMetadata:sourceMetadata];
	} else {
		return NO;
	}
}

/**
 * Returns the persistent store coordinator for the application.
 * If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
-(NSPersistentStoreCoordinator *)persistentStoreCoordinatorWithError:(NSError **)error {

	if (persistentStoreCoordinator == nil) {
		@synchronized(self) {
			// This next block is useful when the store is initialized for the first time.  If the DB doesn't already
			// exist and a copy of the db (with the same name) exists in the bundle, it'll be copied over and used.  This
			// is useful for the initial seeding of data in the app.
			NSString *storePath = [self storePath];
			NSFileManager *fileManager = [NSFileManager defaultManager];

			if (![fileManager fileExistsAtPath:storePath]) {
				NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:[self databaseName] ofType:nil];

				if ([fileManager fileExistsAtPath:defaultStorePath]) {
					[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:error];
				}
			}

			NSURL *storeURL = [self storeURL];
			//			NSError *error = nil;

			self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

			// https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html#//apple_ref/doc/uid/TP40004399-CH4-SW1
			NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
									 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

			if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                          configuration:nil
                                                                    URL:storeURL
                                                                options:options
                                                                  error:error]) {
				/*
				 Replace this implementation with code to handle the error appropriately.

				 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.

				 Typical reasons for an error here include:
				 * The persistent store is not accessible;
				 * The schema for the persistent store is incompatible with current managed object model.
				 Check the error message to determine what the actual problem was.


				 If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

				 If you encounter schema incompatibility errors during development, you can reduce their frequency by:
				 * Simply deleting the existing store:
				 [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]

				 * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
				 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

				 Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.

				 */
				NSLog(@"Unresolved error %@, %@", *error, [*error userInfo]);
				abort();
			}
		} // end @synchronized
	}

	return persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Application's Documents directory
-(NSString *)storePath {
	return [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[self databaseName]];
}

-(NSURL *)storeURL {
	return [NSURL fileURLWithPath:[self storePath]];
}

-(NSString *)databaseName {
    return [NSString stringWithFormat:@"%@.sqlite", [self.modelName lowercaseString]];
}

-(NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

-(NSString *)applicationCachesDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
}

@end