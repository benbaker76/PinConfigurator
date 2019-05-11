//
//  MiscTools.m
//  Hackintool
//
//  Created by Ben Baker on 1/29/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#include "MiscTools.h"

NSData *stringToData(NSString *dataString, int size)
{
	NSString *hexChars = @"0123456789abcdefABCDEF";
	NSCharacterSet *hexCharSet = [NSCharacterSet characterSetWithCharactersInString:hexChars];
	NSCharacterSet *invalidHexCharSet = [hexCharSet invertedSet];
	NSString *cleanDataString = [dataString stringByReplacingOccurrencesOfString:@"0x" withString:@""];
	cleanDataString = [[cleanDataString componentsSeparatedByCharactersInSet:invalidHexCharSet] componentsJoinedByString:@""];
	
	NSMutableData *result = [[NSMutableData alloc] init];
	
	for (int i = 0; i + size <= cleanDataString.length; i += size)
	{
		NSRange range = NSMakeRange(i, size);
		NSString *hexString = [cleanDataString substringWithRange:range];
		NSScanner *scanner = [NSScanner scannerWithString:hexString];
		unsigned int intValue;
		[scanner scanHexInt:&intValue];
		unsigned char uc = (unsigned char)intValue;
		[result appendBytes:&uc length:1];
	}
	
	NSData *resultData = [NSData dataWithData:result];
	[result release];
	
	return resultData;
}

NSData *stringToData(NSString *dataString)
{
	return stringToData(dataString, 2);
}

uint32_t getReverseBytes(uint32_t value)
{
	return ((value >> 24) & 0xFF) | ((value << 8) & 0xFF0000) | ((value >> 8) & 0xFF00) | ((value << 24) & 0xFF000000);
}

NSData *getReverseData(NSData *data)
{
	const char *bytes = (const char *)[data bytes];
	int idx = (int)[data length] - 1;
	char *reversedBytes = (char *)calloc(sizeof(char), [data length]);
	
	for (int i = 0; i < [data length]; i++)
		reversedBytes[idx--] = bytes[i];
	
	NSData *reversedData = [NSData dataWithBytes:reversedBytes length:[data length]];
	free(reversedBytes);
	
	return reversedData;
}

NSData *getNSDataUInt32(uint32_t uint32Value, bool reverseBytes)
{
	NSData *data = [NSData dataWithBytes:&uint32Value length:sizeof(uint32Value)];

	if (reverseBytes)
		return getReverseData(data);
	
	return data;
}

NSData *getNSDataUInt32(uint32_t uint32Value)
{
	return getNSDataUInt32(uint32Value, false);
}

uint32_t getUInt32FromData(NSData *data)
{
	if (data == nil)
		return 0;
	
	if ([data length] != 4)
		return 0;
	
	return *(const uint32_t *)[data bytes];
}

bool getRegExArray(NSString *regExPattern, NSString *valueString, uint32_t itemCount, NSMutableArray **itemArray)
{
	NSError *regError = nil;
	NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:&regError];
	
	if (regError)
		return false;
	
	NSTextCheckingResult *match = [regEx firstMatchInString:valueString options:0 range:NSMakeRange(0, [valueString length])];
	
	if (match == nil || [match numberOfRanges] != itemCount + 1)
		return false;
	
	*itemArray = [NSMutableArray array];
	
	for (int i = 1; i < match.numberOfRanges; i++)
		[*itemArray addObject:[valueString substringWithRange:[match rangeAtIndex:i]]];
	
	return true;
}

uint32_t getInt(NSString *valueString)
{
	uint32_t value;
	
	NSScanner *scanner = [NSScanner scannerWithString:valueString];
	[scanner scanInt:(int *)&value];
	
	return value;
}

uint32_t getHexInt(NSString *valueString)
{
	uint32_t value;
	
	NSScanner *scanner = [NSScanner scannerWithString:valueString];
	[scanner scanHexInt:&value];
	
	return value;
}
