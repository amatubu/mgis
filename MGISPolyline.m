//
//  MGISPolyline.m
//  mgis
//
//  Created by naoki iimura on 3/20/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "MGISPolyline.h"


@implementation MGISPolyline

@synthesize lineWidth;
@synthesize shapeBezier;
@synthesize lineColor;

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

// ポイントを最後に追加する
- (void)addPoint:(NSPoint)aPoint {
    if ( [self.shapeBezier elementCount] == 0 ) {
        [self.shapeBezier moveToPoint:aPoint];
    } else {
        [self.shapeBezier lineToPoint:aPoint];
    }
}

// ポイントを途中に追加する
// index が 0 ならば、最初に追加する
- (void)insertPoint:(NSPoint)aPoint atIndex:(NSInteger)index {
    if ( index >= [self.shapeBezier elementCount] ) {
        // ポイントを最後に追加する
        [self.shapeBezier lineToPoint:aPoint];
        return;
    }
    
    // 新しいベジエパスを作成する
    NSBezierPath *newBezier = [NSBezierPath bezierPath];
    for ( NSInteger i = 0; i < [self.shapeBezier elementCount]; i++ ) {
        if ( i == index ) {
            if ( i == 0 ) {
                [newBezier moveToPoint:aPoint];
            } else {
                [newBezier lineToPoint:aPoint];
            }
        }
        NSPoint controlPoint[3];
        NSBezierPathElement element = [self.shapeBezier elementAtIndex:i
                                       associatedPoints:&controlPoint[0]];
        if ( i == 0 && index != 0 ) {
            [newBezier moveToPoint:controlPoint[0]];
        } else {
            [newBezier lineToPoint:controlPoint[0]];
        }
    }
    self.shapeBezier = newBezier;
}

// ポイントを削除する
- (void)deletePointAtIndex:(NSInteger)index {
    // エレメントの数が 2つ以下の場合は削除不可
    if ( [self.shapeBezier elementCount] <= 2 ) return;
    
    NSBezierPath *newBezier = [NSBezierPath bezierPath];
    for ( NSInteger i = 0; i < [self.shapeBezier elementCount]; i++ ) {
        if ( i == index ) continue;
        
        NSPoint controlPoint[3];
        NSBezierPathElement element = [self.shapeBezier elementAtIndex:i
                                       associatedPoints:&controlPoint[0]];
        if ( i == 0 || index == 0 ) {
            [newBezier moveToPoint:controlPoint[0]];
        } else {
            [newBezier lineToPoint:controlPoint[0]];
        }
    }
    self.shapeBezier = newBezier;
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
        NSPoint prevPoint;
        for ( NSInteger index = 0; index < [self.shapeBezier elementCount]; index++ ) {
            NSPoint controlPoint[3];
            NSBezierPathElement element = [self.shapeBezier elementAtIndex:index
                                           associatedPoints:&controlPoint[0]];
            if ( element != NSMoveToBezierPathElement && element != NSLineToBezierPathElement ) continue;

            [[NSColor redColor] set];
            [NSBezierPath fillRect:NSMakeRect( controlPoint[0].x - self.lineWidth / 2 - 2,
                                               controlPoint[0].y - self.lineWidth / 2 - 2,
                                               self.lineWidth + 4,
                                               self.lineWidth + 4 )];
            if ( index > 0 ) {
                NSPoint betweenPoint = NSMakePoint( ( prevPoint.x + controlPoint[0].x ) / 2,
                                                    ( prevPoint.y + controlPoint[0].y ) / 2 );
                NSRect betweenControlRect = NSMakeRect( betweenPoint.x - self.lineWidth / 2 - 2,
                                                        betweenPoint.y - self.lineWidth / 2 - 2,
                                                        self.lineWidth + 4,
                                                        self.lineWidth + 4 );
                
                [[[NSColor whiteColor] colorWithAlphaComponent:0.6] set];
                [NSBezierPath fillRect:betweenControlRect];
                [[NSColor redColor] set];
                [NSBezierPath strokeRect:betweenControlRect];
            }
            prevPoint = controlPoint[0];
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
        NSLog( @"Start element %d", element );
        for ( NSInteger index = 1; index < pointCount; index++ ) {
            NSPoint lineEnd[3];
            NSBezierPathElement element = [self.shapeBezier elementAtIndex:index
                                           associatedPoints:&lineEnd[0]];
            if ( element != NSLineToBezierPathElement ) continue;

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
            if ( element != NSMoveToBezierPathElement && element != NSLineToBezierPathElement ) continue;

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

// ポリラインの点と点の間がクリックされたかどうか
- (NSInteger)clickedBetweenControlPoint:(NSPoint)point {
    float halfWidth = [self.shapeBezier lineWidth] / 2.0 + 2.5; // 若干余裕を持たせる
    if ( NSPointInRect( point, NSInsetRect( [self.shapeBezier bounds], -halfWidth, -halfWidth ) ) ) {
        NSInteger pointCount = [self.shapeBezier elementCount];
        NSPoint prevPoint;
        for ( NSInteger index = 0; index < pointCount; index++ ) {
            NSPoint controlPoint[3];
            NSBezierPathElement element = [self.shapeBezier elementAtIndex:index
                                           associatedPoints:&controlPoint[0]];
            if ( element != NSMoveToBezierPathElement && element != NSLineToBezierPathElement ) continue;
            
            if ( index > 0 ) {
                NSPoint betweenPoint = NSMakePoint( ( prevPoint.x + controlPoint[0].x ) / 2,
                                                   ( prevPoint.y + controlPoint[0].y ) / 2 );
                NSRect betweenControlRect = NSMakeRect( betweenPoint.x - self.lineWidth / 2 - 2,
                                                       betweenPoint.y - self.lineWidth / 2 - 2,
                                                       self.lineWidth + 4,
                                                       self.lineWidth + 4 );
                if ( NSPointInRect( point, betweenControlRect ) ) {
                    return index;
                }
            }
            prevPoint = controlPoint[0];
        }
    }
    return -1;
}

// ポリラインのコントロールポイントを動かす
- (void)moveControlPointTo:(NSPoint)point atIndex:(NSInteger)index {
    [self.shapeBezier setAssociatedPoints:&point atIndex:index];
}

// アフィン変換を適用する
- (void)applyAffineTransform:(NSAffineTransform *)transform {
    [self.shapeBezier transformUsingAffineTransform:transform];
}

// 代表点を得る
// ポリラインの代表点は、真ん中の線分の中点。線分の数が偶数ならば、真ん中の点
- (NSPoint)representativePoint {
    NSInteger elementCount = [self.shapeBezier elementCount];
    NSBezierPathElement element;
    NSPoint controlPoint[3];
    
    if ( elementCount % 2 == 0 ) {
        // 点の数が偶数→真ん中の線分の中点
        NSPoint result;
        NSBezierPathElement element = [self.shapeBezier elementAtIndex:( elementCount / 2 - 1)
                                                      associatedPoints:&controlPoint[0]];
        result = controlPoint[0];
        element = [self.shapeBezier elementAtIndex:( elementCount / 2 )
                                  associatedPoints:&controlPoint[0]];
        result.x = ( result.x + controlPoint[0].x ) / 2;
        result.y = ( result.y + controlPoint[0].y ) / 2;
        return result;
    } else {
        // 点の数が奇数→真ん中の点
        element = [self.shapeBezier elementAtIndex:floor( elementCount / 2 )
                                  associatedPoints:&controlPoint[0]];
        return controlPoint[0];
    }
}

// プライベート関数

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
