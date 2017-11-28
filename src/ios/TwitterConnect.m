
#import "TwitterConnect.h"
#import <objc/runtime.h>
#import <TwitterKit/TwitterKit.h>

@implementation TwitterConnect

- (void)pluginInitialize
{
    NSString* consumerKey = [self.commandDelegate.settings objectForKey:[@"TwitterConsumerKey" lowercaseString]];
    NSString* consumerSecret = [self.commandDelegate.settings objectForKey:[@"TwitterConsumerSecret" lowercaseString]];
    [[Twitter sharedInstance] startWithConsumerKey:consumerKey consumerSecret:consumerSecret];
}

- (void)login:(CDVInvokedUrlCommand*)command
{
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
		CDVPluginResult* pluginResult = nil;
		if (session){
			NSLog(@"signed in as %@", [session userName]);
			NSDictionary *userSession = @{
										  @"userName": [session userName],
										  @"userId": [session userID],
										  @"secret": [session authTokenSecret],
										  @"token" : [session authToken]};
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userSession];
		} else {
			NSLog(@"error: %@", [error localizedDescription]);
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
		}
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}];
}

- (void)logout:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end

@implementation AppDelegate (Twitter)

void TwitterMethodSwizzle(Class c, SEL originalSelector) {
    NSString *selectorString = NSStringFromSelector(originalSelector);
    SEL newSelector = NSSelectorFromString([@"swizzled_" stringByAppendingString:selectorString]);
    SEL noopSelector = NSSelectorFromString([@"noop_" stringByAppendingString:selectorString]);
    Method originalMethod, newMethod, noop;
    originalMethod = class_getInstanceMethod(c, originalSelector);
    newMethod = class_getInstanceMethod(c, newSelector);
    noop = class_getInstanceMethod(c, noopSelector);
    if (class_addMethod(c, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(c, newSelector, method_getImplementation(originalMethod) ?: method_getImplementation(noop), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

+ (void)load
{
    TwitterMethodSwizzle([self class], @selector(application:openURL:options:));
    TwitterMethodSwizzle([self class], @selector(application:openURL:sourceApplication:annotation:));
}


- (void)noop_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
}

- (void)swizzled_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    
    if (!url) {
        return ;
    }

    [[Twitter sharedInstance] application:app openURL:url options:options];
    [self swizzled_application:app openURL:url options:options];
}

@end
