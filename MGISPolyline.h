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
    CGFloat lineWidth;
    NSBezierPath *shapeBezier;
    NSColor *lineColor;
    NSManagedObjectID *objectID;
}

- (void) addPoint:(NSPoint)aPoint;
- (void) insertPoint:(NSPoint)aPoint atIndex:(NSInteger)index;
- (void) deletePointAtIndex:(NSInteger)index;
- (void) draw:(BOOL)selected;
- (BOOL) clickCheck:(NSPoint)point;
- (NSInteger) clickedControlPoint:(NSPoint)point;
- (NSInteger) clickedBetweenControlPoint:(NSPoint)point;
- (void) moveControlPointTo:(NSPoint)point atIndex:(NSInteger)index;
- (float) calcDistance:(NSPoint)point lineFrom:(NSPoint)lineStart lineTo:(NSPoint)lineEnd;

@property NSRect bounds;
@property CGFloat lineWidth;
@property (retain) NSBezierPath *shapeBezier;
@property (retain) NSColor *lineColor;
@property (retain) NSManagedObjectID *objectID;

@end
