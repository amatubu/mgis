//
//  ContentsObject.h
//  mgis
//
//  Created by naoki iimura on 3/16/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGISView.h"


@interface ContentsObject : NSObject {
	MGISView *mgisView;
    NSWindow *window;
	NSWindow *detailWindow;
    NSPanel *shapeParamPanel;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;

    NSArrayController *contentArray;
    NSArrayController *layerArray;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSWindow *detailWindow;
@property (nonatomic, retain) IBOutlet MGISView *mgisView;
@property (nonatomic, retain) IBOutlet NSPanel *shapeParamPanel;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet NSArrayController *contentArray;
@property (nonatomic, retain) IBOutlet NSArrayController *layerArray;

- (IBAction) saveAction:sender;
- (IBAction) showListWindow:(id)sender;
- (IBAction) showDetailWindow:(id)sender;

- (IBAction) importContents:(id)sender;
- (IBAction) exportContents:(id)sender;

- (IBAction) createPointContent:(id)sender;
- (IBAction) createPolylineContent:(id)sender;
- (IBAction) createPolygonContent:(id)sender;
- (IBAction) createTextContent:(id)sernder;

- (void) insertContent:(NSData *)aContent ofClass:(Class)aClass;
- (void) setContent:(NSData *)aContent ofClass:(Class)aClass atObjectID:(NSManagedObjectID *)objectID;
- (void) showShapePanel;
- (void) closeShapePanel;

@end
