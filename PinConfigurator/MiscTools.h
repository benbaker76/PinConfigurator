//
//  MiscTools.h
//  Hackintool
//
//  Created by Ben Baker on 1/29/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#ifndef MiscTools_h
#define MiscTools_h

#import <Cocoa/Cocoa.h>

NSData *stringToData(NSString *dataString, int size);
NSData *stringToData(NSString *dataString);
uint32_t getReverseBytes(uint32_t value);
NSData *getReverseData(NSData *data);
NSData *getNSDataUInt32(uint32_t uint32Value, bool reverseBytes);
NSData *getNSDataUInt32(uint32_t uint32Value);
uint32_t getUInt32FromData(NSData *data);
bool getRegExArray(NSString *regExPattern, NSString *valueString, uint32_t itemCount, NSMutableArray **itemArray);
uint32_t getInt(NSString *valueString);
uint32_t getHexInt(NSString *valueString);

#endif /* MiscTools_hpp */
