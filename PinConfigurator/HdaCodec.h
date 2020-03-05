//
//  HdaCodec.h
//  PinConfigurator
//
//  Created by Ben Baker on 2/16/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#ifndef HdaCodec_h
#define HdaCodec_h

#import <Cocoa/Cocoa.h>
#import <stdint.h>

#define HDA_PARSE_MAXDEPTH	10
#define HDA_MAX_CONNS		32
#define HDA_MAX_NAMELEN		32

@interface HdaWidget : NSObject
{
}

- (id)initWithNodeID:(uint8_t)nodeID;
- (NSString *)typeString;
- (uint32_t)type;
- (BOOL)isStereo;
- (BOOL)isDigital;
- (BOOL)isAmpIn;
- (BOOL)isAmpOut;
- (BOOL)isLRSwap;
- (BOOL) hasConnectionList;
- (NSString *)defaultPortConnectionString;
- (uint32_t)defaultPortConnection;
- (NSString *)defaultDeviceString;
- (uint32_t)defaultDevice;
- (NSString *)defaultSurfaceString;
- (uint32_t)defaultSurface;
- (NSString *)defaultLocationString;
- (uint32_t)defaultLocation;
- (NSString *)defaultConnectionTypeString;
- (uint32_t)defaultConnectionType;
- (NSString *)defaultColorString;
- (uint32_t)defaultColor;
- (uint8_t)defaultAssociation;
- (uint8_t)defaultSequence;
- (NSString *)capabilitiesString;
- (NSString *)controlString;
- (NSString *)eapdString;
- (BOOL) hasImpendance;
- (BOOL) hasTrigger;
- (BOOL) hasPresence;
- (BOOL) hasHeadphone;
- (BOOL) hasOutput;
- (BOOL) hasInput;
- (BOOL) hasBalanced;
- (BOOL) hasHDMI;
- (BOOL) hasEAPD;
- (BOOL) hasDisplayPort;
- (BOOL) hasHBR;
- (BOOL) isInputDevice;
- (BOOL) isOutputDevice;
- (BOOL) isEnabled;
- (void) dealloc;

@property uint8_t nodeID;
@property (retain) NSString *name;
@property uint32_t capabilities;
@property uint8_t defaultUnSol;
@property uint8_t defaultEapd;
@property (retain) NSMutableArray *connections;
@property uint32_t supportedPowerStates;
@property uint32_t defaultPowerState;
@property uint32_t ampInCapabilities;
@property uint32_t ampOutCapabilities;
@property (retain) NSMutableArray *ampInLeftDefaultGainMute;
@property (retain) NSMutableArray *ampInRightDefaultGainMute;
@property uint8_t ampOutLeftDefaultGainMute;
@property uint8_t ampOutRightDefaultGainMute;
@property uint32_t supportedPcmRates;
@property uint32_t supportedFormats;
@property uint16_t defaultConvFormat;
@property uint8_t defaultConvStreamChannel;
@property uint8_t defaultConvChannelCount;
@property uint32_t pinCapabilities;
@property uint8_t defaultPinControl;
@property uint32_t defaultConfiguration;
@property uint32_t volumeCapabilities;
@property uint8_t defaultVolume;
@property uint32_t bindAssoc;
@property uint32_t bindSeqMask;
@property uint8_t connectionSelect;

@end

@interface HdaCodec : NSObject
{
}

- (id) initWithName:(NSString *)name audioFuncID:(uint32_t)audioFuncID unsol:(uint32_t)unsol vendorID:(uint32_t)vendorID revisionID:(uint32_t)revisionID rates:(uint32_t)rates formats:(uint32_t)formats ampInCaps:(uint32_t)ampInCaps ampOutCaps:(uint32_t)ampOutCaps;
- (void) dealloc;
- (NSString *) sampleRatesString;
- (NSString *) bitRatesString;
- (NSString *) streamFormatString;
- (NSString *) ampCapsString:(uint32_t)ampCaps;
- (NSMutableString *)codecString;
+ (bool)getHdaCodecArray_Linux:(NSString *)hdaCodecString hdaCodecArray:(NSMutableArray **)hdaCodecArray;
+ (bool)parseHdaCodecString_Linux:(NSString *)hdaCodecString index:(uint32_t)index hdaCodec:(HdaCodec *)hdaCodec;
+ (uint32_t)parseHdaCodecString:(NSString *)hdaCodecString index:(uint32_t)index hdaCodec:(HdaCodec **)hdaCodec hdaCodecArray:(NSMutableArray **)hdaCodecArray;
+ (bool)parseHdaCodecData:(uint8_t *)hdaCodecData length:(uint32_t)length hdaCodec:(HdaCodec **)hdaCodec;
+ (bool)getWidget:(NSArray *)widgets nodeID:(uint8_t)nodeID hdaWidget:(HdaWidget **)hdaWidget;
+ (void)createPlatformsXml:(HdaCodec *)hdaCodec;

@property (retain) NSString *name;
@property uint32_t address;
@property uint32_t audioFuncID;
@property uint32_t unsol;
@property uint32_t vendorID;
@property uint32_t revisionID;
@property uint32_t rates;
@property uint32_t formats;
@property uint32_t ampInCaps;
@property uint32_t ampOutCaps;
@property (retain) NSMutableArray *widgets;

@end

#endif /* HdaCodec_h */
