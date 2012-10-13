//
//  ExampleTableViewController.m
//  SimplifiedCoreDataExample
//
//  Created by Christopher Meyer on 8/13/12.
//
//

#import "ExampleTableViewController.h"
#import "Employee.h"

@implementation ExampleTableViewController


-(void)viewDidLoad {
	[super viewDidLoad];
    
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRandomEmployee:)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];
    
    [self addSearchBarWithPlaceHolder:@"Filter"];
	
}

-(void)addRandomEmployee:(id)sender {
	
	NSArray *firstNames = [NSArray arrayWithObjects:@"Steve", @"Caroline", @"Neal", @"Jean", @"Sandy", @"Claire", @"Tim", @"Malcolm", nil];
	NSArray *lastNames = [NSArray arrayWithObjects:@"James", @"Bowman", @"Sinclair", @"Hamilton", @"Vick", @"Johnston", @"Walton", @"Solomon", @"Melton", @"Hoyle", nil];
	
	NSUInteger randomFirstName = arc4random() % [firstNames count];
	NSUInteger randomLastName = arc4random() % [lastNames count];
	
	Employee *newEmployee = (Employee *)[Employee newEntity];
	newEmployee.firstName = [firstNames objectAtIndex:randomFirstName];
	newEmployee.lastName = [lastNames objectAtIndex:randomLastName];
	
	[Employee commit];
	
}


-(NSFetchedResultsController *)fetchedResultsController {
	if (fetchedResultsController == nil) {
		NSSortDescriptor *sort1 = [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:YES];
		
		NSPredicate *predicate;
		
        if (self.searchString) {
            predicate = [NSPredicate predicateWithFormat:@"firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", self.searchString, self.searchString];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"1==1"];
        }
        
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[Employee entityDescription]];
		
		[fetchRequest setPredicate:predicate];
		[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort1, nil]];
		[fetchRequest setFetchBatchSize:20];
		
		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:[Employee managedObjectContextForCurrentThread]
																			  sectionNameKeyPath:nil
																					   cacheName:nil];
		
		fetchedResultsController.delegate = self;
		
		[sort1 release];
		
		[fetchRequest release];
		[fetchedResultsController release];
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error]) {
			NSLog(@"Unresolved error: %@", [error localizedDescription]);
		}
    }
	
	return fetchedResultsController;
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	
	Employee *employee = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", employee.firstName, employee.lastName];
    
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"EmployeeCell";
	
	UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
    
	[self configureCell:cell atIndexPath:indexPath];

	return cell;
}

-(NSString *)tableView:(UITableView *)_tableView titleForFooterInSection:(NSInteger)section {
	if (_tableView == self.tableView) {
        return @"Press the plus button to create a random employee.  See\n\n-(void)addRandomEmployee:(id)sender\n\nin\n\nExampleTableViewController.m";
    } else {
        return @""; // search tableview
    }
}

@end