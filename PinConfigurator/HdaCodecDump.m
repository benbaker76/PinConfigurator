/*
 * File: HdaCodecDump.m
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

#include "HdaCodecDump.h"

void HdaCodecDumpPrintRatesFormats(NSMutableString *outputString, uint32_t rates, uint32_t formats) {
    // Print sample rates.
	[outputString appendFormat:@"    rates [0x%04X]:", (uint16_t)rates];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_8KHZ)
        [outputString appendFormat:@" 8000"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_11KHZ)
        [outputString appendFormat:@" 11025"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_16KHZ)
        [outputString appendFormat:@" 16000"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_22KHZ)
        [outputString appendFormat:@" 22050"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_32KHZ)
        [outputString appendFormat:@" 32000"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_44KHZ)
        [outputString appendFormat:@" 44100"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_48KHZ)
        [outputString appendFormat:@" 48000"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_88KHZ)
        [outputString appendFormat:@" 88200"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_96KHZ)
        [outputString appendFormat:@" 96000"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_176KHZ)
        [outputString appendFormat:@" 176400"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_192KHZ)
        [outputString appendFormat:@" 192000"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_384KHZ)
        [outputString appendFormat:@" 384000"];
    [outputString appendFormat:@"\n"];

    // Print bits.
    [outputString appendFormat:@"    bits [0x%04X]:", (uint16_t)(rates >> 16)];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_8BIT)
        [outputString appendFormat:@" 8"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_16BIT)
        [outputString appendFormat:@" 16"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_20BIT)
        [outputString appendFormat:@" 20"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_24BIT)
        [outputString appendFormat:@" 24"];
    if (rates & HDA_PARAMETER_SUPPORTED_PCM_SIZE_RATES_32BIT)
        [outputString appendFormat:@" 32"];
    [outputString appendFormat:@"\n"];

    // Print formats.
    [outputString appendFormat:@"    formats [0x%08X]:", formats];
    if (formats & HDA_PARAMETER_SUPPORTED_STREAM_FORMATS_PCM)
        [outputString appendFormat:@" PCM"];
    if (formats & HDA_PARAMETER_SUPPORTED_STREAM_FORMATS_FLOAT32)
        [outputString appendFormat:@" FLOAT32"];
    if (formats & HDA_PARAMETER_SUPPORTED_STREAM_FORMATS_AC3)
        [outputString appendFormat:@" AC3"];
    [outputString appendFormat:@"\n"];
}

void HdaCodecDumpPrintAmpCaps(NSMutableString *outputString, uint32_t ampCaps)
{
    if (ampCaps)
	{
        [outputString appendFormat:@"ofs=0x%02X, nsteps=0x%02X, stepsize=0x%02X, mute=%u\n",
            HDA_PARAMETER_AMP_CAPS_OFFSET(ampCaps), HDA_PARAMETER_AMP_CAPS_NUM_STEPS(ampCaps),
            HDA_PARAMETER_AMP_CAPS_STEP_SIZE(ampCaps), (ampCaps & HDA_PARAMETER_AMP_CAPS_MUTE) != 0];
    } else
        [outputString appendFormat:@"N/A\n"];
}

int HdaCodecDumpPrintWidgets(NSMutableString *outputString, uint8_t *pData, uint32_t widgetCount) {
	uint32_t totalWidgetSize = 0;
	HdaWidgetEntry *hdaWidgetEntry = (HdaWidgetEntry *)pData;
    // Print each widget.
    for (uint32_t w = 0; w < widgetCount; w++) {
        // Determine name of widget.
		NSArray *widgetNames = @[@"Audio Output", @"Audio Input", @"Audio Mixer",
								@"Audio Selector", @"Pin Complex", @"Power Widget",
								@"Volume Knob Widget", @"Beep Generator Widget",
								@"Reserved", @"Reserved", @"Reserved", @"Reserved",
								@"Reserved", @"Reserved", @"Reserved",
								@"Vendor Defined Widget"];

        // Print header and capabilities.
        [outputString appendFormat:@"Node 0x%02X [%@] wcaps 0x%08X:", hdaWidgetEntry->NodeId,
            widgetNames[HDA_PARAMETER_WIDGET_CAPS_TYPE(hdaWidgetEntry->Capabilities)], hdaWidgetEntry->Capabilities];
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_STEREO)
            [outputString appendFormat:@" Stereo"];
        else
            [outputString appendFormat:@" Mono"];
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_DIGITAL)
            [outputString appendFormat:@" Digital"];
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_IN_AMP)
            [outputString appendFormat:@" Amp-In"];
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_OUT_AMP)
            [outputString appendFormat:@" Amp-Out"];
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_L_R_SWAP)
            [outputString appendFormat:@" R/L"];
        [outputString appendFormat:@"\n"];

		uint32_t connectionListLength = HDA_PARAMETER_CONN_LIST_LENGTH_LEN(hdaWidgetEntry->ConnectionListLength);
		uint32_t ampInSize = 0;
		
        // Print input amp info.
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_IN_AMP) {
			uint8_t *pAmpIn = pData + sizeof(HdaWidgetEntry);
			ampInSize = (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_STEREO ? connectionListLength * 2 : connectionListLength);

			// Print caps.
            [outputString appendFormat:@"  Amp-In caps: "];
            HdaCodecDumpPrintAmpCaps(outputString, hdaWidgetEntry->AmpInCapabilities);

            // Print default values.
            [outputString appendFormat:@"  Amp-In vals:"];
            for (uint8_t i = 0; i < connectionListLength; i++)
			{
                if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_STEREO)
                    [outputString appendFormat:@" [0x%02X 0x%02X]", pAmpIn[i], pAmpIn[connectionListLength + i]];
                else
                    [outputString appendFormat:@" [0x%02X]", pAmpIn[i]];
            }
			
            [outputString appendFormat:@"\n"];
        }

        // Print output amp info.
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_OUT_AMP) {
            // Print caps.
            [outputString appendFormat:@"  Amp-Out caps: "];
            HdaCodecDumpPrintAmpCaps(outputString, hdaWidgetEntry->AmpOutCapabilities);

            // Print default values.
            [outputString appendFormat:@"  Amp-Out vals:"];
            if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_STEREO)
                [outputString appendFormat:@" [0x%02X 0x%02X]\n", hdaWidgetEntry->AmpOutLeftDefaultGainMute, hdaWidgetEntry->AmpOutRightDefaultGainMute];
            else
                [outputString appendFormat:@" [0x%02X]\n", hdaWidgetEntry->AmpOutLeftDefaultGainMute];
        }

        // Print pin complexe info.
        if (HDA_PARAMETER_WIDGET_CAPS_TYPE(hdaWidgetEntry->Capabilities) == HDA_WIDGET_TYPE_PIN_COMPLEX) {
            // Print pin capabilities.
            [outputString appendFormat:@"  Pincap 0x%08X:", hdaWidgetEntry->PinCapabilities];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_INPUT)
                [outputString appendFormat:@" IN"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_OUTPUT)
                [outputString appendFormat:@" OUT"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_HEADPHONE)
                [outputString appendFormat:@" HP"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_EAPD)
                [outputString appendFormat:@" EAPD"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_TRIGGER)
                [outputString appendFormat:@" Trigger"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_PRESENCE)
                [outputString appendFormat:@" Detect"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_HBR)
                [outputString appendFormat:@" HBR"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_HDMI)
                [outputString appendFormat:@" HDMI"];
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_DISPLAYPORT)
                [outputString appendFormat:@" DP"];
            [outputString appendFormat:@"\n"];

            // Print EAPD info.
            if (hdaWidgetEntry->PinCapabilities & HDA_PARAMETER_PIN_CAPS_EAPD) {
                [outputString appendFormat:@"  EAPD 0x%02X:", hdaWidgetEntry->DefaultEapd];
                if (hdaWidgetEntry->DefaultEapd & HDA_EAPD_BTL_ENABLE_BTL)
                    [outputString appendFormat:@" BTL"];
                if (hdaWidgetEntry->DefaultEapd & HDA_EAPD_BTL_ENABLE_EAPD)
                    [outputString appendFormat:@" EAPD"];
                if (hdaWidgetEntry->DefaultEapd & HDA_EAPD_BTL_ENABLE_L_R_SWAP)
                    [outputString appendFormat:@" R/L"];
                [outputString appendFormat:@"\n"];
            }

            // Create pin default names.
			NSArray *portConnectivities = @[@"Jack", @"None", @"Fixed", @"Int Jack"];
			NSArray *defaultDevices = @[@"Line Out", @"Speaker", @"HP Out", @"CD", @"SPDIF Out",
									   @"Digital Out", @"Modem Line", @"Modem Handset", @"Line In", @"Aux",
									   @"Mic", @"Telephone", @"SPDIF In", @"Digital In", @"Reserved", @"Other"];
			NSArray *surfaces = @[@"Ext", @"Int", @"Ext", @"Other"];
			NSArray *locations = @[@"N/A", @"Rear", @"Front", @"Left", @"Right", @"Top", @"Bottom", @"Special",
								   @"Special", @"Special", @"Reserved", @"Reserved", @"Reserved", @"Reserved"];
			NSArray *connTypes = @[@"Unknown", @"1/8", @"1/4", @"ATAPI", @"RCA", @"Optical", @"Digital",
								   @"Analog", @"Multi", @"XLR", @"RJ11", @"Combo", @"Other", @"Other", @"Other", @"Other"];
			NSArray *colors = @[@"Unknown", @"Black", @"Grey", @"Blue", @"Green", @"Red", @"Orange",
								@"Yellow", @"Purple", @"Pink", @"Reserved", @"Reserved", @"Reserved",
								@"Reserved", @"White", @"Other"];

            // Print pin default header.
            [outputString appendFormat:@"  Pin Default 0x%08X: [%@] %@ at %@ %@\n", hdaWidgetEntry->DefaultConfiguration,
                portConnectivities[HDA_VERB_GET_CONFIGURATION_DEFAULT_PORT_CONN(hdaWidgetEntry->DefaultConfiguration)],
                defaultDevices[HDA_VERB_GET_CONFIGURATION_DEFAULT_DEVICE(hdaWidgetEntry->DefaultConfiguration)],
                surfaces[HDA_VERB_GET_CONFIGURATION_DEFAULT_SURF(hdaWidgetEntry->DefaultConfiguration)],
				locations[HDA_VERB_GET_CONFIGURATION_DEFAULT_LOC(hdaWidgetEntry->DefaultConfiguration)]];

            // Print connection type and color.
            [outputString appendFormat:@"    Conn = %@, Color = %@\n",
                connTypes[HDA_VERB_GET_CONFIGURATION_DEFAULT_CONN_TYPE(hdaWidgetEntry->DefaultConfiguration)],
                colors[HDA_VERB_GET_CONFIGURATION_DEFAULT_COLOR(hdaWidgetEntry->DefaultConfiguration)]];

            // Print default association and sequence.
            [outputString appendFormat:@"    DefAssociation = 0x%1X, Sequence = 0x%1X\n",
                HDA_VERB_GET_CONFIGURATION_DEFAULT_ASSOCIATION(hdaWidgetEntry->DefaultConfiguration),
                HDA_VERB_GET_CONFIGURATION_DEFAULT_SEQUENCE(hdaWidgetEntry->DefaultConfiguration)];

            // Print default pin control.
            [outputString appendFormat:@"Pin-ctls: 0x%02X:", hdaWidgetEntry->DefaultPinControl];
            if (hdaWidgetEntry->DefaultPinControl & HDA_PIN_WIDGET_CONTROL_VREF_EN)
                [outputString appendFormat:@" VREF"];
            if (hdaWidgetEntry->DefaultPinControl & HDA_PIN_WIDGET_CONTROL_IN_EN)
                [outputString appendFormat:@" IN"];
            if (hdaWidgetEntry->DefaultPinControl & HDA_PIN_WIDGET_CONTROL_OUT_EN)
                [outputString appendFormat:@" OUT"];
            if (hdaWidgetEntry->DefaultPinControl & HDA_PIN_WIDGET_CONTROL_HP_EN)
                [outputString appendFormat:@" HP"];
            [outputString appendFormat:@"\n"];
        }
		
		uint32_t connectionListSize = 0;

        // Print connections.
        if (hdaWidgetEntry->Capabilities & HDA_PARAMETER_WIDGET_CAPS_CONN_LIST) {
			uint16_t *pConnections = (uint16_t *)(pData + sizeof(HdaWidgetEntry) + ampInSize);
			connectionListSize = connectionListLength * sizeof(uint16_t);
            [outputString appendFormat:@"  Connection: %u\n    ", connectionListLength];
            for (uint8_t i = 0; i < connectionListLength; i++)
                [outputString appendFormat:@" 0x%02X", pConnections[i]];
            [outputString appendFormat:@"\n"];
        }
		
		uint32_t widgetSize = sizeof(HdaWidgetEntry) + ampInSize + connectionListSize;

		pData += widgetSize;
		totalWidgetSize += widgetSize;

		hdaWidgetEntry = (HdaWidgetEntry *)pData;
    }
	
	return totalWidgetSize;
}

int HdaCodecDump(uint8_t *hdaCodecData, uint32_t length, NSMutableString **outputString)
{
	uint8_t *pHdaCodecData = hdaCodecData;
	
	if (length < sizeof(HdaCodecEntry))
		return 1;

	if (pHdaCodecData[0] != 'H' || pHdaCodecData[1] != 'D' || pHdaCodecData[2] != 'A')
		return 1;
	
	pHdaCodecData += 4;
	
	while ((pHdaCodecData - hdaCodecData) < length)
	{
		HdaCodecEntry *hdaCodecEntry = (HdaCodecEntry *)pHdaCodecData;
		uint32_t widgetCount = hdaCodecEntry->WidgetCount;

		[*outputString appendFormat:@"HdaCodecDump start\n"];
		[*outputString appendFormat:@"Codec: %s\n", hdaCodecEntry->Name];

		[*outputString appendFormat:@"AFG Function Id: 0x%02X (unsol %u)\n", hdaCodecEntry->AudioFuncID, hdaCodecEntry->Unsol];
		[*outputString appendFormat:@"Vendor ID: 0x%08X\n", hdaCodecEntry->VendorID];
		[*outputString appendFormat:@"Revision ID: 0x%08X\n", hdaCodecEntry->RevisionID];

		if ((hdaCodecEntry->Rates != 0) || (hdaCodecEntry->Formats != 0)) {
			[*outputString appendFormat:@"Default PCM:\n"];
			HdaCodecDumpPrintRatesFormats(*outputString, hdaCodecEntry->Rates, hdaCodecEntry->Formats);
		} else
			[*outputString appendFormat:@"Default PCM: N/A\n"];

		[*outputString appendFormat:@"Default Amp-In caps: "];
		HdaCodecDumpPrintAmpCaps(*outputString, hdaCodecEntry->AmpInCaps);
		[*outputString appendFormat:@"Default Amp-Out caps: "];
		HdaCodecDumpPrintAmpCaps(*outputString, hdaCodecEntry->AmpOutCaps);
		
		pHdaCodecData += sizeof(HdaCodecEntry);

		uint32_t widgetSize = HdaCodecDumpPrintWidgets(*outputString, pHdaCodecData, widgetCount);
		
		pHdaCodecData += widgetSize;
	}
	
	//printf("%s", [*outputString UTF8String]);
	
	return 0;
}
