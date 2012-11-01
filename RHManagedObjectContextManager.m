//
//  RHManagedObjectContextManager.m
//  Version: 0.9
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

#import "RHManagedObjectContextManager.h"

@interface RHManagedObjectContextManager()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContextBackground;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContextForMainThread;
@property (nonatomic, strong) NSMutableDictionary *managedObjectContexts;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSString *modelName;

+(NSMutableDictionary *)sharedInstances;
-(void)discardManagedObjectContext;
-(NSString *)storePath;
-(NSURL *)storeURL;
-(NSString *)databaseName;
-(void)backgroundMocDidSave:(NSNotification *)saveNotification;
@end

@implementation RHManagedObjectContextManager
@synthesize managedObjectContextBackground;
@synthesize managedObjectContextForMainThread;
@synthesize managedObjectContexts;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;
@synthesize modelName;

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
    dispatch_once(&once, ^ {
        sharedInstances = [[NSMutableDictionary alloc] init];
    });
    return sharedInstances;
}

-(id)initWithModelName:(NSString *)_modelName {
    if (self=[super init]) {
        self.modelName = _modelName;
    }
    return self;
}

-(NSMutableDictionary *)managedObjectContexts {
	if (managedObjectContexts == nil) {
		self.managedObjectContexts = [NSMutableDictionary dictionary];
	}
	return managedObjectContexts;
}

#pragma mark -
#pragma mark Other useful stuff
// Used to flush and reset the database.
-(void)deleteStore {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error;
	
	if (persistentStoreCoordinator == nil) {
		NSString *storePath = [self storePath];
		
		if ([fm fileExistsAtPath:storePath] && [fm isDeletableFileAtPath:storePath]) {
			[fm removeItemAtPath:storePath error:&error];
		}
		
	} else {
		NSPersistentStoreCoordinator *storeCoordinator = [self persistentStoreCoordinator];
		
		for (NSPersistentStore *store in [storeCoordinator persistentStores]) {
			NSURL *storeURL = store.URL;
			NSString *storePath = storeURL.path;
			[storeCoordinator removePersistentStore:store error:&error];
			
			if ([fm fileExistsAtPath:storePath] && [fm isDeletableFileAtPath:storePath]) {
				[fm removeItemAtPath:storePath error:&error];
			}
		}
	}
	
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContextBackground];
		
	self.managedObjectContextBackground = nil;
	self.managedObjectContextForMainThread = nil;
	self.managedObjectContexts = nil;
	self.managedObjectModel = nil;
	self.persistentStoreCoordinator = nil;
	
	[[RHManagedObjectContextManager sharedInstances] removeObjectForKey:[self modelName]];
}

-(NSUInteger)pendingChangesCount {
	NSManagedObjectContext *moc = [self managedObjectContextForCurrentThread];
	
	NSSet *updated  = [moc updatedObjects];
	NSSet *deleted  = [moc deletedObjects];
	NSSet *inserted = [moc insertedObjects];
	
	return [updated count] + [deleted count] + [inserted count];
}

// http://stackoverflow.com/questions/5236860/app-freeze-on-coredata-save
-(void)commit {
	
 	NSManagedObjectContext *moc = [self managedObjectContextForCurrentThread];
	NSError *error = nil;
	
	if ([self pendingChangesCount] > kPostMassUpdateNotificationThreshold) {
		[[NSNotificationCenter defaultCenter] postNotificationName:RHWillMassUpdateNotification object:nil];
	}
	
	if ([moc hasChanges] && ![moc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	
	NSManagedObjectContext *parentContext = [moc parentContext];
	
	[parentContext performBlock:^{
		NSError *error = nil;
		
		if (![parentContext save:&error])			{
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}];
	
	[self discardManagedObjectContext];
}

#pragma mark -
#pragma mark Core Data stack

-(NSManagedObjectContext *)managedObjectContextBackground {
	if (managedObjectContextBackground == nil) {
		self.managedObjectContextBackground = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[managedObjectContextBackground setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
		[managedObjectContextBackground setMergePolicy:kMergePolicy];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(backgroundMocDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:managedObjectContextBackground];
		
	}
	
	return managedObjectContextBackground;
}

-(NSManagedObjectContext *)managedObjectContextForMainThread {
	if (managedObjectContextForMainThread == nil) {
		// NSAssert([NSThread isMainThread], @"Construction may only happen on the main thread!");
		self.managedObjectContextForMainThread = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
		[managedObjectContextForMainThread setParentContext:[self managedObjectContextBackground]];
	}
	
	return managedObjectContextForMainThread;
}

-(NSManagedObjectContext *)managedObjectContextForCurrentThread {
	NSThread *thread = [NSThread currentThread];
	
	if ([thread isMainThread]) {
		return [self managedObjectContextForMainThread];
	} else if (managedObjectContextForMainThread == nil) {
		// YES, this is necessary.
		dispatch_sync(dispatch_get_main_queue(),^{
			[self managedObjectContextForCurrentThread];
		});
	}
	
	
	// a key to cache the moc for the current thread
	NSString *threadKey = [NSString stringWithFormat:@"%p", thread];
	
	@synchronized(self) {
		if ( [self.managedObjectContexts objectForKey:threadKey] == nil ) {
			// create a moc for this thread
			NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
			[threadContext setParentContext:[self managedObjectContextBackground]];
			[self.managedObjectContexts setObject:threadContext forKey:threadKey];
		}
	}
	
	return [self.managedObjectContexts objectForKey:threadKey];
}

-(void)discardManagedObjectContext {
	NSString *threadKey = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
	[self.managedObjectContexts removeObjectForKey:threadKey];
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

/**
 * Returns the persistent store coordinator for the application.
 * If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
-(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
	if (persistentStoreCoordinator == nil) {
		
		// This next block is useful when the store is initialized for the first time.  If the DB doesn't already
		// exist and a copy of the db (with the same name) exists in the bundle, it'll be copied over and used.  This
		// is useful for the initial seeding of data in the app.
		NSString *storePath = [self storePath];
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		if (![fileManager fileExistsAtPath:storePath]) {
			NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:[self databaseName] ofType:nil];
			
			if ([fileManager fileExistsAtPath:defaultStorePath]) {
				[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
			}
		}
		
		NSURL *storeURL = [self storeURL];
		NSError *error = nil;
		
		self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		
		// https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html#//apple_ref/doc/uid/TP40004399-CH4-SW1
		NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
								 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
		
		if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
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
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}
	
	return persistentStoreCoordinator;
}

-(void)backgroundMocDidSave:(NSNotification *)saveNotification {
	
	NSManagedObjectContext *moc = [self managedObjectContextForMainThread];
	
	/*
	 // This ensures no updated object is fault, which would cause the NSFetchedResultsController updates to fail.
	 // http://www.mlsite.net/blog/?p=518
	 NSArray* updates = [[saveNotification.userInfo objectForKey:@"updated"] allObjects];
	 for (NSInteger i = [updates count]-1; i >= 0; i--) {
	 [[[self managedObjectContextForMainThread] objectWithID:[[updates objectAtIndex:i] objectID]] willAccessValueForKey:nil];
	 }
	 */
	
	[moc performBlock:^{
		[moc mergeChangesFromContextDidSaveNotification:saveNotification];
	}];
}

-(BOOL)doesRequireMigration {
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self storePath]]) {
		NSError *error;
		NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:[self storeURL] error:&error];
		return ![[self managedObjectModel] isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
	} else {
		return NO;
	}
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

@end