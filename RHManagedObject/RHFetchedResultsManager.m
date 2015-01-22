//
//  RHFetchedResultsManager.m
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

#import "RHFetchedResultsManager.h"
#import "RHManagedObject.h"

@interface RHFetchedResultsManager()
@end

@implementation RHFetchedResultsManager

-(id)initWithTableView:(UITableView *)tableView
		   entityClass:(NSString *)entityClass
			 predicate:(NSPredicate *)predicate
		sortDescriptor:(NSSortDescriptor *)sortDescriptor
			 cellBlock:(RHCellBlock)cellBlock
		configureBlock:(RHCellConfigureBlock)configureBlock
	didSelectCellBlock:(RHDidSelectCellBlock)didSelectCellBlock {

	if (self=[super init]) {
		self.tableView = tableView;
		self.entityClass = entityClass;
		self.predicate = predicate;
		self.sortDescriptor = sortDescriptor;
		self.cellBlock = cellBlock;
		self.configureBlock = configureBlock;
		self.didSelectCellBlock = didSelectCellBlock;
		self.tableView.dataSource = self;
		self.tableView.delegate = self;
		self.deleteButtonText = NSLocalizedString(@"Delete", nil);
	}

	return self;
}

-(id)objectAtIndexPath:(NSIndexPath *)indexPath {
	return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

-(void)reload {
	[self setFetchedResultsController:nil];
	[self.tableView reloadData];
}

-(NSFetchedResultsController *)fetchedResultsController {

	if (_fetchedResultsController == nil) {

		Class classFromString = NSClassFromString(self.entityClass);

		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:[classFromString entityDescriptionWithError:nil]];
		[fetchRequest setPredicate:self.predicate];
		[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:self.sortDescriptor, nil]];

		self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:[classFromString managedObjectContextForCurrentThreadWithError:nil]
																			  sectionNameKeyPath:self.sectionNameKeyPath
																					   cacheName:nil];
		// _fetchedResultsController.delegate = self;

		NSError *error = nil;

		if (![_fetchedResultsController performFetch:&error]) {
			NSLog(@"Unresolved error: %@", [error localizedDescription]);
		}
	}

	return _fetchedResultsController;
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

	if (self.didSelectCellBlock == nil) {
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}

	self.configureBlock(cell, self.fetchedResultsController, indexPath);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = self.cellBlock(self.tableView, indexPath);
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.didSelectCellBlock) {
		self.didSelectCellBlock(self.fetchedResultsController, indexPath);
	}
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.willDisplayCellBlock) {
		self.willDisplayCellBlock(tableView, cell, indexPath);
	}
}


#pragma mark -
-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.deleteButtonText;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return (self.deleteActionCellBlock != nil);
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		self.deleteActionCellBlock(self.fetchedResultsController, indexPath);
	}
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
	if (self.titleForHeaderInSectionBlock) {
		return self.titleForHeaderInSectionBlock(section);
	} else {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo name];
	}
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.heightForCellBlock) {
		return self.heightForCellBlock(tableView, self.fetchedResultsController, indexPath);
	}

	return 44;
}

#pragma mark -
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

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
	[self.tableView endUpdates];
}

@end