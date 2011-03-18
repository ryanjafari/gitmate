#import "GITMate.h"
#import "TextMate.h"

NSString* GITMate_redrawRequired = @"GITMate_redrawRequired";

float ToolbarHeightForWindow(NSWindow *window)
{
	NSToolbar *toolbar;
	float toolbarHeight = 0.0;
	NSRect windowFrame;

	toolbar = [window toolbar];

	if(toolbar && [toolbar isVisible])
	{
		windowFrame   = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
	}

	return toolbarHeight;
}

static const NSString* GITMate_PREFERENCES_LABEL = @"GITMate";

@implementation NSWindowController (PreferenceAdditions)
- (NSArray*)GITMate_toolbarAllowedItemIdentifiers:(id)sender
{
	return [[self GITMate_toolbarAllowedItemIdentifiers:sender] arrayByAddingObject:GITMate_PREFERENCES_LABEL];
}
- (NSArray*)GITMate_toolbarDefaultItemIdentifiers:(id)sender
{
	return [[self GITMate_toolbarDefaultItemIdentifiers:sender] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:GITMate_PREFERENCES_LABEL,nil]];
}
- (NSArray*)GITMate_toolbarSelectableItemIdentifiers:(id)sender
{
	return [[self GITMate_toolbarSelectableItemIdentifiers:sender] arrayByAddingObject:GITMate_PREFERENCES_LABEL];
}

- (NSToolbarItem*)GITMate_toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem *item = [self GITMate_toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
	if([itemIdentifier isEqualToString:GITMate_PREFERENCES_LABEL])
		[item setImage:[[GITMate sharedInstance] iconImage]];
	return item;
}

- (void)GITMate_selectToolbarItem:(id)item
{
	if ([[item label] isEqualToString:GITMate_PREFERENCES_LABEL]) {
		if ([[self valueForKey:@"selectedToolbarItem"] isEqualToString:[item label]]) return;
		[[self window] setTitle:[item label]];
		[self setValue:[item label] forKey:@"selectedToolbarItem"];
		
		NSSize prefsSize = [[[GITMate sharedInstance] preferencesView] frame].size;
		NSRect frame = [[self window] frame];
		prefsSize.width = [[self window] contentMinSize].width;

		[[self window] setContentView:[[GITMate sharedInstance] preferencesView]];

		float newHeight = prefsSize.height + ToolbarHeightForWindow([self window]) + 22;
		frame.origin.y += frame.size.height - newHeight;
		frame.size.height = newHeight;
		frame.size.width = prefsSize.width;
		[[self window] setFrame:frame display:YES animate:YES];
	} else {
		[self GITMate_selectToolbarItem:item];
	}
}
@end

@implementation NSWindowController (OakProjectController_Redrawing)
- (id)GITMate_init
{
	self = [self GITMate_init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GITMate_redrawRequired:) name:GITMate_redrawRequired object:nil];
	return self;
}

- (void)GITMate_redrawRequired:(NSNotification*)notification
{
	[(NSOutlineView*)[self valueForKey:@"outlineView"] setNeedsDisplay:YES];
}
@end

static GITMate* SharedInstance = nil;
@implementation GITMate
+ (GITMate*)sharedInstance
{
	return SharedInstance ?: [[self new] autorelease];
}

- (id)init
{
	if(SharedInstance)
	{
		[self release];
	}
	else if(self = SharedInstance = [[super init] retain])
	{
		quickLookAvailable = [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load];

		NSApp = [NSApplication sharedApplication];

		// Preferences
		NSString* nibPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Preferences" ofType:@"nib"];
		NSWindowController *controller = [[NSWindowController alloc] initWithWindowNibPath:nibPath owner:self];
		[controller showWindow:self];


		[OakPreferencesManager jr_swizzleMethod:@selector(toolbarAllowedItemIdentifiers:) withMethod:@selector(GITMate_toolbarAllowedItemIdentifiers:) error:NULL];
		[OakPreferencesManager jr_swizzleMethod:@selector(toolbarDefaultItemIdentifiers:) withMethod:@selector(GITMate_toolbarDefaultItemIdentifiers:) error:NULL];
		[OakPreferencesManager jr_swizzleMethod:@selector(toolbarSelectableItemIdentifiers:) withMethod:@selector(GITMate_toolbarSelectableItemIdentifiers:) error:NULL];
		[OakPreferencesManager jr_swizzleMethod:@selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:) withMethod:@selector(GITMate_toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:) error:NULL];
		[OakPreferencesManager jr_swizzleMethod:@selector(selectToolbarItem:) withMethod:@selector(GITMate_selectToolbarItem:) error:NULL];

		[OakProjectController jr_swizzleMethod:@selector(init) withMethod:@selector(GITMate_init) error:NULL];
        
        // Load icon.
        // @author Cetrasoft
        NSString* iconPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"gitlogo" ofType:@"tiff"];
		icon = [[NSImage alloc] initByReferencingFile:iconPath];
	}

	return SharedInstance;
}

// This does not load and causes:
// 3/18/11 1:37:16 AM	TextMate[12114]	instance GITMate plug-in doesn't have proper initializer
// @author Cetrasoft
- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
	if(self = [self init])
	{
		NSString* iconPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"gitlogo" ofType:@"tiff"];
		icon = [[NSImage alloc] initByReferencingFile:iconPath];
	}
	return self;
}

- (void)dealloc
{
	[icon release];
	[super dealloc];
}

- (void)awakeFromNib
{
	if([[NSUserDefaults standardUserDefaults] stringForKey:@"GITMate Selected Tab Identifier"])
		[preferencesTabView selectTabViewItemWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:@"GITMate Selected Tab Identifier"]];
}

- (IBAction)showSortingDefaultsSheet:(id)sender
{
	[NSApp beginSheet:sortingDefaultsSheet modalForWindow:[preferencesTabView window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)orderOutShortingDefaultSheet:(id)sender
{
	[sortingDefaultsSheet orderOut:nil];
	[NSApp endSheet:sortingDefaultsSheet];
}

- (void)tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	[[NSUserDefaults standardUserDefaults] setObject:[tabViewItem identifier] forKey:@"GITMate Selected Tab Identifier"];
}

- (IBAction)notifyOutlineViewsAsDirty:(id)sender;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GITMate_redrawRequired object:nil];
}

- (void)watchDefaultsKey:(NSString*)keyPath
{
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:keyPath options:NULL context:NULL];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)changes context:(void*)context
{
	[self notifyOutlineViewsAsDirty:self];
}

- (NSView*)preferencesView
{
	return preferencesView;
}

- (NSImage*)iconImage;
{
	return icon;
}

- (BOOL)quickLookAvailable
{
	return quickLookAvailable;
}
@end
