//
//  MGISContent.h
//  mgis
//
//  Created by naoki iimura on 4/3/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MGISContent : NSObject <NSCoding> {
    NSRect bounds;
    NSManagedObjectID *objectID;
}

- (void) addPoint:(NSPoint)aPoint;
- (void) insertPoint:(NSPoint)aPoint atIndex:(NSInteger)index;
- (void) deletePointAtIndex:(NSInteger)index;
- (NSPoint) getPointAtIndex:(NSInteger)index;
- (void) setLineWidth:(CGFloat)width;
- (CGFloat) lineWidth;
- (void) setLineColor:(NSColor *)color;
- (NSColor *) lineColor;
- (void) draw:(BOOL)selected;
- (BOOL) clickCheck:(NSPoint)aPoint;
- (NSInteger) clickedControlPoint:(NSPoint)aPoint;
- (NSInteger) clickedBetweenControlPoint:(NSPoint)aPoint;
- (void) moveControlPointTo:(NSPoint)point atIndex:(NSInteger)index;
- (void) applyAffineTransform:(NSAffineTransform *)transform;
- (NSPoint) representativePoint;

@property NSRect bounds;
@property (retain) NSManagedObjectID *objectID;

@end
