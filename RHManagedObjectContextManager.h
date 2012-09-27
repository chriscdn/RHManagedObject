//
//  RHManagedObjectContextManager.h
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

#define kMergePolicy NSMergeByPropertyObjectTrumpMergePolicy

#define WillMassUpdateNotificationName @"WillMassUpdateNotificationName"
// If more than kPostMassUpdateNotificationThreshold updates are commited at once, post a WillMassUpdateNotificationName notification first
#define kPostMassUpdateNotificationThreshold 10

// #define kMergePolicy NSErrorMergePolicy

#import <CoreData/CoreData.h>

@interface RHManagedObjectContextManager : NSObject

@property (nonatomic, retain) NSMutableDictionary *managedObjectContexts;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) NSString *modelName;

+(NSMutableDictionary *)sharedInstances;
+(RHManagedObjectContextManager *)sharedInstanceWithModelName:(NSString *)modelName;

-(id)initWithModelName:(NSString *)_modelName;
-(NSManagedObjectContext *)managedObjectContext;
-(void)deleteStore;
-(void)commit;
-(void)discardManagedObjectContext;
-(NSUInteger)pendingChangesCount;

-(NSManagedObjectContext *)mainThreadManagedObjectContext;
-(NSString *)storePath;
-(NSString *)applicationDocumentsDirectory;

@end