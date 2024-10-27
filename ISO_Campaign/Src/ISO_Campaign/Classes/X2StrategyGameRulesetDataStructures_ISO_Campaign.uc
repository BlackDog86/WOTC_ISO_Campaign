class X2StrategyGameRulesetDataStructures_ISO_Campaign extends X2StrategyGameRulesetDataStructures;

`include(ISO_Campaign\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static function GetTimeStringSeparated(TDateTime kDateTime, out string Hours, out string Minutes, out string Suffix)
{
	local int iHour;
	local bool bUse24hClock;

	bUse24hClock = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK);

	iHour = GetHour(kDateTime);

	// Over-ride 12/24h setting if bool is set
	if(!bUse24hClock)
	{
		// AM
		if( iHour < 12 )
		{
			if( iHour == 0 )
				iHour = 12;

			Suffix = default.m_sAM;
		}
		// PM
		else
		{
			if( iHour > 12 )
				iHour = iHour - 12;

			Suffix = default.m_sPM;
		}
	}
	else 
	{
		//iHour is a 24 hour time. 
		Suffix = "";
	}

	if( GetMinute(kDateTime) < 10 )
	{
		Minutes = "0"$GetMinute(kDateTime);
	}
	else
	{
		Minutes = string(GetMinute(kDateTime));
	}
	if( GetHour(kDateTime) < 10)
	{
		Hours = "0"$GetHour(kDateTime);
	}
	else
	{
		Hours = string(GetHour(kDateTime));
	}
}

static function string GetDateString(TDateTime kDateTime, optional bool bShortFormat = false)
{
	local XGParamTag kTag;
	local bool bEuroStyleDate;
	local string Lang;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	// this can happen in the editor/PIE
	if( kTag != none )
	{
		kTag.StrValue0 = GetMonthString(,,kDateTime);		
		kTag.StrValue2 = appendZeroes(kDateTime.m_iMonth);
		kTag.StrValue3 = appendZeroes(kDateTime.m_iDay);

		kTag.IntValue0 = kDateTime.m_iDay;
		kTag.IntValue1 = kDateTime.m_iYear;
		kTag.IntValue2 = kDateTime.m_iMonth;

		Lang = GetLanguage();

		kTag.StrValue1 = "/";
		/// HL-Docs: feature:EuroDateOverride; issue:1191; tags:
		/// Add config option to force Euro date style with INT localisation
		if  (Lang == "FRA" || Lang == "ITA" || Lang == "ESN" || class'CHHelpers'.default.bForceEuroDateStrings)
		{
			bEuroStyleDate = true;
		}

		if (Lang == "DEU" || Lang == "RUS" || Lang == "POL")
		{
			bEuroStyleDate = true;
			kTag.StrValue1 = ".";
		}

		if( Lang == "FRA" && kDateTime.m_iDay == 1 )
		{
			kTag.StrValue2 = "er";
		}
		else if ( Lang == "JPN" || Lang == "KOR" || Lang == "CHN" || Lang == "CHT" )
		{
			kTag.StrValue0 $= default.m_strDaySuffix;
			kTag.StrValue1 = default.m_strMonthSuffix;

			return String(kDateTime.m_iYear) $ default.m_strYearSuffix $ "  " $
				String( kDateTime.m_iMonth ) $ default.m_strMonthSuffix $ "  " $
				String(kDateTime.m_iDay) $ default.m_strDaySuffix;
		}

		if (bEuroStyleDate)
		{
			if (bShortFormat)
			{
				return `XEXPAND.ExpandString( default.m_strDayMonthYearShort );
			}
			else
			{
				return `XEXPAND.ExpandString( default.m_strDayMonthYearLong );
			}
		}
		else
		{
			if (bShortFormat)
			{
				return `XEXPAND.ExpandString( default.m_strMonthDayYearShort );
			}
			else
			{
				return `XEXPAND.ExpandString( default.m_strMonthDayYearLong );
			}
		}
	}
	else
	{
		return string('dateTime');
	}
}

static function string appendZeroes(int appendMe)
{
	if(appendMe < 10)
	{
	return 0 $ string(appendMe);
	}
	else
	{
	return string(appendMe);
	}
}