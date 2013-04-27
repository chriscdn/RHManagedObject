//
//  RHManagedObjectContextManager.h
//  Version: 0.8.12
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

@interface RHManagedObjectContextManager : NSObject

+(RHManagedObjectContextManager *)sharedInstanceWithModelName:(NSString *)modelName;
-(id)initWithModelName:(NSString *)_modelName;
-(NSManagedObjectContext *)managedObjectContextForCurrentThread;
-(void)deleteStore;
-(void)commit;
-(NSUInteger)pendingChangesCount;
-(BOOL)doesRequireMigration;
-(NSString *)applicationDocumentsDirectory;

@end