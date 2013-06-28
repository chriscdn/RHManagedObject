//
//  RHCoreDataTableViewController.m
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

#import "RHCoreDataTableViewController.h"
#import "RHManagedObjectContextManager.h"

@implementation RHCoreDataTableViewController
@synthesize fetchedResultsController;
@synthesize massUpdate;
@synthesize enableSectionIndex;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(willMassUpdateNotificationReceived:)
													 name:RHWillMassUpdateNotification
												   object:nil];
		[self resetMassUpdate];
		[self setEnableSectionIndex:NO];
	}
	
	return self;
}

-(void)addSearchBarWithPlaceHolder:(NSString *)placeholder {
	UISearchBar *searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width,44)];
	searchBar.placeholder = placeholder;
	searchBar.delegate = self;
	self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
	self.searchController.delegate = self;
	self.searchController.searchResultsDataSource = self;
	self.searchController.searchResultsDelegate = self;
	self.tableView.tableHeaderView = self.searchController.searchBar;
}


-(BOOL)searchDisplayController:(UISearchDisplayController *)_controller shouldReloadTableForSearchString:(NSString *)_asearchString {
	self.searchString = _asearchString;
	self.fetchedResultsController = nil;
	
	return YES;
}

-(void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
	self.searchString = nil;
	self.fetchedResultsController = nil;
    // is this called automatically? - no, this is required
	[self.tableView reloadData];
}

-(void)willMassUpdateNotificationReceived:(id)notification {
	self.massUpdate = YES;
}

-(void)resetMassUpdate {
	self.massUpdate = NO;
}

-(void)refreshVisibleCells {
	for (UITableViewCell *cell in [self.tableView visibleCells]) {
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
		[self configureCell:cell atIndexPath:indexPath];
	}
}

#pragma mark Abstact classes (implment in sub-class)
-(NSFetchedResultsController *)fetchedResultsController {
	NSLog(@"Implement fetchedResultsController in subclass");
	abort();
	
	/*
	 if (fetchedResultsController == nil) {
	 NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"field1" ascending:NO];
	 NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"field2" ascending:NO];
	 
	 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"1=1"];
	 
	 NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	 [fetchRequest setEntity:[RHManagedObjectSubclass entityDescription]];
	 [fetchRequest setPredicate:predicate];
	 [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort1, sort2, nil]];
	 // [fetchRequest setFetchBatchSize:20];
	 
	 self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
	 managedObjectContext:[RHManagedObjectSubclass managedObjectContextForCurrentThread]
	 sectionNameKeyPath:nil
	 cacheName:nil];
	 
	 fetchedResultsController.delegate = self;
	
	 NSError *error = nil;
	 if (![fetchedResultsController performFetch:&error]) {
	 NSLog(@"Unresolved error: %@", [error localizedDescription]);
	 }
	 
	 }
	 
	 return fetchedResultsController;
	 */
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Implement configureCell:atIndexPath: in subclass");
	abort();
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Implement tableView:cellForRowAtIndexPath: in subclass");
	abort();
	
	/*
	 static NSString *CellIdentifier = @"MyCell";
	 
	 UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	 if (cell == nil) {
	 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	 cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	 }
	 
	 [self configureCell:cell atIndexPath:indexPath];
	 
	 return cell;
	 */
}


#pragma mark -
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

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	if (self.enableSectionIndex) {
		return [self.fetchedResultsController sectionIndexTitles];
	}
	
	return nil;
}

-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end