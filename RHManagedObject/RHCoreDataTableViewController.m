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

static UITableViewRowAnimation insertRowAnimation = UITableViewRowAnimationAutomatic;
static UITableViewRowAnimation deleteRowAnimation = UITableViewRowAnimationAutomatic;

@interface RHCoreDataTableViewController()

// @property (nonatomic, assign, getter = isSearching) BOOL searching;

@property (nonatomic, strong) NSMutableIndexSet *deletedSectionIndexes;
@property (nonatomic, strong) NSMutableIndexSet *insertedSectionIndexes;
@property (nonatomic, strong) NSMutableArray *deletedRowIndexPaths;
@property (nonatomic, strong) NSMutableArray *insertedRowIndexPaths;
@property (nonatomic, strong) NSMutableArray *updatedRowIndexPaths;

@end

@implementation RHCoreDataTableViewController
@synthesize fetchedResultsController;


+(void)setInsertRowAnimation:(UITableViewRowAnimation)rowAnimation {
    insertRowAnimation = rowAnimation;
}

+(void)setDeleteRowAnimation:(UITableViewRowAnimation)rowAnimation {
    deleteRowAnimation = rowAnimation;
}

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
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    // Setting this to YES causes problems when presenting the search controller in a UINavigationController.
    // Tapping the Back button will not deallocate the controller due to a regain loop (source of loop not clear).
    // By keeping this NO (default) we are forced to close the search controller before hitting the back button.
    // self.searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = placeholder;
    // self.searchController.searchBar.showsScopeBar = YES;
    // self.searchController.searchBar.scopeButtonTitles = @[];
    
    self.definesPresentationContext = YES;
    
    // [self.searchController.searchBar sizeToFit];
    
    [self.tableView setTableHeaderView:self.searchController.searchBar];
}

#pragma mark -
#pragma mark UISearchBarDelegate
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self setSearchString:nil];
    [self.tableView reloadData];
}

-(void)dismissSearchBar {
    [self.searchController setActive:NO];
}

#pragma mark -
#pragma mark UISearchResultsUpdating (delegate)
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    [self setSearchString:searchString];
    [self reload];
}

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

-(NSArray *)sortDescriptors {
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

-(void)configureCell:(UITableViewCell *)cell
         atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Implement configureCell:atIndexPath: in subclass.");
    abort();
}

-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

-(NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
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
    //  [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller
  didChangeObject:(id)anObject
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath {
    
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            if ([self.insertedSectionIndexes containsIndex:newIndexPath.section]) {
                // If we've already been told that we're adding a section for this inserted row we skip it since it will handled by the section insertion.
                return;
            }
            
            [self.insertedRowIndexPaths addObject:newIndexPath];
            
            break;
            
        case NSFetchedResultsChangeDelete:
            if ([self.deletedSectionIndexes containsIndex:indexPath.section]) {
                // If we've already been told that we're deleting a section for this deleted row we skip it since it will handled by the section deletion.
                return;
            }
            
            [self.deletedRowIndexPaths addObject:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            if ([self.insertedSectionIndexes containsIndex:newIndexPath.section] == NO) {
                [self.insertedRowIndexPaths addObject:newIndexPath];
            }
            
            if ([self.deletedSectionIndexes containsIndex:indexPath.section] == NO) {
                [self.deletedRowIndexPaths addObject:indexPath];
            }
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.updatedRowIndexPaths addObject:indexPath];
            break;
        default:
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller
 didChangeSection:(id )sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(NSFetchedResultsChangeType)type {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.insertedSectionIndexes addIndex:sectionIndex];
            break;
        case NSFetchedResultsChangeDelete:
            [self.deletedSectionIndexes addIndex:sectionIndex];
            break;
        default:
            ; // Shouldn't have a default
            break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSInteger totalChanges = [self.deletedSectionIndexes count] +
    [self.insertedSectionIndexes count] + [self.deletedRowIndexPaths count] +
    [self.insertedRowIndexPaths count] + [self.updatedRowIndexPaths count];
    
//    if (totalChanges > 50) {
//        [self.tableView reloadData];
//        return;
//    }
    
    // based on https://gist.github.com/MrRooni/4988922
    
    // iOS11/12 is buggy as hell when inserting and removing sections while changing indexes
    // creates ghosts
    if ((totalChanges > 50) || self.deletedSectionIndexes.count || self.insertedSectionIndexes.count) {
    
        [self.tableView reloadData];
        
    } else {
        
        [self.tableView beginUpdates];
        
        [self.tableView deleteSections:self.deletedSectionIndexes
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView insertSections:self.insertedSectionIndexes
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView deleteRowsAtIndexPaths:self.deletedRowIndexPaths
                              withRowAnimation:UITableViewRowAnimationLeft];
        
        [self.tableView insertRowsAtIndexPaths:self.insertedRowIndexPaths
                              withRowAnimation:UITableViewRowAnimationRight];
        
        [self.tableView reloadRowsAtIndexPaths:self.updatedRowIndexPaths
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        
         [self.tableView endUpdates];
    }
 
    // nil out the collections so their ready for their next use.
    self.insertedSectionIndexes = nil;
    self.deletedSectionIndexes = nil;
    self.deletedRowIndexPaths = nil;
    self.insertedRowIndexPaths = nil;
    self.updatedRowIndexPaths = nil;
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (self.enableSectionIndex && (self.searchString == nil)) {
        return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
    }
    
    return nil;
}

-(NSMutableIndexSet *)deletedSectionIndexes {
    if (_deletedSectionIndexes == nil) {
        _deletedSectionIndexes = [NSMutableIndexSet indexSet];
    }
    
    return _deletedSectionIndexes;
}

-(NSMutableIndexSet *)insertedSectionIndexes {
    if (_insertedSectionIndexes == nil) {
        _insertedSectionIndexes = [NSMutableIndexSet indexSet];
    }
    
    return _insertedSectionIndexes;
}

-(NSMutableArray *)deletedRowIndexPaths {
    if (_deletedRowIndexPaths == nil) {
        _deletedRowIndexPaths = [[NSMutableArray alloc] init];
    }
    
    return _deletedRowIndexPaths;
}

-(NSMutableArray *)insertedRowIndexPaths {
    if (_insertedRowIndexPaths == nil) {
        _insertedRowIndexPaths = [[NSMutableArray alloc] init];
    }
    
    return _insertedRowIndexPaths;
}

-(NSMutableArray *)updatedRowIndexPaths {
    if (_updatedRowIndexPaths == nil) {
        _updatedRowIndexPaths = [[NSMutableArray alloc] init];
    }
    
    return _updatedRowIndexPaths;
}

-(void)dealloc {
    // NSLog(@"%@", @"dealloc - RHCoreDataTableViewController");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // http://stackoverflow.com/questions/32282401/attempting-to-load-the-view-of-a-view-controller-while-it-is-deallocating-uis
    [self.searchController.view removeFromSuperview];
}

@end
