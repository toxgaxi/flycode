//
//  JSTalk.m
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTalk.h"
#import "JSTListener.h"
#import "JSTPreprocessor.h"
#import <ScriptingBridge/ScriptingBridge.h>

@interface JSTalk (Private)
- (void) print:(NSString*)s;
@end


@implementation JSTalk
@synthesize printController=_printController;
@synthesize errorController=_errorController;

+ (void) load {
    //debug(@"%s:%d", __FUNCTION__, __LINE__);
}

+ (void) listen {
    [JSTListener listen];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void) pushObject:(id)obj withName:(NSString*)name inController:(JSCocoaController*)jsController {
    
    JSContextRef ctx                = [jsController ctx];
    JSStringRef jsName              = JSStringCreateWithUTF8CString([name UTF8String]);
    JSObjectRef jsObject            = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
    JSCocoaPrivateObject *private   = JSObjectGetPrivate(jsObject);
    private.type = @"@";
    [private setObject:obj];
    
    JSObjectSetProperty(ctx, JSContextGetGlobalObject(ctx), jsName, jsObject, 0, NULL);
    JSStringRelease(jsName);  
}


- (void) executeString:(NSString*) str {
    
    str = [JSTPreprocessor preprocessCode:str];
        
    JSCocoaController *jsController = [JSCocoaController sharedController];
    
    [self pushObject:self withName:@"jstalk" inController:jsController];
    
    @try {
        [jsController setUseAutoCall:NO];
        [jsController evalJSString:[NSString stringWithFormat:@"function print(s) { jstalk.print_(s); } var nil=null; %@", str]];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [self print:[e description]];
    }
    @finally {
        //
    }
}

- (JSCocoaController*) jsController {
    // right now we just return a shared one.
    return [JSCocoaController sharedController];
}

- (id) callFunctionNamed:(NSString*)name withArguments:(NSArray*)args {
    
    JSCocoaController *jsController = [self jsController];
    JSContextRef ctx                = [jsController ctx];
    
    JSValueRef exception            = 0x00;   
    JSStringRef functionName        = JSStringCreateWithUTF8CString([name UTF8String]);
    JSValueRef functionValue        = JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx), functionName, &exception);
    
    JSStringRelease(functionName);  
    
    JSValueRef returnValue = [jsController callJSFunction:functionValue withArguments:args];
    
    id returnObject;
    [JSCocoaFFIArgument unboxJSValueRef:returnValue toObject:&returnObject inContext:ctx];
    
    return returnObject;
}



- (void) print:(NSString*)s {
    
    if (_printController && [_printController respondsToSelector:@selector(print:)]) {
        [_printController print:s];
    }
    else {
        printf("%s\n", [s UTF8String]);
    }
}




+ (id) proxyForApp:(NSString*)app {
    
    NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:app];
    
    if (!appPath) {
        NSLog(@"Could not find application '%@'", app);
        return [NSNumber numberWithBool:NO];
    }
    
    NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
    NSString *bundleId  = [appBundle bundleIdentifier];
    
    // make sure it's running
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bundleId
                                                         options:NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync
                                  additionalEventParamDescriptor:nil
                                                launchIdentifier:nil];
    
    NSString *port      = [NSString stringWithFormat:@"%@.JSTalk", bundleId];
    NSConnection *conn  = 0x00;
    NSUInteger tries    = 0;
    
    while (!conn && tries < 10) {
        
        conn = [NSConnection connectionWithRegisteredName:port host:nil];
        tries++;
        if (!conn) {
            debug(@"Sleeping, waiting for %@ to open its port", app);
            sleep(1);
        }
    }
    
    if (!conn) {
        NSBeep();
        NSLog(@"Could not find a JSTalk connection to %@", app);
    }
    
    return [conn rootProxy];
    
}

@end
