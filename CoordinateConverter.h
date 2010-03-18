//
//  CoordinateConverter.h
//  mgis
//
//  Created by naoki iimura on 3/18/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoordinateConverter : NSObject {
	double a;
    double f;
    double e2;
    double et2;
}

+ (id) coordinateConverterWithSpheroidalType:(NSString*)type;
- (id) initWithSpheroidalType:(NSString *)type;
- (void) getLatLongFromXY:(NSPoint)XY latitude:(double *)latitude longitude:(double *)longitude kei:(int)kei;
- (void) getXYFromLatitude: (double)latitude longitude:(double)longitude xy:(NSPoint *)XY kei:(int)kei;
- (double) calcMeridianLengthFromLatitude: (double)p;
- (double) calcLatitudeFromY: (double)y p0:(double)p0;
- (void) getLangLotOfOriginFromKei:(int)kei latitude:(double*)latitude longitude:(double*)longitude;

@property double a;
@property double f;
@property double e2;
@property double et2;
@end

