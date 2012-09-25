# RHManagedObject

RHManagedObject is a simplified library for Core Data on iOS.  It was motivated by the following:

- Core Data is verbose.  Have a look at [Listing 1](http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreData/Articles/cdFetching.html) from the Apple Documentation and you'll see it takes ~14 lines of code for a single fetch request.  `RHManagedObject` can reduce this to 1 line of code.
- Core Data is not thread safe. If you wish to interact with your objects off the main thread you need to create a separate object context, attach a `NSManagedObjectContextDidSaveNotification` notification to it, and merge the context into the observer method on the main thread when performing a save.  `RHManagedObject` does all of this for you so that you can work with your objects transparently in any thread.  
- Each managed object has an object context associated with it, and for some operations you must first fetch the object context in order to operate on the object. For example,
``` objective-c
NSManagedObjectContext *moc = [myManagedObject managedObjectContext];
[moc deleteObject:myManagedObject];
```
This is more verbose than necessary since it introduces the moc when its existence is implied by the managed object. `RHManagedObject` replaces the above code with:
``` objective-c
[myManagedObject delete];
```
