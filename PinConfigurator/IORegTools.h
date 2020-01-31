//
//  IORegTools.h
//  Hackintool
//
//  Created by Ben Baker on 1/29/19.
//  Copyright © 2019 Ben Baker. All rights reserved.
//

#ifndef IORegTools_h
#define IORegTools_h

#import <Cocoa/Cocoa.h>

uint32_t propertyToUInt32(id value);
bool getIORegAudioDeviceArray(NSMutableArray **audioDeviceArray);

#endif /* IORegTools_hpp */
