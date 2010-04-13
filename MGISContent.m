//
//  MGISContent.m
//  mgis
//
//  Created by naoki iimura on 4/3/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "MGISContent.h"


@implementation MGISContent

@synthesize bounds;
@synthesize objectID;

- (id)init {
    
    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {
        
        // Set up decent defaults for a new graphic.
        self.bounds = NSZeroRect;
    }
    return self;
}

// 保存されたデータをデコードしてオブジェクトを作成する
- (id)initWithCoder: (NSCoder *)decoder {
    self = [super init];
    if( self ) {
    }
    return self;
}

// 保存できるデータにエンコードする
- (void)encodeWithCoder: (NSCoder *)encoder
{
}

- (void)dealloc {
    [super dealloc];
}

// ポイントを最後に追加する
- (void)addPoint:(NSPoint)aPoint {
}

// ポイントを途中に追加する
// index が 0 ならば、最初に追加する
- (void)insertPoint:(NSPoint)aPoint atIndex:(NSInteger)index {
}

// ポイントを削除する
- (void)deletePointAtIndex:(NSInteger)index {
}

// 線の太さを設定する
- (void)setLineWidth:(CGFloat)width {
}

// 線の太さを得る
- (CGFloat)lineWidth {
    return 0;
}

// 線の色を設定する
- (void)setLineColor:(NSColor *)color {
}

// 線の色を得る
- (NSColor *)lineColor {
    return [NSColor blackColor];
}

// 描画する
- (void)draw:(BOOL)selected {
}

// クリックされたかどうか
- (BOOL)clickCheck:(NSPoint)point {
    return NO;
}

// コントロールポイントがクリックされたかどうか
- (NSInteger)clickedControlPoint:(NSPoint)point {
    return -1;
}

// ポリラインの点と点の間がクリックされたかどうか
- (NSInteger)clickedBetweenControlPoint:(NSPoint)point {
    return -1;
}

// ポリラインのコントロールポイントを動かす
- (void)moveControlPointTo:(NSPoint)point atIndex:(NSInteger)index {
}

// アフィン変換を適用する
- (void)applyAffineTransform:(NSAffineTransform *)transform {
}

// 図形の代表点を得る
- (NSPoint)representativePoint {
    return NSZeroPoint;
}

@end
