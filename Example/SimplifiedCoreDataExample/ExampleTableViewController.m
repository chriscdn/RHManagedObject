//
//  ExampleTableViewController.m
//  SimplifiedCoreDataExample
//
//  Created by Christopher Meyer on 8/13/12.
//
//

#define kCellIdentifier @"EmployeeCell"

#import "ExampleTableViewController.h"
#import "Employee.h"

@implementation ExampleTableViewController

-(void)viewDidLoad {
	[super viewDidLoad];

	[self setTitle:@"Example"];

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRandomEmployee:)];
	self.navigationItem.rightBarButtonItem = button;

    [self addSearchBarWithPlaceHolder:@"Filter"];

	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];

}

-(void)addRandomEmployee:(id)sender {
	NSArray *firstNames = [NSArray arrayWithObjects:@"Steve", @"Caroline", @"Neal", @"Jean", @"Sandy", @"Claire", @"Tim", @"Malcolm", nil];
	NSArray *lastNames = [NSArray arrayWithObjects:@"James", @"Bowman", @"Sinclair", @"Hamilton", @"Vick", @"Johnston", @"Walton", @"Solomon", @"Melton", @"Hoyle", nil];

	NSUInteger randomFirstName = arc4random() % [firstNames count];
	NSUInteger randomLastName = arc4random() % [lastNames count];

	Employee *newEmployee = [Employee newEntityWithError:nil];
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
			// i.e., show all
            predicate = [NSPredicate predicateWithFormat:@"1=1"];
        }

		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[Employee entityDescriptionWithError:nil]];

		[fetchRequest setPredicate:predicate];
		[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sort1, nil]];

		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:[Employee managedObjectContextForCurrentThreadWithError:nil]
																			  sectionNameKeyPath:nil
																					   cacheName:nil];

		fetchedResultsController.delegate = self;

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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	// We must dequeue from self.tableView and not tableView since this method is also used by the search controller
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[[self.fetchedResultsController objectAtIndexPath:indexPath] delete];
		[Employee commit];
	}
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	if (tableView == self.tableView) {
        return @"Press the plus button to create a random employee. Swipe to delete. See\n\n  -addRandomEmployee:\n\nin ExampleTableViewController.m";
    } else {
        return @""; // search tableview
    }
}

@end