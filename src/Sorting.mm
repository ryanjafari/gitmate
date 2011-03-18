#import "TextMate.h"

@interface GITMateSorting : NSObject {}

+ (BOOL)useSorting;
+ (BOOL)descending;
+ (BOOL)byExtension;
+ (BOOL)foldersOnTop;

+ (void)addProjectController:(id)projectController;
+ (void)removeProjectController:(id)projectController;
+ (NSMutableDictionary*)sortDescriptorForProjectController:(id)projectController;

@end

struct item_sort_descriptor
{
	BOOL ascending;
	BOOL by_extension;
	BOOL folders_on_top;
};

int sort_items(id a, id b, void *context)
{
	item_sort_descriptor *sortDescriptor = (item_sort_descriptor*)context;
	NSString *aText = [a objectForKey:@"displayName"];
	NSString *bText = [b objectForKey:@"displayName"];
	BOOL ignoreExtensions = NO;
    
	if(sortDescriptor->folders_on_top)
	{
		BOOL aIsDir = [a objectForKey:@"children"] != nil;
		BOOL bIsDir = [b objectForKey:@"children"] != nil;
		
		if(aIsDir && bIsDir)
			ignoreExtensions = NO; // Fall through to name sorting but ignore extensions
		else if(aIsDir)
			return NSOrderedAscending;
		else if(bIsDir)
			return NSOrderedDescending;
	}
	
	if(sortDescriptor->by_extension && ! ignoreExtensions)
	{
		aText = [aText pathExtension];
		bText = [bText pathExtension];
	}
	
	int result = [aText caseInsensitiveCompare:bText];
    
	if (not sortDescriptor->ascending)
		result = -result;
	return result;
}

@interface NSMutableArray (RecursiveSort)
- (void)recursiveSortItemsAscending:(BOOL)ascending
                        byExtension:(BOOL)byExtension
                       foldersOnTop:(BOOL)foldersOnTop;
@end


@implementation NSMutableArray (RecursiveSort)
- (void)recursiveSortItemsAscending:(BOOL)ascending
                        byExtension:(BOOL)byExtension
                       foldersOnTop:(BOOL)foldersOnTop
{
	struct item_sort_descriptor sortDescriptor;
    
	sortDescriptor.ascending      = ascending;
	sortDescriptor.by_extension   = byExtension;
	sortDescriptor.folders_on_top = foldersOnTop;
	
	unsigned int itemCount = [self count];
    
	for(unsigned int index = 0; index < itemCount; index += 1)
	{
		id item = [self objectAtIndex:index];
		
		if([item objectForKey:@"children"])
			[[item objectForKey:@"children"] recursiveSortItemsAscending:ascending byExtension:byExtension foldersOnTop:foldersOnTop];
	}
    
	[self sortUsingFunction:sort_items context:&sortDescriptor];
}
@end

@implementation NSWindowController (OakProjectController_Sorting)
- (NSMutableDictionary*)sortDescriptor
{
	return [GITMateSorting sortDescriptorForProjectController:self];
}

- (void)resortItems
{
	NSMutableArray* rootItems = [self valueForKey:@"rootItems"];
	[rootItems recursiveSortItemsAscending:! [[[self sortDescriptor] objectForKey:@"descending"] boolValue]
							   byExtension:[[[self sortDescriptor] objectForKey:@"byExtension"] boolValue]
							  foldersOnTop:[[[self sortDescriptor] objectForKey:@"foldersOnTop"] boolValue]];
	[[self valueForKey:@"outlineView"] reloadData];
}

- (void)GITMate_Sorting_windowDidLoad
{
	[self GITMate_Sorting_windowDidLoad];
	
	if(not [GITMateSorting useSorting])
		return;
    
	[GITMateSorting addProjectController:self];
	[[self sortDescriptor] setObject:[NSNumber numberWithBool:[GITMateSorting foldersOnTop]] forKey:@"foldersOnTop"];
	[[self sortDescriptor] setObject:[NSNumber numberWithBool:[GITMateSorting byExtension]] forKey:@"byExtension"];
	[[self sortDescriptor] setObject:[NSNumber numberWithBool:[GITMateSorting descending]] forKey:@"descending"];
	[self resortItems];
}

- (void)toggleDescending:(NSMenuItem*)menuItem
{
	[menuItem setState:! [menuItem state]];
    // Need to set the preference! @author Cetrasoft
    [[NSUserDefaults standardUserDefaults] setBool:[menuItem state] forKey:@"GITMateSortingDescending"];
	[[self sortDescriptor] setObject:[NSNumber numberWithBool:[menuItem state]] forKey:@"descending"];
	[self resortItems];
}

- (void)toggleByExtension:(NSMenuItem*)menuItem
{
	[menuItem setState:! [menuItem state]];
    // Need to set the preference! @author Cetrasoft
    [[NSUserDefaults standardUserDefaults] setBool:[menuItem state] forKey:@"GITMateSortingByExtension"];
	[[self sortDescriptor] setObject:[NSNumber numberWithBool:[menuItem state]] forKey:@"byExtension"];
	[self resortItems];
}

- (void)toggleFoldersOnTop:(NSMenuItem*)menuItem
{
	[menuItem setState:! [menuItem state]];
    // Need to set the preference! @author Cetrasoft
    [[NSUserDefaults standardUserDefaults] setBool:[menuItem state] forKey:@"GITMateSortingFoldersOnTop"];
	[[self sortDescriptor] setObject:[NSNumber numberWithBool:[menuItem state]] forKey:@"foldersOnTop"];
	[self resortItems];
}

//========================================================//
// New listeners to keep sorting sticky @author Cetrasoft //
//========================================================//
- (void)GITMate_Sorting_performNewFileSheetAction:(id)arg1 
{	
	[self GITMate_Sorting_performNewFileSheetAction: arg1];
	
	[self resortItems];
}

- (void)GITMate_Sorting_projectAddFiles:(id)arg1 
{	
	[self GITMate_Sorting_projectAddFiles: arg1];
	
	[self resortItems];
}

- (void)GITMate_Sorting_projectRemoveFiles:(id)arg1
{	
	[self GITMate_Sorting_projectRemoveFiles: arg1];
	
	[self resortItems];
}

- (void)GITMate_Sorting_projectNewGroup:(id)arg1
{	
	[self GITMate_Sorting_projectNewGroup: arg1];
	
	[self resortItems];
}

- (void)GITMate_Sorting_projectGroupFiles:(id)arg1
{	
	[self GITMate_Sorting_projectGroupFiles: arg1];
	
	[self resortItems];
}

- (void)GITMate_Sorting_applicationDidBecomeActiveNotification:(id)arg1
{	
	[self GITMate_Sorting_applicationDidBecomeActiveNotification: arg1];
	
	[self resortItems];
}
@end

@implementation NSButton (OakMenuButton_GITMate_Sorting)
- (void)GITMate_Sorting_awakeFromNib
{
	[self GITMate_Sorting_awakeFromNib];
    
	if(not [[self window] isKindOfClass:NSClassFromString(@"NSDrawerWindow")])
		return;
	
	NSMenu *menu = (NSMenu*)[self valueForKey:@"actionMenu"];
	[menu addItem:[NSMenuItem separatorItem]];
    
	NSMenuItem *sortingMenu = [[NSMenuItem alloc] initWithTitle:@"Sort" action:nil keyEquivalent:@""];
	{
		NSMenu *sortingSubMenu = [[NSMenu alloc] init];
		NSMenuItem *item;
		
		item = [[NSMenuItem alloc] initWithTitle:@"Descending"
                                          action:@selector(toggleDescending:)
                                   keyEquivalent:@""];
		[item setTarget:[self valueForKey:@"delegate"]];
		[item setState:[GITMateSorting descending]];
		[sortingSubMenu addItem:item];
		[item release];
        
		item = [[NSMenuItem alloc] initWithTitle:@"By Extension"
                                          action:@selector(toggleByExtension:)
                                   keyEquivalent:@""];
		[item setTarget:[self valueForKey:@"delegate"]];
		[item setState:[GITMateSorting byExtension]];
		[sortingSubMenu addItem:item];
		[item release];
        
		item = [[NSMenuItem alloc] initWithTitle:@"Folders on Top"
                                          action:@selector(toggleFoldersOnTop:)
                                   keyEquivalent:@""];
		[item setTarget:[self valueForKey:@"delegate"]];
		[item setState:[GITMateSorting foldersOnTop]];
		[sortingSubMenu addItem:item];
		[item release];
        
		[sortingMenu setSubmenu:sortingSubMenu];
		[sortingSubMenu release];
	}
	[menu addItem:sortingMenu];
	[sortingMenu release];
}

- (BOOL)GITMate_Sorting_validateMenuItem:(NSMenuItem*)menuItem
{
	if([menuItem action] == @selector(toggleDescending:) || [menuItem action] == @selector(toggleByExtension:))
		return YES;
	
	return [self GITMate_Sorting_validateMenuItem:menuItem];
}
@end

static NSMutableArray* sortDescriptors = [[NSMutableArray alloc] initWithCapacity:1];

@implementation GITMateSorting
+ (void)load
{	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"GITMate Use Sorting"]];
	
	[OakProjectController jr_swizzleMethod:@selector(windowDidLoad) withMethod:@selector(GITMate_Sorting_windowDidLoad) error:NULL];
    //========================================================//
    // New listeners to keep sorting sticky @author Cetrasoft //
    //========================================================//
	[OakProjectController jr_swizzleMethod:@selector(performNewFileSheetAction:) withMethod:@selector(GITMate_Sorting_performNewFileSheetAction:) error:NULL];
	[OakProjectController jr_swizzleMethod:@selector(projectAddFiles:) withMethod:@selector(GITMate_Sorting_projectAddFiles:) error:NULL];
	[OakProjectController jr_swizzleMethod:@selector(projectRemoveFiles:) withMethod:@selector(GITMate_Sorting_projectRemoveFiles:) error:NULL];
	[OakProjectController jr_swizzleMethod:@selector(projectNewGroup:) withMethod:@selector(GITMate_Sorting_projectNewGroup:) error:NULL];
	[OakProjectController jr_swizzleMethod:@selector(projectGroupFiles:) withMethod:@selector(GITMate_Sorting_projectGroupFiles:) error:NULL];
	[OakProjectController jr_swizzleMethod:@selector(applicationDidBecomeActiveNotification:) withMethod:@selector(GITMate_Sorting_applicationDidBecomeActiveNotification:) error:NULL];
    
	[OakMenuButton jr_swizzleMethod:@selector(awakeFromNib) withMethod:@selector(GITMate_Sorting_awakeFromNib) error:NULL];
	[OakMenuButton jr_swizzleMethod:@selector(validateMenuItem:) withMethod:@selector(GITMate_Sorting_validateMenuItem:) error:NULL];
}

+ (BOOL)foldersOnTop
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GITMateSortingFoldersOnTop"];
}

+ (BOOL)byExtension
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GITMateSortingByExtension"];
}

+ (BOOL)descending
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GITMateSortingDescending"];
}

+ (BOOL)useSorting
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GITMate Use Sorting"];
}

+ (void)addProjectController:(id)projectController;
{
	NSMutableDictionary* sortDescriptor = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"descending",
                                           [NSNumber numberWithBool:NO],@"byExtension",
                                           [NSNumber numberWithBool:NO],@"foldersOnTop",
                                           nil];
	[sortDescriptors addObject:[NSDictionary dictionaryWithObjectsAndKeys:projectController,@"controller",sortDescriptor,@"sortDescriptor",nil]];
}

+ (void)removeProjectController:(id)projectController;
{
	unsigned int	controllerCount = [sortDescriptors count];
    
	for(unsigned int index = 0; index < controllerCount; index += 1)
	{
		NSDictionary* info = [sortDescriptors objectAtIndex:index];
		if([info objectForKey:@"controller"] == projectController)
		{
			[sortDescriptors removeObject:info];
			return;
		}
	}
}

+ (NSMutableDictionary*)sortDescriptorForProjectController:(id)projectController;
{
	unsigned int controllerCount = [sortDescriptors count];
    
	for(unsigned int index = 0; index < controllerCount; index += 1)
	{
		NSDictionary* info = [sortDescriptors objectAtIndex:index];
		if([info objectForKey:@"controller"] == projectController)
			return [info objectForKey:@"sortDescriptor"];
	}
    
	return nil;
}
@end
