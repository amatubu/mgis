//
//  CoordinateConverter.m
//  mgis
//
//  Created by naoki iimura on 3/18/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "CoordinateConverter.h"


@implementation CoordinateConverter

@synthesize a;
@synthesize f;
@synthesize e2;
@synthesize et2;

+ (id) coordinateConverterWithSpheroidalType:(NSString*)type
{
	return [[[CoordinateConverter alloc] initWithSpheroidalType:type] autorelease];
}

// 初期化ルーチン
- (id)initWithSpheroidalType:(NSString*)type
{
    self = [super init];
    if (self) {
    	if ( [type isEqualToString:@"bessel"] ) {
			// 地球楕円体の長半径(日本測地系：ベッセル球体)
			// http://vldb.gsi.go.jp/sokuchi/surveycalc/algorithm/ellipse/ellipse.htm
        	self.a = 6377397.155;
            self.f = 1.0 / 299.152813;
            self.e2 = 2.0 * f - f * f;
            self.et2 = e2 / ( 1.0 - e2 );
        }
	}
    return self;
}


// 平面直角座標系から、緯度・経度に変換する
// http://vldb.gsi.go.jp/sokuchi/surveycalc/algorithm/xy2bl/xy2bl.htm
// 国土地理院の計算式とは、X と Y が入れかわっていることに注意
// 国土地理院の計算式では、X は南北方向、Y は東西方向になっている
// TODO:
//   エラーチェック
- (void) getLatLongFromXY:(NSPoint)XY latitude:(double *)latitude longitude:(double *)longitude kei:(int)kei
{
	// 原点の座標
    double p0;
    double r0;
    [self getLangLotOfOriginFromKei:kei latitude:&p0 longitude:&r0];

	// ラジアンに変換する
	p0 *= rd;
	r0 *= rd;

	double p1 = [self calcLatitudeFromY:XY.y p0:p0];

	double n1 = a / sqrt( 1.0 - e2 * pow( sin( p1 ), 2.0 ) );
	double xm0 = XY.x / m0;
	double t1 = tan( p1 );
	double eta2 = et2 * pow( cos( p1 ), 2.0 );
	double t1_2 = t1 * t1;
	double t1_4 = t1_2 * t1_2;
	double t1_6 = t1_2 * t1_4;
	double eta4 = eta2 * eta2;

	// 緯度を4項まで計算
	double p_1 = -( 1.0 /     2.0 ) * pow( n1, -2.0 ) * t1 * ( 1 + eta2 ) * pow( xm0, 2.0 );
	double p_2 =  ( 1.0 /    24.0 ) * pow( n1, -4.0 ) * t1 * ( 5 + 3 * t1_2 + 6 * eta2 - 6 * t1_2 * eta2 - 3 * eta4 - 9 * t1_2 * eta4 ) * pow( xm0, 4.0 );
	double p_3 = -( 1.0 /   727.0 ) * pow( n1, -6.0 ) * t1 * ( 61 + 90 * t1_2 + 45 * t1_4 + 107 * eta2 - 162 * t1_2 * eta2 - 45 * t1_4 * eta2 ) * pow( xm0, 6.0 );
	double p_4 =  ( 1.0 / 40320.0 ) * pow( n1, -8.0 ) * t1 * ( 1385 + 3633 * t1_2 + 4095 * t1_4 + 1575 * t1_6 ) * pow( xm0, 8.0 );
	
	double p = p1 + p_1 + p_2 + p_3 + p_4;
	*latitude = p / rd;

	// 経度を4項まで計算
	double cp1 = cos( p1 );
	double r_1 =                     pow( n1, -1.0 ) / cp1 * xm0;
	double r_2 = -( 1.0 /    6.0 ) * pow( n1, -3.0 ) / cp1 * ( 1 + 2 * t1_2 + eta2 ) * pow( xm0, 3.0 );
	double r_3 =  ( 1.0 /  120.0 ) * pow( n1, -5.0 ) / cp1 * ( 5 + 28 * t1_2 + 24 * t1_4 + 6 * eta2+ 8 * t1_2 * eta2 ) * pow( xm0, 5.0 );
	double r_4 = -( 1.0 / 5040.0 ) * pow( n1, -7.0 ) / cp1 * ( 61 + 662 * t1_2 + 1320 * t1_4 + 720 * t1_6 ) * pow( xm0, 7.0 );
	
	double r = r0 + r_1 + r_2 + r_3 + r_4;
	*longitude = r / rd;
}

// 緯度・経度から平面直角座標系の座標に変換する
- (void) getXYFromLatitude: (double)latitude longitude:(double)longitude xy:(NSPoint *)XY kei:(int)kei
{
	// ラジアンに変換する
	double p = latitude * rd;
	double r = longitude * rd;

	// 原点の座標
	double p0;
	double r0;
    [self getLangLotOfOriginFromKei:kei latitude:&p0 longitude:&r0];

	// ラジアンに変換する
	p0 *= rd;
	r0 *= rd;

	// 赤道から緯度までの子午線弧長
	double s = [self calcMeridianLengthFromLatitude:p];
	// 座標原点の緯度までの子午線弧長
	double s0 = [self calcMeridianLengthFromLatitude:p0];

	// 
	double n = a / sqrt( 1.0 - e2 * pow( sin( p ), 2.0 ) );
	double dr = r - r0;
	double cp = cos( p );
	double eta2 = et2 * pow( cp, 2.0 );
	double t = tan( p );
	double t2 = t * t;
	double t4 = t2 * t2;
	double t6 = t2 * t4;
	double eta4 = eta2 * eta2;

	// Xを第4項まで計算する
	double x1 =  ( 1.0 /     2.0 ) * n * pow( cp, 2.0 ) * t * pow( dr, 2.0 );
	double x2 =  ( 1.0 /    24.0 ) * n * pow( cp, 4.0 ) * t * ( 5 - t2 + 9 * eta2 + 4 * eta4 ) * pow( dr, 4.0 );
	double x3 = -( 1.0 /   720.0 ) * n * pow( cp, 6.0 ) * t * ( -61 + 58 * t2 - t4 - 270 * eta2 + 330 * t2 * eta2 ) * pow( dr, 6.0 );
	double x4 = -( 1.0 / 40320.0 ) * n * pow( cp, 8.0 ) * t * ( -1385 + 3111 * t2 - 543 * t4 + t6 ) * pow( dr, 8.0 );

	XY->x = ( ( s - s0 ) + x1 + x2 + x3 + x4 ) * m0;

	// Yを第4項まで計算する
	double y1 =                     n *      cp *                                  dr;
	double y2 = -( 1.0 /    6.0 ) * n * pow( cp, 3.0 ) * ( -1 + t2 - eta2 ) * pow( dr, 3.0 );
	double y3 = -( 1.0 /  120.0 ) * n * pow( cp, 5.0 ) * ( -5 + 18 * t2 - t4 - 14 * eta2 + 58 * t2 * eta2 ) * pow( dr, 5.0 );
	double y4 = -( 1.0 / 5040.0 ) * n * pow( cp, 7.0 ) * ( -61 + 479 * t2 - 179 * t4 + t6 ) * pow( dr, 7.0 );

	XY->y = ( y1 + y2 + y3 + y4 ) * m0;
}

// 緯度を与えて赤道からの子午線長を求める
// http://vldb.gsi.go.jp/sokuchi/surveycalc/algorithm/b2s/b2s.htm
- (double) calcMeridianLengthFromLatitude: (double)p
{
	// 定数
	double e4  = e2 * e2;
	double e6  = e2 * e4;
	double e8  = e4 * e4;
	double e10 = e4 * e6;
	double e12 = e6 * e6;
	double e14 = e6 * e8;
	double e16 = e8 * e8;
	double aa = 1.0                                   + (         3.0 /         4.0 ) * e2
	          + (         45.0 /         64.0 ) * e4  + (       175.0 /       256.0 ) * e6
			  + (      11025.0 /      16384.0 ) * e8  + (     43659.0 /     65536.0 ) * e10
	          + (     693693.0 /    1048576.0 ) * e12 + (  19324305.0 /  29360128.0 ) * e14
	          + ( 4927697775.0 / 7516192768.0 ) * e16;
	double bb = (          3.0 /          4.0 ) * e2 
	          + (         15.0 /         16.0 ) * e4  + (       525.0 /       512.0 ) * e6
	          + (       2205.0 /       2048.0 ) * e8  + (     72765.0 /     65536.0 ) * e10
	          + (     297297.0 /     262144.0 ) * e12 + ( 135270135.0 / 117440512.0 ) * e14
	          + (  547521975.0 /  469762048.0 ) * e16;
	double cc = (         15.0 /         64.0 ) * e4  + (       105.0 /       256.0 ) * e6
	          + (       2205.0 /       4096.0 ) * e8  + (     10395.0 /     16384.0 ) * e10
			  + (    1486485.0 /    2097152.0 ) * e12 + (  45090045.0 /  58720256.0 ) * e14
			  + (  766530765.0 /  939524096.0 ) * e16;
	double dd = (         35.0 /        512.0 ) * e6
			  + (        315.0 /       2048.0 ) * e8  + (     31185.0 /    131072.0 ) * e10
			  + (     165165.0 /     524288.0 ) * e12 + (  45090045.0 / 117440512.0 ) * e14
			  + (  209053845.0 /  469762048.0 ) * e16;
	double ee = (        315.0 /      16384.0 ) * e8  + (      3645.0 /     65536.0 ) * e10
			  + (      99099.0 /    1048576.0 ) * e12 + (   4099095.0 /  29360128.0 ) * e14
			  + (  348423075.0 /  187948192.0 ) * e16;
	double ff = (        693.0 /     131072.0 ) * e10
			  + (       9009.0 /     524288.0 ) * e12 + (   4099095.0 / 117440512.0 ) * e14
			  + (   26801775.0 /  469762048.0 ) * e16;
	double gg = (       3003.0 /    2097152.0 ) * e12 + (    315315.0 /  58720256.0 ) * e14
			  + (   11486475.0 /  939524096.0 ) * e16;
	double hh = (      45045.0 /  117440512.0 ) * e14 + (    765765.0 / 469762048.0 ) * e16;
	double ii = (     765765.0 / 7516192768.0 ) * e16;
	
	double b1 = a * ( 1.0 - e2 ) *    aa;
	double b2 = a * ( 1.0 - e2 ) * ( -bb /  2.0 );
	double b3 = a * ( 1.0 - e2 ) * (  cc /  4.0 );
	double b4 = a * ( 1.0 - e2 ) * ( -dd /  6.0 );
	double b5 = a * ( 1.0 - e2 ) * (  ee /  8.0 );
	double b6 = a * ( 1.0 - e2 ) * ( -ff / 10.0 );
	double b7 = a * ( 1.0 - e2 ) * (  gg / 12.0 );
	double b8 = a * ( 1.0 - e2 ) * ( -hh / 14.0 );
	double b9 = a * ( 1.0 - e2 ) * (  ii / 16.0 );
	
	// 緯度から赤道からの子午線長を求める
	double s = b1 * p
			 + b2 * sin(  2.0 * p ) + b3 * sin(  4.0 * p )
			 + b4 * sin(  6.0 * p ) + b5 * sin(  8.0 * p )
			 + b6 * sin( 10.0 * p ) + b7 * sin( 12.0 * p )
			 + b8 * sin( 14.0 * p ) + b9 * sin( 16.0 * p );

	return s;
}

- (double) calcLatitudeFromY: (double)y p0:(double)p0
{
	double s0 = [self calcMeridianLengthFromLatitude:p0];
	double m = s0 + y / m0;

	double pn = p0;
	while ( YES ) {
		double sn = [self calcMeridianLengthFromLatitude:pn];
		double v1 = 2 * ( sn - m ) * pow(  1 - e2 * pow( sin( pn ), 2.0 ), ( 3.0 / 2.0 ) );
		double v2 = 3 * e2 * ( sn - m ) * sin( pn ) * cos( pn ) * sqrt( 1 - e2 * pow( sin( pn ), 2.0 ) ) - 2 * a * ( 1 - e2 );
		double v = v1 / v2;
		pn += v;
		// TODO:
		//   終了条件はこれでよいか?
		if ( v < 1.0e-14 && v > -1.0e-14 ) break;
	}
	return pn;
}

- (void) getLangLotOfOriginFromKei:(int)kei latitude:(double*)latitude longitude:(double*)longitude
{
	// 原点の緯度・経度
	// http://www.gsi.go.jp/LAW/heimencho.html
	switch (kei) {
    	case 1:
        	*latitude  =  33.0;
            *longitude = 129.0 + 30.0 / 60.0;
            break;
        case 2:
        	*latitude  =  33.0;
            *longitude = 131.0;
        	break;
        case 3:
        	*latitude  =  36.0;
            *longitude = 132.0 + 10.0 / 60.0;
            break;
        case 4:
        	*latitude  =  33.0;
            *longitude = 133.0 + 30.0 / 60.0;
            break;
        case 5:
        	*latitude  =  36.0;
            *longitude = 134.0 + 20.0 / 60.0;
            break;
        case 6:
        	*latitude  =  36.0;
            *longitude = 136.0;
            break;
        case 7:
        	*latitude  =  36.0;
            *longitude = 137.0 + 10.0 / 60.0;
            break;
        case 8:
        	*latitude  =  36.0;
            *longitude = 138.0 + 30.0 / 60.0;
            break;
        case 9:
        	*latitude  =  36.0;
            *longitude = 139.0 + 50.0 / 60.0;
            break;
        case 10:
        	*latitude  =  40.0;
            *longitude = 140.0 + 50.0 / 60.0;
            break;
        case 11:
        	*latitude  =  44.0;
            *longitude = 140.0 + 15.0 / 60.0;
            break;
        case 12:
        	*latitude  =  44.0;
            *longitude = 142.0 + 15.0 / 60.0;
            break;
        case 13:
        	*latitude  =  44.0;
            *longitude = 144.0 + 15.0 / 60.0;
            break;
        case 14:
        	*latitude  =  26.0;
            *longitude = 142.0;
            break;
        case 15:
        	*latitude  =  26.0;
            *longitude = 127.0 + 30.0 / 60.0;
            break;
        case 16:
        	*latitude  =  26.0;
            *longitude = 124.0;
            break;
        case 17:
        	*latitude  =  26.0;
            *longitude = 131.0;
            break;
        case 18:
        	*latitude  =  26.0;
            *longitude = 136.0;
            break;
        case 19:
        	*latitude  =  26.0;
            *longitude = 154.0;
            break;
        default:
        	break;
    }
}

- (void) dealloc {
	[super dealloc];
}

@end
