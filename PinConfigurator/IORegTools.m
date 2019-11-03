//
//  IORegTools.m
//  Hackintool
//
//  Created by Ben Baker on 1/29/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#include "IORegTools.h"
#include "MiscTools.h"
#include "AudioDevice.h"
#include <IOKit/IOKitLib.h>

bool getIORegChild(io_service_t device, NSString *name, io_service_t *foundDevice, bool recursive)
{
	kern_return_t kr;
	io_iterator_t childIterator;
	
	kr = IORegistryEntryGetChildIterator(device, kIOServicePlane, &childIterator);
	
	if (kr != KERN_SUCCESS)
		return false;
	
	for (io_service_t childDevice; IOIteratorIsValid(childIterator) && (childDevice = IOIteratorNext(childIterator)); IOObjectRelease(childDevice))
	{
		if (IOObjectConformsTo(childDevice, [name UTF8String]))
		{
			*foundDevice = childDevice;
			
			IOObjectRelease(childIterator);
			
			return true;
		}
		
		if (recursive)
		{
			if (getIORegChild(childDevice, name, foundDevice, recursive))
				return true;
		}
	}
	
	return false;
}

bool getIORegParent(io_service_t device, NSString *name, io_service_t *foundDevice, bool recursive)
{
	kern_return_t kr;
	io_iterator_t parentIterator;
	
	kr = IORegistryEntryGetParentIterator(device, kIOServicePlane, &parentIterator);
	
	if (kr != KERN_SUCCESS)
		return false;
	
	for (io_service_t parentDevice; IOIteratorIsValid(parentIterator) && (parentDevice = IOIteratorNext(parentIterator)); IOObjectRelease(parentDevice))
	{
		if (IOObjectConformsTo(parentDevice, [name UTF8String]))
		{
			*foundDevice = parentDevice;
			
			IOObjectRelease(parentIterator);
			
			return true;
		}
		
		if (recursive)
		{
			if (getIORegParent(parentDevice, name, foundDevice, recursive))
				return true;
		}
	}
	
	return false;
}

bool getIORegAudioDeviceArray(NSMutableArray **audioDeviceArray)
{
	*audioDeviceArray = [[NSMutableArray array] retain];
	io_iterator_t iterator;
	
	kern_return_t kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHDACodecDevice"), &iterator);
	
	if (kr != KERN_SUCCESS)
		return false;
	
	for (io_service_t device; IOIteratorIsValid(iterator) && (device = IOIteratorNext(iterator)); IOObjectRelease(device))
	{
		io_name_t name {};
		kr = IORegistryEntryGetName(device, name);
		
		if (kr != KERN_SUCCESS)
			continue;
		
		io_name_t className {};
		kr = IOObjectGetClass(device, className);
		
		if (kr != KERN_SUCCESS)
			continue;
		
		io_service_t parentDevice;
		
		if (getIORegParent(device, @"IOPCIDevice", &parentDevice, true))
		{
			io_name_t parentName {};
			kr = IORegistryEntryGetName(parentDevice, parentName);
			
			if (kr == KERN_SUCCESS)
			{
				CFMutableDictionaryRef parentPropertyDictionaryRef = 0;
				
				kr = IORegistryEntryCreateCFProperties(parentDevice, &parentPropertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
				
				if (kr == KERN_SUCCESS)
				{
					NSMutableDictionary *parentPropertyDictionary = (__bridge NSMutableDictionary *)parentPropertyDictionaryRef;
					
					CFMutableDictionaryRef propertyDictionaryRef = 0;
					
					kr = IORegistryEntryCreateCFProperties(device, &propertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
					
					if (kr == KERN_SUCCESS)
					{
						NSMutableDictionary *propertyDictionary = (__bridge NSMutableDictionary *)propertyDictionaryRef;
						
						NSData *deviceID = [parentPropertyDictionary objectForKey:@"device-id"];
						NSData *vendorID = [parentPropertyDictionary objectForKey:@"vendor-id"];
						NSData *revisionID = [parentPropertyDictionary objectForKey:@"revision-id"];
						NSData *alcLayoutID = [parentPropertyDictionary objectForKey:@"alc-layout-id"];
						NSData *subSystemID = [parentPropertyDictionary objectForKey:@"subsystem-id"];
						NSData *subSystemVendorID = [parentPropertyDictionary objectForKey:@"subsystem-vendor-id"];
						NSData *pinConfigurations = [parentPropertyDictionary objectForKey:@"PinConfigurations"];
						
						NSDictionary *digitalAudioCapabilities = [propertyDictionary objectForKey:@"DigitalAudioCapabilities"];
						NSNumber *codecAddressNumber = [propertyDictionary objectForKey:@"IOHDACodecAddress"];
						NSNumber *venderProductIDNumber = [propertyDictionary objectForKey:@"IOHDACodecVendorID"];
						NSNumber *revisionIDNumber = [propertyDictionary objectForKey:@"IOHDACodecRevisionID"];
						
						uint32_t deviceIDInt = getUInt32FromData(deviceID);
						uint32_t vendorIDInt = getUInt32FromData(vendorID);
						uint32_t revisionIDInt = getUInt32FromData(revisionID);
						uint32_t alcLayoutIDInt = getUInt32FromData(alcLayoutID);
						uint32_t subSystemIDInt = getUInt32FromData(subSystemID);
						uint32_t subSystemVendorIDInt = getUInt32FromData(subSystemVendorID);
						
						uint32_t deviceIDNew = (vendorIDInt << 16) | deviceIDInt;
						uint32_t subDeviceIDNew = (subSystemVendorIDInt << 16) | subSystemIDInt;
						
						AudioDevice *audioDevice = [[AudioDevice alloc] initWithDeviceClass:[NSString stringWithUTF8String:parentName] deviceID:deviceIDNew revisionID:revisionIDInt alcLayoutID:alcLayoutIDInt subDeviceID:subDeviceIDNew codecAddress:[codecAddressNumber unsignedIntValue] codecID:[venderProductIDNumber unsignedIntValue] codecRevisionID:[revisionIDNumber unsignedIntValue] pinConfigurations:pinConfigurations digitalAudioCapabilities:digitalAudioCapabilities];
						
						[*audioDeviceArray addObject:audioDevice];
						
						io_service_t childDevice;
						
						if (getIORegChild(device, @"AppleHDACodec", &childDevice, true))
						{
							io_name_t childName {};
							kr = IORegistryEntryGetName(childDevice, childName);
							
							if (kr == KERN_SUCCESS)
							{
								CFMutableDictionaryRef childPropertyDictionaryRef = 0;
								
								kr = IORegistryEntryCreateCFProperties(childDevice, &childPropertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
								
								if (kr == KERN_SUCCESS)
								{
									// +-o AppleHDACodecGeneric  <class AppleHDACodecGeneric, id 0x10000044d, registered, matched, active, busy 0 (14 ms), retain 6>
									//   | {
									//   |   "IOProbeScore" = 1
									//   |   "CFBundleIdentifier" = "com.apple.driver.AppleHDA"
									//   |   "IOProviderClass" = "IOHDACodecFunction"
									//   |   "IOClass" = "AppleHDACodecGeneric"
									//   |   "IOMatchCategory" = "IODefaultMatchCategory"
									//   |   "alc-pinconfig-status" = Yes
									//   |   "vendorcodecID" = 282984514
									//   |   "alc-sleep-status" = No
									//   |   "HDMIDPAudioCapabilities" = Yes
									//   |   "IOHDACodecFunctionGroupType" = 1
									//   |   "HDAConfigDefault" = ({"AFGLowPowerState"=<03000000>,"CodecID"=283904146,"Comment"="ALC892, Toleda","ConfigData"=<01470c02>,"FuncGroup"=1,"BootConfigData"=<21471c1021471d4021471e1121471f9021470c0221571c2021571d1021571e0121571f0121671c3021671d6021671e0121671f0121771cf021771d0021771e0021771f4021871c4021871d9021871ea021871f9021971c6021971d9021971e8121971f0221a71c5021a71d3021a71e8121a71f0121b71c7021b71d4021b71e2121b71f0221b70c0221e71c9021e71d6121e71e4b21e71f0121f71cf021f71d0021f71e0021f71f4021171cf021171d0021171e0021171f40>,"WakeVerbReinit"=Yes,"LayoutID"=7})
									//   | }
									
									NSMutableDictionary *childPropertyDictionary = (__bridge NSMutableDictionary *)childPropertyDictionaryRef;
									audioDevice.hdaConfigDefaultDictionary = [childPropertyDictionary objectForKey:@"HDAConfigDefault"];
									audioDevice.bundleID = [childPropertyDictionary objectForKey:@"CFBundleIdentifier"];
								}
							}
						}
						
						[audioDevice release];
					}
				}
			}
			
			IOObjectRelease(parentDevice);
		}
	}
	
	IOObjectRelease(iterator);
	
	return ([*audioDeviceArray count] > 0);
}
