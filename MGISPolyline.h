//
//  MGISPolyline.h
//  mgis
//
//  Created by naoki iimura on 3/20/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGISPolyline : NSObject {
    NSRect bounds;
    NSMutableArray *points;
    CGFloat lineWidth;
    NSColor *lineColor;
}

- (void) addPoint:(NSPoint)aPoint;
- (void) draw;

@property NSRect bounds;
@property (retain) NSMutableArray *points;
@property CGFloat lineWidth;
@property (retain) NSColor *lineColor;

@end
