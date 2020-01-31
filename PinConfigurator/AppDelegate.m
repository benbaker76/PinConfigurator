//
//  AppDelegate.m
//  PinConfigurator
//
//  Created by Ben Baker on 2/7/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "AppDelegate.h"
#import "NSPinCell.h"
#import "NSString+Pin.h"
#import "AudioNode.h"
#import "AudioDevice.h"
#import "HdaVerbs.h"
#import "MiscTools.h"
#import "IORegTools.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// https://github.com/shmilee/T450-Hackintosh/tree/master/ALC3232
	// https://www.insanelymac.com/forum/topic/223495-the-most-perfect-way-to-get-sound-on-1064acl1200-and-all-others-based-on-acl888/
	// http://roghackintosh.com/index.php?topic=55.0
	// https://www.insanelymac.com/forum/topic/267905-voodoohda-common-problems/
	// https://github.com/nguyenlc1993/mac-os-k501l/wiki/Information-about-patching-AppleHDA
	// https://www.insanelymac.com/forum/topic/311293-applealc-%E2%80%94-dynamic-applehda-patching/?page=104
	// https://github.com/cmatsuoka/codecgraph/blob/master/codecgraph.py
	// https://github.com/Goldfish64/AudioPkg/tree/master/Application/HdaCodecDump
	
	//[self resetDefaults];
	[self setDefaults];
	[self loadSettings];

	[self initOptionsMenu];
	
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSDictionary *infoDictionary = [mainBundle infoDictionary];
	NSString *version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
	[[self mainWindow] setTitle:[NSString stringWithFormat:@"Pin Configurator v%@", version]];
	NSString *filePath = nil;
	
	if ((filePath = [mainBundle pathForResource:@"Controllers" ofType:@"plist" inDirectory:@"Audio"]))
		_controllersDictionary = [[NSDictionary dictionaryWithContentsOfFile:filePath] retain];
	
	if ((filePath = [mainBundle pathForResource:@"Vendors" ofType:@"plist" inDirectory:@"Audio"]))
		_vendorsDictionary = [[NSDictionary dictionaryWithContentsOfFile:filePath] retain];
	
	if ((filePath = [mainBundle pathForResource:@"Codecs" ofType:@"plist" inDirectory:@"Audio"]))
		_codecsArray = [[NSArray arrayWithContentsOfFile:filePath] retain];
	
	if (getIORegAudioDeviceArray(&_audioDeviceArray))
	{
		for (AudioDevice *audioDevice in _audioDeviceArray)
		{
			NSString *vendorName, *codecName;
			
			[self getAudioVendorName:audioDevice.deviceID vendorName:&vendorName];
			[self getAudioCodecName:audioDevice.codecID revisionID:audioDevice.codecRevisionID name:&codecName];
			
			audioDevice.codecName = codecName;
			
			//NSLog(@"DeviceID: 0x%08X (%@) LayoutID: %d SubDeviceID: 0x%08X Codec: %@ (0x%08X) Revision: 0x%04X", audioDevice.deviceID, vendorName, audioDevice.alcLayoutID, audioDevice.subDeviceID, codecName, audioDevice.codecID, audioDevice.revisionID & 0xFFFF);
			
			if (_audioDevice == nil)
			{
				_audioDevice = audioDevice;
				_codecName = audioDevice.codecName;
				_codecID = audioDevice.codecID;
				_layoutID = audioDevice.alcLayoutID;
				
				[[self layoutIDTextField] setIntValue:_layoutID];
			}
		}
	}
	
	_nodeArray = [[NSMutableArray alloc] init];
	NSPinCell *pinCell = [[[NSPinCell alloc] init] autorelease];
	NSTableColumn *tableColumn = [_pinConfigOutlineView tableColumnWithIdentifier:@"1"];
	[tableColumn setDataCell:pinCell];
	[_pinConfigOutlineView setDoubleAction:@selector(editNode:)];
	[_pinConfigOutlineView setTarget:self];
	[_portPopUpButton removeAllItems];
	[_geometricLocationPopUpButton removeAllItems];
	[_devicePopUpButton removeAllItems];
	[_connectorPopUpButton removeAllItems];
	[_colorPopUpButton removeAllItems];
	[_miscPopUpButton removeAllItems];
	[_groupPopUpButton removeAllItems];
	[_positionPopUpButton removeAllItems];
	[_eapdPopUpButton removeAllItems];
	[self updateView];
}

- (void)dealloc
{
	[_originalNodeArray release];
	[_nodeArray release];
	
	[super dealloc];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self saveSettings];
	
	[_fileName release];
	[_codecName release];
	
	[_controllersDictionary release];
	[_vendorsDictionary release];
	
	[_originalNodeArray release];
	[_nodeArray release];
	[_hdaConfigDefaultArray release];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (int) alignCount:(int)count bySize:(int)size
{
	int ret = count;
	
	if (count % size > 0)
		ret = size * (count / size + 1);
	
	return ret;
}

- (void) initOptionsMenu
{
	[_optionsMenu setAutoenablesItems:NO];
	[_verbSanitizeOptionsMenu setAutoenablesItems:NO];
	[_verbSanitizeOptionsMenu removeAllItems];
	
	[_optionsMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
	
	NSMenuItem *sortNodesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Sort Nodes" action:@selector(generalOptionClicked:) keyEquivalent:@""];
	[sortNodesMenuItem setTag:0];
	[sortNodesMenuItem setState:_sortNodes];
	[_optionsMenu insertItem:sortNodesMenuItem atIndex:0];
	[sortNodesMenuItem release];
	
	NSArray *nodeOptionsArray = @[@"Fix Headphone", @"Remove Disabled", @"Remove ATAPI", @"Index to Zero", @"Misc to Zero", @"Make Group Unique", @"Change Location", @"Line Out to Speaker", @"Enable DSP", @"Disable Ext Mic", @"Remove HDMI"];
	
	for (int i = 0; i < [nodeOptionsArray count]; i++)
	{
		NSMenuItem *nodeOptionMenuItem = [[NSMenuItem alloc] initWithTitle:nodeOptionsArray[i] action:@selector(nodeOptionClicked:) keyEquivalent:@""];
		[nodeOptionMenuItem setTag:i];
		[nodeOptionMenuItem setState:_nodeOptions & (1 << i)];
		[_verbSanitizeOptionsMenu addItem:nodeOptionMenuItem];
		[nodeOptionMenuItem release];
	}
}

- (void) updateView
{
	[_pinConfigOutlineView reloadData];
	[[self getConfigDataButton] setEnabled:[_nodeArray count] != 0];
	[[self getConfigDataButton] setEnabled:[_nodeArray count] != 0];
	[[self editNodeSegmentedControl] setEnabled:[_pinConfigOutlineView selectedRow] + 1 != 0 forSegment:1];
	[[self editNodeSegmentedControl] setEnabled:[_pinConfigOutlineView selectedRow] + 1 != 0 forSegment:2];
}

- (void) refreshPopupButtons:(uint8_t)location misc:(uint8_t)misc
{
	uint8_t grossLocation = (location >> 4);
	//uint8_t geometricLocation = (location & 0xF);
	
	for (int i = 0; i <= 0x3; i++)
	{
		if (i >= _portPopUpButton.itemArray.count)
			[_portPopUpButton addItemWithTitle:@""];
		
		[_portPopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %@", i, [NSString pinPort:i]]];
		[_portPopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0x3; i++)
	{
		if (i >= _grossLocationPopUpButton.itemArray.count)
			[_grossLocationPopUpButton addItemWithTitle:@""];
		
		[_grossLocationPopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %@", i, [NSString pinGrossLocation:i]]];
		[_grossLocationPopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0xF; i++)
	{
		if (i >= _geometricLocationPopUpButton.itemArray.count)
			[_geometricLocationPopUpButton addItemWithTitle:@""];
		
		[_geometricLocationPopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %@", i, [NSString pinLocation:grossLocation geometricLocation:i]]];
		[_geometricLocationPopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0xF; i++)
	{
		if (i >= _devicePopUpButton.itemArray.count)
			[_devicePopUpButton addItemWithTitle:@""];
		
		[_devicePopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %@", i, [NSString pinDefaultDevice:i]]];
		[_devicePopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0xF; i++)
	{
		if (i >= _connectorPopUpButton.itemArray.count)
			[_connectorPopUpButton addItemWithTitle:@""];
		
		[_connectorPopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %@", i, [NSString pinConnector:i]]];
		[_connectorPopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0xF; i++)
	{
		if (i >= _colorPopUpButton.itemArray.count)
			[_colorPopUpButton addItemWithTitle:@""];
		
		[_colorPopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %@", i, [NSString pinColor:i]]];
		[_colorPopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0x3; i++)
	{
		if (i >= _miscPopUpButton.itemArray.count)
			[_miscPopUpButton addItemWithTitle:@""];
		
		[_miscPopUpButton.itemArray[i] setTitle:[NSString pinMisc:i]];
		[_miscPopUpButton.itemArray[i] setState:misc & (1 << i)];
		[_miscPopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0xF; i++)
	{
		if (i >= _groupPopUpButton.itemArray.count)
			[_groupPopUpButton addItemWithTitle:@""];
		
		[_groupPopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %d", i, i]];
		[_groupPopUpButton.itemArray[i] setTag:i];
	}
	
	for (int i = 0; i <= 0xF; i++)
	{
		if (i >= _positionPopUpButton.itemArray.count)
			[_positionPopUpButton addItemWithTitle:@""];
		
		[_positionPopUpButton.itemArray[i] setTitle:[NSString stringWithFormat:@"[%1X] %d", i, i]];
		[_positionPopUpButton.itemArray[i] setTag:i];
	}
}

- (void) refreshEapdButton:(uint8_t)eapd
{
	for (int i = 0; i <= 0x2; i++)
	{
		if (i >= _eapdPopUpButton.itemArray.count)
			[_eapdPopUpButton addItemWithTitle:@""];
		
		[_eapdPopUpButton.itemArray[i] setTitle:[NSString pinEAPD:i]];
		[_eapdPopUpButton.itemArray[i] setState:eapd & (1 << i)];
		[_eapdPopUpButton.itemArray[i] setTag:i];
	}
}

- (uint8_t)getCheckedValue:(NSPopUpButton *)popUpButton
{
	uint8_t value = 0;
	
	for (NSMenuItem *menuItem in popUpButton.itemArray)
		value |= (menuItem.state ? 1 << menuItem.tag : 0);
	
	return value;
}

- (void) parseIORegConfigData:(NSData *)configData
{
	if ([configData length] & 3)
		return;
	
	uint8_t *configDataBytes = (uint8_t *)[configData bytes];
	
	for (int i = 0; i < [configData length] / 4; i++)
	{
		uint32_t pinDefault = *((uint32_t *)&configDataBytes[i * 4]);
		AudioNode *audioNode = [[AudioNode alloc] initWithNid:0 pinDefault:pinDefault];
		
		[_nodeArray addObject:audioNode];
		
		[audioNode release];
	}
	
	_originalNodeArray = [[NSMutableArray alloc] initWithArray:_nodeArray copyItems:YES];
}

- (void) parseConfigData:(NSData *)configData
{
	_codecAddress = 0;
	_codecName = @"";
	_codecID = 0;
	_layoutID = 0;
	
	if ([configData length] & 3)
		return;
	
	uint8_t *configDataBytes = (uint8_t *)[configData bytes];
	
	for (int i = 0; i < [configData length] / 4; i++)
	{
		uint32_t verb = getReverseBytes(*((uint32_t *)(&configDataBytes[i * 4])));
		_codecAddress = (verb >> 28) & 0xF;
		uint8_t nid = (verb >> 20) & 0xFF;
		uint32_t command = (verb >> 8) & 0xFFF;
		uint8_t data = verb & 0xFF;
		
		AudioNode *audioNode = nil;
		
		for (AudioNode *findAudioNode in _nodeArray)
		{
			if ([findAudioNode nid] == nid)
				audioNode = findAudioNode;
		}
		
		if (!audioNode)
		{
			audioNode = [[AudioNode alloc] initWithNid:nid];
			[_nodeArray addObject:audioNode];
			[audioNode release];
		}
		
		if (command == 0x70C)
			[audioNode setEapd:data];
		else if ((command >> 4) == 0x71)
			[audioNode updatePinCommand:command data:data];
	}
	
	_originalNodeArray = [[NSMutableArray alloc] initWithArray:_nodeArray copyItems:YES];
}

- (NSString *)getConfigData
{
	if ([_nodeArray count] == 0)
		return nil;
	
	[[self configDataTextField] setStringValue:@""];
	
	NSMutableString *outputString = [NSMutableString string];
	
	if ([[self quotesButton] state])
		[outputString appendString:@"<"];
	
	for (int i = 0; i < [_nodeArray count]; i++)
	{
		if (i > 0)
			[outputString appendString:@" "];
		
		AudioNode *audioNode = [_nodeArray objectAtIndex:i];
		NSInteger address = [_codecAddressPopUpButton indexOfSelectedItem];
		[outputString appendString:[audioNode pinConfigString:(uint32_t)address]];
	}
	
	if ([[self quotesButton] state])
		[outputString appendString:@">"];
	
	return outputString;
}

- (NSString *)getWakeData
{
	if ([_nodeArray count] == 0)
		return nil;
	
	[[self configDataTextField] setStringValue:@""];
	
	NSMutableString *outputString = [NSMutableString string];
	
	if ([[self quotesButton] state])
		[outputString appendString:@"<"];
	
	for (int i = 0; i < [_nodeArray count]; i++)
	{
		if (i > 0)
			[outputString appendString:@" "];
		
		AudioNode *audioNode = [_nodeArray objectAtIndex:i];
		NSInteger address = [_codecAddressPopUpButton indexOfSelectedItem];
		[outputString appendString:[audioNode wakeConfigString:(uint32_t)address]];
	}
	
	if ([[self quotesButton] state])
		[outputString appendString:@">"];
	
	return outputString;
}

- (IBAction)compileConfigList:(id)sender
{
	[[self configDataTextField] setStringValue:[self getConfigData]];
}

- (IBAction)addNode:(id)sender
{
	NSPanel *addNodePanel = _addNodePanel;
	NSButtonCell *addOkButtonCell = [_addOKButton cell];
	[addNodePanel setDefaultButtonCell:addOkButtonCell];
	[_addNodeTextField setStringValue:@"Add New Node"];
	[_addOKButton setTitle:@"Add"];
	[_addOKButton setAction:@selector(addNodeOK:)];
	[_nodeIDTextField setStringValue:@""];
	[_nodeIDTextField setEditable:1];
	[_nodeIDTextField setSelectable:1];
	[_pinDefaultTextField setStringValue:@"00000000"];
	[self refreshEapdButton:0];
	[self editPanelSetPin:0];
	
	[NSApp beginSheet:_addNodePanel modalForWindow:[self mainWindow] modalDelegate:0 didEndSelector:0 contextInfo:0];
}

-(void) addNodeOK:(id) sender
{
	NSString *addNodeId = [_nodeIDTextField stringValue];
	
	if ([addNodeId isEqualToString:@""])
		return;
	
	[NSApp endSheet:_addNodePanel];
	[_addNodePanel orderOut:sender];
	short nid = [_nodeIDTextField intValue];
	AudioNode *audioNode = [[AudioNode alloc] initWithNid:nid];
	uint32_t pinDefault = getHexInt([_pinDefaultTextField stringValue]);
	[audioNode updatePinDefault:pinDefault];
	[audioNode setEapd:[self getCheckedValue:_eapdPopUpButton]];
	[_nodeArray addObject:audioNode];
	[audioNode release];
	[self updateView];
}

- (IBAction)editNodeCancel:(id)sender
{
	[NSApp endSheet:_addNodePanel];
	[_addNodePanel orderOut:sender];
}

- (IBAction)editNodeOK:(id)sender
{
	[NSApp endSheet:_addNodePanel];
	[_addNodePanel orderOut:sender];
	 
	if ([_pinConfigOutlineView selectedRow] != -1)
	{
		NSInteger selectedRow = [_pinConfigOutlineView selectedRow];
		AudioNode *audioNode = [_nodeArray objectAtIndex:selectedRow];

		if (audioNode)
		{
			uint32_t pinDefault = getHexInt([_pinDefaultTextField stringValue]);
			[audioNode updatePinDefault:pinDefault];
			[audioNode setEapd:[self getCheckedValue:_eapdPopUpButton]];
			[_pinConfigOutlineView reloadItem:audioNode];
		}
	}
}

- (IBAction)editNodePinStringAction:(id)sender
{
	uint32_t pinDefault = getHexInt([sender stringValue]);
	[self editPanelSetPin:pinDefault];
}

- (IBAction)editNodeComboAction:(id)sender
{
	NSPopUpButton *popUpButton = (NSPopUpButton *)sender;
	
	if (popUpButton == _miscPopUpButton)
		[_miscPopUpButton.selectedItem setState:!_miscPopUpButton.selectedItem.state];
	
	if (popUpButton == _eapdPopUpButton)
		[_eapdPopUpButton.selectedItem setState:!_eapdPopUpButton.selectedItem.state];
	
	[_pinDefaultTextField setStringValue:[NSString stringWithFormat:@"%08X", [self getPinDefault]]];
	
	uint8_t grossLocation = [_grossLocationPopUpButton.selectedItem tag];
	uint8_t geometricLocation = [_geometricLocationPopUpButton.selectedItem tag];
	uint8_t location = (grossLocation << 4) | geometricLocation;
	uint8_t misc = [self getCheckedValue:_miscPopUpButton];
	uint8_t eapd = [self getCheckedValue:_eapdPopUpButton];

	[self refreshPopupButtons:location misc:misc];
	[self refreshEapdButton:eapd];
}

- (IBAction)editNodeAction:(id)sender
{
	switch([[self editNodeSegmentedControl] selectedSegment])
	{
		case 0: // Add
			[self addNode:sender];
			break;
		case 1: // Edit
			[self editNode:sender];
			break;
		case 2: // Remove
		{
			NSInteger selectedRow = [_pinConfigOutlineView selectedRow];
			
			if (selectedRow == -1)
				return;
			
			[_nodeArray removeObjectAtIndex:selectedRow];
			[self updateView];
			break;
		}
		case 3: // Clear All
			[_nodeArray removeAllObjects];
			
			[self update];
			break;
		case 4: // Reload
			_nodeArray = [[NSMutableArray alloc] initWithArray:_originalNodeArray copyItems:YES];
			
			[self update];
			break;
	}
}

- (void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors;
{
	[_nodeArray sortUsingDescriptors:[_pinConfigOutlineView sortDescriptors]];
	[self updateView];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (outlineView == _pinConfigOutlineView)
	{
		return (item ? 0 : [_nodeArray count]);
	}
	else if (outlineView == [self importPinOutlineView])
	{
		return (item ? 0 : [_hdaConfigDefaultArray count]);
	}
	else if (outlineView == [self importIORegOutlineView])
	{
		return (item ? 0 : [_audioDeviceArray count]);
	}
	
	return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return 0;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
{
	if (outlineView == _pinConfigOutlineView)
	{
		NSString *nid = [tableColumn identifier];
		
		if ([nid intValue] == 1)
		{
			if (cell)
			{
				if (item)
					[cell setItem:item isSelected:NO];
			}
		}
		else
		{
			AudioNode *audioNode = item;
			[cell setFont:[NSFont systemFontOfSize:12]];
			
			switch ([[tableColumn identifier] intValue])
			{
				case 2:
					[cell setStringValue:audioNode.nodeString];
					[cell setFont:[NSFont boldSystemFontOfSize:12]];
					break;
				case 3:
					[cell setStringValue:audioNode.pinDefaultString];
					break;
				case 4:
					[cell setStringValue:audioNode.directionString];
					break;
				case 5:
					[cell setStringValue:[NSString pinDefaultDevice:audioNode.device]];
					break;
				case 6:
					[cell setStringValue:[NSString pinConnector:audioNode.connector]];
					break;
				case 7:
					[cell setStringValue:[NSString pinPort:audioNode.port]];
					break;
				case 8:
					[cell setStringValue:[NSString pinGrossLocation:audioNode.grossLocation]];
					break;
				case 9:
					[cell setStringValue:[NSString pinLocation:audioNode.grossLocation geometricLocation:audioNode.geometricLocation]];
					break;
				case 10:
					[cell setStringValue:[NSString pinColor:[audioNode color]]];
					break;
				case 11:
					[cell setIntValue:audioNode.group];
					break;
				case 12:
					[cell setIntValue:[audioNode index]];
					break;
				case 13:
					[cell setStringValue:audioNode.eapd & HDA_EAPD_BTL_ENABLE_EAPD ? [NSString stringWithFormat:@"0x%1X", audioNode.eapd] : @"-"];
					break;
				default:
					return;
			}
		}
	}
	else if (outlineView == [self importPinOutlineView])
	{
		NSDictionary *hdaConfigDictionary = item;
		
		switch ([[tableColumn identifier] intValue])
		{
			case 0:
				[cell setIntValue:(int)[_hdaConfigDefaultArray indexOfObject:hdaConfigDictionary]];
				break;
			case 1:
				[cell setStringValue:[NSString stringWithFormat:@"0x%08X", [[hdaConfigDictionary objectForKey:@"CodecID"] intValue]]];
				break;
			case 2:
				[cell setIntValue:[[hdaConfigDictionary objectForKey:@"LayoutID"] intValue]];
				break;
			case 3:
			{
				uint32_t codecID = [[hdaConfigDictionary objectForKey:@"CodecID"] intValue];
				NSString *codecName;
				[self getAudioCodecName:codecID revisionID:0 name:&codecName];
				[cell setStringValue:codecName];
				break;
			}
			case 4:
			{
				NSString *codecName = [hdaConfigDictionary objectForKey:@"Codec"];
				[cell setStringValue:codecName != nil ? codecName : @""];
				break;
			}
		}
	}
	else if (outlineView == [self importIORegOutlineView])
	{
		AudioDevice *audioDevice = item;
		
		switch ([[tableColumn identifier] intValue])
		{
			case 0:
				[cell setStringValue:[NSString stringWithFormat:@"0x%08X", audioDevice.deviceID]];
				break;
			case 1:
				[cell setStringValue:[NSString stringWithFormat:@"0x%08X", audioDevice.revisionID]];
				break;
			case 2:
				if ([audioDevice.deviceClass isEqualToString:@"AppleHDADriver"])
					[cell setIntValue:audioDevice.alcLayoutID];
				else
					[cell setStringValue:@"-"];
				break;
			case 3:
				[cell setStringValue:[NSString stringWithFormat:@"0x%08X", audioDevice.subDeviceID]];
				break;
			case 4:
				[cell setStringValue:[NSString stringWithFormat:@"0x%X", audioDevice.codecAddress]];
				break;
			case 5:
				if (audioDevice.codecID != 0)
					[cell setStringValue:[NSString stringWithFormat:@"0x%08X", audioDevice.codecID]];
				else
					[cell setStringValue:@"-"];
				break;
			case 6:
				[cell setStringValue:[NSString stringWithFormat:@"0x%04X", audioDevice.codecRevisionID & 0xFFFF]];
				break;
			case 7:
				[cell setStringValue:audioDevice.codecName];
				break;
		}
	}
}

- (void)outlineViewSelectionIsChanging:(NSNotification *)notification
{
	[[self editNodeSegmentedControl] setEnabled:[_pinConfigOutlineView selectedRow] + 1 != 0 forSegment:1];
	[[self editNodeSegmentedControl] setEnabled:[_pinConfigOutlineView selectedRow] + 1 != 0 forSegment:2];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (outlineView == _pinConfigOutlineView)
		return (item ? nil : [_nodeArray objectAtIndex:index]);
	else if (outlineView == [self importPinOutlineView])
		return (item ? nil : [_hdaConfigDefaultArray objectAtIndex:index]);
	else if (outlineView == [self importIORegOutlineView])
		return (item ? nil : [_audioDeviceArray objectAtIndex:index]);
	
	return nil;
}

- (void) editNode:(id)sender
{
	if ([_pinConfigOutlineView selectedRow] == -1)
		return;
	
	AudioNode *audioNode = [_nodeArray objectAtIndex:[_pinConfigOutlineView selectedRow]];
	
	if (!audioNode)
		return;

	[_addNodePanel setDefaultButtonCell:[_addOKButton cell]];
	[_addNodeTextField setStringValue:[NSString stringWithFormat:@"Edit Node %@", audioNode.nodeString]];
	[_addOKButton setTitle:@"Save"];
	[_addOKButton setAction:@selector(editNodeOK:)];
	[_nodeIDTextField setIntValue:[audioNode nid]];
	[_nodeIDTextField setEditable:0];
	[_nodeIDTextField setSelectable:0];
	[_pinDefaultTextField setStringValue:audioNode.pinDefaultString];
	[self refreshEapdButton:audioNode.eapd];
	[self editPanelSetPin:audioNode.pinDefault];
	
	[NSApp beginSheet:_addNodePanel modalForWindow:[self mainWindow] modalDelegate:0 didEndSelector:0 contextInfo:0];
}

- (void) compilePinDefaults
{
	if ([_nodeArray count] == 0)
		return;

	[[self configDataTextField] setStringValue:@""];

	NSMutableString *dataString = [NSMutableString string];
	
	for (int i = 0; i < [_nodeArray count]; ++i)
	{
		if (i > 0)
			[dataString appendString:@", "];
		
		AudioNode *audioNode = [_nodeArray objectAtIndex:i];
		[dataString appendFormat:@"%02Xh:%@", [audioNode nid], audioNode.pinDefaultString];
	}
	
	[[self configDataTextField] setStringValue:dataString];
}

-(void) editPanelSetPin:(uint32_t)pinDefault
{
	uint8_t index = pinDefault & 0xF;
	uint8_t group = (pinDefault >> 4) & 0xF;
	uint8_t misc = (pinDefault >> 8) & 0xF;
	uint8_t color = (pinDefault >> 12) & 0xF;
	uint8_t connector = (pinDefault >> 16) & 0xF;
	uint8_t device = (pinDefault >> 20) & 0xF;
	uint8_t location = (pinDefault>> 24) & 0x3F;
	uint8_t port = (pinDefault >> 30) & 0x3;
	uint8_t grossLocation = (location >> 4) & 0x3;
	uint8_t geometricLocation = (location & 0xF);
	
	[self refreshPopupButtons:location misc:misc];
	
	[_portPopUpButton selectItemWithTag:port];
	[_grossLocationPopUpButton selectItemWithTag:grossLocation];
	[_geometricLocationPopUpButton selectItemWithTag:geometricLocation];
	[_devicePopUpButton selectItemWithTag:device];
	[_connectorPopUpButton selectItemWithTag:connector];
	[_colorPopUpButton selectItemWithTag:color];
	//[_miscPopUpButton selectItemWithTag:misc];
	[_groupPopUpButton selectItemWithTag:group];
	[_positionPopUpButton selectItemWithTag:index];
}

- (uint32_t)getPinDefault
{
	uint8_t grossLocation = [_grossLocationPopUpButton.selectedItem tag];
	uint8_t geometricLocation = [_geometricLocationPopUpButton.selectedItem tag];
	
	uint8_t port = [_portPopUpButton.selectedItem tag];
	uint8_t location = (grossLocation << 4) | geometricLocation;
	uint8_t device = [_devicePopUpButton.selectedItem tag];
	uint8_t connector = [_connectorPopUpButton.selectedItem tag];
	uint8_t color = [_colorPopUpButton.selectedItem tag];
	uint8_t misc = [self getCheckedValue:_miscPopUpButton];
	uint8_t group = [_groupPopUpButton.selectedItem tag];
	uint8_t index = [_positionPopUpButton.selectedItem tag];
	
	return ((port << 30) | (location << 24) | (device << 20) | (connector << 16) | (color << 12) | (misc << 8) | (group << 4) | index);
}

- (void)parseCodec:(HdaCodec *)hdaCodec
{
	_nodeArray = [[NSMutableArray alloc] init];
	
	for (HdaWidget *hdaWidget in hdaCodec.widgets)
	{
		if (hdaWidget.type != kHdaWidgetTypePinComplex)
			continue;
		
		AudioNode *audioNode = [[AudioNode alloc] initWithNid:hdaWidget.nodeID pinDefault:hdaWidget.defaultConfiguration];
		
		[audioNode setName:hdaWidget.name];
		//[audioNode setPinCaps:hdaWidget.pinCapabilities];
		
		if ([hdaWidget hasEAPD])
			[audioNode setEapd:hdaWidget.defaultEapd];
		
		[_nodeArray addObject:audioNode];
		
		[audioNode release];
	}
	
	_originalNodeArray = [[NSMutableArray alloc] initWithArray:_nodeArray copyItems:YES];
	
	_codecName = hdaCodec.name;
	_codecAddress = hdaCodec.address;
	_codecID = hdaCodec.vendorID;
	_layoutID = 0;
}

- (void)parseConfigString:(NSString *)configString
{
	[self clear];
	
	if ([HdaCodec parseHdaCodecString:configString hdaCodec:&_hdaCodec])
		[self parseCodec:_hdaCodec];
	else
		[self parseConfigData:stringToData(configString)];
	
	[self update];
}

- (BOOL)getIndexOfAudioNode:(NSArray *)hdaConfigDefaultArray index:(int *)index
{
	*index = -1;
	
	for (int i = 0; i < [hdaConfigDefaultArray count]; i++)
	{
		NSDictionary *hdaConfigDictionary = [hdaConfigDefaultArray objectAtIndex:i];
		NSNumber *codecID = [hdaConfigDictionary objectForKey:@"CodecID"];
		NSNumber *layoutID = [hdaConfigDictionary objectForKey:@"LayoutID"];
		
		if ([codecID intValue] == _codecID && [layoutID intValue] == _layoutID)
		{
			*index = i;
			
			break;
		}
	}
	
	return (*index != -1);
}

- (bool)getAudioVendorName:(uint32_t)codecID vendorName:(NSString **)vendorName
{
	*vendorName = @"Unknown";
	
	for (NSString *key in [_vendorsDictionary allKeys])
	{
		NSNumber *vid = [_vendorsDictionary objectForKey:key];
		
		if ([vid intValue]  == (codecID >> 16))
		{
			*vendorName = key;
			
			return true;
		}
	}
	
	return false;
}

- (bool)getAudioCodecName:(uint32_t)deviceID revisionID:(uint16_t)revisionID name:(NSString **)name
{
	*name = @"???";
	
	if (deviceID == 0)
		return false;
	
	for (NSDictionary *codecDictionary in _codecsArray)
	{
		NSNumber *findDeviceID = [codecDictionary objectForKey:@"DeviceID"];
		NSNumber *findRevisionID = [codecDictionary objectForKey:@"RevisionID"];
		NSString *findName = [codecDictionary objectForKey:@"Name"];
		
		if (deviceID == [findDeviceID unsignedIntValue] && revisionID == [findRevisionID unsignedIntValue])
		{
			*name = findName;
			
			return true;
		}
	}
	
	for (NSDictionary *codecDictionary in _codecsArray)
	{
		NSNumber *findDeviceID = [codecDictionary objectForKey:@"DeviceID"];
		NSString *findName = [codecDictionary objectForKey:@"Name"];
		
		if (deviceID == [findDeviceID unsignedIntValue])
		{
			*name = findName;
			
			return true;
		}
	}
	
	return false;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	[self clear];
	
	_fileName = [filename retain];
	NSData *configData = [NSData dataWithContentsOfFile:filename];
	
	if ([[filename lastPathComponent] caseInsensitiveCompare:@"PinConfigs.kext"] == NSOrderedSame)
	{
		_pinConfigsFileName = [_fileName retain];
		
		[self importPinConfigsKext:nil];
		
		return YES;
	}
	
	if ([HdaCodec parseHdaCodecData:(uint8_t *)[configData bytes] length:(uint32_t)[configData length] hdaCodec:&_hdaCodec])
	{
		[self parseCodec:_hdaCodec];
		[self update];
		
		return YES;
	}
	
	NSString *configString = [[NSString alloc] initWithData:configData encoding:NSUTF8StringEncoding];
	[self parseConfigString:configString];
	[configString release];
	
	return YES;
}

- (IBAction)openDocument:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:YES];
	
	[openPanel beginSheetModalForWindow:[self mainWindow] completionHandler:^(NSModalResponse returnCode)
	 {
		 [NSApp stopModalWithCode:returnCode];
	 }];
	
	if ([NSApp runModalForWindow:[self mainWindow]] != NSOKButton)
		return;
	
	for (NSURL *url in [openPanel URLs])
	{
		[self application:NSApp openFile:[url path]];
		
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];
		
		break;
	}
}

- (IBAction)exportVerbsTxt:(id)sender
{
	NSMutableString *verbsString = [NSMutableString string];
	NSString *title = (_fileName != nil ? [NSString stringWithFormat:@"Verbs from File: \"%@\"\n", [_fileName lastPathComponent]] : @"Verbs from ConfigData\n");
	
	[verbsString appendString:@"\n"];
	[verbsString appendString:title];
	[verbsString appendString:@"\n"];
	[verbsString appendString:[NSString stringWithFormat:@"Codec: %@   Address: %d   DevID: %d (0x%08X)\n", _codecName != nil ? _codecName : @"???", _codecAddress, _codecID, _codecID]];
	[verbsString appendString:@"\n"];
	[verbsString appendString:@"NID       PinDefault     Device             Connector           Port            Location                    Color     G  P  EAPD  Original Verbs\n"];
	[verbsString appendString:@"------------------------------------------------------------------------------------------------------------------------------------------------\n"];

	for (AudioNode *audioNode in _originalNodeArray)
	{
		[verbsString appendString:[NSString stringWithFormat:@"%-9s ", [audioNode.nodeString UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-10s ", [audioNode.pinDefaultString UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-3s ", [[audioNode directionString] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-18s ", [[NSString pinDefaultDevice:audioNode.device] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-19s ", [[NSString pinConnector:audioNode.connector] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-15s ", [[NSString pinPort:audioNode.port] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-8s ", [[NSString pinGrossLocation:audioNode.grossLocation] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-18s ", [[NSString pinLocation:audioNode.grossLocation geometricLocation:audioNode.geometricLocation] UTF8String]]];
		
		[verbsString appendString:[NSString stringWithFormat:@"%-9s ", [[NSString pinColor:[audioNode color]] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-2d ", audioNode.group]];
		[verbsString appendString:[NSString stringWithFormat:@"%-2d ", [audioNode index]]];
		[verbsString appendString:audioNode.eapd & HDA_EAPD_BTL_ENABLE_EAPD ? [NSString stringWithFormat:@"0x%1X   ", audioNode.eapd] : @"-     "];
		[verbsString appendString:[NSString stringWithFormat:@"%@", [audioNode pinConfigString:_codecAddress]]];
		[verbsString appendString:@"\n"];
	}
	
	[verbsString appendString:@"------------------------------------------------------------------------------------------------------------------------------------------------\n"];
	[verbsString appendString:@"\n\n"];
	[verbsString appendString:@"NID       PinDefault     Device             Connector           Port            Location                    Color     G  P  EAPD  Modified Verbs\n"];
	[verbsString appendString:@"------------------------------------------------------------------------------------------------------------------------------------------------\n"];

	for (AudioNode *audioNode in _nodeArray)
	{
		[verbsString appendString:[NSString stringWithFormat:@"%-9s ", [audioNode.nodeString UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-10s ", [audioNode.pinDefaultString UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-3s ", [[audioNode directionString] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-18s ", [[NSString pinDefaultDevice:audioNode.device] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-19s ", [[NSString pinConnector:audioNode.connector] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-15s ", [[NSString pinPort:audioNode.port] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-8s ", [[NSString pinGrossLocation:audioNode.grossLocation] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-18s ", [[NSString pinLocation:audioNode.grossLocation geometricLocation:audioNode.geometricLocation] UTF8String]]];
		
		[verbsString appendString:[NSString stringWithFormat:@"%-9s ", [[NSString pinColor:[audioNode color]] UTF8String]]];
		[verbsString appendString:[NSString stringWithFormat:@"%-2d ", audioNode.group]];
		[verbsString appendString:[NSString stringWithFormat:@"%-2d ", [audioNode index]]];
		[verbsString appendString:audioNode.eapd & HDA_EAPD_BTL_ENABLE_EAPD ? [NSString stringWithFormat:@"0x%1X   ", audioNode.eapd] : @"-     "];
		[verbsString appendString:[NSString stringWithFormat:@"%@", [audioNode pinConfigString:[_codecAddressPopUpButton indexOfSelectedItem]]]];
		[verbsString appendString:@"\n"];
	}
	
	[verbsString appendString:@"------------------------------------------------------------------------------------------------------------------------------------------------\n"];
	[verbsString appendString:@"\n"];
	
	NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *verbsPath = [desktopPath stringByAppendingPathComponent:@"verbs.txt"];
	
	NSError *error;
	
	if ([verbsString writeToFile:verbsPath atomically:YES encoding:NSUTF8StringEncoding error:&error])
	{
		NSArray *fileURLs = [NSArray arrayWithObjects:[NSURL fileURLWithPath:verbsPath], nil];
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
	}
	else
		NSLog(@"Error: %@", error);
}

- (IBAction)exportHdaCodecTxt:(id)sender
{
	if (_hdaCodec == nil)
		return;
	
	NSArray *fileTypes = [NSArray arrayWithObjects: @"txt", nil];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setNameFieldStringValue:[NSString stringWithFormat:@"HdaCodec (%@).txt", _hdaCodec.name]];
	[savePanel setAllowedFileTypes:fileTypes];
	
	[savePanel beginSheetModalForWindow:[self mainWindow] completionHandler:^(NSModalResponse returnCode)
	 {
		 [NSApp stopModalWithCode:returnCode];
	 }];
	
	if ([NSApp runModalForWindow:[self mainWindow]] != NSOKButton)
		return;
	
	NSString *hdaCodecTxt = [_hdaCodec codecString];
	
	[hdaCodecTxt writeToFile:[[savePanel URL] path] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (IBAction)exportPlatformsXml:(id)sender
{
	[HdaCodec createPlatformsXml:_hdaCodec];
}

- (IBAction)importPinConfigsKext:(id)sender
{
	[_hdaConfigDefaultArray release];
	
	if (_pinConfigsFileName == nil)
	{
		NSArray *fileTypes = [NSArray arrayWithObjects: @"kext", nil];
		
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setDelegate:self];
		[openPanel setCanChooseFiles:YES];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setAllowedFileTypes:fileTypes];
		[openPanel setPrompt:@"Select"];
		
		[openPanel beginSheetModalForWindow:[self mainWindow] completionHandler:^(NSModalResponse returnCode)
		 {
			 [NSApp stopModalWithCode:returnCode];
		 }];
		
		if ([NSApp runModalForWindow:[self mainWindow]] != NSOKButton)
			return;
		
		_pinConfigsFileName = [[[openPanel URL] path] retain];
	}
	
	NSString *infoPlistPath = [NSString stringWithFormat:@"%@/Contents/Info.plist", _pinConfigsFileName];
	NSDictionary *infoPlistDictionary = infoPlistDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
	NSDictionary *ioKitPersonalitiesDictionary = [infoPlistDictionary objectForKey:@"IOKitPersonalities"];
	NSDictionary *hdaHardwareConfigResourceDictionary = [ioKitPersonalitiesDictionary objectForKey:@"HDA Hardware Config Resource"];
	_hdaConfigDefaultArray = [[hdaHardwareConfigResourceDictionary objectForKey:@"HDAConfigDefault"] retain];
	
	[[self importPinOutlineView] reloadData];
	
	if ([[self importPinOutlineView] selectedRow] == -1)
	{
		int configEntryIndex = -1;
		
		[self getIndexOfAudioNode:_hdaConfigDefaultArray index:&configEntryIndex];
		
		[[self importPinOutlineView] selectRowIndexes:[NSIndexSet indexSetWithIndex:configEntryIndex] byExtendingSelection:NO];
		[[self importPinOutlineView] scrollRowToVisible:configEntryIndex];
	}
	
	[NSApp beginSheet:[self importPinConfigPanel] modalForWindow:[self mainWindow] modalDelegate:0 didEndSelector:0 contextInfo:0];
}

- (IBAction)exportPinConfigsKext:(id)sender
{
	NSArray *fileTypes = [NSArray arrayWithObjects: @"kext", nil];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setDelegate:self];
	[savePanel setMessage:@"Please select the existing PinConfigs.kext to overwrite."];
	[savePanel setNameFieldStringValue:@"PinConfigs.kext"];
	[savePanel setAllowedFileTypes:fileTypes];
	
	[savePanel beginSheetModalForWindow:[self mainWindow] completionHandler:^(NSModalResponse returnCode)
	 {
		 [NSApp stopModalWithCode:returnCode];
	 }];
	
	if ([NSApp runModalForWindow:[self mainWindow]] != NSOKButton)
		return;
	
	NSString *infoPlistPath = [NSString stringWithFormat:@"%@/Contents/Info.plist", [[savePanel URL] path]];
	NSDictionary *infoPlistDictionary = infoPlistDictionary = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];
	NSDictionary *ioKitPersonalitiesDictionary = [infoPlistDictionary objectForKey:@"IOKitPersonalities"];
	NSDictionary *hdaHardwareConfigResourceDictionary = [ioKitPersonalitiesDictionary objectForKey:@"HDA Hardware Config Resource"];
	NSArray *hdaConfigDefaultArray = [hdaHardwareConfigResourceDictionary objectForKey:@"HDAConfigDefault"];
	NSMutableArray *hdaConfigDefaultMutableArray = [NSMutableArray arrayWithArray:hdaConfigDefaultArray];
	int configEntryIndex = -1;
	
	[self getIndexOfAudioNode:hdaConfigDefaultArray index:&configEntryIndex];

	if (configEntryIndex != -1)
	{
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert setMessageText:@"Overwrite Existing Entry?"];
		[alert setInformativeText:@"An entry for your Codec was found in PinConfigs.kext"];
		[alert addButtonWithTitle:@"Cancel"];
		[alert addButtonWithTitle:@"Overwrite"];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:[self mainWindow] completionHandler:^(NSModalResponse returnCode)
		 {
			 [NSApp stopModalWithCode:returnCode];
		 }];
		
		if ([NSApp runModalForWindow:[self mainWindow]] == NSAlertFirstButtonReturn)
			return;
	}
	
	NSMutableDictionary *hdaConfigDictionary = [NSMutableDictionary dictionary];
	
	[hdaConfigDictionary setValue:getNSDataUInt32(3) forKey:@"AFGLowPowerState"];
	[hdaConfigDictionary setValue:[NSString stringWithFormat:@"%@ by %@", _codecName, NSUserName()] forKey:@"Codec"];
	[hdaConfigDictionary setValue:[NSNumber numberWithInt:_codecID] forKey:@"CodecID"];
	[hdaConfigDictionary setValue:stringToData([self getConfigData]) forKey:@"ConfigData"];
	[hdaConfigDictionary setValue:[NSNumber numberWithInt:1] forKey:@"FuncGroup"];
	[hdaConfigDictionary setValue:[NSNumber numberWithInt:_layoutID] forKey:@"LayoutID"];
	[hdaConfigDictionary setValue:stringToData([self getWakeData]) forKey:@"WakeConfigData"];
	[hdaConfigDictionary setValue:[NSNumber numberWithBool:YES] forKey:@"WakeVerbReinit"];
	
	if (configEntryIndex != -1)
		[hdaConfigDefaultMutableArray setObject:hdaConfigDictionary atIndexedSubscript:configEntryIndex];
	else
		[hdaConfigDefaultMutableArray addObject:hdaConfigDictionary];
	
	[hdaHardwareConfigResourceDictionary setValue:hdaConfigDefaultMutableArray forKey:@"HDAConfigDefault"];
	
	[infoPlistDictionary writeToFile:infoPlistPath atomically:YES];
}

- (IBAction)importIORegistry:(id)sender
{
	[[self importIORegOutlineView] reloadData];
	
	int selectedAudioDevice = -1;
	
	for (int i = 0; i < [_audioDeviceArray count]; i++)
	{
		AudioDevice *audioDevice = _audioDeviceArray[i];
		
		if ([audioDevice.deviceClass isEqualToString:@"AppleHDADriver"])
		{
			selectedAudioDevice = i;
			break;
		}
	}
	
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:selectedAudioDevice];
	[[self importIORegOutlineView] selectRowIndexes:indexSet byExtendingSelection:NO];
	
	[NSApp beginSheet:[self importIORegPanel] modalForWindow:[self mainWindow] modalDelegate:0 didEndSelector:0 contextInfo:0];
}

- (IBAction)importClipboard:(id)sender
{
	NSPasteboard *pasteboard  = [NSPasteboard generalPasteboard];
	NSString *string = [pasteboard stringForType:NSPasteboardTypeString];
	
	[self parseConfigString:string];
}

- (IBAction)print:(id)sender
{
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:self.pinConfigOutlineView];
	NSPrintInfo *printInfo = printOperation.printInfo;
	[printInfo.dictionary setObject:@YES forKey:NSPrintHeaderAndFooter];
	[printOperation runOperation];
}

- (void)clear
{
	[_nodeArray removeAllObjects];
	[_pinConfigOutlineView reloadData];
	
	if (_hdaCodec != nil)
	{
		[_hdaCodec release];
		_hdaCodec = nil;
	}
	
	_codecName = nil;
	_codecAddress = 0;
	_codecID = 0;
	_layoutID = 0;
	
	[[self layoutIDTextField] setIntValue:_layoutID];
}

- (void)update
{
	if (_sortNodes)
		[_nodeArray sortUsingSelector:@selector(compareDevice:)];
	
	[self updateView];
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
	NSNumber *isDirectory;
	
	BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
	
	if (success && [isDirectory boolValue])
		return true;
	
	return ([[url lastPathComponent] caseInsensitiveCompare:@"PinConfigs.kext"] == NSOrderedSame);
}

- (IBAction)importPinSelect:(id)sender
{
	[self clear];
	
	[NSApp endSheet:[self importPinConfigPanel]];
	[[self importPinConfigPanel] orderOut:sender];
	
	if ([[self importPinOutlineView] selectedRow] != -1)
	{
		NSInteger selectedRow = [[self importPinOutlineView] selectedRow];
		NSDictionary *hdaConfigDictionary = [_hdaConfigDefaultArray objectAtIndex:selectedRow];
		
		if (hdaConfigDictionary)
		{
			_codecName = [[hdaConfigDictionary objectForKey:@"Codec"] retain];
			_codecID = [[hdaConfigDictionary objectForKey:@"CodecID"] intValue];
			NSData *configData = [hdaConfigDictionary objectForKey:@"ConfigData"];
			_layoutID = [[hdaConfigDictionary objectForKey:@"LayoutID"] intValue];
			//NSData *wakeConfigData = [hdaConfigDictionary objectForKey:@"WakeConfigData"];
			//NSMutableData *allConfigData = [NSMutableData dataWithData:configData];
			//[allConfigData appendData:wakeConfigData];
			
			if ([configData length] > 0)
			{
				const char *configDataBytes = (const char *)[configData bytes];
				_codecAddress = HINIBBLE(configDataBytes[0]);
			}
			
			[[self layoutIDTextField] setIntValue:_layoutID];
			
			[self parseConfigData:configData];
		}
	}
	
	[self update];
}

- (IBAction)importPinCancel:(id)sender
{
	[NSApp endSheet:[self importPinConfigPanel]];
	[[self importPinConfigPanel] orderOut:sender];
}

- (IBAction)importIORegSelect:(id)sender
{
	[self clear];
	
	[NSApp endSheet:[self importIORegPanel]];
	[[self importIORegPanel] orderOut:sender];
	
	if ([[self importIORegOutlineView] selectedRow] != -1)
	{
		NSInteger selectedRow = [[self importIORegOutlineView] selectedRow];
		AudioDevice *audioDevice = [_audioDeviceArray objectAtIndex:selectedRow];
		
		if (audioDevice)
		{
			_codecName = audioDevice.codecName;
			_codecID = audioDevice.codecID;
			NSData *configData = audioDevice.pinConfigurations;
			_layoutID = audioDevice.alcLayoutID;
			//NSData *wakeConfigData = [hdaConfigDictionary objectForKey:@"WakeConfigData"];
			//NSMutableData *allConfigData = [NSMutableData dataWithData:configData];
			//[allConfigData appendData:wakeConfigData];
			
			/* if ([configData length] > 0)
			{
				const char *configDataBytes = (const char *)[configData bytes];
				_codecAddress = HINIBBLE(configDataBytes[0]);
			} */
			
			[[self layoutIDTextField] setIntValue:_layoutID];
			
			[self parseIORegConfigData:configData];
		}
	}
	
	[self update];
}

- (IBAction)importIORegCancel:(id)sender
{
	[NSApp endSheet:[self importIORegPanel]];
	[[self importIORegPanel] orderOut:sender];
}

- (IBAction)layoutIDAction:(id)sender
{
	_layoutID = [[[self layoutIDTextField] stringValue] intValue];
	
	[[self layoutIDTextField] setIntValue:_layoutID];
}

- (IBAction)removeDisabledAction:(id)sender
{
	for (int i = (int)[_nodeArray count] - 1; i >= 0; i--)
	{
		AudioNode *audioNode = [_nodeArray objectAtIndex:i];
		
		if (audioNode.port == 1 && audioNode.group == 0xF && audioNode.index == 0)
			[_nodeArray removeObjectAtIndex:i];
	}
	
	[self update];
}

- (IBAction)verbSanitizeAction:(id)sender
{
	if ([_nodeArray count] == 0)
		return;
	
	// Verb Sanitize Rules:
	// - Fix "Headphone Mic Boost Volume" (insanelyDeepak)
	// - Remove 0x411111F0 / 0x400000F0
	// - Remove CD at INT ATAPI
	// - 0x71C: Index should always be 0 (No need - Rodion2010)
	// - 0x71C: Group should be unique (No need - Rodion2010)
	// - 0x71D: Set all Misc to 0 (Jack Detect)
	// - 0x71F: Front Panel change Location from 2 to 1 (Cosmetic only - Rodion2010)
	// - 0x71E: Line Out must be set to Speaker for Headphone autodetect to work correctly (Rodion2010)
	// - 0x71E / 0x71F: Fi﻿rst Microphone Port set to Fixed / Location set to Internal, N/A and Connector set to Unknown (Enables DSP Noise Reduction - Rodion2010)
	// - 0x71E: Second Microphone Device set to Line In / Connector set to Unknown (Ext Mic doesn't work on Hackintoshes - Rodion2010)
	// - 0x71E: Remove if Device set to Digital Other Out / Port is not Internal (HDMI)
	
	if (_nodeOptions & kNodeFixHeadphone)
	{
		// Fix "Headphone Mic Boost Volume"
		for (AudioNode *audioNode in _nodeArray)
		{
			//		Node 0x19 [Pin Complex] wcaps 0x40048b: Stereo Amp-In
			//	Control: name="Headset Mic Boost Volume", index=0, device=0
			//		Node 0x1a [Pin Complex] wcaps 0x40048b: Stereo Amp-In
			//	Control: name="Headphone Mic Boost Volume", index=0, device=0
			
			/* if ([audioNode.name isEqualToString:@"Headset Mic Boost Volume"])
			{
				[audioNode setPort:kHdaConfigDefaultPortConnJack];
				[audioNode setDevice:kHdaConfigDefaultDeviceMicIn];
				[audioNode setConnector:kHdaConfigDefaultConnDigitalOther];
			} */
			
			if ([audioNode.name isEqualToString:@"Headphone Mic Boost Volume"])
			{
				[audioNode setPort:kHdaConfigDefaultPortConnJack];
				[audioNode setDevice:kHdaConfigDefaultDeviceLineIn];
				[audioNode setConnector:kHdaConfigDefaultConnCombo];
			}
		}
	}

	if (_nodeOptions & kNodeRemoveDisabled)
	{
		// Remove 0x411111F0 / 0x400000F0
		for (int i = (int)[_nodeArray count] - 1; i >= 0; i--)
		{
			AudioNode *audioNode = [_nodeArray objectAtIndex:i];
			
			if (audioNode.port == 1 && audioNode.group == 0xF && audioNode.index == 0)
				[_nodeArray removeObjectAtIndex:i];
		}
	}
	
	// Remove CD at INT ATAPI
	if (_nodeOptions & kNodeRemoveATAPI)
	{
		for (int i = (int)[_nodeArray count] - 1; i >= 0; i--)
		{
			AudioNode *audioNode = [_nodeArray objectAtIndex:i];
			
			if (//audioNode.device == kHdaConfigDefaultDeviceCD &&
				//audioNode.geometricLocation == kHdaConfigDefaultLocSpecSpecial9 &&
				//audioNode.grossLocation == kHdaConfigDefaultLocSurfATAPI &&
				audioNode.connector == kHdaConfigDefaultConnATAPI)
				[_nodeArray removeObjectAtIndex:i];
		}
	}
	
	// 0x71C: Index should always be 0
	if (_nodeOptions & kNodeIndexToZero)
	{
		for (AudioNode *audioNode in _nodeArray)
		{
			[audioNode setIndex:0x0];
		}
	}
	
	// 0x71C: Group should be unique (No need - Rodion2010)
	if (_nodeOptions & kNodeMakeGroupUnique)
	{
		NSMutableArray *usedGroupArray = [NSMutableArray array];
		NSMutableArray *unusedGroupArray = [NSMutableArray array];
		
		for (AudioNode *audioNode in _nodeArray)
		{
			if (audioNode.group == 0 || audioNode.group == 0xF)
				[audioNode setGroup:0x1];
			
			[usedGroupArray addObject:[NSNumber numberWithInt:audioNode.group]];
		}
		
		for (int i = 1; i <= 0xF; i++)
		{
			NSNumber *groupNumber = [NSNumber numberWithInt:i];
			
			if (![usedGroupArray containsObject:groupNumber])
				[unusedGroupArray addObject:groupNumber];
		}
		
		// Correcting duplicate Groups
		for (int i = 0; i < (int)[_nodeArray count]; i++)
		{
			AudioNode *audioNode = [_nodeArray objectAtIndex:i];
			NSNumber *groupNumber = [NSNumber numberWithInt:audioNode.group];
			NSUInteger groupIndex = [usedGroupArray indexOfObject:groupNumber];
			
			if (groupIndex == -1 || groupIndex == i)
				continue;
			
			if ([unusedGroupArray count] > 0)
			{
				NSNumber *newGroupNumber = [unusedGroupArray objectAtIndex:0];
				[audioNode setGroup:[newGroupNumber intValue]];
				[usedGroupArray replaceObjectAtIndex:i withObject:newGroupNumber];
				[unusedGroupArray removeObjectAtIndex:0];
			}
		}
	}
	
	// 0x71D: Set all Misc to 0 (Jack Detect)
	if (_nodeOptions & kNodeMiscToZero)
	{
		for (AudioNode *audioNode in _nodeArray)
		{
			[audioNode setMisc:0x0];
		}
	}
	
	// 0x71F: Front Panel change Location from 2 to 1 (Cosmetic only - Rodion2010)
	if (_nodeOptions & kNodeChangeLocation)
	{
		for (AudioNode *audioNode in _nodeArray)
		{
			if (audioNode.geometricLocation == kHdaConfigDefaultLocSpecFront)
				[audioNode setGeometricLocation:kHdaConfigDefaultLocSpecRear];
			
			if (audioNode.geometricLocation != kHdaConfigDefaultLocSpecRear)
				[audioNode setGeometricLocation:kHdaConfigDefaultLocSpecNA];
		}
	}
	
	// 0x71E: Line Out must be set to Speaker for Headphone autodetect to work correctly (Rodion2010)
	if (_nodeOptions & kNodeLineOutToSpeaker)
	{
		for (AudioNode *audioNode in _nodeArray)
		{
			if (audioNode.device == kHdaConfigDefaultDeviceLineOut)
				[audioNode setDevice:kHdaConfigDefaultDeviceSpeaker];
		}
	}
	
	// 0x71E / 0x71F: Fi﻿rst Microphone Port set to Fixed / Location set to Internal, N/A and Connector set to Unknown (Enables DSP Noise Reduction - Rodion2010)
	// 0x71E: Second Microphone Device set to Line In / Connector set to Unknown (Ext Mic doesn't work on Hackintoshes - Rodion2010)
	int micCount = 0;
	
	for (AudioNode *audioNode in _nodeArray)
	{
		if (audioNode.device == kHdaConfigDefaultDeviceMicIn)
		{
			if (_nodeOptions & kNodeEnableDSP)
			{
				if (micCount == 0)
				{
					[audioNode setPort:kHdaConfigDefaultPortConnFixedDevice];
					[audioNode setGrossLocation:kHdaConfigDefaultLocSurfInternal];
					[audioNode setConnector:kHdaConfigDefaultConnUnknown];
				}
			}
			
			if (_nodeOptions & kNodeDisableExtMic)
			{
				if (micCount >= 1)
				{
					[audioNode setDevice:kHdaConfigDefaultDeviceLineIn];
					[audioNode setConnector:kHdaConfigDefaultConnUnknown];
				}
			}
			
			micCount++;
		}
	}
	
	// 0x71E: Remove if Device set to Digital Other Out / Port is not Internal (HDMI)
	if (_nodeOptions & kNodeRemoveHDMI)
	{
		for (int i = (int)[_nodeArray count] - 1; i >= 0; i--)
		{
			AudioNode *audioNode = [_nodeArray objectAtIndex:i];
			
			if (audioNode.device == kHdaConfigDefaultDeviceOtherDigitalOut &&
				audioNode.geometricLocation == kHdaConfigDefaultLocSpecSpecial8 &&
				audioNode.grossLocation == kHdaConfigDefaultLocSurfDigitalDisplay) //  && (audioNode.pinCaps & (kHdaPinCapabilitiesHDMI | kHdaPinCapabilitiesDisplayPort)
				[_nodeArray removeObjectAtIndex:i];
		}
	}

	[self update];
}

- (void)resetDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *dictionary = [defaults dictionaryRepresentation];
	
	for (id key in dictionary)
		[defaults removeObjectForKey:key];
	
	[defaults synchronize];
}

- (void)setDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										@YES, @"SortNodes",
										//@(0x7FF), @"NodeOptions",
										@(0x786), @"NodeOptions",
										nil];
	
	[defaults registerDefaults:defaultsDictionary];
	[defaults synchronize];
}

- (void)loadSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	_sortNodes = [defaults boolForKey:@"SortNodes"];
	_nodeOptions = (uint32_t)[defaults integerForKey:@"NodeOptions"];
}

- (void)saveSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setBool:_sortNodes forKey:@"SortNodes"];
	[defaults setInteger:_nodeOptions forKey:@"NodeOptions"];
	
	[defaults synchronize];
}

- (IBAction)generalOptionClicked:(id)sender
{
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	uint32_t index = (uint32_t)menuItem.tag;
	
	[menuItem setState:!menuItem.state];
	
	switch(index)
	{
		case 0:
			_sortNodes = menuItem.state;
			break;
		default:
			break;
	}
}

- (IBAction)nodeOptionClicked:(id)sender
{
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	uint32_t index = (uint32_t)menuItem.tag;
	
	[menuItem setState:!menuItem.state];

	if (menuItem.state)
		_nodeOptions |= (1 << index);
	else
		_nodeOptions &= ~(1 << index);
}

@end
