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

bool getIORegChild(io_service_t device, NSArray *nameArray, io_service_t *foundDevice, uint32_t *foundIndex, bool recursive)
{
	io_iterator_t childIterator;
	kern_return_t kr = IORegistryEntryCreateIterator(device, kIOServicePlane, (recursive ? kIORegistryIterateRecursively : 0), &childIterator);
	
	if (kr != KERN_SUCCESS)
		return false;
	
	for (io_service_t childDevice; IOIteratorIsValid(childIterator) && (childDevice = IOIteratorNext(childIterator)); IOObjectRelease(childDevice))
	{
		for (int i = 0; i < [nameArray count]; i++)
		{
			if (IOObjectConformsTo(childDevice, [[nameArray objectAtIndex:i] UTF8String]))
			{
				*foundDevice = childDevice;
				*foundIndex = i;
				
				IOObjectRelease(childIterator);
				
				return true;
			}
		}
	}
	
	return false;
}

bool getIORegParent(io_service_t device, NSString *name, io_service_t *foundDevice, bool recursive)
{
	io_iterator_t parentIterator;
	kern_return_t kr = IORegistryEntryCreateIterator(device, kIOServicePlane, (recursive ? kIORegistryIterateRecursively : 0) | kIORegistryIterateParents, &parentIterator);
	
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
	io_iterator_t pciIterator;
	
	kern_return_t kr = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOPCIDevice"), &pciIterator);
	
	if (kr != KERN_SUCCESS)
		return false;
	
	io_iterator_t iterator;
	
	for (io_service_t pciDevice; IOIteratorIsValid(pciIterator) && (pciDevice = IOIteratorNext(pciIterator)); IOObjectRelease(pciDevice))
	{
		kern_return_t kr = IORegistryEntryCreateIterator(pciDevice, kIOServicePlane, kIORegistryIterateRecursively, &iterator);
		
		if (kr != KERN_SUCCESS)
			continue;
		
		for (io_service_t device; IOIteratorIsValid(iterator) && (device = IOIteratorNext(iterator)); IOObjectRelease(device))
		{
			if (IOObjectConformsTo(device, "IOPCIDevice"))
			{
				IOObjectRelease(iterator);
				IOObjectRelease(device);
				break;
			}
			
			if (!IOObjectConformsTo(device, "IOAudioDevice"))
				continue;
			
			io_name_t className {};
			kr = IOObjectGetClass(device, className);
			
			if (kr != KERN_SUCCESS)
				continue;
			
			CFMutableDictionaryRef propertyDictionaryRef = 0;
			
			kr = IORegistryEntryCreateCFProperties(device, &propertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
			
			if (kr == KERN_SUCCESS)
			{
				NSMutableDictionary *propertyDictionary = (__bridge NSMutableDictionary *)propertyDictionaryRef;
				
				NSString *bundleID = [propertyDictionary objectForKey:@"CFBundleIdentifier"];
				NSString *audioDeviceName = [propertyDictionary objectForKey:@"IOAudioDeviceName"];
				NSString *audioDeviceModelID = [propertyDictionary objectForKey:@"IOAudioDeviceModelID"];
				NSString *audioDeviceManufacturerName = [propertyDictionary objectForKey:@"IOAudioDeviceManufacturerName"];
				uint32_t audioDeviceDeviceID = 0, audioDeviceVendorID = 0;
				uint32_t audioDeviceDeviceIDNew = 0;
				
				if (audioDeviceModelID != nil)
				{
					NSArray *modelIDArray = [audioDeviceModelID componentsSeparatedByString:@":"];
					
					if ([modelIDArray count] == 3)
					{
						NSScanner *deviceIDScanner = [NSScanner scannerWithString:[modelIDArray objectAtIndex:1]];
						NSScanner *productIDScanner = [NSScanner scannerWithString:[modelIDArray objectAtIndex:2]];

						[deviceIDScanner setScanLocation:0];
						[deviceIDScanner scanHexInt:&audioDeviceVendorID];
													   
						[productIDScanner setScanLocation:0];
						[productIDScanner scanHexInt:&audioDeviceDeviceID];
													   
						audioDeviceDeviceIDNew = (audioDeviceVendorID << 16) | audioDeviceDeviceID;
					}
				}
				
				io_service_t parentDevice;
					
				if (getIORegParent(device, @"IOPCIDevice", &parentDevice, true))
				{
					CFMutableDictionaryRef parentPropertyDictionaryRef = 0;
					
					kr = IORegistryEntryCreateCFProperties(parentDevice, &parentPropertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
					
					if (kr == KERN_SUCCESS)
					{
						NSMutableDictionary *parentPropertyDictionary = (__bridge NSMutableDictionary *)parentPropertyDictionaryRef;
						
						uint32_t deviceID = propertyToUInt32([parentPropertyDictionary objectForKey:@"device-id"]);
						uint32_t vendorID = propertyToUInt32([parentPropertyDictionary objectForKey:@"vendor-id"]);
						uint32_t revisionID = propertyToUInt32([parentPropertyDictionary objectForKey:@"revision-id"]);
						uint32_t alcLayoutID = propertyToUInt32([parentPropertyDictionary objectForKey:@"alc-layout-id"]);
						uint32_t subSystemID = propertyToUInt32([parentPropertyDictionary objectForKey:@"subsystem-id"]);
						uint32_t subSystemVendorID = propertyToUInt32([parentPropertyDictionary objectForKey:@"subsystem-vendor-id"]);
						
						uint32_t deviceIDNew = (vendorID << 16) | deviceID;
						uint32_t subDeviceIDNew = (subSystemVendorID << 16) | subSystemID;
						
						AudioDevice *audioDevice = [[AudioDevice alloc] initWithDeviceBundleID:bundleID deviceClass:[NSString stringWithUTF8String:className] audioDeviceName:audioDeviceName audioDeviceManufacturerName:audioDeviceManufacturerName audioDeviceModelID:audioDeviceDeviceIDNew deviceID:deviceIDNew revisionID:revisionID alcLayoutID:alcLayoutID subDeviceID:subDeviceIDNew];

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
						
						if (getIORegParent(device, @"AppleHDACodec", &codecDevice, true))
						{
							CFMutableDictionaryRef codecPropertyDictionaryRef = 0;
							
							kr = IORegistryEntryCreateCFProperties(codecDevice, &codecPropertyDictionaryRef, kCFAllocatorDefault, kNilOptions);
							
							if (kr == KERN_SUCCESS)
							{
								NSMutableDictionary *codecPropertyDictionary = (__bridge NSMutableDictionary *)codecPropertyDictionaryRef;
								
								NSArray *hdaConfigDefaultArray = [codecPropertyDictionary objectForKey:@"HDAConfigDefault"];
								
								if (hdaConfigDefaultArray != nil && [hdaConfigDefaultArray count] > 0)
									audioDevice.hdaConfigDefaultDictionary = [hdaConfigDefaultArray objectAtIndex:0];
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
	}
	
	IOObjectRelease(pciIterator);
	
	return ([*audioDeviceArray count] > 0);
}
