//
//  MGISPolyline.h
//  mgis
//
//  Created by naoki iimura on 3/20/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MGISPolyline : NSObject <NSCoding> {
    NSRect bounds;
    NSMutableArray *points;
    CGFloat lineWidth;
    NSBezierPath *shapeBezier;
    NSColor *lineColor;
    NSManagedObjectID *objectID;
}

- (void) addPoint:(NSPoint)aPoint;
- (void) draw:(BOOL)selected;
- (BOOL) clickCheck:(NSPoint)point;
- (float) calcDistance:(NSPoint)point lineFrom:(NSPoint)lineStart lineTo:(NSPoint)lineEnd;

@property NSRect bounds;
@property (retain) NSMutableArray *points;
@property CGFloat lineWidth;
@property (retain) NSBezierPath *shapeBezier;
@property (retain) NSColor *lineColor;
@property (retain) NSManagedObjectID *objectID;

@end
