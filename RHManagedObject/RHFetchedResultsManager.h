//
//  RHFetchedResultsManager.h
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

#import <CoreData/CoreData.h>

typedef UITableViewCell *(^RHCellBlock)(UITableView *tableView, NSIndexPath *indexPath);
typedef void (^RHCellConfigureBlock)(UITableViewCell *cell, NSFetchedResultsController *fetchedResultsController, NSIndexPath *indexPath);
typedef void (^RHDidSelectCellBlock)(NSFetchedResultsController *fetchedResultsController, NSIndexPath *indexPath);
typedef void (^RHWillDisplayCellBlock)(UITableView *tableView, UITableViewCell *cell, NSIndexPath *indexPath);
typedef CGFloat (^RHHeightForCellBlock)(UITableView *tableView, NSFetchedResultsController *fetchedResultsController, NSIndexPath *indexPath);
typedef NSString *(^RHTitleForHeaderInSectionBlock)(NSInteger section);
typedef void (^RHDeleteActionCellBlock)(NSFetchedResultsController *fetchedResultsController, NSIndexPath *indexPath);

@interface RHFetchedResultsManager : NSObject<NSFetchedResultsControllerDelegate,UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSString *entityClass;
@property (nonatomic, strong) NSPredicate *predicate;
@property (nonatomic, strong) NSSortDescriptor *sortDescriptor;
@property (nonatomic, strong) NSString *sectionNameKeyPath;
@property (nonatomic, strong) NSString *deleteButtonText;

@property (nonatomic, copy) RHCellBlock cellBlock;
@property (nonatomic, copy) RHCellConfigureBlock configureBlock;
@property (nonatomic, copy) RHDidSelectCellBlock didSelectCellBlock;
@property (nonatomic, copy) RHWillDisplayCellBlock willDisplayCellBlock;
@property (nonatomic, copy) RHHeightForCellBlock heightForCellBlock;
@property (nonatomic, copy) RHTitleForHeaderInSectionBlock titleForHeaderInSectionBlock;
@property (nonatomic, copy) RHDeleteActionCellBlock deleteActionCellBlock;

-(id)initWithTableView:(UITableView *)tableView
		   entityClass:(NSString *)entityClass
			 predicate:(NSPredicate *)predicate
		sortDescriptor:(NSSortDescriptor *)sortDescriptor
			 cellBlock:(RHCellBlock)cellBlock
		configureBlock:(RHCellConfigureBlock)configureBlock
	 didSelectCellBlock:(RHDidSelectCellBlock)didSelectCellBlock;

-(void)reload;

-(id)objectAtIndexPath:(NSIndexPath *)indexPath;

@end