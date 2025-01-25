//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_ISO_Campaign.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_ISO_Campaign extends X2DownloadableContentInfo;

`include(ISO_Campaign\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static event OnPostTemplatesCreated()
{
	class'CHHelpers'.default.bForce24hClock = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);	
	class'CHHelpers'.default.bForce24hClockLeadingZero = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK_ON_GEOSCAPE);
}

exec function PurgeRenamedSavesLibrary()
{
	class'SaveGameNamingManagerIndividual'.default.SaveNameDictInd.Length = 0;
}

exec function PurgedRenamedCampaignsLibrary()
{
	class'SaveGameNamingManagerCampaign'.default.SaveNameDict.Length = 0;
}
