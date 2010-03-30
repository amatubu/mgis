//
//  MGISPolyline.m
//  mgis
//
//  Created by naoki iimura on 3/20/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "MGISPolyline.h"


@implementation MGISPolyline

@synthesize bounds;
@synthesize lineWidth;
@synthesize shapeBezier;
@synthesize lineColor;
@synthesize objectID;

NSString *ContentPointsKey = @"points";
NSString *ContentLineWidthKey = @"lineWidth";
NSString *ContentShapeBezierKey = @"shapeBezier";
NSString *ContentLineColorKey = @"lineColor";

- (id)init {
    
    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {
        
        // Set up decent defaults for a new graphic.
        self.bounds = NSZeroRect;
        self.lineColor = [[NSColor blackColor] retain];
        self.shapeBezier = [NSBezierPath bezierPath];
        [self.shapeBezier setLineWidth:3.0f];
        self.lineWidth = 3.0f;
    }
    return self;
}

// 保存されたデータをデコードしてオブジェクトを作成する
- (id)initWithCoder: (NSCoder *)decoder {
    self = [super init];
    if( self ) {
        if ( [decoder containsValueForKey:ContentLineColorKey] ) {
            self.lineColor = [[decoder decodeObjectForKey:ContentLineColorKey] retain];
        } else {
            self.lineColor = [[NSColor blackColor] retain];
        }
        if ( [decoder containsValueForKey:ContentPointsKey] ) {
            NSArray *points = [decoder decodeObjectForKey:ContentPointsKey];
            self.lineWidth = [decoder decodeFloatForKey:ContentLineWidthKey];
            self.shapeBezier = [NSBezierPath bezierPath];
            [self.shapeBezier setLineWidth:self.lineWidth];

            // bounds と bezierPath は読み込んだデータから作る
            for ( NSInteger index = 0; index < [points count]; index++ ) {
                NSString *pointString = [points objectAtIndex:index];
                NSPoint point = NSPointFromString( pointString );
                if ( index == 0 ) {
                    [self.shapeBezier moveToPoint:point];
                } else {
                    [self.shapeBezier lineToPoint:point];
                }
            }
            self.bounds = [self.shapeBezier bounds];
            
        } else {
            self.shapeBezier = [[decoder decodeObjectForKey:ContentShapeBezierKey] retain];
            // bounds は読み込んだデータから作る
            self.bounds = [self.shapeBezier bounds];
            self.lineWidth = [self.shapeBezier lineWidth];
        }
    }
    return self;
}

// 保存できるデータにエンコードする
- (void)encodeWithCoder: (NSCoder *)encoder
{
//    [encoder encodeObject:self.points forKey:ContentPointsKey];
//    [encoder encodeFloat:self.lineWidth forKey:ContentLineWidthKey];
    [encoder encodeObject:self.lineColor forKey:ContentLineColorKey];
    [encoder encodeObject:self.shapeBezier forKey:ContentShapeBezierKey];
}

- (void)dealloc {
    
    // Do the regular Cocoa thing.
    [self.lineColor release];
//    [self.shapeBezier release];
    [super dealloc];
    
}

// ポイントを追加する
- (void)addPoint:(NSPoint)aPoint {
    if ( [self.shapeBezier elementCount] == 0 ) {
        [self.shapeBezier moveToPoint:aPoint];
    } else {
        [self.shapeBezier lineToPoint:aPoint];
    }
}

// ポリラインを描画する
- (void)draw:(BOOL)selected {
    // 色を設定
    [self.lineColor set];

    // ポリラインのベジエパスを得る
    [self.shapeBezier setLineWidth:self.lineWidth];
    [self.shapeBezier stroke];
    if ( selected ) {
        // 選択状態の場合は、各ポイントにマーカーを表示する
        [[NSColor redColor] set];
        for ( NSInteger index = 0; index < [self.shapeBezier elementCount]; index++ ) {
            NSPoint controlPoint[3];
            NSBezierPathElement element = [self.shapeBezier elementAtIndex:index
                                           associatedPoints:&controlPoint[0]];
            
            [NSBezierPath fillRect:NSMakeRect( controlPoint[0].x - self.lineWidth / 2 - 2,
                                               controlPoint[0].y - self.lineWidth / 2 - 2,
                                               self.lineWidth + 4,
                                               self.lineWidth + 4 )];
        }
    }
}

// ポリラインがクリックされたかどうか
- (BOOL)clickCheck:(NSPoint)point {
    float halfWidth = [self.shapeBezier lineWidth] / 2.0 + 2.5; // 若干余裕を持たせる
    if ( NSPointInRect( point, NSInsetRect( [self.shapeBezier bounds], -halfWidth, -halfWidth ) ) ) {
        NSInteger pointCount = [self.shapeBezier elementCount];
        NSPoint prevPoint[3];
        NSBezierPathElement element = [self.shapeBezier elementAtIndex:0
                                       associatedPoints:&prevPoint[0]];
        for ( NSInteger index = 1; index < pointCount; index++ ) {
            NSPoint lineEnd[3];
            NSBezierPathElement element = [self.shapeBezier elementAtIndex:index
                                           associatedPoints:&lineEnd[0]];
            float distance = [self calcDistance:point lineFrom:prevPoint[0] lineTo:lineEnd[0]];
            if ( distance < halfWidth ) {
                return YES;
            }
            prevPoint[0] = lineEnd[0];
        }
    }
    return NO;
}

// ポリラインのコントロールポイントがクリックされたかどうか
- (NSInteger)clickedControlPoint:(NSPoint)point {
    float halfWidth = [self.shapeBezier lineWidth] / 2.0 + 2.5; // 若干余裕を持たせる
    if ( NSPointInRect( point, NSInsetRect( [self.shapeBezier bounds], -halfWidth, -halfWidth ) ) ) {
        NSInteger pointCount = [self.shapeBezier elementCount];
        for ( NSInteger index = 0; index < pointCount; index++ ) {
            NSPoint controlPoint[3];
            NSBezierPathElement element = [self.shapeBezier elementAtIndex:index
                                           associatedPoints:&controlPoint[0]];
            if ( NSPointInRect( point, NSMakeRect( controlPoint[0].x - self.lineWidth / 2 - 2,
                                                   controlPoint[0].y - self.lineWidth / 2 - 2,
                                                   self.lineWidth + 4,
                                                   self.lineWidth + 4 ) ) ) {
                return index;
            }
        }
    }
    return -1;
}

// ポリラインのコントロールポイントを動かす
- (void)moveControlPointTo:(NSPoint)point atIndex:(NSInteger)index {
    [self.shapeBezier setAssociatedPoints:&point atIndex:index];
}

// 線分と点の間の距離を計算
- (float)calcDistance:(NSPoint)point lineFrom:(NSPoint)lineStart lineTo:(NSPoint)lineEnd {
    NSRect lineRect = NSMakeRect( fmin( lineStart.x, lineEnd.x ), fmin( lineStart.y, lineEnd.y ),
                                  fabs( lineStart.x - lineEnd.x ), fabs( lineStart.y - lineEnd.y ) );
    if ( !NSPointInRect( point, NSInsetRect( lineRect, -10.0, -10.0 ) ) ) {
        return 1.0e10;
    }
    float v1 = fabs( ( lineStart.y - lineEnd.y ) * point.x - ( lineStart.x - lineEnd.x ) * point.y + lineStart.x * lineEnd.y - lineEnd.x * lineStart.y );
    float v2 = sqrt( pow( lineStart.y - lineEnd.y, 2.0 ) + pow( lineStart.x - lineEnd.x, 2.0 ) );
    return v1 / v2;
}

@end
