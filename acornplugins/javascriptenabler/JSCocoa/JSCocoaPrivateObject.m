//
//  JSCocoaPrivateObject.m
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaPrivateObject.h"
#import "JSCocoaController.h"

@implementation JSCocoaPrivateObject

@synthesize type, xml, declaredType, methodName, structureName, isAutoCall;


- (id)init
{
	id r = [super init];

	type = xml = declaredType = methodName = nil;
	object		= nil;
	isAutoCall	= NO;
	jsValue		= NULL;
	retainObject	= YES;
	rawPointer	= NULL;
	
	
	[JSCocoaController upJSCocoaPrivateObjectCount];
	return	r;
}

- (void)dealloc
{
	[JSCocoaController downJSCocoaPrivateObjectCount];
//	if (object)	NSLog(@"GO for release (%@) %x %d", [object class], object, [object retainCount]);
	if (object && retainObject)
	{
//		NSLog(@"released !");
		[object release];
	}
	if (jsValue)		
	{
		JSValueUnprotect(ctx, jsValue);
		[JSCocoaController downJSValueProtectCount];
	}
	[super dealloc];
}

- (void)setObject:(id)o
{
	object = o;


	if (object && [object retainCount] == -1)	return;
	[object retain];
}

- (id)object
{
	return	object;
}

- (void)setObjectNoRetain:(id)o
{
	object = o;
	retainObject = NO;
}



- (void)setMethod:(Method)m
{
	method = m;
}
- (Method)method
{
	return method;
}

- (void)setJSValueRef:(JSValueRef)v ctx:(JSContextRef)c;
{
	// While autocalling we'll get a NULL value when boxing a void return type - just skip JSValueProtect
	if (!v)	
	{
//		NSLog(@"setJSValueRef: NULL value");
		jsValue = 0;
		return;
	}
	jsValue = v;
	ctx		= c;
	JSValueProtect(ctx, jsValue);
	[JSCocoaController upJSValueProtectCount];
}
- (JSValueRef)jsValueRef
{
	return	jsValue;
}


- (void*)rawPointer	
{
	return	rawPointer;
}
- (void)setRawPointer:(void*)rp
{
	rawPointer = rp;
}

@end








