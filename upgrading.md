# Upgrading Notes

## Upgrading to v0.10

After some review and discussion with users of the library, I decided to accept a pull request that added stronger error handling to most methods in the `RHManagedObject` class.  In order to keep things consistent and enforce better programming practices, I decided to remove the old methods that do not return errors.  This will cause errors in your project until you port your method calls to the new syntax.  However, if you are lazy like me, you can use the included `RHManagedObject+legacy.h` category to get the old interface back.