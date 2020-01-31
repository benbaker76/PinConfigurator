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

uint32_t propertyToUInt32(id value)
{
	if (value == nil)
		return 0;
	
	if ([value isKindOfClass:[NSNumber class]])
		return [value unsignedIntValue];
	else if ([value isKindOfClass:[NSData class]])
	{
		NSData *data = (NSData *)value;
		uint32_t retVal = 0;
		
		memcpy(&retVal, data.bytes, MIN(data.length, 4));
		
		return retVal;
	}
	
	return 0;
}

bool getIORegAudioDeviceArray(NSMutableArray **audioDeviceArray)
{
	*audioDeviceArray = [[NSMutableArray array] retain];
	io_iterator_t iterator;
	
	kern_return_t kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOAudioDevice"), &iterator);
	
	if (kr != KERN_SUCCESS)
		return false;
	
	for (io_service_t device; IOIteratorIsValid(iterator) && (device = IOIteratorNext(iterator)); IOObjectRelease(device))
	{
		io_name_t className {};
		kr = IOObjectGetClass(device, className);
		
		if (kr != KERN_SUCCESS)
			continue;
		
		CFMutableDictionaryRef propertyDictionaryRef = 0;
		
		kr = IORegistryEntryCreateCFProperties(device, &propertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
		
		if (kr == KERN_SUCCESS)
		{
			NSMutableDictionary *propertyDictionary = (__bridge NSMutableDictionary *)propertyDictionaryRef;
			
			io_service_t parentDevice;
			
			if (getIORegParent(device, @"IOPCIDevice", &parentDevice, true))
			{
				CFMutableDictionaryRef parentPropertyDictionaryRef = 0;
				
				kr = IORegistryEntryCreateCFProperties(parentDevice, &parentPropertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
				
				if (kr == KERN_SUCCESS)
				{
					NSMutableDictionary *parentPropertyDictionary = (__bridge NSMutableDictionary *)parentPropertyDictionaryRef;
					
					NSString *bundleID = [propertyDictionary objectForKey:@"CFBundleIdentifier"];
					uint32_t deviceID = propertyToUInt32([parentPropertyDictionary objectForKey:@"device-id"]);
					uint32_t vendorID = propertyToUInt32([parentPropertyDictionary objectForKey:@"vendor-id"]);
					uint32_t revisionID = propertyToUInt32([parentPropertyDictionary objectForKey:@"revision-id"]);
					uint32_t alcLayoutID = propertyToUInt32([parentPropertyDictionary objectForKey:@"alc-layout-id"]);
					uint32_t subSystemID = propertyToUInt32([parentPropertyDictionary objectForKey:@"subsystem-id"]);
					uint32_t subSystemVendorID = propertyToUInt32([parentPropertyDictionary objectForKey:@"subsystem-vendor-id"]);
					NSData *pinConfigurations = [parentPropertyDictionary objectForKey:@"PinConfigurations"];
					
					uint32_t deviceIDNew = (vendorID << 16) | deviceID;
					uint32_t subDeviceIDNew = (subSystemVendorID << 16) | subSystemID;
					
					AudioDevice *audioDevice = [[AudioDevice alloc] initWithDeviceBundleID:bundleID deviceClass:[NSString stringWithUTF8String:className] deviceID:deviceIDNew revisionID:revisionID alcLayoutID:alcLayoutID subDeviceID:subDeviceIDNew pinConfigurations:pinConfigurations];
					
					io_service_t codecDevice;
					
					if (getIORegParent(device, @"IOHDACodecDevice", &codecDevice, true))
					{
						CFMutableDictionaryRef codecPropertyDictionaryRef = 0;
						
						kr = IORegistryEntryCreateCFProperties(codecDevice, &codecPropertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
						
						if (kr == KERN_SUCCESS)
						{
							NSMutableDictionary *codecPropertyDictionary = (__bridge NSMutableDictionary *)codecPropertyDictionaryRef;
							
							audioDevice.digitalAudioCapabilities = [codecPropertyDictionary objectForKey:@"DigitalAudioCapabilities"];
							audioDevice.codecAddress = propertyToUInt32([codecPropertyDictionary objectForKey:@"IOHDACodecAddress"]);
							audioDevice.codecID = propertyToUInt32([codecPropertyDictionary objectForKey:@"IOHDACodecVendorID"]);
							audioDevice.revisionID = propertyToUInt32([codecPropertyDictionary objectForKey:@"IOHDACodecRevisionID"]);
						}
					}
					
					[*audioDeviceArray addObject:audioDevice];
					
					[audioDevice release];
				}
				
				IOObjectRelease(parentDevice);
			}
		}
	}
	
	IOObjectRelease(iterator);
	
	return ([*audioDeviceArray count] > 0);
}
