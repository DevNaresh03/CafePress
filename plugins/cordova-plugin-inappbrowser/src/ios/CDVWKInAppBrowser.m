/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWKInAppBrowser.h"
#import <Photos/Photos.h>
#if __has_include("CDVWKProcessPoolFactory.h")
#import "CDVWKProcessPoolFactory.h"
#endif

#import <Cordova/CDVPluginResult.h>
#import <Cordova/CDVUserAgentUtil.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#define    kInAppBrowserTargetSelf @"_self"
#define    kInAppBrowserTargetSystem @"_system"
#define    kInAppBrowserTargetBlank @"_blank"

#define    kInAppBrowserToolbarBarPositionBottom @"bottom"
#define    kInAppBrowserToolbarBarPositionTop @"top"

#define    IAB_BRIDGE_NAME @"cordova_iab"

#define    TOOLBAR_HEIGHT 44.0
#define    STATUSBAR_HEIGHT 20.0
#define    LOCATIONBAR_HEIGHT 21.0
#define    FOOTER_HEIGHT ((TOOLBAR_HEIGHT) + (LOCATIONBAR_HEIGHT))

#pragma mark CDVWKInAppBrowser

@interface CDVWKInAppBrowser () {
    NSInteger _previousStatusBarStyle;
}
@end

@implementation CDVWKInAppBrowser

static CDVWKInAppBrowser* instance = nil;

+ (id) getInstance{
    return instance;
}

- (void)pluginInitialize
{
    instance = self;
    _previousStatusBarStyle = -1;
    _callbackIdPattern = nil;
    _beforeload = @"";
    _waitForBeforeload = NO;
}

- (id)settingForKey:(NSString*)key
{
    return [self.commandDelegate.settings objectForKey:[key lowercaseString]];
}

- (void)onReset
{
    [self close:nil];
}

- (void)close:(CDVInvokedUrlCommand*)command
{
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"IAB.close() called but it was already closed.");
        return;
    }
    // Things are cleaned up in browserExit.
    [self.inAppBrowserViewController close];
}

- (BOOL) isSystemUrl:(NSURL*)url
{
    if ([[url host] isEqualToString:@"itunes.apple.com"]) {
        return YES;
    }
    
    return NO;
}

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    
    NSString* url = [command argumentAtIndex:0];
    NSString* target = [command argumentAtIndex:1 withDefault:kInAppBrowserTargetSelf];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    
    self.callbackId = command.callbackId;
    
    if (url != nil) {
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        if ([self isSystemUrl:absoluteUrl]) {
            target = kInAppBrowserTargetSystem;
        }
        
        if ([target isEqualToString:kInAppBrowserTargetSelf]) {
            [self openInCordovaWebView:absoluteUrl withOptions:options];
        } else if ([target isEqualToString:kInAppBrowserTargetSystem]) {
            [self openInSystem:absoluteUrl];
        } else { // _blank or anything else
            [self openInInAppBrowser:absoluteUrl withOptions:options];
        }
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)openInInAppBrowser:(NSURL*)url withOptions:(NSString*)options
{
    CDVInAppBrowserOptions* browserOptions = [CDVInAppBrowserOptions parseOptions:options];
    
    WKWebsiteDataStore* dataStore = [WKWebsiteDataStore defaultDataStore];
    if (browserOptions.cleardata) {
        
        NSDate* dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [dataStore removeDataOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] modifiedSince:dateFrom completionHandler:^{
            NSLog(@"Removed all WKWebView data");
            self.inAppBrowserViewController.webView.configuration.processPool = [[WKProcessPool alloc] init]; // create new process pool to flush all data
        }];
    }
    
    if (browserOptions.clearcache) {
        bool isAtLeastiOS11 = false;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
        if (@available(iOS 11.0, *)) {
            isAtLeastiOS11 = true;
        }
#endif
        
        if(isAtLeastiOS11){
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
            // Deletes all cookies
            WKHTTPCookieStore* cookieStore = dataStore.httpCookieStore;
            [cookieStore getAllCookies:^(NSArray* cookies) {
                NSHTTPCookie* cookie;
                for(cookie in cookies){
                    [cookieStore deleteCookie:cookie completionHandler:nil];
                }
            }];
#endif
        }else{
            // https://stackoverflow.com/a/31803708/777265
            // Only deletes domain cookies (not session cookies)
            [dataStore fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes]
                             completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
                                 for (WKWebsiteDataRecord *record  in records){
                                     NSSet<NSString*>* dataTypes = record.dataTypes;
                                     if([dataTypes containsObject:WKWebsiteDataTypeCookies]){
                                         [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes
                                                                                   forDataRecords:@[record]
                                                                                completionHandler:^{}];
                                     }
                                 }
                             }];
        }
    }
    
    if (browserOptions.clearsessioncache) {
        bool isAtLeastiOS11 = false;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
        if (@available(iOS 11.0, *)) {
            isAtLeastiOS11 = true;
        }
#endif
        if (isAtLeastiOS11) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
            // Deletes session cookies
            WKHTTPCookieStore* cookieStore = dataStore.httpCookieStore;
            [cookieStore getAllCookies:^(NSArray* cookies) {
                NSHTTPCookie* cookie;
                for(cookie in cookies){
                    if(cookie.sessionOnly){
                        [cookieStore deleteCookie:cookie completionHandler:nil];
                    }
                }
            }];
#endif
        }else{
            NSLog(@"clearsessioncache not available below iOS 11.0");
        }
    }
    
    if (self.inAppBrowserViewController == nil) {
        
        NSString *userAgent = self.inAppBrowserViewController.CPUserAgent;
        self.inAppBrowserViewController = [[CDVWKInAppBrowserViewController alloc] initWithUserAgent:userAgent prevUserAgent:[self.commandDelegate userAgent] browserOptions: browserOptions];
        self.inAppBrowserViewController.navigationDelegate = self;
        
        if ([self.viewController conformsToProtocol:@protocol(CDVScreenOrientationDelegate)]) {
            self.inAppBrowserViewController.orientationDelegate = (UIViewController <CDVScreenOrientationDelegate>*)self.viewController;
        }
    }
    
    [self.inAppBrowserViewController showLocationBar:browserOptions.location];
    [self.inAppBrowserViewController showToolBar:browserOptions.toolbar :browserOptions.toolbarposition];
    
    if (browserOptions.closebuttoncaption != nil || browserOptions.closebuttoncolor != nil) {
        self.inAppBrowserViewController.lastClicked = browserOptions.closebuttoncaption;
        NSString *last = self.inAppBrowserViewController.lastClicked;
        int closeButtonIndex = browserOptions.lefttoright ? (browserOptions.hidenavigationbuttons ? 1 : 4) : 0;
        [self.inAppBrowserViewController setCloseButtonTitle:browserOptions.closebuttoncaption :browserOptions.closebuttoncolor :closeButtonIndex];
    }
    // Set Presentation Style
    UIModalPresentationStyle presentationStyle = UIModalPresentationFullScreen; // default
    if (browserOptions.presentationstyle != nil) {
        if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"pagesheet"]) {
            presentationStyle = UIModalPresentationPageSheet;
        } else if ([[browserOptions.presentationstyle lowercaseString] isEqualToString:@"formsheet"]) {
            presentationStyle = UIModalPresentationFormSheet;
        }
    }
    self.inAppBrowserViewController.modalPresentationStyle = presentationStyle;
    
    // Set Transition Style
    UIModalTransitionStyle transitionStyle = UIModalTransitionStyleCoverVertical; // default
    if (browserOptions.transitionstyle != nil) {
        if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"fliphorizontal"]) {
            transitionStyle = UIModalTransitionStyleFlipHorizontal;
        } else if ([[browserOptions.transitionstyle lowercaseString] isEqualToString:@"crossdissolve"]) {
            transitionStyle = UIModalTransitionStyleCrossDissolve;
        }
    }
    self.inAppBrowserViewController.modalTransitionStyle = transitionStyle;
    
    //prevent webView from bouncing
    if (browserOptions.disallowoverscroll) {
        if ([self.inAppBrowserViewController.webView respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[self.inAppBrowserViewController.webView scrollView]).bounces = NO;
        } else {
            for (id subview in self.inAppBrowserViewController.webView.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
    }
    
    // use of beforeload event
    if([browserOptions.beforeload isKindOfClass:[NSString class]]){
        _beforeload = browserOptions.beforeload;
    }else{
        _beforeload = @"yes";
    }
    _waitForBeforeload = ![_beforeload isEqualToString:@""];
    
    [self.inAppBrowserViewController navigateTo:url];
    [self show:nil withNoAnimate:browserOptions.hidden];
}

- (void)show:(CDVInvokedUrlCommand*)command{
    [self show:command withNoAnimate:NO];
}

- (void)show:(CDVInvokedUrlCommand*)command withNoAnimate:(BOOL)noAnimate
{
    BOOL initHidden = NO;
    if(command == nil && noAnimate == YES){
        initHidden = YES;
    }
    
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    if (_previousStatusBarStyle != -1) {
        NSLog(@"Tried to show IAB while already shown");
        return;
    }
    
    if(!initHidden){
        _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    }
    
    __block CDVInAppBrowserNavigationController* nav = [[CDVInAppBrowserNavigationController alloc]
                                                        initWithRootViewController:self.inAppBrowserViewController];
    nav.orientationDelegate = self.inAppBrowserViewController;
    nav.navigationBarHidden = YES;
    nav.modalPresentationStyle = self.inAppBrowserViewController.modalPresentationStyle;
    
    __weak CDVWKInAppBrowser* weakSelf = self;
    
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.inAppBrowserViewController != nil) {
            float osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            CGRect frame = [[UIScreen mainScreen] bounds];
            if(initHidden && osVersion < 11){
                frame.origin.x = -10000;
            }
            
            UIWindow *tmpWindow = [[UIWindow alloc] initWithFrame:frame];
            UIViewController *tmpController = [[UIViewController alloc] init];
            
            [tmpWindow setRootViewController:tmpController];
            [tmpWindow setWindowLevel:UIWindowLevelNormal];
            
            if(!initHidden || osVersion < 11){
                [tmpWindow makeKeyAndVisible];
            }
            [tmpController presentViewController:nav animated:!noAnimate completion:nil];
        }
    });
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to hide IAB after it was closed.");
        return;
        
        
    }
    if (_previousStatusBarStyle == -1) {
        NSLog(@"Tried to hide IAB while already hidden");
        return;
    }
    
    _previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.inAppBrowserViewController != nil) {
            _previousStatusBarStyle = -1;
            [self.inAppBrowserViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

- (void)openInCordovaWebView:(NSURL*)url withOptions:(NSString*)options
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
#ifdef __CORDOVA_4_0_0
    // the webview engine itself will filter for this according to <allow-navigation> policy
    // in config.xml for cordova-ios-4.0
    [self.webViewEngine loadRequest:request];
#else
    if ([self.commandDelegate URLIsWhitelisted:url]) {
        [self.webView loadRequest:request];
    } else { // this assumes the InAppBrowser can be excepted from the white-list
        [self openInInAppBrowser:url withOptions:options];
    }
#endif
}

- (void)openInSystem:(NSURL*)url
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)loadAfterBeforeload:(CDVInvokedUrlCommand*)command
{
    NSString* urlStr = [command argumentAtIndex:0];
    
    if ([_beforeload isEqualToString:@""]) {
        NSLog(@"unexpected loadAfterBeforeload called without feature beforeload=get|post");
    }
    if (self.inAppBrowserViewController == nil) {
        NSLog(@"Tried to invoke loadAfterBeforeload on IAB after it was closed.");
        return;
    }
    if (urlStr == nil) {
        NSLog(@"loadAfterBeforeload called with nil argument, ignoring.");
        return;
    }
    
    NSURL* url = [NSURL URLWithString:urlStr];
    //_beforeload = @"";
    _waitForBeforeload = NO;
    [self.inAppBrowserViewController navigateTo:url];
}

// This is a helper method for the inject{Script|Style}{Code|File} API calls, which
// provides a consistent method for injecting JavaScript code into the document.
//
// If a wrapper string is supplied, then the source string will be JSON-encoded (adding
// quotes) and wrapped using string formatting. (The wrapper string should have a single
// '%@' marker).
//
// If no wrapper is supplied, then the source string is executed directly.

- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    // Ensure a message handler bridge is created to communicate with the CDVWKInAppBrowserViewController
    [self evaluateJavaScript: [NSString stringWithFormat:@"(function(w){if(!w._cdvMessageHandler) {w._cdvMessageHandler = function(id,d){w.webkit.messageHandlers.%@.postMessage({d:d, id:id});}}})(window)", IAB_BRIDGE_NAME]];
    
    if (jsWrapper != nil) {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@[source] options:0 error:nil];
        NSString* sourceArrayString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (sourceArrayString) {
            NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
            NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
            [self evaluateJavaScript:jsToInject];
        }
    } else {
        [self evaluateJavaScript:source];
    }
}


//Synchronus helper for javascript evaluation
- (void)evaluateJavaScript:(NSString *)script {
    __block NSString* _script = script;
    [self.inAppBrowserViewController.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        if (error == nil) {
            if (result != nil) {
                NSLog(@"%@", result);
            }
        } else {
            NSLog(@"evaluateJavaScript error : %@ : %@", error.localizedDescription, _script);
        }
    }];
}

- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper = nil;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"_cdvMessageHandler('%@',JSON.stringify([eval(%%@)]));", command.callbackId];
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('script'); c.src = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('script'); c.src = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%@; c.onload = function() { _cdvMessageHandler('%@'); }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('link'); c.rel='stylesheet', c.type='text/css'; c.href = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (BOOL)isValidCallbackId:(NSString *)callbackId
{
    NSError *err = nil;
    // Initialize on first use
    if (self.callbackIdPattern == nil) {
        self.callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"^InAppBrowser[0-9]{1,10}$" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex; No is safer than Yes.
            return NO;
        }
    }
    if ([self.callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])]) {
        return YES;
    }
    return NO;
}

/**
 * The message handler bridge provided for the InAppBrowser is capable of executing any oustanding callback belonging
 * to the InAppBrowser plugin. Care has been taken that other callbacks cannot be triggered, and that no
 * other code execution is possible.
 */
- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURL* url = navigationAction.request.URL;
    NSURL* mainDocumentURL = navigationAction.request.mainDocumentURL;
    BOOL isTopLevelNavigation = [url isEqual:mainDocumentURL];
    BOOL shouldStart = YES;
    BOOL useBeforeLoad = NO;
    NSString* httpMethod = navigationAction.request.HTTPMethod;
    NSString* errorMessage = nil;
    
    if([_beforeload isEqualToString:@"post"]){
        //TODO handle POST requests by preserving POST data then remove this condition
        errorMessage = @"beforeload doesn't yet support POST requests";
    }
    else if(isTopLevelNavigation && (
                                     [_beforeload isEqualToString:@"yes"]
                                     || ([_beforeload isEqualToString:@"get"] && [httpMethod isEqualToString:@"GET"])
                                     // TODO comment in when POST requests are handled
                                     // || ([_beforeload isEqualToString:@"post"] && [httpMethod isEqualToString:@"POST"])
                                     )){
        useBeforeLoad = YES;
    }
    
    // When beforeload, on first URL change, initiate JS callback. Only after the beforeload event, continue.
    if (_waitForBeforeload && useBeforeLoad) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"beforeload", @"url":[url absoluteString]}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if(errorMessage != nil){
        NSLog(errorMessage);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                      messageAsDictionary:@{@"type":@"loaderror", @"url":[url absoluteString], @"code": @"-1", @"message": errorMessage}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
    
    //if is an app store link, let the system handle it, otherwise it fails to load it
    if ([[ url scheme] isEqualToString:@"itms-appss"] || [[ url scheme] isEqualToString:@"itms-apps"]) {
        [theWebView stopLoading];
        [self openInSystem:url];
        shouldStart = NO;
    }
    else if ((self.callbackId != nil) && isTopLevelNavigation) {
        // Send a loadstart event for each top-level navigation (includes redirects).
        NSString* lastClick = self.inAppBrowserViewController.lastClicked;
        if(![[url absoluteString] isEqualToString:@"inapp://capture"]){
            
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:@{@"type":@"loadstart", @"url":[url absoluteString],@"lastClickedTab":lastClick}];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
        else{
            NSLog(@"last load ---++%@",_lastLoaded);
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:@{@"type":@"loadstart", @"url":_lastLoaded,@"lastClickedTab":lastClick}];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
    }
    
    if (useBeforeLoad) {
        _waitForBeforeload = YES;
    }
    if(shouldStart){
        
        
        if (!navigationAction.targetFrame){
            
            [theWebView loadRequest:navigationAction.request];
            decisionHandler(WKNavigationActionPolicyCancel);
            
        }
        else if ([navigationAction.request.mainDocumentURL.scheme isEqualToString: @"tel"]){
            NSString *_code = [[[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider] mobileNetworkCode];
            if(_code!=nil){
                [[UIApplication sharedApplication] openURL:url];
                decisionHandler(WKNavigationActionPolicyCancel);
            }
            else{
                decisionHandler(WKNavigationActionPolicyCancel);
                _inAppBrowserViewController.myProgressView.tintColor = [UIColor colorWithRed:249.0f/255.0f
                                                            green:249.0f/255.0f
                                                             blue:249.0f/255.0f
                                                            alpha:1.0f];
                _inAppBrowserViewController.myProgressView.hidden = true;
            }
            return;
        }
        else if([navigationAction.request.mainDocumentURL.scheme isEqualToString:@"inapp"]) {
            if ([navigationAction.request.URL.host isEqualToString:@"capture"]) {
                _inAppBrowserViewController.myProgressView.progress = 1.0;
                _inAppBrowserViewController.myProgressView.tintColor = [UIColor colorWithRed:249.0f/255.0f
                                                            green:249.0f/255.0f
                                                             blue:249.0f/255.0f
                                                            alpha:1.0f];
                
                [_inAppBrowserViewController checkPhotoPermissions];
                decisionHandler(WKNavigationActionPolicyCancel);
            }
        }
        
        else{
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }else{
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}


#pragma mark WKScriptMessageHandler delegate
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    
    CDVPluginResult* pluginResult = nil;
    
    if([message.body isKindOfClass:[NSDictionary class]]){
        NSDictionary* messageContent = (NSDictionary*) message.body;
        NSString* scriptCallbackId = messageContent[@"id"];
        
        if([messageContent objectForKey:@"d"]){
            NSString* scriptResult = messageContent[@"d"];
            NSError* __autoreleasing error = nil;
            NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
    }else if(self.callbackId != nil){
        // Send a message event
        NSString* messageContent = (NSString*) message.body;
        NSError* __autoreleasing error = nil;
        NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[messageContent dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
        if (error == nil) {
            NSMutableDictionary* dResult = [NSMutableDictionary new];
            [dResult setValue:@"message" forKey:@"type"];
            [dResult setObject:decodedResult forKey:@"data"];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dResult];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
    }
}

- (void)didStartProvisionalNavigation:(WKWebView*)theWebView
{
    NSLog(@"didStartProvisionalNavigation");
    //    self.inAppBrowserViewController.currentURL = theWebView.URL;
}

- (void)didFinishNavigation:(WKWebView*)theWebView
{
    
        _inAppBrowserViewController.myProgressView.tintColor = [UIColor colorWithRed:249.0f/255.0f
                                                    green:249.0f/255.0f
                                                     blue:249.0f/255.0f
                                                    alpha:1.0f];
        
    
    NSString* lastClick = self.inAppBrowserViewController.lastClicked;
    
    if (self.callbackId != nil) {
        NSString* url = [theWebView.URL absoluteString];
        if(url == nil){
            if(self.inAppBrowserViewController.currentURL != nil){
                url = [self.inAppBrowserViewController.currentURL absoluteString];
            }else{
                url = @"";
            }
        }
        if(![url isEqualToString: @"inapp://capture"]){
            _lastLoaded = url;
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:@{@"type":@"loadstop", @"url":url,@"lastClickedTab":lastClick}];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
    }
}

-(void)sendImgData:(NSArray *)arr {
    NSString * f = [arr objectAtIndex:0];
    NSString * s = [arr objectAtIndex:1];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"imageUpload", @"imgData":f,@"imgPath":s}];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(NSError*)error
{
    if (self.callbackId != nil) {
        NSString* url = [theWebView.URL absoluteString];
        if(url == nil){
            if(self.inAppBrowserViewController.currentURL != nil){
                url = [self.inAppBrowserViewController.currentURL absoluteString];
            }else{
                url = @"";
            }
        }
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                      messageAsDictionary:@{@"type":@"loaderror", @"url":url, @"code": [NSNumber numberWithInteger:error.code], @"message": error.localizedDescription}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void)browserExit
{
    if (self.callbackId != nil) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"exit"}];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        self.callbackId = nil;
    }
    
    [self.inAppBrowserViewController.configuration.userContentController removeScriptMessageHandlerForName:IAB_BRIDGE_NAME];
    self.inAppBrowserViewController.configuration = nil;
    
    [self.inAppBrowserViewController.webView stopLoading];
    [self.inAppBrowserViewController.webView removeFromSuperview];
    [self.inAppBrowserViewController.webView setUIDelegate:nil];
    [self.inAppBrowserViewController.webView setNavigationDelegate:nil];
    self.inAppBrowserViewController.webView = nil;
    
    // Set navigationDelegate to nil to ensure no callbacks are received from it.
    self.inAppBrowserViewController.navigationDelegate = nil;
    self.inAppBrowserViewController = nil;
    
    if (IsAtLeastiOSVersion(@"7.0")) {
        if (_previousStatusBarStyle != -1) {
            [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle];
            
        }
    }
    
    _previousStatusBarStyle = -1; // this value was reset before reapplying it. caused statusbar to stay black on ios7
}

@end //CDVWKInAppBrowser

#pragma mark CDVWKInAppBrowserViewController

@implementation CDVWKInAppBrowserViewController

@synthesize currentURL;

BOOL viewRenderedAtLeastOnce = FALSE;
BOOL isExiting = FALSE;

- (id)initWithUserAgent:(NSString*)userAgent prevUserAgent:(NSString*)prevUserAgent browserOptions: (CDVInAppBrowserOptions*) browserOptions
{
    self = [super init];
    if (self != nil) {
        _userAgent = userAgent;
        _prevUserAgent = prevUserAgent;
        _browserOptions = browserOptions;
        self.webViewUIDelegate = [[CDVWKInAppBrowserUIDelegate alloc] initWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
        [self.webViewUIDelegate setViewController:self];
        
        [self createViews];
    }
    
    return self;
}

-(void)dealloc {
    //NSLog(@"dealloc");
}

//Open Action sheet with camera and gallery
-(void)openOptions{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _actionSheet= [[UIActionSheet alloc]
                       initWithTitle:nil
                       delegate:self
                       cancelButtonTitle:@"Cancel"
                       destructiveButtonTitle:nil
                       otherButtonTitles:@"Camera", @"Photos", nil];
        
        [_actionSheet showInView:self.webView];
    });
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Index = %d - Title = %@", buttonIndex, [actionSheet buttonTitleAtIndex:buttonIndex]);
    if(buttonIndex == 0){
        [self CheckCameraPermissions];
    }
    else if(buttonIndex == 1){
        [self popGallery];
    }
    
}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSLog(@"Action sheet did dismiss");
    
}

//Check for Gallary permissions
-(void)checkPhotoPermissions{
    _showPermissions = true;
    PHAuthorizationStatus photoStatus = [PHPhotoLibrary authorizationStatus];
    if (photoStatus == PHAuthorizationStatusAuthorized) {
        // Access has been granted
        _photoPermissions = true;
        [self openOptions];
    }
    else if (photoStatus == PHAuthorizationStatusDenied) {
        // Access has been denied.
        _photoPermissions = false;
        [self PhotoDeniedAlert];
    }
    
    else if (photoStatus == PHAuthorizationStatusNotDetermined) {
        _showPermissions = false;
        // Access has not been determined.
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                // Access has been granted.
                _photoPermissions = true;
                [self openOptions];
            }
            else {
                _photoPermissions = false;
            }
        }];
    }
    else if (photoStatus == PHAuthorizationStatusRestricted) {
        // Restricted access - normally won't happen.
        _photoPermissions = false;
        [self PhotoDeniedAlert];
        
    }
}

//Check camera permissions
-(void)CheckCameraPermissions{
    _showPermissions = true;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized)
    {
        NSLog(@"permissions granted");
        _camaraPermissions = true;
        [self popCamera];
    }
    else if(authStatus == AVAuthorizationStatusNotDetermined)
    {
        _showPermissions = false;
        NSLog(@"%@", @"Camera access not determined. Ask for permission.");
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted)
         {
             if(granted)
             {
                 NSLog(@"Granted access to %@", AVMediaTypeVideo);
                 _camaraPermissions = true;
                 [self popCamera];
             }
             else
             {
                 _camaraPermissions = false;
                 NSLog(@"Not granted access to %@", AVMediaTypeVideo);
             }
             
         }];
    }
    else if (authStatus == AVAuthorizationStatusRestricted)
    {
        _camaraPermissions = false;
        [self CamDeniedAlert];
    }
    else
    {
        _camaraPermissions = false;
        [self CamDeniedAlert];
    }
}


//Open Camera
-(void)popCamera{
    if(_camaraPermissions){
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            // do work in the UI thread here
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType =  UIImagePickerControllerSourceTypeCamera;
            picker.delegate = self;
            [self presentViewController:picker animated:YES completion:nil];
        });
    }
    else{
        [self CamDeniedAlert];
    }
}

//open Gallery
-(void)popGallery{
    if(_photoPermissions){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self presentViewController:picker animated:YES completion:nil];
        }];
    }
    else{
        [self PhotoDeniedAlert];
    }
}
- (UIImage *)fixOrientationOfImage:(UIImage *)image {
    
    // No-op if the orientation is already correct
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 3491832 || alertView.tag == 3492 || alertView.tag == 34092)
    {
        switch(buttonIndex) {
            case 0: //"No" pressed
                //do something?
                break;
            case 1: //"Yes" pressed
                //here you pop the viewController
            {
                BOOL canOpenSettings = (&UIApplicationOpenSettingsURLString != NULL);
                if (canOpenSettings)
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
                break;
        }
    }
}
-(void)CamDeniedAlert{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Allow access to Camera"
                          message:@"Your camera can be used to take photos for personalized products"
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Open Settings",nil];
    alert.tag = 3492;
    [alert show];
}

-(void)PhotoDeniedAlert{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Allow access to Photos"
                          message:@"Photos from your photo library can be used to personalized products."
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Open Settings",nil];
    alert.tag = 34092;
    [alert show];
}
// Image Picker delegate metods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"Action sheet did dismiss");
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img = [self fixOrientationOfImage:img];
    NSDate *time = [NSDate date];
    NSDateFormatter* df = [NSDateFormatter new];
    [df setDateFormat:@"dd_MM_yyyy_hh_mm_ss"];
    NSString *timeString = [df stringFromDate:time];
    NSString *fileName = [NSString stringWithFormat:@"File-%@%@", timeString, @"_mobile_ios.jpg"];
    NSData *imageData = UIImagePNGRepresentation(img);
    NSString * base64String = [imageData base64EncodedStringWithOptions:0];
    NSArray * imgArr = [NSArray arrayWithObjects:base64String,fileName,nil];
    [_navigationDelegate sendImgData:imgArr];
    [picker dismissViewControllerAnimated:YES completion:nil];}
-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if (self.presentedViewController){
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


- (void)createViews
{
    // We create the views in code for primarily for ease of upgrades and not requiring an external .xib to be included
    
    CGRect webViewBounds = self.view.bounds;
    BOOL toolbarIsAtBottom = ![_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop];
    webViewBounds.size.height -= _browserOptions.location ? FOOTER_HEIGHT : TOOLBAR_HEIGHT;
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;
#if __has_include("CDVWKProcessPoolFactory.h")
    configuration.processPool = [[CDVWKProcessPoolFactory sharedFactory] sharedProcessPool];
#endif
    [configuration.userContentController addScriptMessageHandler:self name:IAB_BRIDGE_NAME];
    
    //WKWebView options
    configuration.allowsInlineMediaPlayback = _browserOptions.allowinlinemediaplayback;
    if (IsAtLeastiOSVersion(@"10.0")) {
        configuration.ignoresViewportScaleLimits = _browserOptions.enableviewportscale;
        if(_browserOptions.mediaplaybackrequiresuseraction == YES){
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
        }else{
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        }
    }else{ // iOS 9
        configuration.mediaPlaybackRequiresUserAction = _browserOptions.mediaplaybackrequiresuseraction;
    }
    
    self.webView = [[WKWebView alloc] initWithFrame:webViewBounds configuration:configuration];
    
    [self.view addSubview:self.webView];
    [self.view sendSubviewToBack:self.webView];
    
    
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self.webViewUIDelegate;
    self.webView.backgroundColor = [UIColor whiteColor];
    
    self.webView.clearsContextBeforeDrawing = YES;
    self.webView.clipsToBounds = YES;
    self.webView.contentMode = UIViewContentModeScaleToFill;
    self.webView.multipleTouchEnabled = YES;
    self.webView.opaque = YES;
    self.webView.userInteractionEnabled = YES;
    self.automaticallyAdjustsScrollViewInsets = YES ;
    [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    self.webView.allowsLinkPreview = NO;
    self.webView.allowsBackForwardNavigationGestures = NO;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) {
        [self.webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
#endif
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.alpha = 1.000;
    self.spinner.autoresizesSubviews = YES;
    self.spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin);
    self.spinner.clearsContextBeforeDrawing = NO;
    self.spinner.clipsToBounds = NO;
    self.spinner.contentMode = UIViewContentModeScaleToFill;
    self.spinner.frame = CGRectMake(CGRectGetMidX(self.webView.frame), CGRectGetMidY(self.webView.frame), 20.0, 20.0);
    self.spinner.hidden = NO;
    self.spinner.hidesWhenStopped = YES;
    self.spinner.multipleTouchEnabled = NO;
    self.spinner.opaque = NO;
    self.spinner.userInteractionEnabled = NO;
    [self.spinner stopAnimating];
    
    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.closeButton.enabled = YES;
 
    UIBarButtonItem* flexibleSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem* fixedSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpaceButton.width = 20;
    
    float toolbarY = toolbarIsAtBottom ? self.view.bounds.size.height - TOOLBAR_HEIGHT : 0.0;
    CGRect toolbarFrame = CGRectMake(0.0, toolbarY, self.view.bounds.size.width, TOOLBAR_HEIGHT);
    if (@available(iOS 11, *)) {
        if(UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom > 0) {
            self.tabView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-80, self.view.frame.size.width, 80)];
            
            
        }
        else{
            self.tabView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-60, self.view.frame.size.width, 60)];
        }
        
    } else {
        // iOS 10 or older code
        self.tabView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-60, self.view.frame.size.width, 60)];
    }
    NSString* appendUserAgent = [CDVUserAgentUtil originalUserAgent];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *userAgentSuffix = [NSString stringWithFormat:@"%@%@%@", @"Cpmobileappiosv", appVersionString,@" "];
    _CPUserAgent = [userAgentSuffix stringByAppendingString: appendUserAgent];
    
    self.tabView.backgroundColor = [UIColor colorWithRed:249.0f/255.0f
                                                   green:249.0f/255.0f
                                                    blue:249.0f/255.0f
                                                   alpha:1.0f];
    
   
    _baseUrl = _browserOptions.closebuttoncolor;
    [self.view addSubview: self.tabView];
    _homeSelected = true;
    _settingsSelected =false;
    _gidtSelected = false;
    _dealsSelected = false;
    _homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _homeButton.frame = CGRectMake(0, 0, self.tabView.frame.size.width/4, 50);
    [_homeButton setClipsToBounds:false];
    [_homeButton setImage:[UIImage imageNamed:@"home-active.png"] forState:UIControlStateNormal]; // SET the image name for your wishes
    [_homeButton setTitle:@"Featured" forState:UIControlStateNormal];
    [_homeButton setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                               green:184.0f/255.0f
                                                blue:0.0f/255.0f
                                               alpha:1.0f] forState:UIControlStateNormal]; // SET the colour for your wishes
    [_homeButton.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
    [_homeButton addTarget:self action:@selector(goHome:) forControlEvents:UIControlEventTouchUpInside]; // you can ADD the action to the button as well like
    
    [self.tabView addSubview:_homeButton];
    
    
    _dealsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _dealsButton.frame = CGRectMake(_homeButton.frame.origin.x + _homeButton.frame.size.width, 0, self.tabView.frame.size.width/4, 50);
    [_dealsButton setClipsToBounds:false];
    [_dealsButton setImage:[UIImage imageNamed:@"deals.png"] forState:UIControlStateNormal]; // SET the image name for your wishes
    [_dealsButton setTitle:@"Deals" forState:UIControlStateNormal];
    [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal]; // SET the colour for your wishes
    [_dealsButton.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
    
    [_dealsButton addTarget:self action:@selector(goDeals:) forControlEvents:UIControlEventTouchUpInside]; // you can ADD the action to the button as well like
    
    [self.tabView addSubview:_dealsButton];
    
    _giftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _giftButton.frame = CGRectMake(_dealsButton.frame.origin.x + _dealsButton.frame.size.width, 0, self.tabView.frame.size.width/4, 50);
    [_giftButton setClipsToBounds:false];
    [_giftButton setImage:[UIImage imageNamed:@"gift-icon.png"] forState:UIControlStateNormal]; // SET the image name for your wishes
    [_giftButton setTitle:@"Gift guide" forState:UIControlStateNormal];
    [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal]; // SET the colour for your wishes
    [_giftButton.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
    
    [_giftButton addTarget:self action:@selector(goGift:) forControlEvents:UIControlEventTouchUpInside]; // you can ADD the action to the button as well like
    
    [self.tabView addSubview:_giftButton];
    
    _settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _settingsButton.frame = CGRectMake(_giftButton.frame.origin.x + _giftButton.frame.size.width, 0, self.tabView.frame.size.width/4, 50);
    [_settingsButton setClipsToBounds:false];
    [_settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateNormal]; // SET the image name for your wishes
    [_settingsButton setTitle:@"Settings" forState:UIControlStateNormal];
    [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal]; // SET the colour for your wishes
    [_settingsButton.titleLabel setFont:[UIFont systemFontOfSize:13.f]];
    
    [_settingsButton addTarget:self action:@selector(goSettings:) forControlEvents:UIControlEventTouchUpInside]; // you can ADD the action to the button as well like
    
    _settingsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.tabView addSubview:_settingsButton];
    
    //to check the previous state when navigate from settings page
    
    if([_browserOptions.closebuttoncaption  isEqual: @"Featured"]){
        // SET the colour for your wishes nares
        [_homeButton setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                                   green:184.0f/255.0f
                                                    blue:0.0f/255.0f
                                                   alpha:1.0f] forState:UIControlStateNormal];
        [_homeButton setSelected:YES];
        [_homeButton setImage:[UIImage imageNamed:@"home-active.png"] forState:UIControlStateNormal];
        [_homeButton setSelected:NO];
        [_dealsButton setSelected:YES];
        [_settingsButton setSelected:YES];
        [_giftButton setSelected:YES];
        [_dealsButton setImage:[UIImage imageNamed:@"deals.png"] forState:UIControlStateSelected];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateSelected];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_giftButton setImage:[UIImage imageNamed:@"gift-icon.png"] forState:UIControlStateSelected];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        NSURL* urlapp =  [NSURL URLWithString:_browserOptions.closebuttoncolor];
        [self navigateTo:urlapp];
        
    }
    else if([_browserOptions.closebuttoncaption  isEqual: @"Deals"]){
        NSString *loadUrl = [_baseUrl stringByAppendingString:@"/p/sale"];
        _dealsSelected = false;
        _lastClicked = @"Deals";
        [_dealsButton setImage:[UIImage imageNamed:@"deals-active.png"] forState:UIControlStateNormal];
        [_dealsButton setSelected:NO];
        [_giftButton setSelected:YES];
        [_settingsButton setSelected:YES];
        [_homeButton setSelected:YES];
        [_dealsButton setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                                    green:184.0f/255.0f
                                                     blue:0.0f/255.0f
                                                    alpha:1.0f] forState:UIControlStateNormal];
        [_homeButton setImage:[UIImage imageNamed:@"home.png"] forState:UIControlStateSelected];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateSelected];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_giftButton setImage:[UIImage imageNamed:@"gift-icon.png"] forState:UIControlStateSelected];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        NSURL* urlapp =  [NSURL URLWithString:loadUrl];
        [self navigateTo:urlapp];
    }
    else if([_browserOptions.closebuttoncaption  isEqual: @"Gift guide"]){
        _gidtSelected = false;
        _lastClicked = @"Gift guide";
        NSString *loadUrl = [_baseUrl stringByAppendingString:@"/p/gift-center"];
        [_giftButton setImage:[UIImage imageNamed:@"gift-active.png"] forState:UIControlStateNormal];
        [_giftButton setSelected:NO];
        [_dealsButton setSelected:YES];
        [_settingsButton setSelected:YES];
        [_homeButton setSelected:YES];
        [_giftButton setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                                   green:184.0f/255.0f
                                                    blue:0.0f/255.0f
                                                   alpha:1.0f] forState:UIControlStateNormal];
        
        [_homeButton setImage:[UIImage imageNamed:@"home.png"] forState:UIControlStateSelected];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateSelected];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_dealsButton setImage:[UIImage imageNamed:@"deals.png"] forState:UIControlStateSelected];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        NSURL* urlapp =  [NSURL URLWithString:_browserOptions.closebuttoncolor];
        [self navigateTo:urlapp];
    }
    else if([_browserOptions.closebuttoncaption  isEqual: @"Settings"]){
        [_settingsButton setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                                       green:184.0f/255.0f
                                                        blue:0.0f/255.0f
                                                       alpha:1.0f] forState:UIControlStateSelected]; // SET the colour for your wishes
        [_settingsButton setImage:[UIImage imageNamed:@"settings-active.png"] forState:UIControlStateSelected];
        [_settingsButton setSelected:YES];
    }
    else{
        [_homeButton setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                                   green:184.0f/255.0f
                                                    blue:0.0f/255.0f
                                                   alpha:1.0f] forState:UIControlStateSelected]; // SET the colour for your wishes
        [_homeButton setImage:[UIImage imageNamed:@"home-active.png"] forState:UIControlStateSelected];
        [_homeButton setSelected:YES];
    }
    
    
    [self updateFramesOfTabBarButtons];
    
    
    
    
    
    NSString* frontArrowString = NSLocalizedString(@"►", nil); // create arrow from Unicode char
    self.forwardButton = [[UIBarButtonItem alloc] initWithTitle:frontArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goForward:)];
    self.forwardButton.enabled = YES;
    self.forwardButton.imageInsets = UIEdgeInsetsZero;
    if (_browserOptions.navigationbuttoncolor != nil) { // Set button color if user sets it in options
        self.forwardButton.tintColor = [self colorFromHexString:_browserOptions.navigationbuttoncolor];
    }
    
    NSString* backArrowString = NSLocalizedString(@"◄", nil); // create arrow from Unicode char
    self.backButton = [[UIBarButtonItem alloc] initWithTitle:backArrowString style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    self.backButton.enabled = YES;
    self.backButton.imageInsets = UIEdgeInsetsZero;
    if (_browserOptions.navigationbuttoncolor != nil) { // Set button color if user sets it in options
        self.backButton.tintColor = [self colorFromHexString:_browserOptions.navigationbuttoncolor];
    }
    
    // Filter out Navigation Buttons if user requests so
    if (_browserOptions.hidenavigationbuttons) {
        if (_browserOptions.lefttoright) {
            [self.toolbar setItems:@[flexibleSpaceButton, self.closeButton]];
        } else {
            [self.toolbar setItems:@[self.closeButton, flexibleSpaceButton]];
        }
    } else if (_browserOptions.lefttoright) {
        [self.toolbar setItems:@[self.backButton, fixedSpaceButton, self.forwardButton, flexibleSpaceButton, self.closeButton]];
    } else {
        [self.toolbar setItems:@[self.closeButton, flexibleSpaceButton, self.backButton, fixedSpaceButton, self.forwardButton]];
    }
 
    self.view.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.addressLabel];
    [self.view addSubview:self.spinner];
    
}



-(void)updateFramesOfTabBarButtons {
    
    if (@available(iOS 11.0, *)) {
        if (UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom > 0) {
            self.tabView.frame = CGRectMake(0, self.view.frame.size.height-80, self.view.frame.size.width, 80);
        } else {
            // iOS 10 or older code
            self.tabView.frame = CGRectMake(0, self.view.frame.size.height-60, self.view.frame.size.width, 60);
        }
    } else {
        self.tabView.frame = CGRectMake(0, self.view.frame.size.height-60, self.view.frame.size.width, 60);
    }
    if(_myProgressView.progress > 0.01){
    _showProgressView = true;
    [self showProgressBar];
    }
    float buttonWidth = self.tabView.frame.size.width/4;
    _homeButton.frame = CGRectMake(0, 0, buttonWidth, 50);
    [_homeButton setImageEdgeInsets:UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f)];
    [self updateImageAndTextIndsets:_homeButton];
    _dealsButton.frame = CGRectMake(_homeButton.frame.origin.x + _homeButton.frame.size.width, 0, buttonWidth, 50);
    [self updateImageAndTextIndsets:_dealsButton];
    _giftButton.frame = CGRectMake(_dealsButton.frame.origin.x + _dealsButton.frame.size.width, 0, buttonWidth, 50);
    [self updateImageAndTextIndsets:_giftButton];
    _settingsButton.frame = CGRectMake(_giftButton.frame.origin.x + _giftButton.frame.size.width, 0, buttonWidth, 50);
    [self updateImageAndTextIndsets:_settingsButton];
}
-(void)updateImageAndTextIndsets: (UIButton*) button {
    // the space between the image and text
    CGFloat spacing = 6.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = button.imageView.image.size;
    //    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    //
    //    // raise the image and push it right so it appears centered
    //    //  above the text
    //    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    //    button.imageEdgeInsets = UIEdgeInsetsMake( - (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
    button.titleEdgeInsets = UIEdgeInsetsMake(
                                              10, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(
                                              0.0, 0.0, 0.0, - titleSize.width);
    // increase the content height to avoid clipping
    CGFloat edgeOffset = fabsf(titleSize.height - imageSize.height) / 2.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(edgeOffset, 0.0, edgeOffset, 0.0);
}
-(void) loadProgressBar:(NSURL *)url
{
    // 1. Create a fak webview and bind the url source
    
    // 2.Add KVO and Get the estimated
    [self.webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
    
}

-(void)showProgressBar{
    
    if(_showProgressView){   // Here pass frame as per your requirement
        [_myProgressView removeFromSuperview];
        _myProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,90)];    // Here pass frame as per your requirement
        
        _myProgressView.tintColor = [UIColor colorWithRed:249.0f/255.0f
                                                                       green:249.0f/255.0f
                                                                        blue:249.0f/255.0f
                                                                       alpha:1.0f];
        _myProgressView.transform = CGAffineTransformMakeScale(1.0f, 2.0f);
        _myProgressView.hidden = NO;
        [_tabView addSubview:_myProgressView];
        
        //[self addProgress];
        
    }
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.webView) {
        {
            // if(self.fkWebView.estimatedProgress > 0.10 && self.fkWebView.estimatedProgress < 0.11){
            [_myProgressView setProgress:self.webView.estimatedProgress];
            // NSLog(@"+++++%f", _navigationDelegate.myProgressView.progress);
            if(self.webView.estimatedProgress >= 1.0f) {
                [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [_myProgressView setAlpha:0.0f];
                } completion:^(BOOL finished) {
                    [_myProgressView setProgress:0.0f animated:NO];
                    _myProgressView.tintColor = [UIColor colorWithRed:249.0f/255.0f
                                                                green:249.0f/255.0f
                                                                 blue:249.0f/255.0f
                                                                alpha:1.0f];
                }];
            }
            else{
                _myProgressView.tintColor = [UIColor colorWithRed:119.0f/255.0f
                                                            green:184.0f/255.0f
                                                             blue:0.0f/255.0f
                                                            alpha:1.0f];
            }
        
        }
    }
}
- (void) setWebViewFrame : (CGRect) frame {
    NSLog(@"Setting the WebView's frame to %@", NSStringFromCGRect(frame));
    [self.webView setFrame:frame];
}

- (void)setCloseButtonTitle:(NSString*)title : (NSString*) colorString : (int) buttonIndex
{
    // the advantage of using UIBarButtonSystemItemDone is the system will localize it for you automatically
    // but, if you want to set this yourself, knock yourself out (we can't set the title for a system Done button, so we have to create a new one)
    self.closeButton = nil;
    // Initialize with title if title is set, otherwise the title will be 'Done' localized
    self.closeButton = title != nil ? [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:self action:@selector(close)] : [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close)];
    self.closeButton.enabled = YES;
    // If color on closebutton is requested then initialize with that that color, otherwise use initialize with default
    self.closeButton.tintColor = colorString != nil ? [self colorFromHexString:colorString] : [UIColor colorWithRed:60.0 / 255.0 green:136.0 / 255.0 blue:230.0 / 255.0 alpha:1];
    
    NSMutableArray* items = [self.toolbar.items mutableCopy];
    [items replaceObjectAtIndex:buttonIndex withObject:self.closeButton];
    [self.toolbar setItems:items];
}

- (void)showLocationBar:(BOOL)show
{
    CGRect locationbarFrame = self.addressLabel.frame;
    
    BOOL toolbarVisible = !self.toolbar.hidden;
    
    // prevent double show/hide
    if (show == !(self.addressLabel.hidden)) {
        return;
    }
    
    if (show) {
        self.addressLabel.hidden = NO;
        
        if (toolbarVisible) {
            // toolBar at the bottom, leave as is
            // put locationBar on top of the toolBar
            
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= FOOTER_HEIGHT;
            [self setWebViewFrame:webViewBounds];
            
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        } else {
            // no toolBar, so put locationBar at the bottom
            
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];
            
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        }
    } else {
        self.addressLabel.hidden = YES;
        
        if (toolbarVisible) {
            // locationBar is on top of toolBar, hide locationBar
            
            // webView take up whole height less toolBar height
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];
        } else {
            // no toolBar, expand webView to screen dimensions
            [self setWebViewFrame:self.view.bounds];
        }
    }
}

- (void)showToolBar:(BOOL)show : (NSString *) toolbarPosition
{
    CGRect toolbarFrame = self.toolbar.frame;
    CGRect locationbarFrame = self.addressLabel.frame;
    
    BOOL locationbarVisible = !self.addressLabel.hidden;
    
    // prevent double show/hide
    if (show == !(self.toolbar.hidden)) {
        return;
    }
    
    if (show) {
        self.toolbar.hidden = NO;
        CGRect webViewBounds = self.view.bounds;
        
        if (locationbarVisible) {
            // locationBar at the bottom, move locationBar up
            // put toolBar at the bottom
            webViewBounds.size.height -= FOOTER_HEIGHT;
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
            self.toolbar.frame = toolbarFrame;
        } else {
            // no locationBar, so put toolBar at the bottom
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= TOOLBAR_HEIGHT;
            self.toolbar.frame = toolbarFrame;
        }
        
        if ([toolbarPosition isEqualToString:kInAppBrowserToolbarBarPositionTop]) {
            toolbarFrame.origin.y = 0;
            webViewBounds.origin.y += toolbarFrame.size.height;
            [self setWebViewFrame:webViewBounds];
        } else {
            toolbarFrame.origin.y = (webViewBounds.size.height + LOCATIONBAR_HEIGHT);
        }
        [self setWebViewFrame:webViewBounds];
        
    } else {
        self.toolbar.hidden = YES;
        
        if (locationbarVisible) {
            // locationBar is on top of toolBar, hide toolBar
            // put locationBar at the bottom
            
            // webView take up whole height less locationBar height
            CGRect webViewBounds = self.view.bounds;
            webViewBounds.size.height -= LOCATIONBAR_HEIGHT;
            [self setWebViewFrame:webViewBounds];
            
            // move locationBar down
            locationbarFrame.origin.y = webViewBounds.size.height;
            self.addressLabel.frame = locationbarFrame;
        } else {
            // no locationBar, expand webView to screen dimensions
            [self setWebViewFrame:self.view.bounds];
        }
    }
}

- (void)viewDidLoad
{
    viewRenderedAtLeastOnce = FALSE;
    CTTelephonyNetworkInfo *phoneInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *phoneCarrier = [phoneInfo subscriberCellularProvider];
    NSLog(@"Carrier = %@", [phoneCarrier carrierName]);
    _navigationDelegate.cellularName = [phoneCarrier carrierName];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStatusBarWillChange) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    [super viewDidLoad];
}
-(void)didStatusBarWillChange{
    if([self getNavHeight] == 40){
        self.tabView.frame = CGRectMake(0, self.view.frame.size.height-80, self.view.frame.size.width, 60);
    }
    else if([self getNavHeight] == 20){
        self.tabView.frame = CGRectMake(0, self.view.frame.size.height-40, self.view.frame.size.width, 60);
    }
}
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (isExiting && (self.navigationDelegate != nil) && [self.navigationDelegate respondsToSelector:@selector(browserExit)]) {
        [self.navigationDelegate browserExit];
        isExiting = FALSE;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
     if ([[UIDevice currentDevice]orientation] != UIInterfaceOrientationPortrait){
         return YES;
     }
     else{
         return NO;
     }
}
- (void)close
{
    [CDVUserAgentUtil releaseLock:&_userAgentLockToken];
    self.currentURL = nil;
    
    __weak UIViewController* weakSelf = self;
    
    // Run later to avoid the "took a long time" log message.
    dispatch_async(dispatch_get_main_queue(), ^{
        isExiting = TRUE;
        if ([weakSelf respondsToSelector:@selector(presentingViewController)]) {
            [[weakSelf presentingViewController] dismissViewControllerAnimated:YES completion:nil];
        } else {
            [[weakSelf parentViewController] dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

- (void)navigateTo:(NSURL*)url
{
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    if (_userAgentLockToken != 0) {
        [self.webView loadRequest:request];
    } else {
        __weak CDVWKInAppBrowserViewController* weakSelf = self;
        [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
            _userAgentLockToken = lockToken;
            [CDVUserAgentUtil setUserAgent:_CPUserAgent lockToken:lockToken];
            [weakSelf.webView loadRequest:request];
        }];
    }
}

- (void)goBack:(id)sender
{
    [self.webView goBack];
}

-(void)goHome:()sender
{
    _homeSelected = true;
    _settingsSelected =false;
    _gidtSelected = false;
    _dealsSelected = false;
    
    if (_homeSelected) {
        _homeSelected = false;
        _lastClicked = @"Featured";
        [sender setImage:[UIImage imageNamed:@"home-active.png"] forState:UIControlStateNormal];
        [sender setSelected:NO];
        [_dealsButton setSelected:YES];
        [_settingsButton setSelected:YES];
        [_giftButton setSelected:YES];
        [sender setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                              green:184.0f/255.0f
                                               blue:0.0f/255.0f
                                              alpha:1.0f] forState:UIControlStateNormal];
        [_dealsButton setImage:[UIImage imageNamed:@"deals.png"] forState:UIControlStateSelected];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateSelected];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_giftButton setImage:[UIImage imageNamed:@"gift-icon.png"] forState:UIControlStateSelected];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        NSURL* urlapp =  [NSURL URLWithString:_baseUrl];
        [self navigateTo:urlapp];
        
        
    } else {
        [sender setImage:[UIImage imageNamed:@"home.png"] forState:UIControlStateSelected];
        [sender setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [sender setSelected:YES];
    }
}


-(void)goDeals:()sender
{
    
    _dealsSelected = true;
    _homeSelected = false;
    _settingsSelected =false;
    _gidtSelected = false;
    NSString *loadUrl = [_baseUrl stringByAppendingString:@"/p/sale"];
    if (_dealsSelected) {
        _dealsSelected = false;
        _lastClicked = @"Deals";
        [sender setImage:[UIImage imageNamed:@"deals-active.png"] forState:UIControlStateNormal];
        [sender setSelected:NO];
        [_giftButton setSelected:YES];
        [_settingsButton setSelected:YES];
        [_homeButton setSelected:YES];
        [sender setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                              green:184.0f/255.0f
                                               blue:0.0f/255.0f
                                              alpha:1.0f] forState:UIControlStateNormal];
        [_homeButton setImage:[UIImage imageNamed:@"home.png"] forState:UIControlStateSelected];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateSelected];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_giftButton setImage:[UIImage imageNamed:@"gift-icon.png"] forState:UIControlStateSelected];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        NSURL* urlapp =  [NSURL URLWithString:loadUrl];
        [self navigateTo:urlapp];
    } else {
        [sender setImage:[UIImage imageNamed:@"deals.png"] forState:UIControlStateNormal];
        [sender setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [sender setSelected:YES];
    }
    
}
-(void)goGift:()sender
{
    
    _gidtSelected = true;
    _dealsSelected = false;
    _homeSelected = false;
    _settingsSelected =false;
    NSString *loadUrl = [_baseUrl stringByAppendingString:@"/p/gift-center"];
    if (_gidtSelected) {
        _gidtSelected = false;
        _lastClicked = @"Gift guide";
        [sender setImage:[UIImage imageNamed:@"gift-active.png"] forState:UIControlStateNormal];
        [sender setSelected:NO];
        [_dealsButton setSelected:YES];
        [_settingsButton setSelected:YES];
        [_homeButton setSelected:YES];
        [sender setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                              green:184.0f/255.0f
                                               blue:0.0f/255.0f
                                              alpha:1.0f] forState:UIControlStateNormal];
        
        [_homeButton setImage:[UIImage imageNamed:@"home.png"] forState:UIControlStateSelected];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_settingsButton setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateSelected];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_dealsButton setImage:[UIImage imageNamed:@"deals.png"] forState:UIControlStateSelected];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        NSURL* urlapp =  [NSURL URLWithString:loadUrl];
        [self navigateTo:urlapp];
    } else {
        [sender setImage:[UIImage imageNamed:@"gift-icon.png"] forState:UIControlStateNormal];
        [sender setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [sender setSelected:YES];
    }
    
}
-(void)goSettings:()sender
{
    
    _settingsSelected =true;
    _gidtSelected = false;
    _dealsSelected = false;
    _homeSelected = false;
    
    if (_settingsSelected) {
        _settingsSelected=false;
        [sender setImage:[UIImage imageNamed:@"settings-active.png"] forState:UIControlStateSelected];
        [sender setSelected:NO];
        [sender setTitleColor:[UIColor colorWithRed:119.0f/255.0f
                                              green:184.0f/255.0f
                                               blue:0.0f/255.0f
                                              alpha:1.0f] forState:UIControlStateSelected];
        [_homeButton setImage:[UIImage imageNamed:@"home.png"] forState:UIControlStateSelected];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_dealsButton setImage:[UIImage imageNamed:@"deals.png"] forState:UIControlStateSelected];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_giftButton setImage:[UIImage imageNamed:@"gift-icon.png"] forState:UIControlStateSelected];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        NSURL* urlapp =  [NSURL URLWithString:@"gotosettings.com"];
        [self navigateTo:urlapp];
    } else {
        [sender setImage:[UIImage imageNamed:@"settings.png"] forState:UIControlStateNormal];
        [sender setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_homeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_dealsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_giftButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [sender setSelected:YES];
    }
    
}
- (void)goForward:(id)sender
{
    [self.webView goForward];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (IsAtLeastiOSVersion(@"7.0") && !viewRenderedAtLeastOnce) {
        viewRenderedAtLeastOnce = TRUE;
        
        self.statusBar = (UIView *)[[UIApplication sharedApplication] valueForKey:@"statusBar"];
        self.statusBar.backgroundColor = [UIColor whiteColor];
        self.webView.backgroundColor = [UIColor whiteColor];
        CGRect viewBounds = [self.webView bounds];
        float navHeight = [self getNavHeight];
        if (navHeight == 44) {
            self.statusBar .frame = CGRectMake(0, 0, viewBounds.size.width, STATUSBAR_HEIGHT+20);
            viewBounds.origin.y = STATUSBAR_HEIGHT+20;
            viewBounds.size.height = self.view.frame.size.height - (70 + viewBounds.origin.y );
        }
        else if(navHeight == 20){
            viewBounds.origin.y = STATUSBAR_HEIGHT;
            viewBounds.size.height = self.view.frame.size.height - (50 + viewBounds.origin.y );
        }
        else if(navHeight == 0){
                viewBounds.size.height = self.view.frame.size.height - (50 + viewBounds.origin.y );
        }
        else if(navHeight == 40){
            viewBounds.origin.y = STATUSBAR_HEIGHT;
            viewBounds.size.height = self.view.frame.size.height - (50 + viewBounds.origin.y );
        }
        self.webView.frame = viewBounds;
        [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle]];
    }
    [self rePositionViews];
    [super viewWillAppear:animated];
}
-(float)getNavHeight{
    return [UIApplication sharedApplication].statusBarFrame.size.height;
}

//
// On iOS 7 the status bar is part of the view's dimensions, therefore it's height has to be taken into account.
// The height of it could be hardcoded as 20 pixels, but that would assume that the upcoming releases of iOS won't
// change that value.
//
- (float) getStatusBarOffset {
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    float statusBarOffset = IsAtLeastiOSVersion(@"7.0") ? MIN(statusBarFrame.size.width, statusBarFrame.size.height) : 0.0;
    return statusBarOffset;
}

- (void) rePositionViews {
    if ([_browserOptions.toolbarposition isEqualToString:kInAppBrowserToolbarBarPositionTop]) {
        [self.webView setFrame:CGRectMake(self.webView.frame.origin.x, TOOLBAR_HEIGHT, self.webView.frame.size.width, self.webView.frame.size.height)];
        [self.toolbar setFrame:CGRectMake(self.toolbar.frame.origin.x, [self getStatusBarOffset], self.toolbar.frame.size.width, self.toolbar.frame.size.height)];
    }
}

// Helper function to convert hex color string to UIColor
// Assumes input like "#00FF00" (#RRGGBB).
// Taken from https://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

#pragma mark WKNavigationDelegate

- (void)webView:(WKWebView *)theWebView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
    // loading url, start spinner, update back/forward
    
    self.addressLabel.text = NSLocalizedString(@"Loading...", nil);
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    
    NSLog(_browserOptions.hidespinner ? @"Yes" : @"No");
    if(!_browserOptions.hidespinner) {
        //[self.spinner startAnimating];
    }
    
    return [self.navigationDelegate didStartProvisionalNavigation:theWebView];
}

- (void)webView:(WKWebView *)theWebView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    NSURL *mainDocumentURL = navigationAction.request.mainDocumentURL;
    
    // 2.Add KVO and Get the estimated
    [self.webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];
    
    BOOL isTopLevelNavigation = [url isEqual:mainDocumentURL];
    
    if (isTopLevelNavigation) {
        self.currentURL = url;
        _showProgressView = true;
        [self showProgressBar];
    }
    
    [self.navigationDelegate webView:theWebView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
}

- (void)webView:(WKWebView *)theWebView didFinishNavigation:(WKNavigation *)navigation
{
    // update url, stop spinner, update back/forward
    
    self.addressLabel.text = [self.currentURL absoluteString];
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    theWebView.scrollView.contentInset = UIEdgeInsetsZero;
    
    [self.spinner stopAnimating];
    
    // Work around a bug where the first time a PDF is opened, all UIWebViews
    // reload their User-Agent from NSUserDefaults.
    // This work-around makes the following assumptions:
    // 1. The app has only a single Cordova Webview. If not, then the app should
    //    take it upon themselves to load a PDF in the background as a part of
    //    their start-up flow.
    // 2. That the PDF does not require any additional network requests. We change
    //    the user-agent here back to that of the CDVViewController, so requests
    //    from it must pass through its white-list. This *does* break PDFs that
    //    contain links to other remote PDF/websites.
    // More info at https://issues.apache.org/jira/browse/CB-2225
    BOOL isPDF = NO;
    //TODO webview class
    //BOOL isPDF = [@"true" isEqualToString :[theWebView evaluateJavaScript:@"document.body==null"]];
    if (isPDF) {
        [CDVUserAgentUtil setUserAgent:_prevUserAgent lockToken:_userAgentLockToken];
    }
    
    [self.navigationDelegate didFinishNavigation:theWebView];
}

- (void)webView:(WKWebView*)theWebView failedNavigation:(NSString*) delegateName withError:(nonnull NSError *)error{
    // log fail message, stop spinner, update back/forward
    NSLog(@"webView:%@ - %ld: %@", delegateName, (long)error.code, [error localizedDescription]);
    
    self.backButton.enabled = theWebView.canGoBack;
    self.forwardButton.enabled = theWebView.canGoForward;
    [self.spinner stopAnimating];
    
    self.addressLabel.text = NSLocalizedString(@"Load Error", nil);
    
    [self.navigationDelegate webView:theWebView didFailNavigation:error];
}

- (void)webView:(WKWebView*)theWebView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailNavigation" withError:error];
}

- (void)webView:(WKWebView*)theWebView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self webView:theWebView failedNavigation:@"didFailProvisionalNavigation" withError:error];
}

#pragma mark WKScriptMessageHandler delegate
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    if (![message.name isEqualToString:IAB_BRIDGE_NAME]) {
        return;
    }
    //NSLog(@"Received script message %@", message.body);
    [self.navigationDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

#pragma mark CDVScreenOrientationDelegate

- (BOOL)shouldAutorotate
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.orientationDelegate shouldAutorotate];
    }
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.orientationDelegate supportedInterfaceOrientations];
    }
    
    return 1 << UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((self.orientationDelegate != nil) && [self.orientationDelegate respondsToSelector:@selector(shouldAutorotateToInterfaceOrientation:)]) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Code here will execute before the rotation begins.
    // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Place code here to perform animations during the rotation.
        // You can pass nil or leave this block empty if not necessary.
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Code here will execute after the rotation has finished.
        // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        CGRect viewBounds = [self.webView bounds];

        if ([self getNavHeight] == 44) {
            [self setFrameForNotch];
        }
        else if([self getNavHeight] == 0){
            viewBounds.size.height = self.view.frame.size.height - (50 + viewBounds.origin.y );
            self.webView.frame = viewBounds;
        }
        else if([self getNavHeight] == 20 || [self getNavHeight]  == 40) {
            viewBounds.origin.y = STATUSBAR_HEIGHT;
            viewBounds.size.height = self.view.frame.size.height - (50 + viewBounds.origin.y );
            self.webView.frame = viewBounds;
        }
        self.tabView.frame = CGRectMake(0, self.view.frame.size.height-60, self.view.frame.size.width, 60);
        [self updateFramesOfTabBarButtons];
    }];
}
-(void)setFrameForNotch{
    CGRect viewBounds = [self.webView bounds];
    self.statusBar.backgroundColor = [UIColor whiteColor];
    if ([[UIDevice currentDevice]orientation] == UIInterfaceOrientationLandscapeLeft){
        self.statusBar .frame = CGRectMake(0, STATUSBAR_HEIGHT , viewBounds.size.width, viewBounds.origin.y);
        self.webView.frame = CGRectMake(0, 0, viewBounds.size.width, self.view.frame.size.height - 70) ;
    }
    else if ([[UIDevice currentDevice]orientation] == UIInterfaceOrientationPortrait){
        viewBounds.origin.y = STATUSBAR_HEIGHT+20;
        self.statusBar .frame = CGRectMake(0, 0, viewBounds.size.width, viewBounds.origin.y);
        self.webView.frame = CGRectMake(0, viewBounds.origin.y, viewBounds.size.width, self.view.frame.size.height - (70 + viewBounds.origin.y ));
    }
}
@end //CDVWKInAppBrowserViewController

