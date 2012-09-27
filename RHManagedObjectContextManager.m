//
//  RHManagedObjectContextManager.m
//  Version: 0.7.1
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

@implementation RHManagedObjectContextManager
@synthesize managedObjectContexts;
@synthesize managedObjectContext, managedObjectModel, persistentStoreCoordinator;
@synthesize modelName;

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

-(NSString *)databaseName {
    return [NSString stringWithFormat:@"%@.sqlite", [self.modelName lowercaseString]];
}

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
	
	self.managedObjectContexts = nil;
	self.managedObjectContext = nil;
	self.managedObjectModel = nil;
	self.persistentStoreCoordinator = nil;
	
	[[RHManagedObjectContextManager sharedInstances] removeObjectForKey:[self modelName]];
}

-(NSMutableDictionary *)managedObjectContexts {
	if (managedObjectContexts == nil) {
		self.managedObjectContexts = [NSMutableDictionary dictionary];
	}
	return managedObjectContexts;
}

-(NSUInteger)pendingChangesCount {
	NSManagedObjectContext *moc = [self managedObjectContext];
	
	NSSet *updated  = [moc updatedObjects];
	NSSet *deleted  = [moc deletedObjects];
	NSSet *inserted = [moc insertedObjects];
	
	return [updated count] + [deleted count] + [inserted count];
}

// Do I need to lock the context?
// http://stackoverflow.com/questions/5236860/app-freeze-on-coredata-save
-(void)commit {
	
 	NSManagedObjectContext *moc = [self managedObjectContext];
	NSError *error = nil;
    
	if ([self pendingChangesCount] > kPostMassUpdateNotificationThreshold) {
        //		dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:WillMassUpdateNotificationName object:nil];
        //		});
	}
	
	if ([moc hasChanges] && ![moc save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	
	// Is this safe to do here?  Probably... I think the moc will still have a retain within the NSNotification
	// and will be gracefully trashed once mocDidSave: is called.
	[self discardManagedObjectContext];
}

// This is the NSManagedObjectContextDidSaveNotification delegate method.  It gets called when a commit is applied
// on a thread other than the MainThread.
-(void)mocDidSave:(NSNotification *)saveNotification {
    if ([NSThread isMainThread]) {
		// This ensures no updated object is fault, which would cause the NSFetchedResultsController updates to fail.
		// http://www.mlsite.net/blog/?p=518
		
		NSArray* updates = [[saveNotification.userInfo objectForKey:@"updated"] allObjects];
		
		for (NSInteger i = [updates count]-1; i >= 0; i--) {
			[[[self managedObjectContext] objectWithID:[[updates objectAtIndex:i] objectID]] willAccessValueForKey:nil];
		}
		
        [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:saveNotification];
    } else {
        [self performSelectorOnMainThread:@selector(mocDidSave:) withObject:saveNotification waitUntilDone:NO];
    }
}


-(NSManagedObjectContext *)managedObjectContext {
    NSThread *thread = [NSThread currentThread];
	
    if ([thread isMainThread]) {
        return [self mainThreadManagedObjectContext];
    }
	
    // a key to cache the moc for the current thread
    NSString *threadKey = [NSString stringWithFormat:@"%p", thread];
	
    if ( [self.managedObjectContexts objectForKey:threadKey] == nil ) {
		// create a moc for this thread
        NSManagedObjectContext *threadContext = [[[NSManagedObjectContext alloc] init] autorelease];
        [threadContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
		[threadContext setMergePolicy:kMergePolicy];
		
        // cache the moc for this thread
        [self.managedObjectContexts setObject:threadContext forKey:threadKey];
		
		// attach a notification thingie
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mocDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:threadContext];
    }
	
    return [self.managedObjectContexts objectForKey:threadKey];
}

-(void)discardManagedObjectContext {
	NSString *threadKey = [NSString stringWithFormat:@"%p", [NSThread currentThread]];
	NSManagedObjectContext *threadContext = [self.managedObjectContexts objectForKey:threadKey];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:threadContext];
	[self.managedObjectContexts removeObjectForKey:threadKey];
}

#pragma mark -
#pragma mark Core Data stack
// This stuff is more or less what's automatically generated when creating a new project.

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
-(NSManagedObjectContext *)mainThreadManagedObjectContext {
	if (managedObjectContext == nil) {
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			self.managedObjectContext = [[[NSManagedObjectContext alloc] init] autorelease];
			[managedObjectContext setPersistentStoreCoordinator:coordinator];
			[managedObjectContext setMergePolicy:kMergePolicy];
			
			// http://stackoverflow.com/questions/4817416/why-am-i-getting-a-merge-error-when-saving-an-nsmanagedobjectcontext-this-clean
			// [managedObjectContext setStalenessInterval:0.0];
		}
	}
	
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
-(NSManagedObjectModel *)managedObjectModel {
	if (managedObjectModel == nil) {
		NSString *modelPath = [[NSBundle mainBundle] pathForResource:self.modelName ofType:@"momd"];
		NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
		
		self.managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
	}
	
	return managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
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
		
		NSURL *storeURL = [NSURL fileURLWithPath:storePath];
		NSError *error = nil;
		
		self.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]] autorelease];
		
		if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
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



#pragma mark -
#pragma mark Application's Documents directory
-(NSString *)storePath {
	return [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[self databaseName]];
}

/**
 Returns the URL to the application's Documents directory.
 */
-(NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end