//
//  MGISView.m
//  mgis
//
//  Created by naoki iimura on 3/11/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "MGISView.h"


@implementation MGISView

@synthesize center_x;
@synthesize center_y;

// 初期化ルーチン
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 地図の画像ファイルが保存されているパス
//		map_folder = @"/Users/sent/Library/Application Data/M-GIS/map/200403/";
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString *basePath = ([paths count] > 0 ) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
		map_folder = [[basePath stringByAppendingPathComponent:@"M-GIS/map/200403/"] retain];

		// 画面の中心の座標の初期値
		// 直交座標系 VI 系
		// TODO:
		//   最後に表示していた場所を記録するようにしたい
		center_x = 46665.476f;
		center_y = -140941.652f;

		//
		first_draw = YES;
		
		// 地図のフォーマット(拡張子)
		map_suffix = @".jpg";
		
		// 地図のズームレベル
		zoom = ZoomLarge;

		// 初期設定
		[self setupDefaults];
		
		dragging = NO;
	}
    return self;
}

// デフォルト値の設定
// UserDefaults.plist の内容を読み込んで初期設定にする
- (void) setupDefaults
{
	NSString *userDefaultsValuesPath;
	NSDictionary *userDefaultsValuesDict;
	
	// デフォルト値を読み込む
	userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
	
	// デフォルト値を設定する
	[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
}

// 描画ルーチン
// ビューの内容を更新する必要が生じた際に呼ばれる
- (void)drawRect:(NSRect)rect {
	if ( first_draw ) {
		// ズームレベルや地図形式を初期化する
		[self changeZoomLevel:zoomSlider];
		[self changeMapFormat:mapFormat];
		// 情報ウィンドウやスケールの内容を更新する
		[self updateInfoWindow];
		[self updateScaleText];
		first_draw = NO;
	}
	
	// ズームレベルによって異なる定数を変数に保存しておく
	float meterPerPixel = [self getMeterPerPixel];
	float mapWidth = [self getMapWidth];
	float mapHeight = [self getMapHeight];

	// 画面の左下の座標(原点)に表示すべき地図を調べる
	// x は、画面の左下の座標(原点)の地図上の横位置
	// x_offset,y_offset は、そこに表示すべき地図の、原点からのオフセット
	float x = center_x - [self bounds].size.width / 2.0 * meterPerPixel;
	float y = center_y - [self bounds].size.height / 2.0 * meterPerPixel;
	float x_offset = - ( x - floor( x / mapWidth ) * mapWidth ) / meterPerPixel;
	float y_offset = - ( y - floor( y / mapHeight ) * mapHeight ) / meterPerPixel;

	float mapImageWidth  = MAP_IMAGE_WIDTH;
	float mapImageHeight = MAP_IMAGE_HEIGHT;
	if ( zoom == ZoomLarge2 || zoom == ZoomMiddle2 ) {
		mapImageWidth  /= 2.0;
		mapImageHeight /= 2.0;
	}
	
	if ( dragging ) {
		x = scrollOrigin.x - [self bounds].size.width / 2.0 * meterPerPixel;
		y = scrollOrigin.y - [self bounds].size.height / 2.0 * meterPerPixel;
		x_offset = - ( x - floor( x / mapWidth ) * mapWidth ) / meterPerPixel;
		y_offset = - ( y - floor( y / mapHeight ) * mapHeight ) / meterPerPixel;
		x_offset += ( scrollOrigin.x - center_x ) / meterPerPixel;
		y_offset += ( scrollOrigin.y - center_y ) / meterPerPixel;
	} else {
		// TODO:
		//   新しく画像を作成しなくてもよいケースもあるので調整する
		float offscreenWidth = mapImageWidth * ( floor( ( [self bounds].size.width - x_offset ) / mapImageWidth ) + 1 );
		float offscreenHeight = mapImageHeight * ( floor( ( [self bounds].size.height - y_offset ) / mapImageHeight ) + 1 );

		// TODO:
		//   たぶんメモリリークしている
		//   offscreenImage が定義されていればリリースする?
		offscreenImage = [[NSImage alloc] initWithSize:NSMakeSize( offscreenWidth, offscreenHeight )];
		[offscreenImage lockFocus];

		float imageOffsetX = 0;
		// オフセットが画面の一番上に逹っするまで繰り返す
		while ( imageOffsetX < offscreenWidth ) {
			// x は、画面の左下の座標(原点)の地図上の縦位置
			// y_offset は、そこに表示すべき地図の、原点からのオフセット
			float y = center_y - rect.size.height / 2.0 * meterPerPixel;
			float imageOffsetY = 0;

			// オフセットが画面の一番右に逹っするまで繰り返す
			while ( imageOffsetY < offscreenHeight ) {
				// LARGE サイズのメッシュッコードを得る
				// MIDDLE、DETAIL サイズについても、このコードを使う
				NSString *meshString = [self getLargeMesh:NSMakePoint( x, y )];

				NSString *mapFile;
				switch (zoom) {
					case ZoomLarge:
					case ZoomLarge2:
						// LARGE サイズの場合は、LARGE フォルダに「メッシュコード名.*」という形式で保存されている
						mapFile = [map_folder stringByAppendingPathComponent:[NSString stringWithFormat:@"LARGE/%@%@%@",
								   @"06", meshString, map_suffix]];
						break;
					case ZoomMiddle:
					case ZoomMiddle2:
						// MIDDLE サイズの場合は、MIDDLE フォルダの中に、そのメッシュを含む LARGE サイズの
						// メッシュコード名のフォルダがあり、その中に保存されている
					{
						NSString *middleMeshString = [self getMiddleMesh:NSMakePoint( x, y )];
						NSLog(@"Middle mesh: %@", middleMeshString);
						NSLog(@"Path %@", [NSString stringWithFormat:@"MIDDLE/%@%@/%@%@%@%@", @"06", meshString, @"06", meshString, middleMeshString, map_suffix]);
						mapFile = [map_folder stringByAppendingPathComponent:[NSString stringWithFormat:@"MIDDLE/%@%@/%@%@%@%@",
								   @"06",meshString,@"06",meshString,middleMeshString,map_suffix]];
					}
						break;
					case ZoomDetail:
						// DETAIL サイズの場合は、DETAIL フォルダの中に、そのメッシュを含む LARGE サイズの
						// メッシュコード名のフォルダがあり、その中に保存されている
					{
						NSString *detailMeshString = [self getDetailMesh:NSMakePoint( x, y )];
						mapFile = [map_folder stringByAppendingPathComponent:[NSString stringWithFormat:@"DETAIL/%@%@/%@%@%@%@",
								   @"06",meshString,@"06",meshString,detailMeshString,map_suffix]];
					}
						break;
					default:
						continue;
				}
				
				NSLog(@"Map file: %@", mapFile);
				NSLog(@"Offset: %.3f, %.3f", x_offset, y_offset);

				// 画像ファイルを得る
				NSImage *anImage = [[NSImage alloc] initWithContentsOfFile:mapFile];
				if ( anImage ) {
					// NSImage が得られたら、計算しておいたオフセットの位置へ描画する
//					[anImage compositeToPoint:NSMakePoint( imageOffsetX, imageOffsetY ) operation:NSCompositeSourceOver];
					[anImage drawInRect:NSMakeRect( imageOffsetX, imageOffsetY, mapImageWidth, mapImageHeight )
						       fromRect:NSMakeRect( 0, 0, MAP_IMAGE_WIDTH, MAP_IMAGE_HEIGHT )
							  operation:NSCompositeSourceOver fraction:1.0];
					[anImage release];
				}
	//			[fileUrl release];
				
				// Y 方向の次のメッシュへ
				y += mapImageHeight * meterPerPixel;
				imageOffsetY += mapImageHeight;
			}
			// X 方向の次のメッシュへ
			x += mapImageWidth * meterPerPixel;
			imageOffsetX += mapImageWidth;
		}
		[offscreenImage unlockFocus];
	}
	[offscreenImage compositeToPoint:NSMakePoint( x_offset, y_offset ) operation:NSCompositeSourceOver];
	
	[self drawCenterMarker:(NSRect)rect];
}

// ビュー上でマウスボタンが押された際に呼ばれる
// 地図をスクロールさせるための事前準備として、ボタンが押された座標を記録しておく
- (void) mouseDown: (NSEvent *) event
{
	// マウスボタンが押された座標を記録しておく
    grabOrigin = [event locationInWindow];
	scrollOrigin = NSMakePoint( center_x, center_y );

	// ドラッグ開始
	dragging = YES;
} // mouseDown

// ビュー上でドラッグされた際に呼ばれる
// 地図をスクロールさせる
- (void) mouseDragged: (NSEvent *) event
{
    NSPoint mousePoint;
    mousePoint = [event locationInWindow];

	// 直前に記録した位置からの移動量を計算する
    float deltaX, deltaY;
    deltaX = grabOrigin.x - mousePoint.x;
    deltaY = mousePoint.y - grabOrigin.y;
	grabOrigin = mousePoint;
	
	// 移動量にピクセルあたりの距離を乗じて地図上の移動距離を計算する
	float meterPerPixel = [self getMeterPerPixel];
	center_x += deltaX * meterPerPixel;
	center_y -= deltaY * meterPerPixel;
	
	// ビューの内容を更新する必要があることを伝える
	[self setNeedsDisplay:YES];
	[self updateInfoWindow];
	
} // mouseDragged

// ドラッグが終了したときに呼ばれる
- (void) mouseUp: (NSEvent *) event
{
	NSPoint mousePoint;
	mousePoint = [event locationInWindow];
	
	// ドラッグ終了
	dragging = NO;
	[self setNeedsDisplay:YES];
} // mouseUp

// 情報ウィンドウの内容を更新する
// 現在は中心点の直交座標系での座標のみを表示
// 起動時や、ズームレベルを変更したときに呼ばれる
- (void) updateInfoWindow {
	[info_x setStringValue:[NSString stringWithFormat:@"%02.3f m", center_x]];
	[info_y setStringValue:[NSString stringWithFormat:@"%02.3f m", center_y]];

	double latitude,longitude;
	[self getLatLongFromXY:NSMakePoint(center_x,center_y) latitude:&latitude longitude:&longitude];

	int d = (int)floor(latitude);
	int m = (int)floor( fmod( latitude * 60.0, 60.0 ) );
	double s = fmod( latitude * 3600.0, 60.0 );
	[info_latitude setStringValue:[NSString stringWithFormat:@"%02d°%02d\'%02.3f\"", d, m, s]];

	d = (int)floor( longitude );
	m = (int)floor( fmod( longitude * 60.0, 60.0 ) );
	s = fmod( longitude * 3600.0, 60.0 );
	[info_longitude setStringValue:[NSString stringWithFormat:@"%02d°%02d\'%02.3f\"", d, m, s]];
}

// 縮尺をあらわすスケールを更新する
// 起動時や、ズームレベルを変更したときに呼ばれる
- (void) updateScaleText {
	float meterPer80Pixels = [self getMeterPerPixel] * 80.0;
	[scale setStringValue:[NSString stringWithFormat:@"%d m", (int)meterPer80Pixels]];
}

// 中心に印を表示する
- (void) drawCenterMarker: (NSRect)viewRect {
	[[NSColor redColor] set];
	NSRect r;
	r= NSMakeRect( viewRect.size.width / 2.0 - 1.0,
						  viewRect.size.height / 2.0 - 10.0,
						   2.0,
						  20.0 );
	NSRectFill(r);
	r = NSMakeRect( viewRect.size.width / 2.0 - 10.0,
						  viewRect.size.height / 2.0 - 1.0,
						  20.0,
						   2.0 );
	NSRectFill(r);
}

// 地図のズームレベルを変更した際に呼ばれる
// TODO:
//   操作時に地図の表示が一部乱れる
- (IBAction) changeZoomLevel: (id)sender {
	int prevZoom = zoom;
	zoom = ZoomLarge2 - [zoomSlider intValue];
	if ( zoom != prevZoom ) {
		[self setNeedsDisplay:YES];
		[self updateScaleText];
	}
	return;
}

// 地図フォーマット切り替えボタンがクリックされたら、地図の拡張子を切り替える
// TODO:
//   変更されていなくても再描画されてしまうと思うので、なんとかしたい
- (IBAction) changeMapFormat: (id)sender {
	switch ([mapFormat selectedSegment]) {
		case 0:
			map_suffix = @".png";
			break;
		case 1:
			map_suffix = @".jpg";
			break;
		default:
			map_suffix = @".jpg";
			break;
	}
	[self setNeedsDisplay:YES];
}

// すべてのもととなるメッシュのコードを得る
// 6桁目までで、ひとつのメッシュの縦横が 3km × 4km
// LARGE サイズを縦横 10 枚つなげたもの
- (void)getFirstMesh:(char *)first x:(int)x_ind y:(int)y_ind {
	first[0] = 'J' - y_ind; // Y 軸方向(南北)は、逆になる
	first[1] = 'E' + x_ind;
	first[2] = 0;
	return;
}

// 10 分割されたメッシュのコードを得る
// LARGE サイズ、DETAIL サイズのメッシュコードを得るために使用
- (void)getTenthMesh:(char *)second x:(int)x_ind y:(int)y_ind {
	second[0] = '9' - y_ind; // Y 軸方向(南北)は、逆になる
	second[1] = '0' + x_ind;
	second[2] = 0;
	return;
}

// 5 分割されたメッシュのコードを得る
// MIDDLE サイズのメッシュコードを得るために使用
- (void)getFifthMesh:(char *)middle x:(int)x_ind y:(int)y_ind {
	middle[0] = '4' - y_ind; // Y 軸方向(南北)は、逆になる
	middle[1] = 'A' + x_ind;
	middle[2] = 0;
	return;
}

// LARGE サイズのメッシュコードを得る
- (NSString *)getLargeMesh:(NSPoint)pt {
	int y_1 = floor( pt.y / MESH_HEIGHT );
	int x_1 = floor( pt.x / MESH_WIDTH  );
	NSLog(@"First : %d, %d", x_1, y_1);
	char meshCode[5];
	[self getFirstMesh:&meshCode[0] x:x_1 y:y_1];
	
	int y_2 = floor( ( pt.y - y_1 * MESH_HEIGHT ) / LARGE_MAP_HEIGHT );
	int x_2 = floor( ( pt.x - x_1 * MESH_WIDTH  ) / LARGE_MAP_WIDTH  );
	NSLog(@"Second: %d, %d", x_2, y_2);
	[self getTenthMesh:&meshCode[2] x:x_2 y:y_2];
	NSString *meshString =
		[[NSString alloc] initWithCString:meshCode
							 encoding:NSMacOSRomanStringEncoding];

	return [meshString autorelease];
}

// MIDDLE サイズのメッシュコードを得る
// MIDDLE サイズは、LARGE サイズを縦横に 5 分割したもの
- (NSString *)getMiddleMesh:(NSPoint)pt {
	int y_3 = floor( ( pt.y - floor( pt.y / LARGE_MAP_HEIGHT ) * LARGE_MAP_HEIGHT ) / MIDDLE_MAP_HEIGHT );
	int x_3 = floor( ( pt.x - floor( pt.x / LARGE_MAP_WIDTH ) * LARGE_MAP_WIDTH ) / MIDDLE_MAP_WIDTH );
	NSLog(@"Third %d, %d", x_3, y_3);
	char meshCode[3];
	[self getFifthMesh:&meshCode[0] x:x_3 y:y_3];
	NSString *meshString =
		[[NSString alloc] initWithCString:meshCode
								 encoding:NSMacOSRomanStringEncoding];

	return [meshString autorelease];
}

// DETAIL サイズのメッシュコードを得る
// DETAIL サイズは、LARGE サイズを縦横に 10 分割したもの
- (NSString *)getDetailMesh:(NSPoint)pt {
	int y_4 = floor( ( pt.y - floor( pt.y / LARGE_MAP_HEIGHT ) * LARGE_MAP_HEIGHT ) / DETAIL_MAP_HEIGHT );
	int x_4 = floor( ( pt.x - floor( pt.x / LARGE_MAP_WIDTH ) * LARGE_MAP_WIDTH ) / DETAIL_MAP_WIDTH );
	NSLog(@"Fourth %d, %d", x_4, y_4);
	char meshCode[3];
	[self getTenthMesh:&meshCode[0] x:x_4 y:y_4];
	NSString *meshString =
	[[NSString alloc] initWithCString:meshCode
							 encoding:NSMacOSRomanStringEncoding];
	
	return [meshString autorelease];
}

// ピクセルあたりの距離を調べる
- (float) getMeterPerPixel {
	float meterPerPixel = LARGE_MAP_METER_PER_PIXEL;
	switch (zoom) {
		case ZoomLarge:
			meterPerPixel = LARGE_MAP_METER_PER_PIXEL;
			break;
		case ZoomLarge2:
			meterPerPixel = LARGE_MAP_METER_PER_PIXEL * 2;
			break;
		case ZoomMiddle:
			meterPerPixel = MIDDLE_MAP_METER_PER_PIXEL;
			break;
		case ZoomMiddle2:
			meterPerPixel = MIDDLE_MAP_METER_PER_PIXEL * 2;
			break;
		case ZoomDetail:
			meterPerPixel = DETAIL_MAP_METER_PER_PIXEL;
			break;
		default:
			break;
	}
	return meterPerPixel;
}

// ひとつのメッシュの横方向の距離を調べる
- (float) getMapWidth {
	float mapWidth = LARGE_MAP_WIDTH;
	switch (zoom) {
		case ZoomLarge:
		case ZoomLarge2:
			mapWidth = LARGE_MAP_WIDTH;
			break;
		case ZoomMiddle:
		case ZoomMiddle2:
			mapWidth = MIDDLE_MAP_WIDTH;
			break;
		case ZoomDetail:
			mapWidth = DETAIL_MAP_WIDTH;
			break;
		default:
			break;
	}
	return mapWidth;
}

// ひとつのメッシュの縦方向の距離を調べる
- (float) getMapHeight {
	float mapHeight = LARGE_MAP_HEIGHT;
	switch (zoom) {
		case ZoomLarge:
		case ZoomLarge2:
			mapHeight = LARGE_MAP_HEIGHT;
			break;
		case ZoomMiddle:
		case ZoomMiddle2:
			mapHeight = MIDDLE_MAP_HEIGHT;
			break;
		case ZoomDetail:
			mapHeight = DETAIL_MAP_HEIGHT;
			break;
		default:
			break;
	}
	return mapHeight;
}

// 平面直角座標系から、緯度・経度に変換する
// http://vldb.gsi.go.jp/sokuchi/surveycalc/algorithm/xy2bl/xy2bl.htm
// 国土地理院の計算式とは、X と Y が入れかわっていることに注意
// 国土地理院の計算式では、X は南北方向、Y は東西方向になっている
// TODO:
//   エラーチェック
- (void) getLatLongFromXY:(NSPoint)XY latitude:(double *)latitude longitude:(double *)longitude {
	// 地球楕円体の長半径(日本測地系：ベッセル球体)
	// http://vldb.gsi.go.jp/sokuchi/surveycalc/algorithm/ellipse/ellipse.htm
	double a = 6377397.155;
	// 扁平率(日本測地系：ベッセル球体)
	double f = 1.0 / 299.152813;
	// 第一離心率の平方
	double e2 = 2.0 * f - f * f;
	// 第二離心率の平方
	double et2 = e2 / ( 1.0 - e2 );
	// 円周率
	double PI = 3.14159265358979323846;
	// ラジアン / 度
	double rd = PI / 180;
	// 原点における縮尺係数
	double m0 = 0.9999;
	
	// 原点の緯度・経度
	// http://www.gsi.go.jp/LAW/heimencho.html
	// ラジアンに変換する
	// TODO:
	//   第VI系以外にも対応する
	double p0 =  36.0 * rd;
	double r0 = 136.0 * rd;

	double p1 = [self calcLatitudeFromY:XY.y p0:p0 a:a e2:e2];

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
- (void) getXYFromLatitude: (double)latitude longitude:(double)longitude xy:(NSPoint *)XY
{
	// 地球楕円体の長半径(日本測地系：ベッセル球体)
	// http://vldb.gsi.go.jp/sokuchi/surveycalc/algorithm/ellipse/ellipse.htm
	double a = 6377397.155;
	// 扁平率(日本測地系：ベッセル球体)
	double f = 1.0 / 299.152813;
	// 第一離心率の平方
	double e2 = 2.0 * f - f * f;
	// 第二離心率の平方
	double et2 = e2 / ( 1.0 - e2 );
	// 円周率
	double PI = 3.14159265358979323846;
	// ラジアン / 度
	double rd = PI / 180;
	// 原点における縮尺係数
	double m0 = 0.9999;

	// ラジアンに変換する
	double p = latitude * rd;
	double r = longitude * rd;
	// TODO:
	//   第VI系以外にも対応する
	double p0 = 36.0 * rd;
	double r0 = 136.0 * rd;

	// 赤道から緯度までの子午線弧長
	double s = [self calcMeridianLengthFromLatitude:p a:a e2:e2];
	// 座標原点の緯度までの子午線弧長
	double s0 = [self calcMeridianLengthFromLatitude:p0 a:a e2:e2];

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
- (double) calcMeridianLengthFromLatitude: (double)p a:(double)a e2:(double)e2
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

- (double) calcLatitudeFromY: (double)y p0:(double)p0 a:(double)a e2:(double)e2
{
	double s0 = [self calcMeridianLengthFromLatitude:p0 a:a e2:e2];
	double m0 = 0.9999;
	double m = s0 + y / m0;

	double pn = p0;
	while ( YES ) {
		double sn = [self calcMeridianLengthFromLatitude:pn a:a e2:e2];
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

@synthesize zoomSlider;
@synthesize mapFormat;
@synthesize info_x;
@synthesize info_y;
@synthesize info_latitude;
@synthesize info_longitude;
@synthesize infoWindow;
@synthesize scale;
@synthesize first_draw;
@synthesize dragging;
@synthesize offscreenImage;
@synthesize map_folder;
@synthesize map_suffix;
@end
