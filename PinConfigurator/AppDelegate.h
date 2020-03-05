//
//  AppDelegate.h
//  PinConfigurator
//
//  Created by Ben Baker on 2/7/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AudioNode.h"
#import "AudioDevice.h"
#import "HdaCodec.h"

enum
{
	kNodeNone = 0,
	kNodeFixHeadphone = (1 << 0),
	kNodeRemoveDisabled = (1 << 1),
	kNodeRemoveATAPI = (1 << 2),
	kNodeIndexToZero = (1 << 3),
	kNodeMiscToZero = (1 << 4),
	kNodeMakeGroupUnique = (1 << 5),
	kNodeChangeLocation = (1 << 6),
	kNodeLineOutToSpeaker = (1 << 7),
	kNodeEnableDSP = (1 << 8),
	kNodeDisableExtMic = (1 << 9),
	kNodeRemoveHDMI = (1 << 10)
} NodeOptions;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate>
{
	HdaCodec *_hdaCodec;
	NSMutableArray *_originalNodeArray;
	NSMutableArray *_nodeArray;
	NSArray *_hdaConfigDefaultArray;
	
	NSString *_fileName;
	NSString *_pinConfigsFileName;
	NSString *_codecName;
	int _codecAddress;
	unsigned int _codecID;
	int _layoutID;
	
	NSMutableArray *_audioDeviceArray;
	AudioDevice *_audioDevice;
	
	NSDictionary *_controllersDictionary;
	NSDictionary *_vendorsDictionary;
	NSArray *_codecsArray;
	NSMutableArray *_codecIDArray;
	
	NSString *_hdaCodecString;
	NSMutableArray *_selectCodecArray;
	
	bool _sortNodes;
	uint32_t _nodeOptions;
}

@property (assign) IBOutlet NSWindow *mainWindow;
@property (assign) IBOutlet NSButton *addOKButton;
@property (assign) IBOutlet NSPopUpButton *codecAddressPopUpButton;
@property (assign) IBOutlet NSButton *getConfigDataButton;
@property (assign) IBOutlet NSButton *quotesButton;
@property (assign) IBOutlet NSPopUpButton *colorPopUpButton;
@property (assign) IBOutlet NSPopUpButton *connectorPopUpButton;
@property (assign) IBOutlet NSPopUpButton *devicePopUpButton;
@property (assign) IBOutlet NSPopUpButton *groupPopUpButton;
@property (assign) IBOutlet NSPopUpButton *grossLocationPopUpButton;
@property (assign) IBOutlet NSPopUpButton *geometricLocationPopUpButton;
@property (assign) IBOutlet NSPopUpButton *miscPopUpButton;
@property (assign) IBOutlet NSPopUpButton *portPopUpButton;
@property (assign) IBOutlet NSPopUpButton *positionPopUpButton;
@property (assign) IBOutlet NSPopUpButton *eapdPopUpButton;
@property (assign) IBOutlet NSTextField *nodeIDTextField;
@property (assign) IBOutlet NSTextField *pinDefaultTextField;
@property (assign) IBOutlet NSTextField *configDataTextField;
@property (assign) IBOutlet NSOutlineView *pinConfigOutlineView;
@property (assign) IBOutlet NSOutlineView *importPinOutlineView;
@property (assign) IBOutlet NSOutlineView *importIORegOutlineView;
@property (assign) IBOutlet NSOutlineView *selectCodecOutlineView;
@property (assign) IBOutlet NSTextField *addNodeTextField;
@property (assign) IBOutlet NSPanel *addNodePanel;
@property (assign) IBOutlet NSPanel *importPinConfigPanel;
@property (assign) IBOutlet NSPanel *importIORegPanel;
@property (assign) IBOutlet NSPanel *selectCodecPanel;
@property (assign) IBOutlet NSSegmentedControl *editNodeSegmentedControl;
@property (assign) IBOutlet NSTextField *layoutIDTextField;
@property (assign) IBOutlet NSMenu *optionsMenu;
@property (assign) IBOutlet NSMenu *verbSanitizeOptionsMenu;

@property (retain) NSMutableArray *originalNodeArray;
@property (retain) NSMutableArray *nodeArray;

- (IBAction)compileConfigList:(id)sender;
- (IBAction)editNodeCancel:(id)sender;
- (IBAction)editNodeOK:(id)sender;
- (IBAction)editNodePinStringAction:(id)sender;
- (IBAction)editNodeComboAction:(id)sender;
- (IBAction)editNodeAction:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)exportVerbsTxt:(id)sender;
- (IBAction)exportHdaCodecTxt:(id)sender;
- (IBAction)exportPlatformsXml:(id)sender;
- (IBAction)importPinConfigsKext:(id)sender;
- (IBAction)exportPinConfigsKext:(id)sender;
- (IBAction)importIORegistry:(id)sender;
- (IBAction)importClipboard:(id)sender;
- (IBAction)print:(id)sender;
- (IBAction)importPinSelect:(id)sender;
- (IBAction)importPinCancel:(id)sender;
- (IBAction)importIORegSelect:(id)sender;
- (IBAction)importIORegCancel:(id)sender;
- (IBAction)selectCodecCancel:(id)sender;
- (IBAction)selectCodecSelect:(id)sender;
- (IBAction)layoutIDAction:(id)sender;
- (IBAction)removeDisabledAction:(id)sender;
- (IBAction)verbSanitizeAction:(id)sender;

@end

