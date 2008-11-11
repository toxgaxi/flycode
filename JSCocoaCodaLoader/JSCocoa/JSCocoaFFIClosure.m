//
//  JSCocoaFFIClosure.m
//  JSCocoa
//
//  Created by Patrick Geiller on 29/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "JSCocoaFFIClosure.h"
#import	"JSCocoaController.h"

@implementation JSCocoaFFIClosure


//
// Common closure function, calling back closure object
//
void closure_function(ffi_cif* cif, void* resp, void** args, void* userdata)
{
	[(id)userdata calledByClosureWithArgs:args returnValue:resp];
}

- (id)init
{
	id o	= [super init];

	argTypes		= NULL;
	encodings		= NULL;
	jsFunction		= NULL;

	return	o;
}

- (void)dealloc
{
	if (encodings)	[encodings release];
	if (argTypes)	free(argTypes);

	if (jsFunction)	
	{
		JSValueUnprotect(ctx, jsFunction);
		[JSCocoaController downJSValueProtectCount];
	}
//	NSLog(@"ClosureDealloc %x", self);
	[super dealloc];
}

- (void*)functionPointer
{
	return	&closure;
}



//
// Bind a js function to closure. We'll jsValueProtect that function from GC.
//
- (void)setJSFunction:(JSValueRef)fn inContext:(JSContextRef)context argumentEncodings:(NSMutableArray*)argumentEncodings objC:(BOOL)objC
{
	if ([argumentEncodings count] == 0)	return;
	
	encodings = argumentEncodings;
	[encodings retain];
	jsFunction	= fn;
	ctx			= context;
	isObjC		= objC;
	
	int i, argumentCount = [argumentEncodings count]-1;
	argTypes = malloc(sizeof(ffi_type*)*argumentCount);
	for (i=0; i<argumentCount; i++)
	{
		JSCocoaFFIArgument*	arg	= [argumentEncodings objectAtIndex:i+1];
		argTypes[i]				= [arg ffi_type];
	}

	id returnValue = [argumentEncodings objectAtIndex:0];
	ffi_status prep_status	= ffi_prep_cif(&cif, FFI_DEFAULT_ABI, argumentCount, [returnValue ffi_type], argTypes);
	if (prep_status != FFI_OK)	return;
	
	ffi_prep_closure(&closure, &cif, closure_function, (void *)self); 
	
	// Protect function from GC
	JSValueProtect(ctx, jsFunction);
	[JSCocoaController upJSValueProtectCount];
}



//
// Called by ffi
//
- (void)calledByClosureWithArgs:(void**)closureArgs returnValue:(void*)returnValue
{
	JSObjectRef jsFunctionObject = JSValueToObject(ctx, jsFunction, NULL);
	JSValueRef	exception = NULL;
	

	// ## Only objC for now. Need to test C function pointers.
	
	// Argument count is encodings count minus return value
	int	i, idx = 0, effectiveArgumentCount = [encodings count]-1;
	// Skip self and selector
	if (isObjC)
	{
		effectiveArgumentCount -= 2;
		idx = 2;
	}
	// Convert arguments
	JSValueRef*	args = NULL;
	if (effectiveArgumentCount)
	{
		args = malloc(effectiveArgumentCount*sizeof(JSValueRef));
		for (i=0; i<effectiveArgumentCount; i++, idx++)
		{
			// +1 to skip return value
			id encodingObject = [encodings objectAtIndex:idx+1];

			id arg = [[JSCocoaFFIArgument alloc] init];
			char encoding = [encodingObject typeEncoding];
			if (encoding == '{')	[arg setStructureTypeEncoding:[encodingObject structureTypeEncoding] withCustomStorage:*(void**)&closureArgs[idx]];
			else					[arg setTypeEncoding:[encodingObject typeEncoding] withCustomStorage:closureArgs[idx]];
			
			args[i] = NULL;
			[arg toJSValueRef:&args[i] inContext:ctx];
			
			[arg release];
		}
	}
	
	JSObjectRef jsThis = NULL;
	
	// Create 'this'
	if (isObjC)
	{
		jsThis = [JSCocoaController jsCocoaPrivateObjectInContext:ctx];
		id this = *(void**)closureArgs[0];
		JSCocoaPrivateObject* private = JSObjectGetPrivate(jsThis);
		private.type = @"@";
		// If we've overloaded retain, we'll be calling ourselves until the stack dies
		[private setObjectNoRetain:this];
	}

	// Call !
	JSValueRef jsReturnValue = JSObjectCallAsFunction(ctx, jsFunctionObject, jsThis, effectiveArgumentCount, args, &exception);

	// Convert return value if it's not void
	char encoding = [[encodings objectAtIndex:0] typeEncoding];
	if (jsReturnValue && encoding != 'v')
	{
		[JSCocoaFFIArgument fromJSValueRef:jsReturnValue inContext:ctx withTypeEncoding:encoding withStructureTypeEncoding:[[encodings objectAtIndex:0] structureTypeEncoding] fromStorage:returnValue];
#ifdef __BIG_ENDIAN__
		// As ffi always uses a sizeof(long) return value (even for chars and shorts), do some shifting
		int size = [JSCocoaFFIArgument sizeOfTypeEncoding:encoding];
		int paddedSize = sizeof(long);
		long	v; 
		if (size > 0 && size < paddedSize && paddedSize == 4)
		{
			v = *(long*)returnValue;
			v = CFSwapInt32(v);
			*(long*)returnValue = v;
		}
#endif	
	}

	if (effectiveArgumentCount)	free(args);
	if (exception)	NSLog(@"%@", [[JSCocoaController sharedController] formatJSException:exception]);
}



@end
