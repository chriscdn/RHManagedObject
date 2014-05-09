# RHManagedObject

RHManagedObject is a library for iOS to simplify your life with Core Data.  It was motivated by the following:

- Core Data is verbose.  Have a look at [Listing 1](http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreData/Articles/cdFetching.html) from the Apple Documentation and you'll see it takes ~14 lines of code for a single fetch request. RHManagedObject reduces this to a single line.

- Each managed object has an object context associated with it, and for some operations you must first fetch the object context in order to operate on the object. For example:
	
		NSManagedObjectContext *moc = [myManagedObject managedObjectContext];
		[moc deleteObject:myManagedObject];
	
	This is more verbose than necessary since it introduces the object context when its existence is implied by the managed object. RHManagedObject simplifies the above code to:

		[myManagedObject delete];
		
- Core Data is not thread safe. If you wish to mutate your objects off the main thread you need to create a managed object context in that thread, attach a `NSManagedObjectContextDidSaveNotification` notification to it, and merge the context into the main object context in an observer method on the main thread.  Bleh.  RHManagedObject does this for you so that you can work with your objects in any thread without having to think about this.

- A common Core Data design pattern is to pass the managed object context between each `UIViewController` that requires it.  This gets cumbersome to maintain, so RHManagedObject puts all the Core Data boilerplate code into a singleton, which becomes accessible from anywhere in your code.  Best of all, the singleton encapsulates the entire `NSManagedObjectContext` lifecycle for you: constructing, merging, and saving (even in a multi-threaded app) such that you never need to interact with `NSManagedObjectContext` directly.  RHManagedObject lets you focus on your objects with simple methods to fetch, modify, and save without having to think about `NSManagedObjectContext`.

- The generated managed object classes leave little room to add additional methods. You can't (or shouldn't) add extra methods to the generated classes since they will be overwritten when the classes are regenerated. RHManagedObject provides a place for additional class and instance methods.

- Managing multiple models becomes tricky with the standard Core Data design pattern.  RHManagedObject (since v0.7) supports multiple models to make this simple and transparent.

## Upgrading

After some review and discussion with users of the library, I decided to accept a pull request that added stronger error handling to most methods in the RHManagedObject class. In order to keep things consistent and enforce better programming practices, I decided to remove the old methods that do not return errors. This will cause errors in your project until you port your method calls to the new syntax. However, if you are lazy like me, you can use the included `RHManagedObject+legacy.h` category to get the old interface back.

## Overview

This brief overview assumes you have some experience with Core Data.

A typical Core Data "Employee" entity (say, with attributes `firstName` and `lastName`) has an inheritance hierarchy of:

	NSObject :: NSManagedObject :: EmployeeEntity

RHManagedObject changes this to:

	NSObject :: NSManagedObject :: RHManagedObject :: EmployeeEntity :: Employee
	
You'll notice that the `RHManagedObject` and `Employee` classes have been added to the hierarchy. The `RHManagedObject` class adds generic methods (i.e., not specific to your model) that simplifies interacting with Core Data. Its main features are:

- It manages the object context.
- It adds easier methods for fetching, creating, cloning, and deleting managed objects.
- It provides a simplified interface for saving the context, and works the same regardless from which thread it's called.

For example, the `+newEntityWithError:` method introduced in RHManagedObject lets you create a new managed object with a single line:

	Employee *newEmployee = [Employee newEntityWithError:&error];

Fetching all employees with first name "John" is also a single line:

	NSArray *employees = [Employee fetchWithPredicate:[NSPredicate predicateWithFormat:@"firstName=%@", @"John"] error:&error];

The `-delete` method lets you delete an existing managed object:

	[firedEmployee delete];

Changes can be saved with the `+commit` method, which will handle the merging of contexts from the different threads. In other words, you can call `+commit` from your thread and forget about it:

	[Employee commit];

You'll notice that none of these examples require direct use of an `NSManagedObjectContext` instance. That's handled for you within the library. Of course, a method is available to fetch the object context for the current thread if it's required:

	NSManagedObjectContext *moc = [Employee managedObjectContextForCurrentThreadWithError:&error];

## How To Get Started

- [Download RHManagedObject](https://github.com/chriscdn/RHManagedObject/zipball/master).
- Copy `RHManagedObject.h`, `RHManagedObject.m`, `RHManagedObjectContextManager.h`, and `RHManagedObjectContextManager.m` into your project.
- Include the CoreData framework in your project.

If you're using [Cocoapods](http://cocoapods.org/) you can just include RHManagedObject in your Podfile:

	pod 'RHManagedObject'

## Setup

Recall the new object hierarchy from the overview:

	NSObject :: NSManagedObject :: RHManagedObject :: EmployeeEntity :: Employee

Your entity class (e.g., EmployeeEntity) is generated by XCode as usual (CMD-N, NSManagedObject subclass, etc.).  However, there are a few manual tasks before and after generation.

- Before generation you must ensure the `Class` setting on your entity is set to the entity name.  That is, open the `xcdatamodeld` in XCode, select the entity, and set the `Class` property (at the right) to the entity name. In the employee example this would be `EmployeeEntity`.  Repeat for each entity to be generated.
- After your entity classes have been generated you must go back to the `xcdatamodeld` and change the `Class` property to your entity subclass.  In the employee example this would be `Employee`.
- The generated classes must be modified to inherit from `RHManagedObject` instead of `NSManagedObject`.  It's a small hack, but only requires changing two lines of code (if anyone has an easier way of doing this then please let me know).
- The entity subclass (e.g., `Employee`) is created by normal means and is just a normal subclass, but requires a method to identify to which model it belongs. This is  used by the `RHManagedObject` superclass and looks like the following in the `Employee` example:

		@implementation Employee
		
		// This returns the name of your xcdatamodeld model, without the extension
		+(NSString *)modelName {
			return @"SimplifiedCoreDataExample";
		}
		
		@end
		
	However, it's also the place where additional methods can be added without disrupting the generated entity class. For example:
		
		-(NSString *)fullName {
			return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
		}

## Other Features

<!-- The library also contains a singleton class called `RHManagedObjectContextManager`, which contains the Core Data boilerplate code that's normally found in the AppDelegate. It also handles the managed object contexts among the different threads, and the merging of contexts when saving. You'll likely never need to use this class directly. -->

### Populate Store on First Launch

The library contains code to populate the store on first launch. This was motivated by the [CoreDataBooks example](http://developer.apple.com/library/ios/#samplecode/CoreDataBooks/Introduction/Intro.html), and all you have to do is copy the sqlite file generated by the simulator into your project. The library takes care of the rest.

### Automatic Reference Counting (ARC)

The library uses Automatic Reference Counting (ARC).

### Lightweight Migration

If possible, RHManagedObject will automatically perform a [Lightweight Migration](http://developer.apple.com/library/ios/#documentation/cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html) to altered models.  If you wish to block the interface or perform other operations when a migration occurs, you can call the RHManagedObject `+doesRequireMigration` method from the `-application:didFinishLaunchingWithOptions:` method of your AppDelegate to see if a migration is pending.  This must be done before executing anything else that requires Core Data.

[Click here for my blog post on performing a Core Data Migration.](http://schwiiz.org/?p=1734)

### RHCoreDataTableViewController

RHCoreDataTableViewController is a `UITableViewController` subclass that simplifies the use of `NSFetchedResultsController`.  It contains most of the boilerplate code required for the different delegates, but also:

* handles large updates by calling `[tableView reloadData]` instead of `-controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:newIndexPath` for each changed object when a large number of changes are pending (currently set to 10 or more);
* provides methods to add and manage a search bar (see sample project for usage); and
* automatically manages the insertion and deletion of rows and sections.

You can use the class by subclassing RHCoreDataTableViewController (instead of UITableViewController) and by implementing the following methods:

* `-fetchedResultsController`
* `-tableView:cellForRowAtIndexPath:`
* `configureCell:atIndexPath:`

An example of how this works can be found in the `ExampleTableViewController.m` file in the sample project.

<!-- ### Mass Update Notification -->

### RHFetchedResultsManager

This class is useful for quickly applying an `NSFetchedResultsController` to a `UITableView` using an RHManagedObject as the data source. It uses blocks to handle the `UITableView` lifecycle.

(documentation pending)

### RHDidUpdateBlock

The `RHManagedObject` subclass has a block that is excuted when the object is updated.  It gets fired on the main thread by a save notification, and is useful for updating a `UIView` that may depend on the object.  For example:

	__weak UIViewController *bself = self;

	[self.employee setDidUpdateBlock:^{
		[bself.view setNeedsLayout];
	}];

### RHCoreDataCollectionViewController

RHCoreDataCollectionViewController is a `UICollectionViewController` subclass with a similar motivation as RHCoreDataTableViewController.  It implements the `NSFetchedResultsControllerDelegate` delegate and requires the following methods to be implemented in your subclass:

* `-fetchedResultsController`
* `-collectionView:cellForItemAtIndexPath:`

The code is based on [Ash Furrow's UICollectionView-NSFetchedResultsController](https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController), but has been modified to fit this library.

### Thread Containment

RHManagedObject still uses the older style thread confinement pattern to manage contexts in different threads.  A beta has been developed to work with nested contexts, but deadlocks in iOS 5.1 has put the approach on hold.  You can read about the deadlocking issue [here](http://wbyoung.tumblr.com/post/27851725562/core-data-growing-pains).

## Examples

Once you have setup RHManagedObject it becomes easier to do common tasks.  Here are some examples.

### Add a new employee

	Employee *employee = [Employee newEntityWithError:&error];
	[employee setFirstName:@"John"];
	[employee setLastName:@"Doe"];
	[Employee commit];

### Fetch all employees

	NSArray *allEmployees = [Employee fetchAllWithError:&error];

### Fetch all employees with first name "John"

	NSArray *employees = [Employee fetchWithPredicate:[NSPredicate predicateWithFormat:@"firstName=%@", @"John"] error:&error];

### Fetch all employees with first name "John" sorted by last name

	NSArray *employees = [Employee fetchWithPredicate:[NSPredicate predicateWithFormat:@"firstName=%@", @"John"] sortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES] error:&error];

### Get a specific employee record

The `+getWithPredicate:` method will return the first object if more than one is found.

	Employee *employee = [Employee getWithPredicate:[NSPredicate predicateWithFormat:@"employeeID=%i", 12345] error:&error];

### Count the total number of employees

	NSUInteger employeeCount = [Employee countWithError:&error];

### Count the total number of employees with first name "John"

	NSUInteger employeeCount = [Employee countWithPredicate:[NSPredicate predicateWithFormat:@"firstName=%@", @"John"] error:&error];

### Get all the unique first names

	NSArray *uniqueFirstNames = [Employee distinctValuesWithAttribute:@"firstName" withPredicate:nil error:&error];

### Get the average age of all employees

	NSNumber *averageAge = [Employee aggregateWithType:RHAggregateAverage key:@"age" predicate:nil defaultValue:nil error:&error];

### Fire all employees

	[Employee deleteAllWithError:&error];

### Fire a single employee

	Employee *employee = [Employee get ...];
	[employee delete];

### Commit changes

This must be called in the same thread where the changes to your objects were made.

	NSError *error = [Employee commit];

### Completely destroy the Employee model (i.e., delete the .sqlite file)

This is useful to reset your Core Data store after making changes to your model.

	NSError *error = [Employee deleteStore];

### Get an object instance in another thread

Core Data doesn't allow managed objects to be passed between threads.  However you can generate a new object in a separate thread that's valid for that thread.  Here's an example using the `-objectInCurrentThreadContext` method:

	Employee *employee = [Employee getWithPredicate:[NSPredicate predicateWithFormat:@"employeID=%i", 12345] error:&error];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		// employee is not valid in this thread, so we fetch one that is:
		Employee *employee2  = [employee objectInCurrentThreadContext];
		
		// do something with employee2	
		
		[Employee commit];
	});

## I'm stuck.  Help!

Check out the included SimplifiedCoreDataExample for a working example.  You can also contact me if you have any questions or comments.

## Where is this being used?

RHManagedObject is being used with:

- [TrackMyTour.com](http://trackmytour.com/) - Travel Sharing for iPhone and iPad
- [Warmshowers.org](http://warmshowers.org/) - Hospitality for Touring Cyclists
- [PubQuest.com](http://pubquest.com/) - Find Craft Breweries

Contact me if you'd like your app to be listed.

## Contact

Are you using RHManagedObject in your project?  I'd love to hear from you!

profile: [Christopher Meyer](https://github.com/chriscdn)  
e-mail: [chris@schwiiz.org](mailto:chris@schwiiz.org)  
twitter: [@chriscdn](http://twitter.com/chriscdn)  
blog: [schwiiz.org](http://schwiiz.org/)

## License
RHManagedObject is available under the MIT license. See the LICENSE file for more info.