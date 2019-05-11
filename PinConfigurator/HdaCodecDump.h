/*
 * File: HdaCodecDump.h
 *
 * Copyright (c) 2018 John Davis
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef _EFI_HDA_CODEC_DUMP_H_
#define _EFI_HDA_CODEC_DUMP_H_

#import <Cocoa/Cocoa.h>
#include "HdaVerbs.h"
#include <stdio.h>
#include <wchar.h>

#define HDA_MAX_CONNS		32
#define HDA_MAX_NAMELEN		32

typedef struct {
	uint8_t NodeId;
	uint8_t Type;
	uint32_t Capabilities;
	uint8_t DefaultUnSol;
	uint32_t ConnectionListLength;
	uint8_t ConnectionSelect;
	uint16_t Connections[HDA_MAX_CONNS];
	uint32_t SupportedPowerStates;
	uint32_t DefaultPowerState;
	uint8_t AmpOverride;
	uint32_t AmpInCapabilities;
	uint32_t AmpOutCapabilities;
	uint8_t AmpInLeftDefaultGainMute[HDA_MAX_CONNS];
	uint8_t AmpInRightDefaultGainMute[HDA_MAX_CONNS];
	uint8_t AmpOutLeftDefaultGainMute;
	uint8_t AmpOutRightDefaultGainMute;
	uint32_t SupportedPcmRates;
	uint32_t SupportedFormats;
	uint16_t DefaultConvFormat;
	uint8_t DefaultConvStreamChannel;
	uint8_t DefaultConvChannelCount;
	uint32_t PinCapabilities;
	uint8_t DefaultEapd;
	uint8_t DefaultPinControl;
	uint32_t DefaultConfiguration;
	uint32_t VolumeCapabilities;
	uint8_t DefaultVolume;
} HdaWidgetEntry;

typedef struct {
	uint8_t Header[4];
	uint8_t Name[HDA_MAX_NAMELEN];
	uint8_t CodecAddress;
	uint8_t AudioFuncID;
	uint8_t Unsol;
	uint32_t VendorID;
	uint32_t RevisionID;
	uint32_t Rates;
	uint32_t Formats;
	uint32_t AmpInCaps;
	uint32_t AmpOutCaps;
	uint32_t WidgetCount;
} HdaCodecEntry;

int HdaCodecDump(uint8_t *hdaCodecData, uint32_t length, NSMutableString **outputString);

#endif
