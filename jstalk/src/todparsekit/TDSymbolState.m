//
//  TDSymbolState.m
//  TDParseKit
//
//  Created by Todd Ditchendorf on 1/20/06.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <TDParseKit/TDSymbolState.h>
#import <TDParseKit/TDToken.h>
#import <TDParseKit/TDSymbolRootNode.h>
#import <TDParseKit/TDReader.h>
#import <TDParseKit/TDTokenizer.h>

@interface TDSymbolState ()
@property (nonatomic, retain) TDSymbolRootNode *rootNode;
@property (nonatomic, retain) NSMutableArray *addedSymbols;
@end

@implementation TDSymbolState

- (id)init {
    self = [super init];
    if (self) {
        self.rootNode = [[[TDSymbolRootNode alloc] init] autorelease];
        self.addedSymbols = [NSMutableArray array];
    }
    return self;
}


- (void)dealloc {
    self.rootNode = nil;
    self.addedSymbols = nil;
    [super dealloc];
}


- (TDToken *)nextTokenFromReader:(TDReader *)r startingWith:(NSInteger)cin tokenizer:(TDTokenizer *)t {
    NSParameterAssert(r);
    NSString *symbol = [rootNode nextSymbol:r startingWith:cin];
    NSInteger len = symbol.length;

    if (0 == len || (len > 1 && [addedSymbols containsObject:symbol])) {
        return [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:symbol floatValue:0.0];
    } else {
        NSInteger i = 0;
        for ( ; i < len - 1; i++) {
            [r unread];
        }
        return [TDToken tokenWithTokenType:TDTokenTypeSymbol stringValue:[NSString stringWithFormat:@"%C", cin] floatValue:0.0];
    }
}


- (void)add:(NSString *)s {
    NSParameterAssert(s);
    [rootNode add:s];
    [addedSymbols addObject:s];
}


- (void)remove:(NSString *)s {
    NSParameterAssert(s);
    [rootNode remove:s];
    [addedSymbols removeObject:s];
}

@synthesize rootNode;
@synthesize addedSymbols;
@end
