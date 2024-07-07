class UISaveGameCampaignSelectItem extends UIPanel config(Game);

var UIButton				AcceptButton;
var UIButton				RenameButton;
var UIButton				DeleteButton;
var OnlineSaveGame			SaveGame;
var array<OnlineSaveGame>	m_arrSaveGames;
var int						Index;
var int						ID; 
var bool					bIsSaving;
var UIPanel					ButtonBG;
var name					ButtonBGLibID;
var string					DateTimeString;
var	bool					bIsDifferentLanguage;
var UIList					List;

var localized string		m_SelectCampaignLabel;
var localized string		m_DeleteCampaignLabel;
var localized string		m_sDeleteAllLabel;
var localized string		m_sDeleteAllSaveTitle;
var localized string		m_sDeleteAllSaveText;
var localized string		m_sDeleteConfirmText;

var config bool				bEnableDeleteCampaignButton;

var delegate<OnMouseInDelegate> OnMouseIn;

// mouse callbacks
delegate OnClickedDelegate(UIButton Button);
delegate OnMouseInDelegate(int ListIndex);

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	List = UIList(GetParent(class'UIList')); // list items must be owned by UIList.ItemContainer
	if(List == none)
	{
		ScriptTrace();
		`warn("UI list items must be owned by UIList.ItemContainer");
	}

	return self;
}

simulated function UISaveGameCampaignSelectItem InitSaveLoadItem(int listIndex, OnlineSaveGame save, bool bSaving, optional delegate<OnClickedDelegate> AcceptClickedDelegate, optional delegate<OnClickedDelegate> RenameClickedDelegate, optional delegate<OnMouseInDelegate> MouseInDelegate)
{
	local XComOnlineEventMgr OnlineEventMgr;

	OnlineEventMgr = `ONLINEEVENTMGR;

	ID = OnlineEventMgr.SaveNameToID(save.Filename);
	InitPanel();
	Index = listIndex;

	SaveGame = save;
	bIsSaving = bSaving;
	
	//SetWidth(List.width);

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
		AcceptButton.SetVisible(true);
	}
	AcceptButton.OnMouseEventDelegate = OnChildMouseEvent;		
	
	RenameButton = Spawn(class'UIButton', ButtonBG);
	RenameButton.bIsNavigable = false;
	RenameButton.InitButton('Button1', class'UISaveLoadItemWithNames'.default.m_RenameCampaign, RenameClickedDelegate);	
	if (`ISCONTROLLERACTIVE)
	{
		RenameButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		RenameButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
		RenameButton.SetVisible(true);
	}	
	RenameButton.OnMouseEventDelegate = OnChildMouseEvent;
	
	DeleteButton = Spawn(class'UIButton', ButtonBG);
	DeleteButton.bIsNavigable = false;
	DeleteButton.InitButton('Button2', default.m_DeleteCampaignLabel, OnDeleteCampaign);	
		
		if (`ISCONTROLLERACTIVE) 
		{
			DeleteButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
			DeleteButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE); // bsg-jrebar (4.3.17): Unifying across platforms to X for delete
			DeleteButton.SetVisible(true);
		}
	
	DeleteButton.OnMouseEventDelegate = OnChildMouseEvent;
	
	If(!default.bEnableDeleteCampaignButton || `ISCONTROLLERACTIVE)
	{
	DeleteButton.SetDisabled(true);
	}
	OnMouseIn = MouseInDelegate;

	return self;
} 

simulated public function OnDeleteCampaign(optional UIButton control)
{
	local TDialogueBoxData kDialogData;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	// Warn before deleting save
	kDialogData.eType     = eDialog_Warning;
	kDialogData.strTitle  = m_sDeleteAllSaveTitle;
	kDialogData.strText   = m_sDeleteAllSaveText;
	kDialogData.strAccept = m_sDeleteConfirmText;
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	kDialogData.fnCallback  = DeleteAllSaveWarningCampaignCallback;
	Movie.Pres.UIRaiseDialog( kDialogData );

}

simulated function DeleteAllSaveWarningCampaignCallback(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		DeleteAllSavesInCampaign();		
	}
}

// Somehow, in this function we need to the items in m_arrSaveGames which have the matching campaign ID number to the current selection
simulated function DeleteAllSavesInCampaign()
{
	local SaveGameHeader	CampaignHeader, IndividualGameHeader;
	local int				SaveIdx;

	//Fill the local var with the save games
	`ONLINEEVENTMGR.GetSaveGames(m_arrSaveGames);

	//Use the campaign header from the dummy save game in the class to get the info
	CampaignHeader = SaveGame.SaveGames[0].SaveGameHeader;
	`Log("Campaign number is " @ CampaignHeader.GameNum);

	//Loop through all the games in the folder
	SaveIdx = 0;	
	while (SaveIdx < m_arrSaveGames.length)
	{
		//Get the header
		IndividualGameHeader = m_arrSaveGames[SaveIdx].SaveGames[0].SaveGameHeader;
		// Match the menu item campaign gamenumber with the individual game campaign number
		If(IndividualGameHeader.GameNum == CampaignHeader.GameNum)
		{
		//Delete the game if it matches
		`ONLINEEVENTMGR.DeleteSaveGame(GetSaveID(SaveIdx));
		}
		++SaveIdx;
	}	
}

simulated function  int GetSaveID(int iIndex)
{
	if (iIndex >= 0 && iIndex < m_arrSaveGames.Length)
		return `ONLINEEVENTMGR.SaveNameToID(m_arrSaveGames[iIndex].Filename);

	return -1;      //  if it's not in the save game list it can't be loaded 
}

simulated function OnInit()
{
	super.OnInit();

	UpdateData(SaveGame);
	if (`ISCONTROLLERACTIVE) 
	{
		//Initially when UpdateData gets called, it invokes the actionscript's UpdateData function
		//that decides it's a good idea to unhighlight the button.
		if( bIsFocused )
		{
			`log("Oninit issue logged");
			OnReceiveFocus();
			UIPanel(Owner).Navigator.SetSelected(self);
		}
		else
		{
		OnLoseFocus();
		}
		`log("not focussed");
	}
}

function ResetButtons()
{
	RenameButton.SetPosition(AcceptButton.X + AcceptButton.Width + 8, AcceptButton.Y);
	DeleteButton.SetPosition(RenameButton.X + RenameButton.Width + 8, RenameButton.Y);
}

function bool ImageCheck()
{
	local string MapName;
	local array<string> Path; 

	//Check to see if the image fails, and clear the image if failed so the default image will stay.
	if (SaveGame.SaveGames.Length < 1)
		return false;

	MapName = SaveGame.SaveGames[0].SaveGameHeader.MapImage;

	Path = SplitString(mapname, ".");

	if( Path.length < 2 ) //you have a malformed path 
		return false;

	return `XENGINE.DoesPackageExist(Path[0]); 
}

simulated function string GetAcceptLabel( bool bIsNewSave )
{
	return m_SelectCampaignLabel;
}

simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	if( OnMouseIn != none )
		OnMouseIn(Index);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	if( bShouldPlayGenericUIAudioEvents )
	{
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN :
			`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
			//ShowHighlight();
			break;
		//case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT :
		//case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT :
		//	HideHighlight();
		//	break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
			if(AcceptButton != none)
				AcceptButton.Click();
			break;
		}
	}

	if(OnMouseIn != none)
		OnMouseIn(Index);

	if( OnMouseEventDelegate != none )
		OnMouseEventDelegate(self, cmd);
}

simulated function ShowHighlight()
{
	MC.FunctionVoid("mouseIn");	
	AcceptButton.SetText(GetAcceptLabel(Index == 0));

	if (`ISCONTROLLERACTIVE)
	{
		AcceptButton.Show();
		AcceptButton.OnReceiveFocus();
		RenameButton.Show();
		RenameButton.OnReceiveFocus();
		DeleteButton.Show();
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

simulated function UpdateData(OnlineSaveGame save)
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

	MC.FunctionBool("SetAutosave", false);

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
	// Append zeroes to 24h clock times if needed (e.g. 1:34 should be 01:34)
	if (len(DateTimeArray[1]) == 4)	
		{
		DateTimeArray[1] = "0" $ DateTimeArray[1];
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
		strTime = saveDateArray[2] $'-'$ saveDateArray[0] $'-'$ saveDateArray[1] $' - '$ dateTimeArray[1]; // This is actually the date & time concatenated together
		strDate = strTime; // StrDate is the whole first line of the save/load box (Date + time + user save description)
		strName = class'XComOnlineEventMgr'.default.m_sCampaignString @ Header.GameNum;	 // StrName is the second line - Get the campaign 
		strCampaignName = class'SaveGameNamingManager'.static.GetSaveName(Header.GameNum);

		//Put the custom campaign name or campaign number at the end of the first line
		if (strCampaignName != "")
		{
			strDate @= "-" @ strCampaignName;
		}
		else
		{
			strDate @= "-" @ strName;
		}	
		
		//Put the ironman label in brackets on the second line after the campaign name / number
		if (Header.bIsIronman)
		{
			strName @= "(" $ class'XComOnlineEventMgr'.default.m_strIronmanLabel $ ")";
		}	
				
			if (Descriptions.Length == 7) // We saved in a mission
			{			
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
				gameHour=Int(Left(Descriptions[5],2))+12;	//If "PM" is in the string, add 12			
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
			
			if (class'UISaveLoadItemWithNames'.default.b24hClock)
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

	//rename label
	myValue.s = class'UISaveLoadItemWithNames'.default.m_RenameCampaign;
	myArray.AddItem(myValue);

	//delete campaign label
	myValue.s = default.m_DeleteCampaignLabel;
	myArray.AddItem(myValue);

	Invoke("updateData", myArray);
	ResetButtons();

}

simulated function string FormatTime( string HeaderTime )
{
	local string FormattedTime;
	
	// HeaderTime is in 24h format
	FormattedTime = HeaderTime;
	if( GetLanguage() == "INT" && !class'UISaveLoadItemWithNames'.default.b24hClock)
	{
		FormattedTime = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(FormattedTime);
	}

	FormattedTime = Repl(FormattedTime, "\n", " - ");

	return FormattedTime;
}

simulated function UpdateSaveName(string saveName)
{
	MC.FunctionString("SetDate", DateTimeString @ saveName);
}

simulated function ClearImage()
{
	MC.FunctionVoid("ClearImage");
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	`log("OnUnrealCommand campaign select activated");
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		AcceptButton.Click();
		return true;
		
	case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		if( RenameButton.IsVisible() )
		{
			RenameButton.Click();
			return true;
		}
		break;
	}
	`log("Using base game stuff to handle dpad up/down on campaign menu");
	return super.OnUnrealCommand(cmd, arg);
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
		AcceptButton.OnReceiveFocus();
		AcceptButton.Show();
		RenameButton.OnReceiveFocus();
		RenameButton.Show();
		DeleteButton.OnReceiveFocus();
		DeleteButton.Show();
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
		MC.FunctionVoid("mouseOut");
		//AcceptButton.Hide();
		AcceptButton.OnLoseFocus();
		//RenameButton.Hide();
		RenameButton.OnLoseFocus();
		//DeleteButton.Hide();
		DeleteButton.OnLoseFocus();
	}
}


defaultproperties
{
	LibID = "SaveLoadListItem";
	ButtonBGLibID = "ButtonGroup"
	height = 135;
	bIsDifferentLanguage = false
	bCascadeFocus = false;
}