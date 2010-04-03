//
//  MGISPolyline.h
//  mgis
//
//  Created by naoki iimura on 3/20/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGISContent.h"


@interface MGISPolyline : MGISContent <NSCoding> {
    CGFloat lineWidth;
    NSBezierPath *shapeBezier;
    NSColor *lineColor;
}

- (float) calcDistance:(NSPoint)point lineFrom:(NSPoint)lineStart lineTo:(NSPoint)lineEnd;

@property CGFloat lineWidth;
@property (retain) NSBezierPath *shapeBezier;
@property (retain) NSColor *lineColor;

@end
