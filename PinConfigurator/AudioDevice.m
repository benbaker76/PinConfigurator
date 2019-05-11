//
//  AudioDevice.m
//  Hackintool
//
//  Created by Ben Baker on 2/12/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#import "AudioDevice.h"

@implementation AudioDevice

-(id) initWithDeviceClass:(NSString *)deviceClass deviceID:(uint32_t)deviceID revisionID:(uint32_t)revisionID alcLayoutID:(uint32_t)alcLayoutID subDeviceID:(uint32_t)subDeviceID codecAddress:(uint32_t)codecAddress codecID:(uint32_t)codecID codecRevisionID:(uint32_t)codecRevisionID pinConfigurations:(NSData *)pinConfigurations digitalAudioCapabilities:(NSDictionary *)digitalAudioCapabilities
{
	if (self = [super init])
	{
		self.deviceClass = deviceClass;
		self.deviceID = deviceID;
		self.revisionID = revisionID;
		self.alcLayoutID = alcLayoutID;
		self.subDeviceID = subDeviceID;
		self.codecAddress = codecAddress;
		self.codecID = codecID;
		self.codecRevisionID = codecRevisionID;
		self.pinConfigurations = pinConfigurations;
		self.digitalAudioCapabilities = digitalAudioCapabilities;
	}
	
	return self;
}

- (void)dealloc
{
	[_deviceClass release];
	[_pinConfigurations release];
	[_digitalAudioCapabilities release];
	[_codecName release];
	[_layoutIDArray release];
	[_revisionArray release];
	[_hdaConfigDefaultDictionary release];
	
	[super dealloc];
}

@end
