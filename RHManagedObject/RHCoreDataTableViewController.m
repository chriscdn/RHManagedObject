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

@interface RHCoreDataTableViewController()

@property (nonatomic, assign, getter = isSearching) BOOL searching;

@end

@implementation RHCoreDataTableViewController
@synthesize fetchedResultsController;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willMassUpdateNotificationReceived:)
                                                     name:RHWillMassUpdateNotification
                                                   object:nil];
        [self resetMassUpdate];
        [self setEnableSectionIndex:NO];
        [self setSearching:NO];

    }
    
    return self;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

}

-(void)addSearchBarWithPlaceHolder:(NSString *)placeholder {
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    // self.searchController.searchBar.showsScopeBar = NO;
    // self.searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"ScopeButtonCountry",@"Country")];
    
    // required to render correctly
    self.searchController.searchBar.scopeButtonTitles = @[];
    
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = placeholder;
    self.definesPresentationContext = YES;
    
    [self.tableView setTableHeaderView:self.searchController.searchBar];
    
    // needed?
    // [self.searchController.searchBar sizeToFit];
}

/*
 -(void)removeSearchBar {
	self.searchController = nil;
	[self.tableView setTableHeaderView:nil];
 }
 */

#pragma mark -
#pragma mark UISearchBarDelegate
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self setSearching:NO];
    [self setSearchString:nil];
    
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark UISearchResultsUpdating (delegate)
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    [self setSearchString:searchString];
    [self reload];
}

#pragma mark -
#pragma mark UISearchControllerDelegate





#pragma mark -
-(void)setSearchString:(NSString *)searchString {
    if (_searchString == searchString) {
        // do nothing
    } else if ([searchString length] == 0) {
        _searchString = nil;
    } else {
        _searchString = searchString;
    }
}

/*
 -(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
 [self updateSearchResultsForSearchController:self.searchController];
 }
 */

#pragma mark -
-(void)reload {
    [self setFetchedResultsController:nil];
    [self.tableView reloadData];
}

#pragma mark -
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

-(NSPredicate *)predicate {
    NSLog(@"Implement fetchedResultsController in subclass.");
    abort();
}

-(NSFetchedResultsController *)fetchedResultsController {
    NSLog(@"Implement fetchedResultsController in subclass.");
    abort();
    
    /*
     if (fetchedResultsController == nil) {
     NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"field1" ascending:NO];
     NSSortDescriptor *sort2 = [[NSSortDescriptor alloc] initWithKey:@"field2" ascending:NO];
     
     NSPredicate *predicate = [self predicate];
     
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
    NSLog(@"Implement configureCell:atIndexPath: in subclass.");
    abort();
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Implement tableView:cellForRowAtIndexPath: in subclass.");
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
    
    /*
     if (self.searchString == nil) {
     id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
     return [sectionInfo name];
     }
     return nil;
     */
}


#pragma mark -
#pragma mark Core Data
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
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
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
    
    if ( self.enableSectionIndex && (self.searchString == nil) ) {
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
    
    return nil;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end