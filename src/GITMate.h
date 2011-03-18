#import <Cocoa/Cocoa.h>

extern NSString* GITMate_redrawRequired;

@protocol TMPlugInController
- (float)version;
@end

@interface GITMate : NSObject
{
	NSImage* icon;
	BOOL quickLookAvailable;
	IBOutlet NSView *preferencesView;
	IBOutlet NSTabView* preferencesTabView;
	IBOutlet NSWindow* sortingDefaultsSheet;
}
+ (GITMate*)sharedInstance;
- (id)initWithPlugInController:(id <TMPlugInController>)aController;

- (IBAction)showSortingDefaultsSheet:(id)sender;
- (IBAction)orderOutShortingDefaultSheet:(id)sender;

- (IBAction)notifyOutlineViewsAsDirty:(id)sender;
- (void)watchDefaultsKey:(NSString*)keyPath;

- (NSView*)preferencesView;
- (NSImage*)iconImage;
@end