//
//  MGISPolyline.m
//  mgis
//
//  Created by naoki iimura on 3/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MGISPolyline.h"


@implementation MGISPolyline

@synthesize bounds;
@synthesize points;
@synthesize lineWidth;
@synthesize lineColor;

- (id)init {
    
    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {
        
        // Set up decent defaults for a new graphic.
        self.bounds = NSZeroRect;
        self.points = [[NSMutableArray alloc] init];
        self.lineColor = [[NSColor blackColor] retain];
        self.lineWidth = 3.0f;
    }
    return self;
}

- (void)dealloc {
    
    // Do the regular Cocoa thing.
    [self.lineColor release];
    [super dealloc];
    
}

- (void)addPoint:(NSPoint)aPoint {
    NSValue *aValue = [NSValue valueWithPoint:aPoint];
    [self.points addObject:aValue];
//    [aValue release];
}

- (void)draw {
    [self.lineColor set];
    NSBezierPath *polyBezier = [NSBezierPath bezierPath];
    [polyBezier setLineWidth:self.lineWidth];
    NSInteger pointCount = [self.points count];
    for ( NSInteger index = 0; index < pointCount; index++ ) {
        NSValue *pointObject = [self.points objectAtIndex:index];
        NSPoint point = [pointObject pointValue];
        if ( index == 0 ) {
            [polyBezier moveToPoint:point];
        } else {
            [polyBezier lineToPoint:point];
        }
//        [NSBezierPath strokeLineFromPoint:_endPoint toPoint:_ctrlPoint2];
    }
    [polyBezier stroke];
}

@end
