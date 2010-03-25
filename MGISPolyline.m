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
@synthesize points;
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
        self.points = [[NSMutableArray alloc] init];
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
            self.points = [decoder decodeObjectForKey:ContentPointsKey];
            self.lineWidth = [decoder decodeFloatForKey:ContentLineWidthKey];
            self.shapeBezier = [NSBezierPath bezierPath];
            [self.shapeBezier setLineWidth:self.lineWidth];

            // bounds と bezierPath は読み込んだデータから作る
            CGFloat left = 1e100, right = -1e100, top = -1e100, bottom = 1e100;
            for ( NSInteger index = 0; index < [self.points count]; index++ ) {
                // NSValue *pointObject = [self.points objectAtIndex:index];
                // NSPoint point = [pointObject pointValue];
                NSString *pointString = [self.points objectAtIndex:index];
                NSPoint point = NSPointFromString( pointString );
                left = fmin( left, point.x );
                right = fmax( right, point.x );
                bottom = fmin( bottom, point.y );
                top = fmax( top, point.y );
                if ( index == 0 ) {
                    [self.shapeBezier moveToPoint:point];
                } else {
                    [self.shapeBezier lineToPoint:point];
                }
            }
            self.bounds = NSMakeRect( left, bottom, right - left, top - bottom );
            
        } else {
            self.shapeBezier = [[decoder decodeObjectForKey:ContentShapeBezierKey] retain];
            // bounds は読み込んだデータから作る
            self.bounds = [self.shapeBezier bounds];
            self.lineWidth = [self.shapeBezier lineWidth];
            self.points = [[NSMutableArray alloc] init];
            NSPoint controlPoints[3];
            for (NSInteger index = 0; index < [self.shapeBezier elementCount]; index++ ) {
                NSBezierPathElement element = [self.shapeBezier elementAtIndex:index
                                               associatedPoints:&controlPoints[0]];
                [self.points addObject:NSStringFromPoint( controlPoints[0] )];
            }
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
    [self.points release];
//    [self.shapeBezier release];
    [super dealloc];
    
}

// ポイントを追加する
- (void)addPoint:(NSPoint)aPoint {
//    NSValue *aValue = [NSValue valueWithPoint:aPoint];
    if ( [self.points count] == 0 ) {
        [self.shapeBezier moveToPoint:aPoint];
    } else {
        [self.shapeBezier lineToPoint:aPoint];
    }
    NSString *aValue = NSStringFromPoint( aPoint );
    [self.points addObject:aValue];
//    [aValue release];
}

// ポリラインを描画する
- (void)draw:(BOOL)selected {
    // 色を設定
    [self.lineColor set];

    // ポリラインのベジエパスを得る
    // TODO:
    //   地図上の位置から変換する必要がある
#if 0
    NSBezierPath *polyBezier = [NSBezierPath bezierPath];
    [polyBezier setLineWidth:self.lineWidth];
    NSInteger pointCount = [self.points count];
    for ( NSInteger index = 0; index < pointCount; index++ ) {
//        NSValue *pointObject = [self.points objectAtIndex:index];
//        NSPoint point = [pointObject pointValue];
        NSString *pointString = [self.points objectAtIndex:index];
        NSPoint point = NSPointFromString( pointString );
        if ( index == 0 ) {
            [polyBezier moveToPoint:point];
        } else {
            [polyBezier lineToPoint:point];
        }
//        [NSBezierPath strokeLineFromPoint:_endPoint toPoint:_ctrlPoint2];
    }
    
    // ベジエパスを描画
    [polyBezier stroke];
#endif
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

// 線分と点の間の距離を計算
- (float)calcDistance:(NSPoint)point lineFrom:(NSPoint)lineStart lineTo:(NSPoint)lineEnd {
    NSRect lineRect = NSMakeRect( fmin( lineStart.x, lineEnd.x ), fmin( lineStart.y, lineEnd.y ),
                                  fabs( lineStart.x - lineEnd.x ), fabs( lineStart.y - lineEnd.y ) );
    if ( !NSPointInRect( point, lineRect ) ) {
        return 1.0e10;
    }
    float v1 = fabs( ( lineStart.y - lineEnd.y ) * point.x - ( lineStart.x - lineEnd.x ) * point.y + lineStart.x * lineEnd.y - lineEnd.x * lineStart.y );
    float v2 = sqrt( pow( lineStart.y - lineEnd.y, 2.0 ) + pow( lineStart.x - lineEnd.x, 2.0 ) );
    return v1 / v2;
}

@end
