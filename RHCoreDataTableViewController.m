//
//  CoreDataTableViewController.m
//
//  Copyright (C) 2012 by Christopher Meyer
//
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

#import "RHCoreDataTableViewController.h"
#import "RHManagedObjectContextManager.h"

@implementation RHCoreDataTableViewController
@synthesize fetchedResultsController;
@synthesize massUpdate;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(willMassUpdateNotificationReceived:) 
													 name:WillMassUpdateNotificationName 
												   object:nil];
		[self resetMassUpdate];
	}
	
	return self;
}

-(void)viewDidLoad {
	[super viewDidLoad];
		
	// workaround for nasty apple bug
	// http://stackoverflow.com/questions/5975019/nsfetchedresultscontroller-numberofobjects-returns-additional-duplicate-when-ru
	// http://blog.engledew.com/post/560601132/duplicate-nsmanagedobject-with
	
	if (self.fetchedResultsController.fetchedObjects == nil) {
		NSError * error = nil;
		if (![self.fetchedResultsController performFetch:&error]) {
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}
	}
}

-(void)willMassUpdateNotificationReceived:(id)notification {
	self.massUpdate = YES;
}

-(void)resetMassUpdate {
	self.massUpdate = NO;
}

#pragma mark Abstact classes (implment in sub-class)
-(NSFetchedResultsController *)fetchedResultsController {
	NSLog(@"Implement fetchedResultsController in subclass");
	abort();
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Implement configureCell:atIndexPath: in subclass");
	abort();
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath { 
	NSLog(@"Implement tableView:cellForRowAtIndexPath: in subclass");
	abort();

	/*
	static NSString *CellIdentifier = @"MapCell";
	
	UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	[self configureCell:cell atIndexPath:indexPath];
	
	return cell;
	*/
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];	
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	if (self.massUpdate) {
		return;
	}

    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	if (self.massUpdate) {
		return;
	}
	
	switch(type) {			
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];			
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	if (self.massUpdate) {
		return;
	}
	
	switch(type) {			
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if (self.massUpdate) {
		[self.tableView reloadData];
		[self resetMassUpdate];
		return;
	}

	// The fetch controller has sent all current change notifications, so tell the table view to process all updates.
	[self.tableView endUpdates];
}


// http://www.raywenderlich.com/999/core-data-tutorial-how-to-use-nsfetchedresultscontroller
-(void)viewDidUnload {
	[super viewDidUnload];
    self.fetchedResultsController = nil;
}

#pragma mark Device Orientation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

-(void)dealloc {	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[fetchedResultsController release];
	[super dealloc];
}

@end