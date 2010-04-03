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
- (void) setLineWidth:(CGFloat)width;
- (CGFloat) getLineWidth;
- (void) setLineColor:(NSColor *)color;
- (NSColor *) getLineColor;
- (void) draw:(BOOL)selected;
- (BOOL) clickCheck:(NSPoint)point;
- (NSInteger) clickedControlPoint:(NSPoint)point;
- (NSInteger) clickedBetweenControlPoint:(NSPoint)point;
- (void) moveControlPointTo:(NSPoint)point atIndex:(NSInteger)index;
- (void) applyAffineTransform:(NSAffineTransform *)transform;

@property NSRect bounds;
@property (retain) NSManagedObjectID *objectID;

@end
