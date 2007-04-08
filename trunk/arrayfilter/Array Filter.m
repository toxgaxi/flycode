//
//  Array Filter.m
//  Array Filter
//
//  Created by August Mueller on 4/8/07.
//  Copyright 2007 Flying Meat Inc.. All rights reserved.
//

#import "Array Filter.h"

#define debug NSLog

@implementation Array_Filter

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo {
    
    NSMutableArray *output = [NSMutableArray array];
    NSString *suffixFilter = [[self parameters] objectForKey:@"suffixFilter"];
    BOOL     negateSuffix  = [[[self parameters] objectForKey:@"negateSuffix"] boolValue];
    
    for (id item in input) {
        
        if (negateSuffix && (![[item description] hasSuffix:suffixFilter])) {
            [output addObject:item];
        }
        else if (!negateSuffix && [[item description] hasSuffix:suffixFilter]) {
            [output addObject:item];
        }
        
    }
    
	return output;
}

@end
