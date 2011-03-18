#import "JRSwizzle.h"
#import "GITMate.h"

@interface ProjectTree : NSObject
+ (BOOL)preserveTreeState;
@end

@implementation NSWindowController (OakProjectController)
- (void)expandItems:(NSArray*)items inOutlineView:(NSOutlineView*)outlineView toState:(NSDictionary*)treeState
{
	unsigned int itemCount = [items count];

	for(unsigned int index = 0; index < itemCount; index += 1)
	{
		NSDictionary *item = [items objectAtIndex:index];

		if(not [item objectForKey:@"children"])
			continue; // We are only interested in directories

		if(NSDictionary *treeItem = [treeState objectForKey:[item objectForKey:@"displayName"]])
		{
			if([[treeItem objectForKey:@"isExpanded"] boolValue])
				[outlineView expandItem:item];
			
			if([[treeItem objectForKey:@"subItems"] count])
				[self expandItems:[item objectForKey:@"children"] inOutlineView:outlineView toState:[treeItem objectForKey:@"subItems"]];
		}
	}
}

- (void)ProjectTree_windowDidLoad
{
	[self ProjectTree_windowDidLoad];

	if(not [ProjectTree preserveTreeState])
		return;

	[[self valueForKey:@"outlineView"] reloadData];

	NSOutlineView *outlineView = [self valueForKey:@"outlineView"];
	
	NSDictionary *treeState = [[NSDictionary dictionaryWithContentsOfFile:[self valueForKey:@"filename"]] objectForKey:@"treeState"];
	if(treeState)
	{
		NSArray *rootItems         = [self valueForKey:@"rootItems"];
		[self expandItems:rootItems inOutlineView:outlineView toState:treeState];
	}
	
	
	
	
	
	
	/***** MARK HUOT ******/
	
	// Get the NSScrollView and remove the border
	NSScrollView *scrollView = [[outlineView superview] superview];
//	[scrollView setBorderType: NSNoBorder];
	
	// Switch the NSOutlineView to use `source` styling
//	[outlineView setSelectionHighlightStyle: NSTableViewSelectionHighlightStyleSourceList];
//	[outlineView setRowHeight: 14];
//	[outlineView setIntercellSpacing: (NSSize){3, 6}];
	
	// Set the background of the entire window to debug
	//[[self window] setBackgroundColor:[NSColor blueColor]];
	
	// Grab the width of the "drawer" (or project frame)
	// not sure why we add 24 here, maybe the width of the scroll bar?
	CGFloat frameWidth = [scrollView frame].size.width;
	
	// Create the background image for the icons and make sure it's sized correctly
	NSString *bkgPath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"bkg" ofType:@"tiff"];
	NSImage *image = [[NSImage alloc] initByReferencingFile:bkgPath];
	[image setSize: (NSSize){3000,23}];
	NSImageView *imageView = [[NSImageView alloc] initWithFrame: [[self window] frame]];
	[imageView setImage:image];
	[imageView setFrame:NSMakeRect(0,0,frameWidth+24,23)];
	[imageView setFrameOrigin:(NSPoint){0,0}];
	[imageView setAutoresizingMask:NSViewWidthSizable];
	[imageView setImageScaling:NSScaleNone];
	
	// Finally add the background image as the bottom layer
	NSArray *siblings = [[scrollView superview] subviews];
	[[scrollView superview] addSubview:imageView positioned:NSWindowBelow relativeTo:[siblings objectAtIndex:0]];
	
	// Update the ADD image
	NSString *plusImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"plus" ofType:@"tiff"];
	NSImage *plusImage = [[NSImage alloc] initByReferencingFile:plusImagePath];
	[[siblings objectAtIndex:4] setImage:plusImage];
	
	NSString *plusPressedImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"pluspressed" ofType:@"tiff"];
	NSImage *plusPressedImage = [[NSImage alloc] initByReferencingFile:plusPressedImagePath];
	[[siblings objectAtIndex:4] setAlternateImage:plusPressedImage];
	
	[[siblings objectAtIndex:4] setFrame:(NSRect){0,0,31,23}];
	
	// Update the ADD DIR image
	NSString *plusDirImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"plusdir" ofType:@"tiff"];
	NSImage *plusDirImage = [[NSImage alloc] initByReferencingFile:plusDirImagePath];
	[[siblings objectAtIndex:2] setImage:plusDirImage];
	
	NSString *plusDirPressedImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"plusdirpressed" ofType:@"tiff"];
	NSImage *plusDirPressedImage = [[NSImage alloc] initByReferencingFile:plusDirPressedImagePath];
	[[siblings objectAtIndex:2] setAlternateImage:plusDirPressedImage];
	
	[[siblings objectAtIndex:2] setFrame:(NSRect){31,0,31,23}];
	
	// Update the GEAR image
	NSString *gearImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"gear" ofType:@"tiff"];
	NSImage *gearImage = [[NSImage alloc] initByReferencingFile:gearImagePath];
	[[siblings objectAtIndex:3] setImage:gearImage];
	
	NSString *gearPressedImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"gearpressed" ofType:@"tiff"];
	NSImage *gearPressedImage = [[NSImage alloc] initByReferencingFile:gearPressedImagePath];
	[[siblings objectAtIndex:3] setAlternateImage:gearPressedImage];
	
	[[siblings objectAtIndex:3] setFrame:(NSRect){62,0,31,23}];
	
	// Update the INFO image
	NSString *infoImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"info" ofType:@"tiff"];
	NSImage *infoImage = [[NSImage alloc] initByReferencingFile:infoImagePath];
	[[siblings objectAtIndex:1] setImage:infoImage];
	
	NSString *infoPressedImagePath = [[NSBundle bundleForClass:[GITMate class]] pathForResource:@"infopressed" ofType:@"tiff"];
	NSImage *infoPressedImage = [[NSImage alloc] initByReferencingFile:infoPressedImagePath];
	[[siblings objectAtIndex:1] setAlternateImage:infoPressedImage];
	
	[[siblings objectAtIndex:1] setFrame:(NSRect){frameWidth-31,0,31,23}];
	
	/***** /MARK HUOT ******/
}

- (NSDictionary*)outlineView:(NSOutlineView*)outlineView stateForItems:(NSArray*)items
{
	NSMutableDictionary *treeState = [NSMutableDictionary dictionaryWithCapacity:3];
	unsigned int itemCount = [items count];

	for(unsigned int index = 0; index < itemCount; index += 1)
	{
		NSDictionary *item = [items objectAtIndex:index];
		if([outlineView isItemExpanded:item])
		{
			NSDictionary *subTreeState = [self outlineView:outlineView stateForItems:[item objectForKey:@"children"]];
			[treeState setObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"isExpanded",
																								 subTreeState,@"subItems",
																								 nil] forKey:[item objectForKey:@"displayName"]];
		}
	}	
	
	return treeState;
}

- (BOOL)ProjectTree_writeToFile:(NSString*)fileName
{
	BOOL result = [self ProjectTree_writeToFile:fileName];
	if(result && [ProjectTree preserveTreeState])
	{
		NSMutableDictionary *project = [NSMutableDictionary dictionaryWithContentsOfFile:fileName];
		NSDictionary *treeState      = [self outlineView:[self valueForKey:@"outlineView"] stateForItems:[self valueForKey:@"rootItems"]];
		[project setObject:treeState forKey:@"treeState"];
		result = [project writeToFile:fileName atomically:NO];
	}
	return result;
}
@end

@implementation ProjectTree
+ (void)load
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																					[NSNumber numberWithBool:YES],@"GITMate Preserve Tree",
																					nil]];

	[NSClassFromString(@"OakProjectController") jr_swizzleMethod:@selector(windowDidLoad) withMethod:@selector(ProjectTree_windowDidLoad) error:NULL];
	[NSClassFromString(@"OakProjectController") jr_swizzleMethod:@selector(writeToFile:) withMethod:@selector(ProjectTree_writeToFile:) error:NULL];
}

+ (BOOL)preserveTreeState;
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GITMate Preserve Tree"];
}
@end
