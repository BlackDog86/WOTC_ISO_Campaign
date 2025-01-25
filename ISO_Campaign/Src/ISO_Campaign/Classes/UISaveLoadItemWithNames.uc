class UISaveLoadItemWithNames extends UISaveLoadGameListItem config(Game);

	//For Reference:
	//Descriptions Array - When we're in mission: (header length = 7)
	//6/13/2023										Descriptions[0]	- Save Date		
	//23:14											Descriptions[1] - Save Time
	//My Special Save Game 1						Descriptions[2] - Player Description (Typed) - OR - IRONMAN: Campaign XXX
	//Rescue VIP from ADVENT Vehicle				Descriptions[3] - Mission type (or geoscape)
	//Operation Massive Willy						Descriptions[4] - Mission Name (optional - may not exist in the array)
	//10/17/2035									Descriptions[5] - In-Game Date
	//11:41 PM ADVENT Patrol Area, Mexico City		Descriptions[6] - In-Game Time & Area

	//Descriptions Array - When we're on the geoscape (header length = 6)
	//6/13/2023										Descriptions[0]	- Save Date		
	//23:14											Descriptions[1] - Save Time
	//My Special Save Game 2						Descriptions[2] - Player Description (Typed)
	//Geoscape										Descriptions[3] - Mission type (or geoscape)
	//10/17/2035									Descriptions[4] - In-Game Date
	//11:41 PM										Descriptions[5] - In-Game Time & Area
var localized string m_RenameLabel;

`include(ISO_Campaign\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

simulated function UISaveLoadGameListItem InitSaveLoadItem(int listIndex, OnlineSaveGame save, bool bSaving, optional delegate<OnClickedDelegate> AcceptClickedDelegate, optional delegate<OnClickedDelegate> DeleteClickedDelegate, optional delegate<OnClickedDelegate> RenameClickedDelegate, optional delegate<OnMouseInDelegate> MouseInDelegate)
{
	local XComOnlineEventMgr OnlineEventMgr;

	OnlineEventMgr = `ONLINEEVENTMGR;
	`log("SaveLoadItem Inited: Save Filename:" @ save.Filename,,'BDLOG');
	`log("SaveLoadItem Inited: ID:" @ OnlineEventMgr.SaveNameToID(save.Filename),,'BDLOG');
	ID = OnlineEventMgr.SaveNameToID(save.Filename);
	InitPanel();
	Index = listIndex;

	SaveGame = save;
	bIsSaving = bSaving;

	SetY(135 * listIndex);
	ButtonBG = Spawn(class'UIPanel', self);
	ButtonBG.bIsNavigable = false;
	ButtonBG.bCascadeFocus = false;
	ButtonBG.InitPanel(ButtonBGLibID);

	//Navigator.HorizontalNavigation = true;
	
	AcceptButton = Spawn(class'UIButton', ButtonBG);
	AcceptButton.bIsNavigable = false;
	AcceptButton.InitButton('Button0', GetAcceptLabel(ID == -1), ID == -1 ? RenameClickedDelegate : AcceptClickedDelegate); 
	if (`ISCONTROLLERACTIVE)
	{
		AcceptButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		AcceptButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
		AcceptButton.SetVisible(bIsFocused);
	}
	AcceptButton.OnMouseEventDelegate = OnChildMouseEvent;

	DeleteButton = Spawn(class'UIButton', ButtonBG);
	DeleteButton.bIsNavigable = false;
	DeleteButton.InitButton('Button1', GetDeleteLabel(), DeleteClickedDelegate);
	if (`ISCONTROLLERACTIVE) 
	{
		DeleteButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		DeleteButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE); // bsg-jrebar (4.3.17): Unifying across platforms to X for delete
		DeleteButton.SetVisible(bIsFocused);
	}
	DeleteButton.OnMouseEventDelegate = OnChildMouseEvent;
	
	RenameButton = Spawn(class'UIButton', ButtonBG);
	RenameButton.bIsNavigable = false;
	RenameButton.InitButton('Button2', m_sRenameLabel, RenameClickedDelegate);
	RenameButton.OnMouseEventDelegate = OnChildMouseEvent;
	// RenameButton.Hide();

	if(bIsSaving && ID == -1)
	{
		DeleteButton.Hide();
		RenameButton.Hide();
	}

	OnMouseIn = MouseInDelegate;

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	UpdateDataWithNames(SaveGame);
	if (`ISCONTROLLERACTIVE) 
	{
		//Initially when UpdateData gets called, it invokes the actionscript's UpdateData function
		//that decides it's a good idea to unhighlight the button.
		if( bIsFocused )
		{
			//`log("Oninit issue logged");
			OnReceiveFocus();
			UIPanel(Owner).Navigator.SetSelected(self);
		}
		else
		{
		OnLoseFocus();
		}
		//`log("not focussed");
	}
}

simulated function UpdateDataWithNames(OnlineSaveGame save)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local XComOnlineEventMgr OnlineEventMgr;
	local string FriendlyName, mapPath, strDate, strName, strMission, strTime, strCampaignName, strRenamedSave;
	local bool bNewSave;
	local array<string> Descriptions;	
	local SaveGameHeader Header;
	local array<string> saveDateArray;
	local array<string> gameDateArray;
	local array<string> dateTimeArray;
	local string gameTime;
	local int gameHour;
	local string gameHourString;
	local int gameMinute;
	local string gameMinuteString;

	OnlineEventMgr = `ONLINEEVENTMGR;	
	if(save.Filename == "")
	{		
		bNewSave = true;
		OnlineEventMgr.FillInHeaderForSave(Header, FriendlyName);
	}
	else
	{
		Header = save.SaveGames[0].SaveGameHeader;
	}

	MC.FunctionBool("SetAutosave", Header.bIsAutosave);

	bIsDifferentLanguage = (Header.Language != GetLanguage());

	//Split up all the descriptions in the file header (you can see these by opening a save file with a text editor)	
	Descriptions = SplitString(Header.Description, "\n");
	//The date and time are concatenated together in a single header - split these into two seperate array elements
	dateTimeArray = SplitString(FormatTime(Header.Time), " - ");
	//Now split the save game date into 3 strings & store in seperate array (of months/days/years)
	saveDateArray=SplitString(Descriptions[0],"/");

	// Append zeros to the month & day if needed
	if (len(saveDateArray[0]) == 1)
		{
		saveDateArray[0] = "0" $ saveDateArray[0];
		}
	if (len(saveDateArray[1]) == 1)
		{
		saveDateArray[1] = "0" $ saveDateArray[1];
		}
	if (len(DateTimeArray[1]) == 4 || len(DateTimeArray[1]) == 7)
	//e.g. A 24h clock time is listed as 1:34 onstead of 01:34
		{
		DateTimeArray[1] = "0" $ DateTimeArray[1];
		}
	//Parse Ironman desc.
	If(InStr(Descriptions[2],class'XComOnlineEventMgr'.default.m_strIronmanLabel) !=INDEX_NONE)
		{
		Descriptions[2] = class'XComOnlineEventMgr'.default.m_strIronmanLabel;
		}
	
	//For old save files that used "-"
	if( Descriptions.length < 2 )
		Descriptions = SplitString(Header.Description, "-");

	// Handle weirdness
	if(Descriptions.Length < 4)
	{
		strDate = Repl(Header.Time, "\n", " - ") @ Header.Description;
	
		//Handle "custom" description such as what the error reports use
		MC.FunctionBool("SetErrorReport", true);
	}
	else
	{
		//We've made a normal save game
		strCampaignName = class'SaveGameNamingManagerCampaign'.static.GetSaveName(Header.GameNum);
		// If we've used the 'rename save' feature, pull from the config array
		strRenamedSave = class'SaveGameNamingManagerIndividual'.static.GetSaveName(save.SaveGames[0].InternalFileName);
		//`log("strRenamedSave: " @ strRenamedSave,,'BDLOG');
		if (strRenamedSave != "")
		{
			Descriptions[2] = strRenamedSave;
		}
		strTime = saveDateArray[2] $'-'$ saveDateArray[0] $'-'$ saveDateArray[1] $' - '$ dateTimeArray[1] $' - '; // This is actually the date & time concatenated together		
		strDate = strTime $ (Descriptions.Length >= 3 ? Descriptions[2] : ""); // This goes on the first line of the save/load box (Date + time + user save description)
				
		//If we're not separating the saves by campaign, start by putting the campaign name/number on line 2
		if(!`GETMCMVAR(SEPARATE_BY_CAMPAIGN))
		{
			if (strCampaignName != "")
			{
				//Output custom campaign name
				strName = strCampaignName @ ":";
			}
			else
			{
				//Output campaign number
				strName = class'XComOnlineEventMgr'.default.m_sCampaignString @ Header.GameNum @ ":";
			}	
		}
		//Then output the mission / geoscape string
		strName @= Descriptions[3];

		if (Descriptions.Length == 7) // We saved in a mission
		{
			
			if(mid(Descriptions[6],1,1) == ":")
			{
				Descriptions[6] = "0" $ Descriptions[6]; //Ensure the time part is a consistent length irrespective of the 12h time in the header
			}

		//Process the 'in-game' time 
		gameHour=Int(Left(Descriptions[6],2));			//Put the in-game time into integer variables
		gameMinute=Int(Mid(Descriptions[6],3,2));		
				
			If(InStr(Left(Descriptions[6],8),"PM") !=INDEX_NONE )		
			{							
				gameHour=Int(Left(Descriptions[6],2));	//If "PM" is in the string & it's not 12pm, add 12				
				if(gameHour < 12 && `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
				{
					gameHour += 12;
				}
			}			
			
			gameHourString="";
			gameHourString$=gameHour;
				
			If (Len(gameHourString)==1)
			{
				gameHourString="0"$gameHourString;			//Append leading 0
			}
			gameMinuteString="";
			gameMinuteString$=gameMinute;					//Append leading 0
				
			If (Len(gameMinuteString)==1)
			{
				gameMinuteString="0"$gameMinuteString;
			}

			if (`GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
			{	
				gameTime=gameHourString$":"$gameMinuteString;
			}
			else
			{
				gameTime=left(Descriptions[6],8);
			}

			gameDateArray=SplitString(Descriptions[5],"/");		//Split in the in-game date up into 3 strings
			
			if (len(gameDateArray[0]) == 1)					// Append zeroes to months & days as needed
			{
				gameDateArray[0] = "0" $ gameDateArray[0];
			}
			if (len(gameDateArray[1]) == 1)
			{
				gameDateArray[1] = "0" $ gameDateArray[1];
			}		
				
			strMission = gameDateArray[2] $'-'$ gameDateArray[0] $'-'$ gameDateArray[1];	//Re-arrange the date strings

			if(`GETMCMVAR(SHOW_MISSION_LOCATION_ON_SAVE_LOAD))
			{
				strMission $= ' - '$ gameTime $ ' - ' $ Split(Mid(Descriptions[6],8,200)," ",true); // This is the final line in the save box (i.e in-game-date + time + description)
			}
			else
			{
				strMission $= ' - '$ gameTime $ ' - ' $ Descriptions[4];						// This is the final line in the save box (i.e in-game-date + time + location)
			}
		}

		if (Descriptions.Length == 6) // We saved on the Geoscape
		{
			
			if(mid(Descriptions[5],1,1) == ":")
			{
				Descriptions[5] = "0" $ Descriptions[5]; //Ensure the time part is a consistent length irrespective of the 12h time in the header
			}
			
			gameHour=Int(Left(Descriptions[5],2));			//Put the in-game time into integer variables	
			gameMinute=Int(Mid(Descriptions[5],3,2));		
				
				If(InStr(Left(Descriptions[5],8),"PM") !=INDEX_NONE)		
				{			
					gameHour=Int(Left(Descriptions[5],2));	//If "PM" is in the string, add 12							
					
					if(gameHour < 12)
					{
						gameHour += 12;
					}					
				}	
				
				gameHourString="";
				gameHourString$=gameHour;
				If (Len(gameHourString)==1)
				{
					gameHourString="0"$gameHourString;
				}
				gameMinuteString="";
				gameMinuteString$=gameMinute;					//Append leading 0
					If (Len(gameMinuteString)==1)
				{
					gameMinuteString="0"$gameMinuteString;
				}

			gameTime=gameHourString$":"$gameMinuteString;			

			gameDateArray=SplitString(Descriptions[4],"/");		//As before - note that the array elements are now offset by one compared with the in-mission saves
			if (len(gameDateArray[0]) == 1)
			{
				gameDateArray[0] = "0" $ gameDateArray[0];
			}
			if (len(gameDateArray[1]) == 1)
			{
				gameDateArray[1] = "0" $ gameDateArray[1];
			}
			strMission = gameDateArray[2] $'-'$ gameDateArray[0] $'-'$ gameDateArray[1];
			
			if (`GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
			{	
				strMission $= ' - ' $ gameTime;
			}
				else
			{
				strMission $= ' - ' $ Descriptions[5];
			}
		}
	}
	
	mapPath = Header.MapImage;

	if(mapPath == "")
	{
		// temp until we get the real screen shots to display
		mapPath = "img:///UILibrary_Common.Xcom_default";
	}
	else
	{
		mapPath = "img:///"$mapPath;
	}

	//Image
	myValue.Type = AS_String;
	myValue.s = mapPath;
	myArray.AddItem(myValue);

	//Date
	myValue.s = strDate;
	myArray.AddItem(myValue);

	//Name
	myValue.s = strName;
	myArray.AddItem(myValue);

	//Mission
	myValue.s = strMission;
	myArray.AddItem(myValue);

	//accept Label
	if(bIsSaving)
	{
		myValue.s = bNewSave ? m_sNewSaveLabel : m_sSaveLabel;
	}
	else
	{
		myValue.s = m_sLoadLabel;
	}
	AcceptButton.SetText(myValue.s);
	myArray.AddItem(myValue);

	//delete label
	myValue.s = m_sDeleteLabel;
	myArray.AddItem(myValue);

	//rename label
	myValue.s = m_RenameLabel;	
	myArray.AddItem(myValue);

	Invoke("updateData", myArray);
}

simulated function ShowHighlight()
{
	MC.FunctionVoid("mouseIn");	
	AcceptButton.SetText(GetAcceptLabel(Index == 0));

	if (`ISCONTROLLERACTIVE)
	{
	//	AcceptButton.Show();
		AcceptButton.OnReceiveFocus();
	//	RenameButton.Show();
		RenameButton.OnReceiveFocus();
	//	DeleteButton.Show();
		DeleteButton.OnReceiveFocus();
	}
}

simulated function HideHighlight()
{
	MC.FunctionVoid("mouseOut");	
	AcceptButton.SetText(GetAcceptLabel( Index == 0 ));
	
	if(`ISCONTROLLERACTIVE)
	{
	//	AcceptButton.Hide();
		AcceptButton.OnLoseFocus();
	//	RenameButton.Hide();
		RenameButton.OnLoseFocus();
	//	DeleteButton.Hide();
		DeleteButton.OnLoseFocus();
	}
}

simulated function OnReceiveFocus()
{
	if (`ISCONTROLLERACTIVE == false)
	{
		super.OnReceiveFocus();
	}
	else
	{
		MC.FunctionVoid("mouseIn");

		AcceptButton.SetText(GetAcceptLabel(Index == 0));
		//`log("Setting recieve focus");
		AcceptButton.OnReceiveFocus();
	//	AcceptButton.Show();
		RenameButton.OnReceiveFocus();
	//	RenameButton.Show();
		DeleteButton.OnReceiveFocus();
	//	DeleteButton.Show();
	}
}

simulated function OnLoseFocus()
{
	if (`ISCONTROLLERACTIVE == false)
	{
		super.OnLoseFocus();
	}
	else
	{
		`log("OnLoseFocus Called",,'BDLOG');
		MC.FunctionVoid("mouseOut");
		//AcceptButton.Hide();
		//`log("Setting lose focus");
		AcceptButton.OnLoseFocus();
		//RenameButton.Hide();
		RenameButton.OnLoseFocus();
		//DeleteButton.Hide();
		DeleteButton.OnLoseFocus();
	}
}

simulated function UpdateDataCamp(OnlineSaveGame save)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local XComOnlineEventMgr OnlineEventMgr;
	local string FriendlyName, mapPath, strDate, strName, strMission, strTime, strCampaignName;
	local array<string> Descriptions;	
	local SaveGameHeader Header;
	local bool bIsNewSave, bHasValidImage;
	local array<string> saveDateArray;
	local array<string> gameDateArray;
	local array<string> dateTimeArray;
	local string gameTime;
	local int gameHour;
	local string gameHourString;
	local int gameMinute;
	local string gameMinuteString;
	
	OnlineEventMgr = `ONLINEEVENTMGR;	
	if(save.Filename == "")
	{		
		bIsNewSave = true; 
		OnlineEventMgr.FillInHeaderForSave(Header, FriendlyName);
	}
	else
	{
		Header = save.SaveGames[0].SaveGameHeader;
	}

	MC.FunctionBool("SetAutosave", Header.bIsAutosave);

	bIsDifferentLanguage = (Header.Language != GetLanguage());

	//Split up all the descriptions in the file header (you can see these by opening a save file with a text editor)	
	Descriptions = SplitString(Header.Description, "\n");	
	//The date and time are concatenated together in a single header - split these into two seperate array elements
	dateTimeArray = SplitString(FormatTime(Header.Time), " - ");
	
	//Now split the save game date into 3 strings & store in seperate array (of months/days/years)
	saveDateArray=SplitString(Descriptions[0],"/");
	// Append zeros to the month & day if needed
	if (len(saveDateArray[0]) == 1)
		{
		saveDateArray[0] = "0" $ saveDateArray[0];
		}
	if (len(saveDateArray[1]) == 1)
		{
		saveDateArray[1] = "0" $ saveDateArray[1];
		}
	if (len(DateTimeArray[1]) == 4)
	//e.g. A 24h clock time is listed as 1:34 onstead of 01:34
		{
		DateTimeArray[1] = "0" $ DateTimeArray[1];
		}
	
	//Parse Ironman desc.
	If(InStr(Descriptions[2],class'XComOnlineEventMgr'.default.m_strIronmanLabel) !=INDEX_NONE)
	{
	Descriptions[2] = class'XComOnlineEventMgr'.default.m_strIronmanLabel;
	}

	//For old save files that used "-"
	if( Descriptions.length < 2 )
		Descriptions = SplitString(Header.Description, "-");

	// Handle weirdness
	if(Descriptions.Length < 4)
	{
		strDate = Repl(Header.Time, "\n", " - ") @ Header.Description;
	
		//Handle "custom" description such as what the error reports use
		MC.FunctionBool("SetErrorReport", true);
	}
	else
	{
		//We've made a normal save game
		strCampaignName = class'SaveGameNamingManagerCampaign'.static.GetSaveName(Header.GameNum);
		strTime = saveDateArray[2] $'-'$ saveDateArray[0] $'-'$ saveDateArray[1] $' - '$ dateTimeArray[1] $' - '; // This is actually the date & time concatenated together
		strDate = strTime $ (Descriptions.Length >= 3 ? Descriptions[2] : ""); // This goes on the first line of the save/load box (Date + time + user save description)
		strName = class'XComOnlineEventMgr'.default.m_sCampaignString @ Header.GameNum;	
		
		//Put the custom campaign name or campaign number in brackets at the end of the first line
		if(!`GETMCMVAR(SEPARATE_BY_CAMPAIGN))
		{
			if (strCampaignName != "")
			{
				strDate @= "-" @ strCampaignName;
			}
			else
			{
				strDate @= "-" @ strName;
			}	
		}
		if (Descriptions.Length == 7) // We saved in a mission
			{
			strName = Descriptions[3];	//Put the mission type on the second line
			gameDateArray=SplitString(Descriptions[5],"/");		//Split in the in-game date up into 3 strings
				if (len(gameDateArray[0]) == 1)					// Append zeroes to months & days if needed
				{
				gameDateArray[0] = "0" $ gameDateArray[0];
				}
				if (len(gameDateArray[1]) == 1)
				{
				gameDateArray[1] = "0" $ gameDateArray[1];
				}			
			strMission = gameDateArray[2] $'-'$ gameDateArray[0] $'-'$ gameDateArray[1];	//Re-arrange the date strings
			strMission $= ' - '$ Descriptions[4];											// This is the final line in the save box (i.e in-game-date + operation name)
			}
		if (Descriptions.Length == 6) // We saved on the Geoscape
			{
			gameHour=Int(Left(Descriptions[5],2));			//Put the in-game time into integer variables	
			gameMinute=Int(Mid(Descriptions[5],3,2));		
				
				If(InStr(Left(Descriptions[5],8),"PM") !=INDEX_NONE)		
				{			
				gameHour=Int(Left(Descriptions[5],2)); // Get the hour from the save description
					if(gameHour < 12)
					{
					gameHour += 12; //Required so that 12pm is ignored
					}									
				}						
				gameHourString="";
				gameHourString$=gameHour;
				If (Len(gameHourString)==1)
					{
					gameHourString="0"$gameHourString;
					}
				gameMinuteString="";
				gameMinuteString$=gameMinute;					//Append leading 0
					If (Len(gameMinuteString)==1)
					{
					gameMinuteString="0"$gameMinuteString;
					}

			gameTime=gameHourString$":"$gameMinuteString;
			
			strName = Descriptions[3];							//Just output "geoscape" since there are no mission details
			gameDateArray=SplitString(Descriptions[4],"/");		//As before - note that the array elements are now offset by one compared with the in-mission saves
			if (len(gameDateArray[0]) == 1)
				{
				gameDateArray[0] = "0" $ gameDateArray[0];
				}
			if (len(gameDateArray[1]) == 1)
				{
				gameDateArray[1] = "0" $ gameDateArray[1];
				}
			strMission = gameDateArray[2] $'-'$ gameDateArray[0] $'-'$ gameDateArray[1];
			
			if (`GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
				{
				strMission $= ' - ' $ gameTime;
				}
				else
				{
				strMission $= ' - ' $ Descriptions[5];
				}
			}
	}
	
	mapPath = Header.MapImage;

	bHasValidImage = ImageCheck();

	if( mapPath == "" || !bHasValidImage )
	{
		// temp until we get the real screen shots to display
		mapPath = "img:///UILibrary_Common.Xcom_default";
	}
	else
	{
		mapPath = "img:///"$mapPath;
	}

	//Image
	myValue.Type = AS_String;
	myValue.s = mapPath;
	myArray.AddItem(myValue);

	//Date
	myValue.s = strDate;
	myArray.AddItem(myValue);

	//Name
	myValue.s = strName;
	myArray.AddItem(myValue);

	//Mission
	myValue.s = strMission;
	myArray.AddItem(myValue);

	//accept Label
	myValue.s = GetAcceptLabel(bIsNewSave);
	AcceptButton.SetText(myValue.s);
	myArray.AddItem(myValue);

	//delete label
	myValue.s = m_sDeleteLabel;
	myArray.AddItem(myValue);
	DeleteButton.SetText(myValue.s);

	//rename label
	myValue.s = bIsSaving? " ": m_sRenameLabel;
	myArray.AddItem(myValue);

	Invoke("updateData", myArray);
}

simulated function string FormatTime( string HeaderTime )
{
	local string FormattedTime;
	
	// HeaderTime is in 24h format
	FormattedTime = HeaderTime;
	if( GetLanguage() == "INT" && !`GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK))
	{
		FormattedTime = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(FormattedTime);
	}

	FormattedTime = Repl(FormattedTime, "\n", " - ");

	return FormattedTime;
}