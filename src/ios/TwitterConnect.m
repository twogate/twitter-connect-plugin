
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

static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector);
@implementation AppDelegate (TwitterConnect)

+(void)load {
    swizzleMethod([AppDelegate class],
                  @selector(application:openURL:options:),
                  @selector(twitter_application_options:openURL:options:));
}

- (BOOL)twitter_application_options: (UIApplication *)app
                              openURL: (NSURL *)url
                              options: (NSDictionary *)options
{
    
    NSRange range = [url.absoluteString rangeOfString:@"twitterkit"];
    if (range.location != NSNotFound) {
        return [[Twitter sharedInstance] application:app openURL:url options:options];
    }
    else {
        // Other. call super
        return [self twitter_application_options:app openURL:url options:options];
    }
}

@end

static void swizzleMethod(Class class, SEL destinationSelector, SEL sourceSelector) {
    Method destinationMethod = class_getInstanceMethod(class, destinationSelector);
    Method sourceMethod = class_getInstanceMethod(class, sourceSelector);
    

    if (class_addMethod(class, destinationSelector, method_getImplementation(sourceMethod), method_getTypeEncoding(sourceMethod))) {
        class_replaceMethod(class, destinationSelector, method_getImplementation(destinationMethod), method_getTypeEncoding(destinationMethod));
    } else {
        method_exchangeImplementations(destinationMethod, sourceMethod);
    }
}
