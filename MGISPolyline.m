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

NSString *ContentPointsKey = @"points";
NSString *ContentLineWidthKey = @"lineWidth";
NSString *ContentLineColorKey = @"lineColor";

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

// 保存されたデータをデコードしてオブジェクトを作成する
- (id)initWithCoder: (NSCoder *)decoder {
    self = [super init];
    if( self ) {
        self.points = [decoder decodeObjectForKey:ContentPointsKey];
        self.lineWidth = [decoder decodeFloatForKey:ContentLineWidthKey];
        self.lineColor = [[decoder decodeObjectForKey:ContentLineColorKey] retain];

        // bounds は読み込んだデータから作る
        CGFloat left = 1e100, right = -1e100, top = -1e100, bottom = 1e100;
        for ( NSInteger index = 0; index < [self.points count]; index++ ) {
//            NSValue *pointObject = [self.points objectAtIndex:index];
//            NSPoint point = [pointObject pointValue];
            NSString *pointString = [self.points objectAtIndex:index];
            NSPoint point = NSPointFromString( pointString );
            left = fmin( left, point.x );
            right = fmax( right, point.x );
            bottom = fmin( bottom, point.y );
            top = fmax( top, point.y );
        }
        self.bounds = NSMakeRect( left, bottom, right - left, top - bottom );
    }
    return self;
}

// 保存できるデータにエンコードする
- (void)encodeWithCoder: (NSCoder *)encoder
{
    [encoder encodeObject:self.points forKey:ContentPointsKey];
    [encoder encodeFloat:self.lineWidth forKey:ContentLineWidthKey];
    [encoder encodeObject:self.lineColor forKey:ContentLineColorKey];
}

- (void)dealloc {
    
    // Do the regular Cocoa thing.
    [self.lineColor release];
    [super dealloc];
    
}

// ポイントを追加する
- (void)addPoint:(NSPoint)aPoint {
//    NSValue *aValue = [NSValue valueWithPoint:aPoint];
    NSString *aValue = NSStringFromPoint( aPoint );
    [self.points addObject:aValue];
//    [aValue release];
}

// ポリラインを描画する
- (void)draw {
    // 色を設定
    [self.lineColor set];

    // ポリラインのベジエパスを得る
    // TODO:
    //   地図上の位置から変換する必要がある
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
}

@end
