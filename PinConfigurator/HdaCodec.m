//
//  HdaCodec.m
//  PinConfigurator
//
//  Created by Ben Baker on 2/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "HdaCodec.h"
#import "HdaCodecDump.h"
#import "MiscTools.h"

@implementation HdaWidget

-(id) initWithNodeID:(uint8_t)nodeID
{
	if (self = [super init])
	{
		self.nodeID = nodeID;
		self.bindAssoc = -1;
		self.bindSeqMask = 0x0;
		self.connectionSelect = -1;
	}
	
	return self;
}

- (void)dealloc
{
	[_name release];
	[_connections release];
	[_ampInLeftDefaultGainMute release];
	[_ampInRightDefaultGainMute release];
	
	[super dealloc];
}

- (NSString *)typeString
{
	NSArray *typeArray = @[@"Audio Output", @"Audio Input", @"Audio Mixer",
						   @"Audio Selector", @"Pin Complex", @"Power Widget",
						   @"Volume Knob Widget", @"Beep Generator Widget",
						   @"Reserved", @"Reserved", @"Reserved", @"Reserved",
						   @"Reserved", @"Reserved", @"Reserved",
						   @"Vendor Defined Widget"];
	
	return typeArray[[self type]];
}

- (uint32_t)type
{
	return HDA_PARAMETER_WIDGET_CAPS_TYPE(_capabilities);
}

- (BOOL)isStereo
{
	return (_capabilities & HDA_PARAMETER_WIDGET_CAPS_STEREO) != 0;
}

- (BOOL)isDigital
{
	return (_capabilities & HDA_PARAMETER_WIDGET_CAPS_DIGITAL) != 0;
}

- (BOOL)isAmpIn
{
	return (_capabilities & HDA_PARAMETER_WIDGET_CAPS_IN_AMP) != 0;
}

- (BOOL)isAmpOut
{
	return (_capabilities & HDA_PARAMETER_WIDGET_CAPS_OUT_AMP) != 0;
}

- (BOOL)isLRSwap
{
	return (_capabilities & HDA_PARAMETER_WIDGET_CAPS_L_R_SWAP) != 0;
}

- (BOOL) hasConnectionList
{
	return (_capabilities & HDA_PARAMETER_WIDGET_CAPS_CONN_LIST) != 0;
}

- (NSString *)defaultPortConnectionString
{
	NSArray *portConnectionArray = @[@"Jack", @"None", @"Fixed", @"Int Jack"];
	
	return portConnectionArray[[self defaultPortConnection]];
}

- (uint32_t)defaultPortConnection
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_PORT_CONN(_defaultConfiguration);
}

- (NSString *)defaultDeviceString
{
	NSArray *defaultDeviceArray = @[@"Line Out", @"Speaker", @"HP Out", @"CD", @"SPDIF Out",
									@"Digital Out", @"Modem Line", @"Modem Handset", @"Line In", @"Aux",
									@"Mic", @"Telephone", @"SPDIF In", @"Digital In", @"Reserved", @"Other"];
	
	return defaultDeviceArray[[self defaultDevice]];
}

- (uint32_t)defaultDevice
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_DEVICE(_defaultConfiguration);
}

- (NSString *)defaultSurfaceString
{
	NSArray *surfaceArray = @[@"Ext", @"Int", @"Ext", @"Other"];
	
	return surfaceArray[[self defaultSurface]];
}

- (uint32_t)defaultSurface
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_SURF(_defaultConfiguration);
}

- (NSString *)defaultLocationString
{
	NSArray *locationArray = @[@"N/A", @"Rear", @"Front", @"Left", @"Right", @"Top", @"Bottom", @"Special",
							   @"Special", @"Special", @"Reserved", @"Reserved", @"Reserved", @"Reserved"];
	
	return locationArray[[self defaultLocation]];
}

- (uint32_t)defaultLocation
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_LOC(_defaultConfiguration);
}

- (NSString *)defaultConnectionTypeString
{
	NSArray *connectionTypeArray = @[@"Unknown", @"1/8", @"1/4", @"ATAPI", @"RCA", @"Optical", @"Digital",
									 @"Analog", @"Multi", @"XLR", @"RJ11", @"Combo", @"Other", @"Other", @"Other", @"Other"];
	
	return connectionTypeArray[[self defaultConnectionType]];
}

- (uint32_t)defaultConnectionType
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_CONN_TYPE(_defaultConfiguration);
}

- (NSString *)defaultColorString
{
	NSArray *colorArray = @[@"Unknown", @"Black", @"Grey", @"Blue", @"Green", @"Red", @"Orange",
							@"Yellow", @"Purple", @"Pink", @"Reserved", @"Reserved", @"Reserved",
							@"Reserved", @"White", @"Other"];
	
	return colorArray[[self defaultColor]];
}

- (uint32_t)defaultColor
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_COLOR(_defaultConfiguration);
}

- (uint8_t)defaultAssociation
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_ASSOCIATION(_defaultConfiguration);
}

- (uint8_t)defaultSequence
{
	return HDA_VERB_GET_CONFIGURATION_DEFAULT_SEQUENCE(_defaultConfiguration);
}

- (NSString *)capabilitiesString
{
	NSMutableString *outputString = [NSMutableString string];
	
	if ([self isStereo])
		[outputString appendFormat:@" Stereo"];
	else
		[outputString appendFormat:@" Mono"];
	if ([self isDigital])
		[outputString appendFormat:@" Digital"];
	if ([self isAmpIn])
		[outputString appendFormat:@" Amp-In"];
	if ([self isAmpOut])
		[outputString appendFormat:@" Amp-Out"];
	if ([self isLRSwap])
		[outputString appendFormat:@" R/L"];
	
	return outputString;
}

- (NSString *)controlString
{
	NSMutableString *outputString = [NSMutableString string];
	
	if (_defaultPinControl & HDA_PIN_WIDGET_CONTROL_VREF_EN)
		[outputString appendFormat:@" VREF"];
	if (_defaultPinControl & HDA_PIN_WIDGET_CONTROL_IN_EN)
		[outputString appendFormat:@" IN"];
	if (_defaultPinControl & HDA_PIN_WIDGET_CONTROL_OUT_EN)
		[outputString appendFormat:@" OUT"];
	if (_defaultPinControl & HDA_PIN_WIDGET_CONTROL_HP_EN)
		[outputString appendFormat:@" HP"];
	
	return outputString;
}

- (NSString *)pinCapString
{
	NSMutableString *outputString = [NSMutableString string];
	
	if ([self hasInput])
		[outputString appendFormat:@" IN"];
	if ([self hasOutput])
		[outputString appendFormat:@" OUT"];
	if ([self hasHeadphone])
		[outputString appendFormat:@" HP"];
	if ([self hasEAPD])
		[outputString appendFormat:@" EAPD"];
	if ([self hasTrigger])
		[outputString appendFormat:@" Trigger"];
	if ([self hasPresence])
		[outputString appendFormat:@" Detect"];
	if ([self hasHBR])
		[outputString appendFormat:@" HBR"];
	if ([self hasHDMI])
		[outputString appendFormat:@" HDMI"];
	if ([self hasDisplayPort])
		[outputString appendFormat:@" DP"];
	
	return outputString;
}

- (NSString *)eapdString
{
	NSMutableString *outputString = [NSMutableString string];
	
	if (_defaultEapd & HDA_EAPD_BTL_ENABLE_BTL)
		[outputString appendFormat:@" BTL"];
	if (_defaultEapd & HDA_EAPD_BTL_ENABLE_EAPD)
		[outputString appendFormat:@" EAPD"];
	if (_defaultEapd & HDA_EAPD_BTL_ENABLE_L_R_SWAP)
		[outputString appendFormat:@" R/L"];
	
	return outputString;
}

- (BOOL) hasImpendance
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_IMPEDANCE) != 0;
}

- (BOOL) hasTrigger
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_TRIGGER) != 0;
}

- (BOOL) hasPresence
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_PRESENCE) != 0;
}

- (BOOL) hasHeadphone
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_HEADPHONE) != 0;
}

- (BOOL) hasOutput
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_OUTPUT) != 0;
}

- (BOOL) hasInput
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_INPUT) != 0;
}

- (BOOL) hasBalanced
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_BALANCED) != 0;
}

- (BOOL) hasHDMI
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_HDMI) != 0;
}

- (BOOL) hasEAPD
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_EAPD) != 0;
}

- (BOOL) hasDisplayPort
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_DISPLAYPORT) != 0;
}

- (BOOL) hasHBR
{
	return (_pinCapabilities & HDA_PARAMETER_PIN_CAPS_HBR) != 0;
}

- (BOOL) isInputDevice
{
	return ([self defaultDevice] > 7 && [self defaultDevice] <= 0xD);
}

- (BOOL) isOutputDevice
{
	return ([self defaultDevice] <= 7);
}

- (BOOL) isEnabled
{
	if ([self type] == HDA_WIDGET_TYPE_POWER || [self type] == HDA_WIDGET_TYPE_VOLUME_KNOB)
		return false;
	
	if ([self type] != HDA_WIDGET_TYPE_PIN_COMPLEX || [self defaultPortConnection] == HDA_CONFIG_DEFAULT_PORT_CONN_NONE || [self defaultAssociation] == 0)
		return false;
	
	return true;
}

@end

@implementation HdaCodec

- (id) initWithName:(NSString *)name audioFuncID:(uint32_t)audioFuncID unsol:(uint32_t)unsol vendorID:(uint32_t)vendorID revisionID:(uint32_t)revisionID rates:(uint32_t)rates formats:(uint32_t)formats ampInCaps:(uint32_t)ampInCaps ampOutCaps:(uint32_t)ampOutCaps
{
	if (self = [super init])
	{
		self.name = name;
		self.audioFuncID = audioFuncID;
		self.unsol = unsol;
		self.vendorID = vendorID;
		self.revisionID = revisionID;
		self.rates = rates;
		self.formats = formats;
		self.ampInCaps = ampInCaps;
		self.ampOutCaps = ampOutCaps;
	}
	
	return self;
}

- (void)dealloc
{
	[_name release];
	[_widgets release];
	
	[super dealloc];
}

- (NSString *) sampleRatesString
{
	NSMutableString *outputString = [NSMutableString string];
	
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_8KHZ)
		[outputString appendFormat:@" 8000"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_11KHZ)
		[outputString appendFormat:@" 11025"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_16KHZ)
		[outputString appendFormat:@" 16000"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_22KHZ)
		[outputString appendFormat:@" 22050"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_32KHZ)
		[outputString appendFormat:@" 32000"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_44KHZ)
		[outputString appendFormat:@" 44100"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_48KHZ)
		[outputString appendFormat:@" 48000"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_88KHZ)
		[outputString appendFormat:@" 88200"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_96KHZ)
		[outputString appendFormat:@" 96000"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_176KHZ)
		[outputString appendFormat:@" 176400"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_192KHZ)
		[outputString appendFormat:@" 192000"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_384KHZ)
		[outputString appendFormat:@" 384000"];
	
	return outputString;
}

- (NSString *) bitRatesString
{
	NSMutableString *outputString = [NSMutableString string];
	
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_8BIT)
		[outputString appendFormat:@" 8"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_16BIT)
		[outputString appendFormat:@" 16"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_20BIT)
		[outputString appendFormat:@" 20"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_24BIT)
		[outputString appendFormat:@" 24"];
	if (_rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_32BIT)
		[outputString appendFormat:@" 32"];
	
	return outputString;
}

- (NSString *) streamFormatString
{
	NSMutableString *outputString = [NSMutableString string];
	
	if (_formats & HDA_PARAMETER_SUPPORTED_STREAM_FORMATS_PCM)
		[outputString appendFormat:@" PCM"];
	if (_formats & HDA_PARAMETER_SUPPORTED_STREAM_FORMATS_FLOAT32)
		[outputString appendFormat:@" FLOAT32"];
	if (_formats & HDA_PARAMETER_SUPPORTED_STREAM_FORMATS_AC3)
		[outputString appendFormat:@" AC3"];
	
	return outputString;
}

- (NSString *) ampCapsString:(uint32_t)ampCaps
{
	if (!ampCaps)
		return @"N/A";
	
	return [NSString stringWithFormat:@"ofs=0x%02X, nsteps=0x%02X, stepsize=0x%02X, mute=%u",
			HDA_PARAMETER_AMP_CAPS_OFFSET(ampCaps), HDA_PARAMETER_AMP_CAPS_NUM_STEPS(ampCaps),
			HDA_PARAMETER_AMP_CAPS_STEP_SIZE(ampCaps), (ampCaps & HDA_PARAMETER_AMP_CAPS_MUTE) != 0];
}

- (NSMutableString *)codecString
{
	// https://github.com/Digilent/linux-Digilent-Dev/blob/master/sound/pci/hda/hda_proc.c
	
	NSMutableString *outputString = [NSMutableString string];
	
	[outputString appendFormat:@"HdaCodecDump Start\n"];
	[outputString appendFormat:@"Codec: %@\n", _name];
	[outputString appendFormat:@"Address: %d\n", _address];
	[outputString appendFormat:@"AFG Function Id: 0x%02X (unsol %u)\n", _audioFuncID, _unsol];
	[outputString appendFormat:@"Vendor ID: 0x%08X\n", _vendorID];
	[outputString appendFormat:@"Revision ID: 0x%08X\n", _revisionID];
	
	if ((_rates != 0) || (_formats != 0))
	{
		[outputString appendFormat:@"Default PCM:\n"];
		[outputString appendFormat:@"    rates [0x%04X]:", (uint16_t)_rates];
		[outputString appendFormat:@"%@\n", [self sampleRatesString]];
		
		[outputString appendFormat:@"    bits [0x%04X]:", (uint16_t)(_rates >> 16)];
		[outputString appendFormat:@"%@\n", [self bitRatesString]];
		
		[outputString appendFormat:@"    formats [0x%08X]:", _formats];
		[outputString appendFormat:@"%@\n", [self streamFormatString]];
	}
	else
		[outputString appendFormat:@"Default PCM: N/A\n"];
	
	[outputString appendFormat:@"Default Amp-In caps: "];
	[outputString appendFormat:@"%@\n", [self ampCapsString:_ampInCaps]];
	[outputString appendFormat:@"Default Amp-Out caps: "];
	[outputString appendFormat:@"%@\n", [self ampCapsString:_ampOutCaps]];
	
	for (HdaWidget *hdaWidget in _widgets)
	{
		[outputString appendFormat:@"Node 0x%02X [%@] wcaps 0x%08X:", hdaWidget.nodeID, hdaWidget.typeString, hdaWidget.capabilities];
		[outputString appendFormat:@"%@\n", [hdaWidget capabilitiesString]];
		
		if ([hdaWidget isAmpIn])
		{
			[outputString appendFormat:@"  Amp-In caps: "];
			[outputString appendFormat:@"%@\n", [self ampCapsString:hdaWidget.ampInCapabilities]];
			[outputString appendFormat:@"  Amp-In vals:"];
			
			for (uint32_t i = 0; i < [hdaWidget.ampInLeftDefaultGainMute count]; i++)
			{
				if ([hdaWidget isStereo])
					[outputString appendFormat:@" [0x%02X 0x%02X]", [hdaWidget.ampInLeftDefaultGainMute[i] intValue], [hdaWidget.ampInRightDefaultGainMute[i] intValue]];
				else
					[outputString appendFormat:@" [0x%02X]", [hdaWidget.ampInLeftDefaultGainMute[i] intValue]];
			}
			
			[outputString appendFormat:@"\n"];
		}
		
		if ([hdaWidget isAmpOut])
		{
			[outputString appendFormat:@"  Amp-Out caps: "];
			[outputString appendFormat:@"%@\n", [self ampCapsString:hdaWidget.ampOutCapabilities]];
			[outputString appendFormat:@"  Amp-Out vals:"];
			
			if ([hdaWidget isStereo])
				[outputString appendFormat:@" [0x%02X 0x%02X]\n", hdaWidget.ampOutLeftDefaultGainMute, hdaWidget.ampOutRightDefaultGainMute];
			else
				[outputString appendFormat:@" [0x%02X]\n", hdaWidget.ampOutLeftDefaultGainMute];
		}
		
		if (hdaWidget.type == HDA_WIDGET_TYPE_PIN_COMPLEX)
		{
			[outputString appendFormat:@"  Pincap 0x%08X:", hdaWidget.pinCapabilities];
			[outputString appendFormat:@"%@\n", [hdaWidget pinCapString]];
			
			if ([hdaWidget hasEAPD])
			{
				[outputString appendFormat:@"  EAPD 0x%02X:", hdaWidget.defaultEapd];
				[outputString appendFormat:@"%@\n", [hdaWidget eapdString]];
			}
			
			[outputString appendFormat:@"  Pin Default 0x%08X: [%@] %@ at %@ %@\n", hdaWidget.defaultConfiguration, [hdaWidget defaultPortConnectionString], [hdaWidget defaultDeviceString], [hdaWidget defaultSurfaceString], [hdaWidget defaultLocationString]];
			[outputString appendFormat:@"    Conn = %@, Color = %@\n", [hdaWidget defaultConnectionTypeString], [hdaWidget defaultColorString]];
			[outputString appendFormat:@"    DefAssociation = 0x%1X, Sequence = 0x%1X\n", [hdaWidget defaultAssociation], [hdaWidget defaultSequence]];
			[outputString appendFormat:@"  Pin-ctls: 0x%02X:", hdaWidget.defaultPinControl];
			[outputString appendFormat:@"%@\n", [hdaWidget controlString]];
		}
		
		if ([hdaWidget hasConnectionList])
		{
			[outputString appendFormat:@"  Connection: %u\n    ", (uint32_t)[hdaWidget.connections count]];
			
			for (int i = 0; i < [hdaWidget.connections count]; i++)
			{
				NSNumber *connection = hdaWidget.connections[i];
				[outputString appendFormat:@" 0x%02X%@", [connection intValue], hdaWidget.connectionSelect == i ? @"*" : @""];
			}
			
			[outputString appendFormat:@"\n"];
		}
	}
	
	return outputString;
}

+ (bool)stringContains:(NSString *)valueString checkString:(NSString *)checkString
{
	return ([valueString rangeOfString:checkString options:NSCaseInsensitiveSearch].location != NSNotFound);
}

+ (bool)parseHdaCodecNode_Voodoo:(NSString *)hdaNodeString hdaCodec:(HdaCodec *)hdaCodec
{
	// nid: 20
	// Name: pin: Speaker (ATAPI)
	// 	Widget cap: 0x0040018d
	//	UNSOL STEREO
	// Association: 0 (0x00000001)
	// 	Pin cap: 0x00010014
	// 	PDC OUT EAPD
	// 	Pin config: 0x99130110
	// 	Pin control: 0x00000040 OUT
	// EAPD: 0x00000002
	// 	Output amp: 0x80000000
	// 	mute=1 step=0 size=0 offset=0
	// 	Output val: [0x00 0x00]
	// connections: 2 enabled 1
	
	NSArray *lineArray = [hdaNodeString componentsSeparatedByString:@"\n"];
	HdaWidget *hdaWidget = nil;
	NSMutableArray *itemArray;
	
	for (int i = 0; i < [lineArray count]; i++)
	{
		NSString *line = lineArray[i];
		
		// =============================================================================
		//  nid: 20
		// =============================================================================
		if (getRegExArray(@"(.*)nid: (.*)", line, 2, &itemArray))
		{
			if (hdaWidget != nil)
				[hdaWidget release];
			
			hdaWidget = [[HdaWidget alloc] initWithNodeID:getInt(itemArray[1])];
			[hdaCodec.widgets addObject:hdaWidget];
		}
		
		// =============================================================================
		//  Widget cap: 0x0040018f
		// =============================================================================
		if (getRegExArray(@"(.*)Widget cap: (.*)", line, 2, &itemArray))
			hdaWidget.capabilities = getInt(itemArray[1]);
		
		// =============================================================================
		//  EAPD: 0x00000002
		// =============================================================================
		if (getRegExArray(@"(.*)EAPD: (.*)", line, 2, &itemArray))
			hdaWidget.defaultEapd = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Pin cap: 0x00010014
		// =============================================================================
		if (getRegExArray(@"(.*)Pin cap: (.*)", line, 2, &itemArray))
			hdaWidget.pinCapabilities = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Pin config: 0x99130110
		// =============================================================================
		if (getRegExArray(@"(.*)Pin config: (.*)", line, 2, &itemArray))
			hdaWidget.defaultConfiguration = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Pin control: 0x00000000
		// =============================================================================
		if (getRegExArray(@"(.*)Pin control: (.*)", line, 2, &itemArray))
			hdaWidget.defaultPinControl = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Output amp: 0x80000000
		// =============================================================================
		if (getRegExArray(@"(.*)Output amp: (.*)", line, 2, &itemArray))
			hdaWidget.ampOutCapabilities = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Output val: [0x80 0x80]
		// =============================================================================
		if (getRegExArray(@"(.*)Output val: (.*)", line, 2, &itemArray))
		{
			NSMutableArray *ampOutArray = [[itemArray[1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
			[ampOutArray removeObjectsInArray:@[@" ", @""]];
			
			for (NSString *ampOutValue in ampOutArray)
			{
				NSArray *stereoArray = [ampOutValue componentsSeparatedByString:@" "];
				
				if ([stereoArray count] > 0)
				{
					hdaWidget.ampOutLeftDefaultGainMute = getInt(stereoArray[0]);
					
					if ([stereoArray count] == 2)
						hdaWidget.ampOutRightDefaultGainMute = getInt(stereoArray[1]);
				}
				
				break;
			}
			
			[ampOutArray release];
		}
		
		// =============================================================================
		// 	Input amp: 0x002f0300
		// =============================================================================
		if (getRegExArray(@"(.*)Input amp: (.*)", line, 2, &itemArray))
			hdaWidget.ampInCapabilities = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Input val: [0x00 0x00] [0x00 0x00]
		// =============================================================================
		if (getRegExArray(@"(.*)Input val: (.*)", line, 2, &itemArray))
		{
			hdaWidget.ampInLeftDefaultGainMute = [NSMutableArray array];
			hdaWidget.ampInRightDefaultGainMute = [NSMutableArray array];
			NSMutableArray *ampInArray = [[itemArray[1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
			[ampInArray removeObjectsInArray:@[@" ", @""]];
			
			for (NSString *ampInValue in ampInArray)
			{
				NSArray *stereoArray = [ampInValue componentsSeparatedByString:@" "];
				
				if ([stereoArray count] > 0)
				{
					[hdaWidget.ampInLeftDefaultGainMute addObject:[NSNumber numberWithInteger:getInt(stereoArray[0])]];
					
					if ([stereoArray count] == 2)
						[hdaWidget.ampInRightDefaultGainMute addObject:[NSNumber numberWithInteger:getInt(stereoArray[1])]];
				}
			}
			
			[ampInArray release];
		}
		
		// =============================================================================
		// connections: 2 enabled 2
		// 	|
		// 	+ <- nid=12 [audio mixer] (selected)
		// 	+ <- nid=13 [audio mixer] [DISABLED]
		// =============================================================================
		if (getRegExArray(@"(.*)connections: (.*) enabled (.*)", line, 3, &itemArray))
		{
			if ((i += 2) >= [lineArray count])
				break;
			
			line = lineArray[i];
			hdaWidget.connections = [NSMutableArray array];
			
			while (getRegExArray(@"(.*)<- nid=(.*) \\[(.*)\\](.*)", line, 4, &itemArray))
			{
				bool selected = [HdaCodec stringContains:itemArray[3] checkString:@"selected"];
				//bool disabled = [HdaCodec stringContains:itemArray[3] checkString:@"disabled"];
				uint32_t connection = getInt(itemArray[1]);
				[hdaWidget.connections addObject:[NSNumber numberWithInteger:connection]];
				
				if (selected)
					hdaWidget.connectionSelect = (uint8_t)(hdaWidget.connections.count - 1);
				
				if (++i >= [lineArray count])
					break;
				
				line = lineArray[i];
			}
			
			continue;
		}
	}
	
	if (hdaWidget != nil)
		[hdaWidget release];
	
	return true;
}

+ (bool)parseHdaCodecString_Voodoo:(NSString *)hdaCodecString hdaCodec:(HdaCodec *)hdaCodec
{
	// 	Probing codec #0...
	// 	HDA Codec #0: Realtek ALC269
	// 	HDA Codec ID: 0x10ec0269
	// Vendor: 0x10ec
	// Device: 0x0269
	// Revision: 0x01
	// Stepping: 0x00
	// 	PCI Subvendor: 0x035d1025
	// 	startNode=1 endNode=2
	// 	Found audio FG nid=1 startNode=2 endNode=36 total=34
	
	NSRange nodeRange = [hdaCodecString rangeOfString:@"nid:"];
	
	if (nodeRange.location == NSNotFound)
		return false;
	
	NSString *headerString = [hdaCodecString substringWithRange:NSMakeRange(0, nodeRange.location)];
	NSString *allNodesString = [hdaCodecString substringFromIndex:nodeRange.location];
	NSArray *nodeArray = [allNodesString componentsSeparatedByString:@"nid:"];
	NSArray *headerLineArray = [headerString componentsSeparatedByString:@"\n"];
	NSMutableArray *itemArray;
	
	for (NSString *line in headerLineArray)
	{
		//NSLog(@"%@", line);
		
		// =============================================================================
		//  HDA Codec #0: Realtek ALC269
		// =============================================================================
		if (getRegExArray(@"(.*)HDA Codec #(.*): (.*)", line, 3, &itemArray))
		{
			hdaCodec.address = getInt(itemArray[1]);
			hdaCodec.name = itemArray[2];
		}
		
		// =============================================================================
		//  HDA Codec ID: 0x10ec0269
		// =============================================================================
		if (getRegExArray(@"(.*)HDA Codec ID: (.*)", line, 2, &itemArray))
			hdaCodec.vendorID = getInt(itemArray[1]);
		
		// =============================================================================
		// Revision: 0x01
		// =============================================================================
		if (getRegExArray(@"(.*)Revision: (.*)", line, 2, &itemArray))
			hdaCodec.revisionID |= getInt(itemArray[1]) << 16;
	}
	
	hdaCodec.widgets = [NSMutableArray array];
	
	for (NSString *nodeString in nodeArray)
	{
		NSString *newNodeString = [@"nid:" stringByAppendingString:nodeString];
		
		[HdaCodec parseHdaCodecNode_Voodoo:newNodeString hdaCodec:hdaCodec];
	}
	
	return true;
}

+ (bool)parseHdaCodecNode_Linux:(NSString *)hdaNodeString hdaCodec:(HdaCodec *)hdaCodec
{
	// Node 0x14 [Pin Complex] wcaps 0x40058d: Stereo Amp-Out
	// Control: name="Speaker Playback Switch", index=0, device=0
	// ControlAmp: chs=3, dir=Out, idx=0, ofs=0
	// 	Amp-Out caps: ofs=0x00, nsteps=0x00, stepsize=0x00, mute=1
	// 	Amp-Out vals:  [0x00 0x00]
	// 	Pincap 0x00010014: OUT EAPD Detect
	// 	EAPD 0x2: EAPD
	// 	Pin Default 0x90170110: [Fixed] Speaker at Int N/A
	// 	Conn = Analog, Color = Unknown
	// 	DefAssociation = 0x1, Sequence = 0x0
	// 	Misc = NO_PRESENCE
	// 	Pin-ctls: 0x40: OUT
	// Unsolicited: tag=00, enabled=0
	// 	Power states:  D0 D1 D2 D3 EPSS
	// Power: setting=D0, actual=D0
	// Connection: 1
	// 	0x02
	
	NSArray *lineArray = [hdaNodeString componentsSeparatedByString:@"\n"];
	HdaWidget *hdaWidget = nil;
	NSMutableArray *itemArray;
	
	for (int i = 0; i < [lineArray count]; i++)
	{
		NSString *line = lineArray[i];
		//NSLog(@"%@", line);
		
		// =============================================================================
		// Node 0x14 [Pin Complex] wcaps 0x40058d: Stereo Amp-Out
		// =============================================================================
		if (getRegExArray(@"Node (.*) \\[(.*)\\] wcaps (.*):(.*)", line, 4, &itemArray))
		{
			if (hdaWidget != nil)
				[hdaWidget release];
			
			hdaWidget = [[HdaWidget alloc] initWithNodeID:getInt(itemArray[0])];
			[hdaCodec.widgets addObject:hdaWidget];
			
			hdaWidget.capabilities = getInt(itemArray[2]);
		}
		
		// =============================================================================
		// Control: name="Speaker Playback Switch", index=0, device=0
		// =============================================================================
		if (getRegExArray(@"Control: name=\"(.*)\", index=(.*), device=(.*)", line, 3, &itemArray))
			hdaWidget.name = itemArray[0];
		
		// =============================================================================
		//	Amp-In caps: ofs=0x00, nsteps=0x00, stepsize=0x00, mute=1
		// =============================================================================
		if (getRegExArray(@"(.*)Amp-In caps: ofs=(.*), nsteps=(.*), stepsize=(.*), mute=(.*)", line, 5, &itemArray))
		{
			hdaWidget.ampInCapabilities |= getInt(itemArray[1]);
			hdaWidget.ampInCapabilities |= getInt(itemArray[2]) << 8;
			hdaWidget.ampInCapabilities |= getInt(itemArray[3]) << 16;
			hdaWidget.ampInCapabilities |= getInt(itemArray[4]) ? HDA_PARAMETER_AMP_CAPS_MUTE : 0;
		}			
		
		// =============================================================================
		//  Amp-In vals:  [0x00 0x00]
		// =============================================================================
		if (getRegExArray(@"(.*)Amp-In vals: (.*)", line, 2, &itemArray))
		{
			hdaWidget.ampInLeftDefaultGainMute = [NSMutableArray array];
			hdaWidget.ampInRightDefaultGainMute = [NSMutableArray array];
			NSMutableArray *ampInArray = [[itemArray[1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
			[ampInArray removeObjectsInArray:@[@" ", @""]];
			
			for (NSString *ampInValue in ampInArray)
			{
				NSArray *stereoArray = [ampInValue componentsSeparatedByString:@" "];
				
				if ([stereoArray count] > 0)
				{
					[hdaWidget.ampInLeftDefaultGainMute addObject:[NSNumber numberWithInteger:getInt(stereoArray[0])]];
					
					if ([stereoArray count] == 2)
						[hdaWidget.ampInRightDefaultGainMute addObject:[NSNumber numberWithInteger:getInt(stereoArray[1])]];
				}
			}
			
			[ampInArray release];
		}
		
		// =============================================================================
		//	Amp-Out caps: ofs=0x00, nsteps=0x00, stepsize=0x00, mute=1
		// =============================================================================
		if (getRegExArray(@"(.*)Amp-Out caps: ofs=(.*), nsteps=(.*), stepsize=(.*), mute=(.*)", line, 5, &itemArray))
		{
			hdaWidget.ampOutCapabilities |= getInt(itemArray[1]);
			hdaWidget.ampOutCapabilities |= getInt(itemArray[2]) << 8;
			hdaWidget.ampOutCapabilities |= getInt(itemArray[3]) << 16;
			hdaWidget.ampOutCapabilities |= getInt(itemArray[4]) ? HDA_PARAMETER_AMP_CAPS_MUTE : 0;
		}
		
		// =============================================================================
		//  Amp-Out vals:  [0x00 0x00]
		// =============================================================================
		if (getRegExArray(@"(.*)Amp-Out vals: (.*)", line, 2, &itemArray))
		{
			NSMutableArray *ampOutArray = [[itemArray[1] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] mutableCopy];
			[ampOutArray removeObjectsInArray:@[@" ", @""]];
			
			for (NSString *ampOutValue in ampOutArray)
			{
				NSArray *stereoArray = [ampOutValue componentsSeparatedByString:@" "];
				
				if ([stereoArray count] > 0)
				{
					hdaWidget.ampOutLeftDefaultGainMute = getInt(stereoArray[0]);
					
					if ([stereoArray count] == 2)
						hdaWidget.ampOutRightDefaultGainMute = getInt(stereoArray[1]);
				}
				
				break;
			}
			
			[ampOutArray release];
		}
		
		// =============================================================================
		// Connection: 2
		// 	0x02 0x03
		// =============================================================================
		if (getRegExArray(@"(.*)Connection: (.*)", line, 2, &itemArray))
		{
			if (++i >= [lineArray count])
				break;
			
			line = lineArray[i];
			hdaWidget.connections = [NSMutableArray array];
			NSMutableArray *connectionArray = [[line componentsSeparatedByString:@" "] mutableCopy];
			[connectionArray removeObject:@""];
			
			for (int j = 0; j < [connectionArray count]; j++)
			{
				bool selected = [connectionArray[j] hasSuffix:@"*"];
				uint32_t connection = getInt(connectionArray[j]);
				[hdaWidget.connections addObject:[NSNumber numberWithInteger:connection]];
				
				if (selected)
					hdaWidget.connectionSelect = (uint8_t)(hdaWidget.connections.count - 1);
			}
			
			[connectionArray release];
			
			continue;
		}
		
		// =============================================================================
		// 	Pincap 0x00010014: OUT EAPD Detect
		// =============================================================================
		if (getRegExArray(@"(.*)Pincap (.*):(.*)", line, 3, &itemArray))
			hdaWidget.pinCapabilities = getInt(itemArray[1]);
		
		// =============================================================================
		// 	EAPD 0x2: EAPD
		// =============================================================================
		if (getRegExArray(@"(.*)EAPD (.*):(.*)", line, 3, &itemArray))
			hdaWidget.defaultEapd = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Pin Default 0x90170110: [Fixed] Speaker at Int N/A
		// =============================================================================
		if (getRegExArray(@"(.*)Pin Default (.*):(.*)", line, 3, &itemArray))
			hdaWidget.defaultConfiguration = getInt(itemArray[1]);
		
		// =============================================================================
		// 	Pin-ctls: 0x40: OUT
		// =============================================================================
		if (getRegExArray(@"(.*)Pin-ctls: (.*):(.*)", line, 3, &itemArray))
			hdaWidget.defaultPinControl = getInt(itemArray[1]);
	}
	
	if (hdaWidget != nil)
		[hdaWidget release];
	
	return true;
}

+ (bool)parseHdaCodecString_Linux:(NSString *)hdaCodecString hdaCodec:(HdaCodec *)hdaCodec
{
	// Codec: Realtek Generic
	// Address: 0
	// AFG Function Id: 0x1 (unsol 1)
	// Vendor Id: 0x10ec1220
	//
	
	NSRange nodeRange = [hdaCodecString rangeOfString:@"Node"];
	
	if (nodeRange.location == NSNotFound)
		return false;
	
	NSString *headerString = [hdaCodecString substringWithRange:NSMakeRange(0, nodeRange.location)];
	NSString *allNodesString = [hdaCodecString substringFromIndex:nodeRange.location];
	allNodesString = [allNodesString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	NSArray *nodeArray = [allNodesString componentsSeparatedByString:@"Node"];
	NSArray *headerLineArray = [headerString componentsSeparatedByString:@"\n"];
	NSMutableArray *itemArray;
	
	for (NSString *line in headerLineArray)
	{
		// =============================================================================
		// Codec: Realtek Generic
		// =============================================================================
		if (getRegExArray(@"Codec: (.*)", line, 1, &itemArray))
			hdaCodec.name = itemArray[0];
		
		// =============================================================================
		// Address: 0
		// =============================================================================
		if (getRegExArray(@"Address: (.*)", line, 1, &itemArray))
			hdaCodec.address = getInt(itemArray[0]);
		
		// =============================================================================
		// Vendor Id: 0x10EC0283
		// =============================================================================
		if (getRegExArray(@"Vendor Id: (.*)", line, 1, &itemArray))
			hdaCodec.vendorID = getInt(itemArray[0]);
		
		// =============================================================================
		// Revision Id: 0x00100003
		// =============================================================================
		if (getRegExArray(@"Revision Id: (.*)", line, 1, &itemArray))
			hdaCodec.revisionID = getInt(itemArray[0]);
		
		// =============================================================================
		// AFG Function Id: 0x1 (unsol 1)
		// =============================================================================
		if (getRegExArray(@"AFG Function Id: (.*) \\(unsol (.*)\\)", line, 2, &itemArray))
		{
			hdaCodec.audioFuncID = getInt(itemArray[0]);
			hdaCodec.unsol = getInt(itemArray[1]);
		}
		
		// =============================================================================
		// rates [0x0560]: 44100 48000 96000 192000
		// bits [0x000E]: 16 20 24
		// formats [0x00000001]: PCM
		// =============================================================================
		if (getRegExArray(@"(.*)rates \\[(.*)\\]:(.*)", line, 3, &itemArray))
			hdaCodec.rates = getInt(itemArray[1]);
		
		if (getRegExArray(@"(.*)bits \\[(.*)\\]:(.*)", line, 3, &itemArray))
			hdaCodec.rates |= getInt(itemArray[1]) << 16;
		
		if (getRegExArray(@"(.*)formats \\(.*)\\]:(.*)", line, 3, &itemArray))
			hdaCodec.formats = getInt(itemArray[1]);
	}
	
	hdaCodec.widgets = [NSMutableArray array];
	
	for (NSString *nodeString in nodeArray)
	{
		if ([nodeString isEqualToString:@""])
			continue;
		
		NSString *newNodeString = [@"Node" stringByAppendingString:nodeString];
		
		[HdaCodec parseHdaCodecNode_Linux:newNodeString hdaCodec:hdaCodec];
	}
	
	return true;
}

+ (bool)parseHdaCodecString:(NSString *)hdaCodecString hdaCodec:(HdaCodec **)hdaCodec
{
	*hdaCodec = [[HdaCodec alloc] init];
	
	if ([hdaCodecString rangeOfString:@"Codec"].location != NSNotFound)
	{
		if ([hdaCodecString rangeOfString:@"Pin config:"].location != NSNotFound)
			return [HdaCodec parseHdaCodecString_Voodoo:hdaCodecString hdaCodec:*hdaCodec];
		else if ([hdaCodecString rangeOfString:@"[Pin Complex]"].location != NSNotFound)
			return [HdaCodec parseHdaCodecString_Linux:hdaCodecString hdaCodec:*hdaCodec];
	}
	
	return false;
}

+ (bool)parseHdaCodecData:(uint8_t *)hdaCodecData length:(uint32_t)length hdaCodec:(HdaCodec **)hdaCodec
{
	if (length < sizeof(HdaCodecEntry))
		return false;
	
	uint8_t *pHdaCodecData = hdaCodecData;
	HdaCodecEntry *hdaCodecEntry = (HdaCodecEntry *)pHdaCodecData;
	
	if (hdaCodecEntry->Header[0] != 'H' || hdaCodecEntry->Header[1] != 'D' || hdaCodecEntry->Header[2] != 'C')
		return false;
	
	uint32_t widgetCount = hdaCodecEntry->WidgetCount;
	*hdaCodec = [[HdaCodec alloc] initWithName:[NSString stringWithCString:(const char *)hdaCodecEntry->Name encoding:NSASCIIStringEncoding] audioFuncID:hdaCodecEntry->AudioFuncID unsol:hdaCodecEntry->Unsol vendorID:hdaCodecEntry->VendorID revisionID:hdaCodecEntry->RevisionID rates:hdaCodecEntry->Rates formats:hdaCodecEntry->Formats ampInCaps:hdaCodecEntry->AmpInCaps ampOutCaps:hdaCodecEntry->AmpOutCaps];
	
	(*hdaCodec).widgets = [NSMutableArray array];
	
	pHdaCodecData += sizeof(HdaCodecEntry);
	
	HdaWidgetEntry *hdaWidgetEntry = (HdaWidgetEntry *)pHdaCodecData;
	
	for (uint32_t w = 0; w < widgetCount; w++)
	{
		HdaWidget *hdaWidget = [[HdaWidget alloc] initWithNodeID:hdaWidgetEntry->NodeId];
		
		hdaWidget.capabilities = hdaWidgetEntry->Capabilities;
		hdaWidget.defaultUnSol = hdaWidgetEntry->DefaultUnSol;
		hdaWidget.defaultEapd = hdaWidgetEntry->DefaultEapd;
		hdaWidget.connectionSelect = hdaWidgetEntry->ConnectionSelect;
		hdaWidget.connections = (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_CONN_LIST ? [NSMutableArray array] : nil);
		hdaWidget.supportedPowerStates = hdaWidgetEntry->SupportedPowerStates;
		hdaWidget.defaultPowerState = hdaWidgetEntry->DefaultPowerState;
		hdaWidget.ampInCapabilities = hdaWidgetEntry->AmpInCapabilities;
		hdaWidget.ampOutCapabilities = hdaWidgetEntry->AmpOutCapabilities;
		hdaWidget.ampInLeftDefaultGainMute = (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_IN_AMP ? [NSMutableArray array] : nil);
		hdaWidget.ampInRightDefaultGainMute = (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_IN_AMP && hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_STEREO ? [NSMutableArray array] : nil);
		hdaWidget.ampOutLeftDefaultGainMute = hdaWidgetEntry->AmpOutLeftDefaultGainMute;
		hdaWidget.ampOutRightDefaultGainMute = hdaWidgetEntry->AmpOutRightDefaultGainMute;
		hdaWidget.supportedPcmRates = hdaWidgetEntry->SupportedPcmRates;
		hdaWidget.supportedFormats = hdaWidgetEntry->SupportedFormats;
		hdaWidget.defaultConvFormat = hdaWidgetEntry->DefaultConvFormat;
		hdaWidget.defaultConvStreamChannel = hdaWidgetEntry->DefaultConvStreamChannel;
		hdaWidget.defaultConvChannelCount = hdaWidgetEntry->DefaultConvChannelCount;
		hdaWidget.pinCapabilities = hdaWidgetEntry->PinCapabilities;
		hdaWidget.defaultPinControl = hdaWidgetEntry->DefaultPinControl;
		hdaWidget.defaultConfiguration = hdaWidgetEntry->DefaultConfiguration;
		hdaWidget.volumeCapabilities = hdaWidgetEntry->VolumeCapabilities;
		hdaWidget.defaultVolume = hdaWidgetEntry->DefaultVolume;
		
		uint32_t connectionListLength = HDA_PARAMETER_CONN_LIST_LENGTH_LEN(hdaWidgetEntry->ConnectionListLength);
		
		for (uint8_t i = 0; i < connectionListLength; i++)
		{
			if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_IN_AMP)
			{
				[hdaWidget.ampInLeftDefaultGainMute addObject:[NSNumber numberWithInteger:hdaWidgetEntry->AmpInLeftDefaultGainMute[i]]];
				
				if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_STEREO)
					[hdaWidget.ampInRightDefaultGainMute addObject:[NSNumber numberWithInteger:hdaWidgetEntry->AmpInRightDefaultGainMute[i]]];
			}
			
			if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_CONN_LIST)
				[hdaWidget.connections addObject:[NSNumber numberWithShort:hdaWidgetEntry->Connections[i]]];
		}
		
		[(*hdaCodec).widgets addObject:hdaWidget];
		
		[hdaWidget release];
		
		pHdaCodecData += sizeof(HdaWidgetEntry);
		
		hdaWidgetEntry = (HdaWidgetEntry *)pHdaCodecData;
	}
	
	return true;
}

/* + (HdaWidget *)getWidget:(NSArray *)widgets nid:(uint8_t)nid
{
	for (HdaWidget *hdaWidget in widgets)
	{
		if (hdaWidget.nodeID == nid)
			return hdaWidget;
	}
	
	return nil;
} */

+ (bool)getWidget:(NSArray *)widgets nodeID:(uint8_t)nodeID hdaWidget:(HdaWidget **)hdaWidget
{
	for (*hdaWidget in widgets)
		if ((*hdaWidget).nodeID == nodeID)
			return true;
	
	return false;
}

+ (bool)getSelectedWidget:(NSArray *)widgets widgetIn:(HdaWidget *)widgetIn widgetOut:(HdaWidget **)widgetOut
{
	if (widgetIn.connections == nil || widgetIn.connectionSelect >= [widgetIn.connections count])
		return false;
	
	//NSLog(@"hdaWidget.nodeID: %02X widgetIn.connectionSelect: %02X", widgetIn.nodeID, widgetIn.connectionSelect);
	
	for (HdaWidget *hdaWidget in widgets)
	{
		if (hdaWidget.nodeID == [widgetIn.connections[widgetIn.connectionSelect] intValue])
		{
			*widgetOut = hdaWidget;
			
			return true;
		}
	}
	
	return false;
}

/* + (void)sortConnections:(HdaWidget *)hdaWidget
{
	NSArray *sortedArray;
	sortedArray = [hdaWidget.connections sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
				   {
					   NSNumber *connectionA = [NSNumber numberWithInt:[(NSNumber *)a intValue]];
					   NSNumber *connectionB = [NSNumber numberWithInt:[(NSNumber *)b intValue]];
					   NSNumber *selectedA = [NSNumber numberWithBool:(([(NSNumber *)a intValue] >> 8) & 0x1) != 0];
					   NSNumber *selectedB = [NSNumber numberWithBool:(([(NSNumber *)b intValue] >> 8) & 0x1) != 0];
					   NSComparisonResult connectionComparison = [connectionA compare:connectionB];
					   NSComparisonResult selectedComparison = [selectedA compare:selectedB];
					   
					   if (selectedComparison != NSOrderedSame)
						   return selectedComparison;
					   
					   return connectionComparison;
				   }];
} */

+ (void)addNodeToPlatformXml:(NSMutableArray *)chain0 hdaWidget:(HdaWidget *)hdaWidget
{
	NSMutableDictionary *chain = [[NSMutableDictionary alloc] init];
	[chain0 addObject:chain];
	[chain release];
	NSNumber *nodeID = @(hdaWidget.nodeID);
	[chain setObject:nodeID forKey:@"NodeID"];
	
	if(hdaWidget.type != HDA_WIDGET_TYPE_PIN_COMPLEX && ([hdaWidget isAmpIn] || [hdaWidget isAmpOut]))
	{
		NSMutableDictionary *amp = [[NSMutableDictionary alloc] init];
		[chain setObject:amp forKey:@"Amp"];
		
		NSMutableArray *channels = [[NSMutableArray alloc] init];
		[amp setObject:channels forKey:@"Channels"];
		
		NSNumber *muteInputAmp = [NSNumber numberWithBool:(hdaWidget.ampInCapabilities & HDA_PARAMETER_AMP_CAPS_MUTE) != 0];
		[amp setObject:muteInputAmp forKey:@"MuteInputAmp"];
		NSNumber *publishMute = [NSNumber numberWithBool:(hdaWidget.ampOutCapabilities & HDA_PARAMETER_AMP_CAPS_MUTE) != 0];
		[amp setObject:publishMute forKey:@"PublishMute"];
		NSNumber *publishVolume = [NSNumber numberWithBool:(hdaWidget.ampOutCapabilities & ~HDA_PARAMETER_AMP_CAPS_MUTE) != 0];
		[amp setObject:publishVolume forKey:@"PublishVolume"];
		NSNumber *volumeInputAmp = [NSNumber numberWithBool:(hdaWidget.ampInCapabilities & ~HDA_PARAMETER_AMP_CAPS_MUTE) != 0];
		[amp setObject:volumeInputAmp forKey:@"VolumeInputAmp"];
		
		NSMutableDictionary *bind0 = [[NSMutableDictionary alloc] init];
		[channels addObject:bind0];
		[bind0 release];
		NSNumber *bind1 = [NSNumber numberWithInteger:1];
		[bind0 setObject:bind1 forKey:@"Bind"];
		NSNumber *channel1 = [NSNumber numberWithInteger:1];
		[bind0 setObject:channel1 forKey:@"Channel"];
		
		NSMutableDictionary *channel0 = [[NSMutableDictionary alloc] init];
		[channels addObject:channel0];
		[channel0 release];
		NSNumber *bind2 = [NSNumber numberWithInteger:2];
		[channel0 setObject:bind2 forKey:@"Bind"];
		NSNumber *channel2 = [NSNumber numberWithInteger:2];
		[channel0 setObject:channel2 forKey:@"Channel"];
		
		[channels release];
		[amp release];
	}
	
	if (hdaWidget.type == HDA_WIDGET_TYPE_PIN_COMPLEX && ([hdaWidget isAmpIn] || [hdaWidget isAmpOut]) && (hdaWidget.ampInCapabilities & 0x7F00))
	{
		NSNumber *boost =@(1); //  параметр step
		[chain setObject:boost forKey:@"Boost"];
	}
}

+ (void)createPlatformsXml:(HdaCodec *)hdaCodec
{
	// https://osxlatitude.com/forums/topic/1946-complete-applehda-patching-guide/
	// https://osxlatitude.com/forums/topic/1946-complete-applehda-patching-guide/?tab=comments#comment-14127
	// https://osxlatitude.com/forums/topic/1967-applehda-binary-patching/
	//
	// http://web.mit.edu/custer/Desktop/custer/MacData/afs/sipb/project/freebsd/head/sys/dev/sound/pci/hda/hdaa.c
	// http://web.mit.edu/custer/Desktop/custer/MacData/afs/sipb/project/freebsd/head/sys/dev/sound/pci/hda/hdaa.h
	
	NSMutableDictionary *root = [[NSMutableDictionary alloc] init];
	NSMutableArray *commonPeripheralDSP = [[NSMutableArray alloc] init];
	[root setObject:commonPeripheralDSP forKey:@"CommonPeripheralDSP"];
	
	NSMutableDictionary *dict0 = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"DeviceID", @"Headphone", @"DeviceType", nil];
	NSMutableDictionary *dict1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"DeviceID", @"Microphone", @"DeviceType", nil];
	
	[commonPeripheralDSP addObject:dict0];
	[commonPeripheralDSP addObject:dict1];
	
	NSMutableArray *pathMaps = [[NSMutableArray alloc] init];
	[root setObject:pathMaps forKey:@"PathMaps"];
	NSMutableDictionary *pathMaps0 = [[NSMutableDictionary alloc] init];
	[pathMaps addObject:pathMaps0];
	[pathMaps0 release];
	NSNumber *pathMapID = @(1);
	[pathMaps0 setObject:pathMapID forKey:@"PathMapID"];
	NSMutableArray *pathMap = [[NSMutableArray alloc] init];
	[pathMaps0 setObject:pathMap forKey:@"PathMap"];
	
	// Input Devices
	// Pin Complex -> Audio Selector/Mixer -> Audio Input
	// (or)
	// Pin Complex -> Audio Input
	
	NSMutableArray *assocElement = [[NSMutableArray alloc] init];
	[pathMap addObject:assocElement]; //1
	[assocElement release];
	NSMutableArray *assocElement1 = [[NSMutableArray alloc] init];
	[assocElement addObject:assocElement1]; //2
	[assocElement1 release];
	NSMutableArray *chain0 = [[NSMutableArray alloc] init];
	[assocElement1 addObject:chain0]; //3
	[chain0 release];
	
	//NSMutableArray *pinConnectionArray = [NSMutableArray array];
	
	for (HdaWidget *audioInputWidget in hdaCodec.widgets)
	{
		//NSLog(@"%02X isOutputDevice: %02X pinComplexWidget.isAmpOut: %02X pinComplexWidget.type: %02X", audioInputWidget.nodeID, audioInputWidget.isOutputDevice, audioInputWidget.isAmpOut, audioInputWidget.type);
		
		if(!audioInputWidget.isAmpIn) // || !audioInputWidget.isInputDevice)
			continue;
		
		HdaWidget *audioMixerWidget = nil, *pinComplexWidget = nil;
		bool audioMixerFound = false, pinComplexFound = false;
		
		for (NSNumber *connection in audioInputWidget.connections)
		{
			if (![HdaCodec getWidget:hdaCodec.widgets nodeID:[connection intValue] hdaWidget:&audioMixerWidget])
				continue;
			
			if (!audioInputWidget.isAmpIn || (audioMixerWidget.type != HDA_WIDGET_TYPE_MIXER && audioMixerWidget.type != HDA_WIDGET_TYPE_SELECTOR))
				continue;
			
			audioMixerFound = true;
			
			break;
		}
		
		for (NSNumber *connection in audioMixerWidget.connections)
		{
			if (![HdaCodec getWidget:hdaCodec.widgets nodeID:[connection intValue] hdaWidget:&pinComplexWidget])
				continue;
			
			//!pinComplexWidget.isEnabled || !pinComplexWidget.isInputDevice ||
			if (!pinComplexWidget.isAmpIn || pinComplexWidget.type != HDA_WIDGET_TYPE_PIN_COMPLEX)
				continue;
			
			pinComplexFound = true;
			
			break;
		}
		
		if (audioMixerFound && pinComplexFound)
		{
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:pinComplexWidget];
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:audioMixerWidget];
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:audioInputWidget];
			
			NSLog(@"Input 0x%02X->0x%02X->0x%02X", pinComplexWidget.nodeID, audioMixerWidget.nodeID, audioInputWidget.nodeID);
		}
		else if (pinComplexFound)
		{
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:pinComplexWidget];
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:audioInputWidget];
			
			NSLog(@"Input 0x%02X->0x%02X", pinComplexWidget.nodeID, audioInputWidget.nodeID);
		}
		//else
		//	NSLog(@"Input 0x%02X (Error!)", audioInputWidget.nodeID);
	}
	
	// Output Devices
	// Pin Complex -> Audio Mixer -> Audio Output
	// (or)
	// Pin Complex ->  Audio Output
	
	assocElement = [[NSMutableArray alloc] init];
	[pathMap addObject:assocElement]; //1
	[assocElement release];
	assocElement1 = [[NSMutableArray alloc] init];
	[assocElement addObject:assocElement1]; //2
	[assocElement1 release];
	chain0 = [[NSMutableArray alloc] init];
	[assocElement1 addObject:chain0]; //3
	[chain0 release];
	
	//[pinConnectionArray removeAllObjects];
	
	for (HdaWidget *pinComplexWidget in hdaCodec.widgets)
	{
		//NSLog(@"%02X pinComplexWidget.isEnabled: %02X isOutputDevice: %02X pinComplexWidget.isAmpOut: %02X pinComplexWidget.type: %02X", pinComplexWidget.nodeID, pinComplexWidget.isEnabled, pinComplexWidget.isOutputDevice, pinComplexWidget.isAmpOut, pinComplexWidget.type);
		
		// !pinComplexWidget.isEnabled || !pinComplexWidget.isOutputDevice ||
		if (!pinComplexWidget.isAmpOut || pinComplexWidget.type != HDA_WIDGET_TYPE_PIN_COMPLEX)
			continue;
		
		HdaWidget *audioMixerWidget = nil, *audioOutputWidget = nil;
		bool audioMixerFound = false, audioOutputFound = false;
		
		for (NSNumber *connection in pinComplexWidget.connections)
		{
			if (![HdaCodec getWidget:hdaCodec.widgets nodeID:[connection intValue] hdaWidget:&audioMixerWidget])
				continue;
			
			if (!pinComplexWidget.isAmpOut || audioMixerWidget.type != HDA_WIDGET_TYPE_MIXER)
				continue;
			
			audioMixerFound = true;
			
			break;
		}
		
		for (NSNumber *connection in audioMixerWidget.connections)
		{
			if (![HdaCodec getWidget:hdaCodec.widgets nodeID:[connection intValue] hdaWidget:&audioOutputWidget])
				continue;
			
			if (!audioOutputWidget.isAmpOut)
				continue;
			
			audioOutputFound = true;
			
			break;
		}
		
		if (audioMixerFound && audioOutputFound)
		{
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:pinComplexWidget];
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:audioMixerWidget];
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:audioOutputWidget];
			
			NSLog(@"Output 0x%02X->0x%02X->0x%02X", pinComplexWidget.nodeID, audioMixerWidget.nodeID, audioOutputWidget.nodeID);
		}
		else if (audioOutputFound)
		{
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:pinComplexWidget];
			[HdaCodec addNodeToPlatformXml:chain0 hdaWidget:audioOutputWidget];
			
			NSLog(@"Output 0x%02X->0x%02X", pinComplexWidget.nodeID, audioOutputWidget.nodeID);
		}
		//else
		//	NSLog(@"Output 0x%02X (Error!)", pinComplexWidget.nodeID);
	}
	
	NSString *folder = [NSString stringWithFormat:@"DumpXML_%@", hdaCodec.name];
	NSArray *dirPath = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
	NSString *dir = [dirPath objectAtIndex:0];
	NSString *fullPath = [dir stringByAppendingPathComponent:folder];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath])
		[[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:NO attributes:nil error:nil];
	
	fullPath = [fullPath stringByAppendingFormat:@"/Platforms.xml"];
	[root writeToFile: fullPath atomically:YES];
	
	[pathMap release];
	[pathMaps release];
	[commonPeripheralDSP release];
	[root release];
}

@end

