//
//  MGISView.h
//  mgis
//
//  Created by naoki iimura on 3/11/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <AppKit/NSView.h>

typedef enum {
    ZoomDetail = 0,
    ZoomMiddle,
	ZoomMiddle2,
    ZoomLarge,
	ZoomLarge2,
} ZoomLevel;

#define MAP_IMAGE_WIDTH  640.0
#define MAP_IMAGE_HEIGHT 480.0

#define MESH_WIDTH  40000.0
#define MESH_HEIGHT 30000.0
#define LARGE_MAP_WIDTH   4000.0
#define LARGE_MAP_HEIGHT  3000.0
#define MIDDLE_MAP_WIDTH   800.0
#define MIDDLE_MAP_HEIGHT  600.0
#define DETAIL_MAP_WIDTH   400.0
#define DETAIL_MAP_HEIGHT  300.0

#define LARGE_MAP_METER_PER_PIXEL  ( LARGE_MAP_WIDTH / MAP_IMAGE_WIDTH )
#define MIDDLE_MAP_METER_PER_PIXEL ( MIDDLE_MAP_WIDTH / MAP_IMAGE_WIDTH )
#define DETAIL_MAP_METER_PER_PIXEL ( DETAIL_MAP_WIDTH / MAP_IMAGE_WIDTH )


@interface MGISView : NSView {
	IBOutlet id zoomSlider;
	IBOutlet id mapFormat;
	IBOutlet id info_x;
	IBOutlet id info_y;
	IBOutlet id info_latitude;
	IBOutlet id info_longitude;
	IBOutlet id infoWindow;
	IBOutlet id scale;
	
	float center_x;
	float center_y;

	BOOL first_draw;

	BOOL dragging;
    NSPoint grabOrigin;
    NSPoint scrollOrigin;
	NSImage *offscreenImage;

	ZoomLevel zoom;

	NSString *map_folder;
	NSString *map_suffix;
}

@property float center_x;
@property float center_y;

- (void) setupDefaults;

- (void) getFirstMesh:(char *)first x:(int)x_ind y:(int)y_ind;
- (void) getTenthMesh:(char *)second x:(int)x_ind y:(int)y_ind;
- (void) getFifthMesh:(char *)middle x:(int)x_ind y:(int)y_ind;
- (NSString *) getLargeMesh:(NSPoint)pt;
- (NSString *) getMiddleMesh:(NSPoint)pt;
- (NSString *) getDetailMesh:(NSPoint)pt;
- (float) getMeterPerPixel;
- (float) getMapWidth;
- (float) getMapHeight;
- (void) updateInfoWindow;
- (void) updateScaleText;
- (void) drawCenterMarker: (NSRect)viewRect;

- (void) getLatLongFromXY:(NSPoint)XY latitude:(double *)latitude longitude:(double *)longitude;
- (void) getXYFromLatitude: (double)latitude longitude:(double)longitude xy:(NSPoint *)XY;
- (double) calcMeridianLengthFromLatitude: (double)p a:(double)a e2:(double)e2;
- (double) calcLatitudeFromY: (double)y p0:(double)p0 a:(double)a e2:(double)e2;

- (IBAction) changeZoomLevel:(id)sender;
- (IBAction) changeMapFormat:(id)sender;

@end
