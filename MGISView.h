//
//  MGISView.h
//  mgis
//
//  Created by naoki iimura on 3/11/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <AppKit/NSView.h>
#import "CoordinateConverter.h"
#import "MGISPolyline.h"

typedef enum {
    ZoomDetail = 0,
    ZoomMiddle,
	ZoomMiddle2,
    ZoomLarge,
	ZoomLarge2,
} ZoomLevel;

typedef enum {
    ModeViewingMap = 0,
    ModeCreatePoint,
    ModeCreatePolyline,
    ModeCreatePolygon,
    ModeCreateText,
    ModeCreatingPoint,
    ModeCreatingPolyline,
    ModeCreatingPolygon,
    ModeCreatingText,
    ModeEditingPoint,
    ModeEditingPolyline,
    ModeEditingpolygon,
    ModeEditingText,
} EditingMode;

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
	IBOutlet id scale;
	IBOutlet id contentObject;
    IBOutlet id userPrefs;
	
	IBOutlet id infoWindow;
	IBOutlet id info_x;
	IBOutlet id info_y;
	IBOutlet id info_latitude;
	IBOutlet id info_longitude;

    IBOutlet id lineWidth;
    IBOutlet id lineColor;
    
	float center_x;
	float center_y;

	BOOL first_draw;

	BOOL dragging;
    NSPoint grabOrigin;

	NSImage *offscreenImage;
	NSPoint offscreenOrigin;
	NSRect offscreenRect;
	ZoomLevel offscreenZoom;
	NSString *offscreenMapSuffix;

	ZoomLevel zoom;
    EditingMode editingMode;

	NSString *map_folder;
	NSString *map_suffix;

	CoordinateConverter *converter;
	
    MGISPolyline *creatingPolyline;
    NSMutableArray *shapes;
    MGISPolyline *selectedPolyline;
}

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
- (void) updateOffscreenImageAtOrigin:(NSPoint)origin size:(NSSize)size;

- (IBAction) changeZoomLevel:(id)sender;
- (IBAction) changeMapFormat:(id)sender;
- (IBAction) changeLineWidth:(id)sender;
- (IBAction) changeLineColor:(id)sender;
- (IBAction) cancelEditing:(id)sender;
- (IBAction) finishEditing:(id)sender;

@property float center_x;
@property float center_y;
@property (retain) id zoomSlider;
@property (retain) id mapFormat;
@property (retain) id info_x;
@property (retain) id info_y;
@property (retain) id info_latitude;
@property (retain) id info_longitude;
@property (retain) id infoWindow;
@property (retain) id scale;
@property BOOL first_draw;
@property BOOL dragging;
@property NSPoint grabOrigin;
@property (retain) NSImage *offscreenImage;
@property NSPoint offscreenOrigin;
@property NSRect offscreenRect;
@property ZoomLevel offscreenZoom;
@property (retain) NSString *offscreenMapSuffix;
@property (retain) NSString *map_folder;
@property (retain) NSString *map_suffix;
@property ZoomLevel zoom;
@property EditingMode editingMode;

@property (retain) CoordinateConverter *converter;
@end

NSRect makeControlRect(NSPoint controlPoint);
