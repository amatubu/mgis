//
//  MGISView.m
//  mgis
//
//  Created by naoki iimura on 3/11/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "MGISView.h"


static int	RADIUS = 2;

@implementation MGISView

@synthesize center_x;
@synthesize center_y;
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
@synthesize offscreenOrigin;
@synthesize offscreenRect;
@synthesize offscreenZoom;
@synthesize offscreenMapSuffix;
@synthesize map_folder;
@synthesize map_suffix;
@synthesize converter;

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

		// 最初の描画
		first_draw = YES;
		
		// 地図のフォーマット(拡張子)
		map_suffix = @".jpg";
		
		// 地図のズームレベル
		zoom = ZoomLarge;

		// 初期設定
		[self setupDefaults];
		
		converter = [[CoordinateConverter coordinateConverterWithSpheroidalType:@"bessel"] retain];
		
		dragging = NO;
	}
    return self;
}

- (void)dealloc {
	
    [converter release];
	[offscreenImage release];
	[offscreenMapSuffix release];
	[map_folder release];
	[map_suffix release];
	
    [super dealloc];
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

	// コンテクストを得る
	NSManagedObjectContext *context = [contentObject managedObjectContext];
	
	// 検索条件
	// BOOL 値は、「= NO」で比較できるようだ
	// リレーションについても、リレーション名.アトリビュート名で指定できる
//	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = 'name1'"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hidden = NO and layer.hidden = NO"];

	// 検索対象のエンティティ
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contents" inManagedObjectContext:context];
	
	// リクエストを新規作成し、検索対象と検索条件を設定
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	[request setPredicate:predicate];

	// 取り出す最大数
	[request setFetchLimit: 10];
	
	// フェッチ
	NSError *error;
	NSArray *fetchedObjects = [context executeFetchRequest:request error: &error ];
	
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
		x = offscreenOrigin.x - [self bounds].size.width / 2.0 * meterPerPixel;
		y = offscreenOrigin.y - [self bounds].size.height / 2.0 * meterPerPixel;
		x_offset = - ( x - floor( x / mapWidth ) * mapWidth ) / meterPerPixel;
		y_offset = - ( y - floor( y / mapHeight ) * mapHeight ) / meterPerPixel;
		x_offset += ( offscreenOrigin.x - center_x ) / meterPerPixel;
		y_offset += ( offscreenOrigin.y - center_y ) / meterPerPixel;
	} else {
		if ( zoom == offscreenZoom && [map_suffix compare:offscreenMapSuffix] == NSOrderedSame &&
			 NSPointInRect( NSMakePoint(x,y), offscreenRect ) &&
			 NSPointInRect( NSMakePoint( center_x + [self bounds].size.width / 2.0 * meterPerPixel,
										 center_y + [self bounds].size.height / 2.0 * meterPerPixel ), offscreenRect ) ) {

			// 前に使用した画像がそのまま使える
			// TODO:
			//   ウィンドウの大きさを変更した際に地図がずれる場合がある
			x = offscreenOrigin.x - [self bounds].size.width / 2.0 * meterPerPixel;
			y = offscreenOrigin.y - [self bounds].size.height / 2.0 * meterPerPixel;
			x_offset = - ( x - floor( x / mapWidth ) * mapWidth ) / meterPerPixel;
			y_offset = - ( y - floor( y / mapHeight ) * mapHeight ) / meterPerPixel;
			x_offset += ( offscreenOrigin.x - center_x ) / meterPerPixel;
			y_offset += ( offscreenOrigin.y - center_y ) / meterPerPixel;
		} else {
			// そのまま使うことができないので、新しく作成する
			float offscreenWidth = mapImageWidth * ( floor( ( [self bounds].size.width - x_offset ) / mapImageWidth ) + 1 );
			float offscreenHeight = mapImageHeight * ( floor( ( [self bounds].size.height - y_offset ) / mapImageHeight ) + 1 );
			offscreenRect = NSMakeRect( x + x_offset * meterPerPixel,
									    y + y_offset * meterPerPixel,
									    offscreenWidth * meterPerPixel, offscreenHeight * meterPerPixel );
			offscreenZoom = zoom;
			offscreenOrigin = NSMakePoint( center_x, center_y );
			offscreenMapSuffix = map_suffix;

			[offscreenImage release];
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
	}
	[offscreenImage compositeToPoint:NSMakePoint( x_offset, y_offset ) operation:NSCompositeSourceOver];
	
	[self drawCenterMarker:(NSRect)rect];

    NSBezierPath*	bezier = [NSBezierPath bezierPath];
    
    // Draw curve
    [[NSColor blackColor] set];
    [bezier moveToPoint:_startPoint];
    [bezier curveToPoint:_endPoint controlPoint1:_ctrlPoint1 controlPoint2:_ctrlPoint2];
    [bezier stroke];
    
    // Draw control points
    [[[NSColor redColor] colorWithAlphaComponent:0.7] set];
    [NSBezierPath fillRect:makeControlRect(_startPoint)];
    [NSBezierPath fillRect:makeControlRect(_endPoint)];
    [[NSBezierPath bezierPathWithOvalInRect:makeControlRect(_ctrlPoint1)] fill];
    [[NSBezierPath bezierPathWithOvalInRect:makeControlRect(_ctrlPoint2)] fill];
    [NSBezierPath strokeLineFromPoint:_startPoint toPoint:_ctrlPoint1];
    [NSBezierPath strokeLineFromPoint:_endPoint toPoint:_ctrlPoint2];
}

// ビュー上でマウスボタンが押された際に呼ばれる
// 地図をスクロールさせるための事前準備として、ボタンが押された座標を記録しておく
- (void) mouseDown: (NSEvent *) event
{
    NSPoint*	targetedPoint = NULL;
    NSPoint		locationInWindow = [event locationInWindow];
    
    if(NSPointInRect(locationInWindow, makeControlRect(_startPoint))) {
        targetedPoint = &_startPoint;
    }
    else if(NSPointInRect(locationInWindow, makeControlRect(_endPoint))) {
        targetedPoint = &_endPoint;
    }
    else if(NSPointInRect(locationInWindow, makeControlRect(_ctrlPoint1))) {
        targetedPoint = &_ctrlPoint1;
    }
    else if(NSPointInRect(locationInWindow, makeControlRect(_ctrlPoint2))) {
        targetedPoint = &_ctrlPoint2;
    }
    
    if(targetedPoint == NULL) {
		// マウスボタンが押された座標を記録しておく
		grabOrigin = [event locationInWindow];
		scrollOrigin = NSMakePoint( center_x, center_y );
		
		// ドラッグ開始
		dragging = YES;
        return;
    }
    
    // Track mouse dragging
    while(1) {
        NSEvent*	evt = [NSApp nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask) untilDate:nil inMode:NSEventTrackingRunLoopMode dequeue:YES];
        
        if([evt type] == NSLeftMouseUp) {
            break;
        }
		if([evt type] == 0) {
			continue;
		}
        
        // Update targetedPoint
        *targetedPoint = [evt locationInWindow];
		NSLog(@"target: %f, %f, %d", targetedPoint->x, targetedPoint->y, [evt type ]);
        
        // Re-display itself
        [self setNeedsDisplay:YES];
    }
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
	[converter getLatLongFromXY:NSMakePoint(center_x,center_y) latitude:&latitude longitude:&longitude kei:6];

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

- (void)awakeFromNib
{
    // Initialize
    _startPoint.x = 50;		_startPoint.y = 100;
    _endPoint.x = 200;		_endPoint.y = 100;
    _ctrlPoint1.x = 100;	_ctrlPoint1.y = 150;
    _ctrlPoint2.x = 150;	_ctrlPoint2.y = 150;
}

NSRect makeControlRect(NSPoint controlPoint)
{
    return NSMakeRect(controlPoint.x - RADIUS * 2, controlPoint.y - RADIUS * 2, RADIUS * 4, RADIUS * 4);
}


@end
