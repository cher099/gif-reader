#import "GiffyAppDelegate.h"
#import "BrowserViewController.h"

@implementation GiffyAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    BrowserViewController *browser = [[[BrowserViewController alloc] init] autorelease];
    UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:browser] autorelease];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}
@end
