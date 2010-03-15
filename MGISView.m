//
//  MGISView.m
//  mgis
//
//  Created by naoki iimura on 3/11/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "MGISView.h"


@implementation MGISView

// 初期化ルーチン
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 地図の画像ファイルが保存されているパス
		// TODO:
		//   任意の場所を指定できるようにする
		//   iPhone では、どこにするか?
		map_folder = @"/Users/sent/work/mgis/200403/";

		// 画面の中心の座標の初期値
		// 直交座標系 VI 系
		// TODO:
		//   最後に表示していた場所を記録するようにしたい
		center_x = 46665.476f;
		center_y = -140941.652f;

		// 地図のフォーマット(拡張子)
		// TODO:
		//   最後に選んだものを記録するようにしたい
		map_suffix = @".jpg";
		
		// 地図のズームレベル
		// TODO:
		//   最後に選んだものを記録するようにしたい
		zoom = ZoomLarge;

		dragging = NO;
		
		// 情報ウィンドウやスケールの内容を更新する
		// TODO:
		//   適切な場所に移動すべき
		//   Nib を読みこんだあとあたり?
		[self updateInfoWindow];
		[self updateScaleText];
	}
    return self;
}

// 描画ルーチン
// ビューの内容を更新する必要が生じた際に呼ばれる
- (void)drawRect:(NSRect)rect {
	// ズームレベルによって異なる定数を変数に保存しておく
	float meterPerPixel = [self getMeterPerPixel];
	float mapWidth = [self getMapWidth];
	float mapHeight = [self getMapHeight];

	// 画面の左下の座標(原点)に表示すべき地図を調べる
	// x は、画面の左下の座標(原点)の地図上の横位置
	// x_offset は、そこに表示すべき地図の、原点からのオフセット
	float x = center_x - rect.size.width / 2.0 * meterPerPixel;
	float y = center_y - rect.size.height / 2.0 * meterPerPixel;
	float x_offset = - ( x - floor( x / mapWidth ) * mapWidth ) / meterPerPixel;
	float y_offset = - ( y - floor( y / mapHeight ) * mapHeight ) / meterPerPixel;

	if ( dragging ) {
	} else {
		float offscreenWidth = MAP_IMAGE_WIDTH * ( floor( ( rect.size.width - x_offset ) / MAP_IMAGE_WIDTH ) + 1 );
		float offscreenHeight = MAP_IMAGE_HEIGHT * ( floor( ( rect.size.height - y_offset ) / MAP_IMAGE_HEIGHT ) + 1 );

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
						// LARGE サイズの場合は、LARGE フォルダに「メッシュコード名.*」という形式で保存されている
						mapFile = [NSString stringWithFormat:@"%@LARGE/%@%@%@",
								   map_folder,@"06",meshString,map_suffix];
						break;
					case ZoomMiddle:
						// MIDDLE サイズの場合は、MIDDLE フォルダの中に、そのメッシュを含む LARGE サイズの
						// メッシュコード名のフォルダがあり、その中に保存されている
					{
						NSString *middleMeshString = [self getMiddleMesh:NSMakePoint( x, y )];
						mapFile = [NSString stringWithFormat:@"%@MIDDLE/%@%@/%@%@%@%@",
								   map_folder,@"06",meshString,@"06",meshString,middleMeshString,map_suffix];
					}
						break;
					case ZoomDetail:
						// DETAIL サイズの場合は、DETAIL フォルダの中に、そのメッシュを含む LARGE サイズの
						// メッシュコード名のフォルダがあり、その中に保存されている
					{
						NSString *detailMeshString = [self getDetailMesh:NSMakePoint( x, y )];
						mapFile = [NSString stringWithFormat:@"%@DETAIL/%@%@/%@%@%@%@",
								   map_folder,@"06",meshString,@"06",meshString,detailMeshString,map_suffix];
					}
						break;
					default:
						// TODO:
						//   Large2、Middle2 が未サポート
						return;
				}
				
				NSLog([NSString stringWithFormat:@"Map file: %@", mapFile]);
				NSLog(@"Offset: %.3f, %.3f", x_offset, y_offset);

				// 画像ファイルを得る
				NSImage *anImage = [[NSImage alloc] initWithContentsOfFile:mapFile];
				if ( anImage ) {
					// NSImage が得られたら、計算しておいたオフセットの位置へ描画する
					[anImage compositeToPoint:NSMakePoint( imageOffsetX, imageOffsetY ) operation:NSCompositeSourceOver];
					[anImage release];
				}
	//			[fileUrl release];
				
				// Y 方向の次のメッシュへ
				y += MAP_IMAGE_HEIGHT * meterPerPixel;
				imageOffsetY += MAP_IMAGE_HEIGHT;
			}
			// X 方向の次のメッシュへ
			x += MAP_IMAGE_WIDTH * meterPerPixel;
			imageOffsetX += MAP_IMAGE_WIDTH;
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
	dragging = YES;
} // mouseDown

// ビュー上でドラッグされた際に呼ばれる
// 地図をスクロールさせる
// TODO:
//   少しでも動かすと全体を再描画しているのでちょっと重たい
//   スクロール中は既に描画したところだけを動かし、mouseUp で全体を再描画する方がよい
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

- (void) mouseUp: (NSEvent *) event
{
	NSPoint mousePoint;
	mousePoint = [event locationInWindow];
	
	dragging = NO;
	[self setNeedsDisplay:YES];
}

// 情報ウィンドウの内容を更新する
// 現在は中心点の直交座標系での座標のみを表示
// 起動時や、ズームレベルを変更したときに呼ばれる
// TODO:
//   起動時には、まだ準備ができていないみたいなので、準備ができたら更新するようにする
- (void) updateInfoWindow {
	[info_x setStringValue:[NSString stringWithFormat:@"%02.3f m", center_x]];
	[info_y setStringValue:[NSString stringWithFormat:@"%02.3f m", center_y]];

	float latitude,longitude;
	[self getLongLatFromXY:NSMakePoint(center_x,center_y) latitude:&latitude longitude:&longitude];
	[info_latitude setStringValue:[NSString stringWithFormat:@"%02.7f", latitude]];
	[info_longitude setStringValue:[NSString stringWithFormat:@"%02.7f", longitude]];
}

// 縮尺をあらわすスケールを更新する
// 起動時や、ズームレベルを変更したときに呼ばれる
// TODO:
//   起動時には、まだ準備ができていないみたいなので、準備ができたら更新するようにする
- (void) updateScaleText {
	float meterPer80Pixels = [self getMeterPerPixel] * 80.0;
	[scale setStringValue:[NSString stringWithFormat:@"%d m", (int)meterPer80Pixels]];
}

//
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
	int x_1 = floor( pt.x / MESH_WIDTH );
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
			mapWidth = LARGE_MAP_WIDTH;
			break;
		case ZoomLarge2:
			mapWidth = LARGE_MAP_WIDTH / 2;
			break;
		case ZoomMiddle:
			mapWidth = MIDDLE_MAP_WIDTH;
			break;
		case ZoomMiddle2:
			mapWidth = MIDDLE_MAP_WIDTH / 2;
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
			mapHeight = LARGE_MAP_HEIGHT;
			break;
		case ZoomLarge2:
			mapHeight = LARGE_MAP_HEIGHT / 2;
			break;
		case ZoomMiddle:
			mapHeight = MIDDLE_MAP_HEIGHT;
			break;
		case ZoomMiddle2:
			mapHeight = MIDDLE_MAP_HEIGHT / 2;
			break;
		case ZoomDetail:
			mapHeight = DETAIL_MAP_HEIGHT;
			break;
		default:
			break;
	}
	return mapHeight;
}

// 
- (void) getLongLatFromXY:(NSPoint)XY latitude:(float *)latitude longitude:(float *)longitude {
	double a = 6377397.155;
	double f = 1 / 299.152813;
	double e2 = 2 * f - f * f;
	double z = 0.0;
	float PI = 3.14159265358979323846f;
	double rd = PI / 180;
	
	double bda, p, t, st, ct, b, l, sb, rn, h;
	bda = sqrt( 1 - e2 );

	p = sqrt( (double)XY.x * (double)XY.x + (double)XY.y * (double)XY.y );
	t = atan2( z, p * bda );
	st = sin( t );
	ct = cos( t );
	b = atan2( z + e2 * a / bda * st * st * st, p - e2 * a * ct * ct * ct );
	l = atan2( (double)XY.y, (double)XY.x );

	sb = sin( b );
	rn = a / sqrt( 1 - e2 * sb * sb );
	h = p / cos( b ) - rn;

	*latitude = b / rd;
	*longitude = l / rd;
}

@end
