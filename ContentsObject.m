//
//  ContentsObject.m
//  mgis
//
//  Created by naoki iimura on 3/16/10.
//  Copyright 2010 naoki iimura. All rights reserved.
//

#import "ContentsObject.h"


@implementation ContentsObject

@synthesize window;
@synthesize detailWindow;
@synthesize mgisView;
@synthesize shapeParamPanel;
@synthesize contentArray;
@synthesize layerArray;

/**
 Returns the support directory for the application, used to store the Core Data
 store file.  This code uses a directory named "M-GIS" for
 the content, either in the NSApplicationSupportDirectory location or (if the
 former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"M-GIS"];
}


/**
 Creates, retains, and returns the managed object model for the application 
 by merging all of the models found in the application bundle.
 */

- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel) return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.  This 
 implementation will create and return a coordinator, having added the 
 store for the application to it.  (The directory for the store is created, 
 if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
	
    if (persistentStoreCoordinator) return persistentStoreCoordinator;
	
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSError *error = nil;
    
    if ( ![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] ) {
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory,error]));
            NSLog(@"Error creating application support directory at %@ : %@",applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL *url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"mgis_contents.db"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType //NSXMLStoreType
												  configuration:nil
															URL:url
														options:nil
														  error:&error]){
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context for the application (which is already
 bound to the persistent store coordinator for the application.) 
 */

- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext) return managedObjectContext;
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	
    return managedObjectContext;
}

/**
 Returns the NSUndoManager for the application.  In this case, the manager
 returned is that of the managed object context for the application.
 */

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.  Any encountered errors
 are presented to the user.
 */

- (IBAction) saveAction:(id)sender {
	
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
    }
	
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction) showListWindow:(id)sender {
	[window makeKeyAndOrderFront:self];
}

- (IBAction) showDetailWindow:(id)sender {
	[detailWindow makeKeyAndOrderFront:self];
}

- (IBAction) importContents:(id)sender {
	NSLog( @"importContents %@", sender );
}

- (IBAction) exportContents:(id)sender {
	NSLog( @"exportContents %@", sender );
}

- (IBAction) createPointContent:(id)sender {
	NSLog( @"createPointContent %@", sender );
}

- (IBAction) createPolylineContent:(id)sender {
	NSLog( @"createPolylineContent %@", sender );
    mgisView.editingMode = ModeCreatePolyline;
    [self showShapePanel];
}

- (IBAction) createPolygonContent:(id)sender {
	NSLog( @"createPolygonContent %@", sender );
}

- (IBAction) createTextContent:(id)sender {
	NSLog( @"createTextContent %@", sender );
}

// コンテンツを追加する
- (void) insertContent:(NSData *)aContent ofClass:(Class)class atPoint:(NSPoint)point {
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contents"
                                              inManagedObjectContext:context];
    //            NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Contents"
    //                                                                    inManagedObjectContext:context];
    NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity
                                       insertIntoManagedObjectContext:context];
    // 図形を設定する
    [object setValue:aContent forKey:@"shape"];
    
    // レイヤーの設定をする
    // TODO:
    //   とりあえず適当なレイヤーを得る
    //   レイヤーが存在しなかった場合のエラー処理
    NSEntityDescription *layerEntity = [NSEntityDescription entityForName:@"Layers"
                                                   inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:layerEntity];
    [request setFetchLimit:1];
    NSArray *layerObjects = [context executeFetchRequest:request error:nil];
    NSManagedObject *layerObject = [layerObjects objectAtIndex:0];
    [object setValue:layerObject forKey:@"layer"];
    
//    [contentArray setSelectionIndex:[contentArray count]];
    
    // 作成したオブジェクトを追加する
    [context insertObject:object];
    [request release];
    
    // 設定パネルを閉じる
    [self closeShapePanel];
    
    // 詳細ウィンドウをアクティブに
    // TODO:
    //   その前に、追加したデータを選択してやる必要がある
    [self.detailWindow makeKeyAndOrderFront:self];
}

// コンテンツに図形を設定する
- (void) setContent:(NSData *)aContent ofClass:(Class)class atObjectID:(NSManagedObjectID *)objectID atPoint:(NSPoint)point {
    NSManagedObjectContext *context = [self managedObjectContext];

    // 図形を設定する
    NSManagedObject *object = [context objectWithID:objectID];
    [object setValue:aContent forKey:@"shape"];
    
    // 代表点を設定する
    [object setValue:[NSNumber numberWithFloat:point.x] forKey:@"x"];
    [object setValue:[NSNumber numberWithFloat:point.y] forKey:@"y"];
    
    // 設定パネルを閉じる
    [self closeShapePanel];
}

// 設定パネルを表示させる
- (void) showShapePanel {
    [self.shapeParamPanel makeKeyAndOrderFront:self];
    [[mgisView window] makeKeyAndOrderFront:self];
}

// 設定パネルを閉じる
- (void) closeShapePanel {
    [self.shapeParamPanel orderOut:self];
}

// コンテンツの位置へ移動する
- (IBAction) scrollToContent:(id)sender {
    NSManagedObject *object = [self.contentArray selection];
    NSLog( @"selected object x %@", [object valueForKey:@"x"] );
    float x,y;
    x = [[object valueForKey:@"x"] floatValue];
    y = [[object valueForKey:@"y"] floatValue];
    if ( x == 0.0f ) {
        return;
    } else {
        mgisView.center_x = x;
        mgisView.center_y = y;
        [mgisView setNeedsDisplay:YES];
        [mgisView updateInfoWindow];
    }
}

/**
 Implementation of the applicationShouldTerminate: method, used here to
 handle the saving of changes in the application managed object context
 before the application terminates.
 */

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
    if (!managedObjectContext) return NSTerminateNow;
	
    if (![managedObjectContext commitEditing]) {
        NSLog(@"%@:%s unable to commit editing to terminate", [self class], _cmd);
        return NSTerminateCancel;
    }
	
    // ビューの変更(中心位置)を保存する
    [mgisView saveSettings];

    if (![managedObjectContext hasChanges]) return NSTerminateNow;
	
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
		
        // This error handling simply presents error information in a panel with an 
        // "Ok" button, which does not include any attempt at error recovery (meaning, 
        // attempting to fix the error.)  As a result, this implementation will 
        // present the information to the user and then follow up with a panel asking 
        // if the user wishes to "Quit Anyway", without saving the changes.
		
        // Typically, this process should be altered to include application-specific 
        // recovery steps.  
		
        BOOL result = [sender presentError:error];
        if (result) return NSTerminateCancel;
		
        NSString *question = NSLocalizedString(@"Could not save changes while quitting.  Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
		
        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) return NSTerminateCancel;
		
    }
	
    return NSTerminateNow;
}


/**
 Implementation of dealloc, to release the retained variables.
 */

- (void)dealloc {
	
    [window release];
	[detailWindow release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
    [managedObjectModel release];
	
    [super dealloc];
}


@end
