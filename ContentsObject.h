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
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSWindow *detailWindow;
@property (nonatomic, retain) IBOutlet MGISView *mgisView;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction) saveAction:sender;
- (IBAction) showListWindow:(id)sender;
- (IBAction) showDetailWindow:(id)sender;

- (IBAction) importContents:(id)sender;
- (IBAction) exportContents:(id)sender;

- (IBAction) createPointContent:(id)sender;
- (IBAction) createPolylineContent:(id)sender;
- (IBAction) createPolygonContent:(id)sender;
- (IBAction) createTextContent:(id)sernder;

@end
