class UILoadProperSort extends UILoadGame config(Game);

var localized string					m_RenameCampaign;
var localized string					m_RenameSave;
var localized string					m_LoadFromCampaign;
var localized string					m_sNameSave;

var int									CurrentlySelectedCampaignIndex;
var array<int>							AvailableCampaignIndex;
var array<UISaveGameCampaignSelectItem> m_arrListCampaign;
var OnlineSaveGame						SaveGame;

`include(ISO_Campaign\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

simulated function OnInit()
{
	local XComGameState_CampaignSettings CampaignSetting;
	
	CampaignSetting = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if (CampaignSetting != none)
	{
		CurrentlySelectedCampaignIndex = CampaignSetting.GameIndex;
	}
	super.OnInit();
}

simulated function OnReadSaveGameListComplete(bool bWasSuccessful)
{
	local int i;
	local XComCheatManager XComCheat;
	local bool FilterLadders;

	if( bWasSuccessful )
		`ONLINEEVENTMGR.GetSaveGames(m_arrSaveGames);
	else
		m_arrSaveGames.Remove(0, m_arrSaveGames.Length);

	XComCheat = XComCheatManager(GetALocalPlayerController().CheatManager);
	FilterLadders = (XComCheat != none) ? !XComCheat.LoadMenuLaddersAllowed : true;
	//class'X2TacticalGameRuleset'.static.ReleaseScriptLog( "Filtering Ladders:" @ FilterLadders @ "with CheatMgr:" @ XComCheat );

	if (FilterSaveGameList(m_arrSaveGames, m_bBlockingSavesFromOtherLanguages, FilterLadders ))
	{
		ShowSaveLanguageDialog();	
	}
	//`ONLINEEVENTMGR.SortSavedGameListByTimestamp(m_arrSaveGames);	
	//m_arrSaveGames.Sort(SortByDate);
	QuickSort(0, m_arrSaveGames.Length, m_arrSaveGames); 

	AvailableCampaignIndex.Length = 0;
	for (i = 0; i < m_arrSaveGames.Length; i ++)
	{
		if (AvailableCampaignIndex.Find(m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum) == INDEX_NONE)
			AvailableCampaignIndex.AddItem(m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum);
	}		

	BuildMenu();		
	// Close progress dialog
	Movie.Stack.PopFirstInstanceOfClass(class'UIProgressDialogue', false);
}

simulated function BuildMenu()
{
	local int i, Index, ItemIndex;
	local array<int> ShownIndex;

	AS_Clear(); // Will be called after deleting a save
	List.ClearItems();
	m_arrListItems.Remove(0, m_arrListItems.Length);
	m_arrListCampaign.Remove(0, m_arrListCampaign.Length);

	ItemIndex = 0;

	//`log("CurrentlySelectedCampaignIndex (load) is:" @ CurrentlySelectedCampaignIndex,,'BDLOG');
	if (`GETMCMVAR(SEPARATE_BY_CAMPAIGN))
	{
		if (CurrentlySelectedCampaignIndex == -1)
		{
			SetTitle(m_sLoadTitle);
			for( i = 0; i < m_arrSaveGames.Length; i++ )
			{
				Index = m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum;
				if (ShownIndex.Find(Index) == INDEX_NONE && AvailableCampaignIndex.Find(Index) != INDEX_NONE)
				{
					ShownIndex.AddItem(Index);
					m_arrListCampaign.AddItem(Spawn(class'UISaveGameCampaignSelectItem', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_arrSaveGames[i], false, OnAcceptCamp, OnRenameCamp, SetSelectionCamp));
					m_arrListCampaign[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);			
				}
				
			}
		}
		else
		{
			SetTitle(m_LoadFromCampaign @ CurrentlySelectedCampaignIndex $ ":" @ class'SaveGameNamingManagerCampaign'.static.GetSaveName(CurrentlySelectedCampaignIndex));
			for( i = 0; i < m_arrSaveGames.Length; i++ )
			{
				if (CurrentlySelectedCampaignIndex == m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum)
				{
					m_arrListItems.AddItem(Spawn(class'UISaveLoadItemWithNames', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_arrSaveGames[i], false, OnAccept, OnDelete, OnRenameInd, SetSelection));
					m_arrListItems[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);
				}
			}
		}
	}
	else
	{
		SetTitle(m_sLoadTitle);
		for( i = 0; i < m_arrSaveGames.Length; i++ )
		{
			m_arrListItems.AddItem(Spawn(class'UISaveLoadItemWithNames', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_arrSaveGames[i], false, OnAccept, OnDelete, OnRenameInd, SetSelection));
			m_arrListItems[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);
		}
	}
	
	m_iCurrentSelection = -1;
	SetTimer(0.3f, false, nameof(UpdateAllSaves));
}

simulated static function QuickSort(int start_idx, int len, out array<OnlineSaveGame> SaveList)
{
	local int pivot, i, len_tmp;
	local OnlineSaveGame save;
	if (len <= 1) // Smallest unit, break
		return;
	len_tmp = len;
	pivot = start_idx + (len / 2);
	for ( i = start_idx; i < start_idx + len_tmp; i++ )
	{
		if (i < pivot)
		{
			if (SortByDate(SaveList[i], SaveList[pivot]) < 0)
			{
				save = SaveList[i];
				SaveList.Remove(i, 1);
				i--;
				pivot--;
				SaveList.InsertItem(start_idx + len_tmp - 1, save);
				len_tmp--;
			}
		}
		else if (i > pivot)
		{
			if (SortByDate(SaveList[i], SaveList[pivot]) > 0)
			{
				save = SaveList[i];
				SaveList.Remove(i, 1);
				SaveList.InsertItem(start_idx, save);
				pivot++;
			}
		}
	}
	QuickSort(start_idx, pivot - start_idx, SaveList);
	QuickSort(pivot + 1, start_idx + len - pivot - 1, SaveList);
}

simulated static function int SortByDate(OnlineSaveGame A, OnlineSaveGame B)
{
	local int YearA, MonthA, DayA, HourA, MinuteA;
	local int YearB, MonthB, DayB, HourB, MinuteB;
	
	if (B.SaveGames.Length == 0)
		return 1;
	if (A.SaveGames.Length == 0)
		return -1;

	`ONLINEEVENTMGR.ParseTimeStamp(A.SaveGames[0].SaveGameHeader.Time, YearA, MonthA, DayA, HourA, MinuteA);
	`ONLINEEVENTMGR.ParseTimeStamp(B.SaveGames[0].SaveGameHeader.Time, YearB, MonthB, DayB, HourB, MinuteB);

	//`log(A.SaveGames[0].SaveGameHeader.Time @ "=" @ YearA $ "/" $ MonthA $ "/" $ DayA @ HourA $ ":" $ MinuteA,, 'SaveGameTimeDebug');
	//`log(B.SaveGames[0].SaveGameHeader.Time @ "=" @ YearB $ "/" $ MonthB $ "/" $ DayB @ HourB $ ":" $ MinuteB,, 'SaveGameTimeDebug');

	if (YearA > YearB)
		return 1;
	else if (YearA < YearB)
		return -1;

	if (MonthA > MonthB)
		return 1;
	else if (MonthA < MonthB)
		return -1;

	if (DayA > DayB)
		return 1;
	else if (DayA < DayB)
		return -1;

	if (HourA > HourB)
		return 1;
	else if (HourA < HourB)
		return -1;

	if (MinuteA > MinuteB)
		return 1;
	else if (MinuteA < MinuteB)
		return -1;

	return 0;
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}

simulated function string GetCurrentSelectedCampaignName()
{
	local string SaveName;

	if (`GETMCMVAR(SEPARATE_BY_CAMPAIGN) && CurrentlySelectedCampaignIndex == -1)
	{
		SaveName = class'SaveGameNamingManagerCampaign'.static.GetSaveName(m_arrListCampaign[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.GameNum);
	}
	else
	{
		SaveName = class'SaveGameNamingManagerCampaign'.static.GetSaveName(m_arrListItems[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.GameNum);
	}

	return SaveName;
}

simulated public function OnRenameCamp(optional UIButton control)
{
	local TInputDialogData kData;

		kData.strTitle = m_RenameCampaign;
		kData.iMaxChars = 40;
		kData.strInputBoxText = GetCurrentSelectedCampaignName();
		kData.fnCallbackAccepted = SetCurrentSelectedFilenameX;
	
	Movie.Pres.UIInputDialog(kData);
}

simulated public function OnRenameInd(optional UIButton control)
{

	local TInputDialogData kData;
	local string AlreadyRenamedSave;

	//`log("Campaign index:" @ currentlyselectedcampaignindex,,'BDLOG');
	//`log("Campaign number:" @ m_arrListItems[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.GameNum,,'BDLOG');

	AlreadyRenamedSave = class'SaveGameNamingManagerIndividual'.static.GetSaveName(m_arrListItems[m_iCurrentSelection].ID);
		// Use the name from the config file in preference to the save file header, if it exists
		if (AlreadyRenamedSave != "")
		{
			kData.strInputBoxText = AlreadyRenamedSave;
		}
		else
		{
			kData.strInputBoxText = GetCurrentSelectedFilename();
		}
		kData.strTitle = m_RenameSave;
		kData.iMaxChars = 40;	
		kData.fnCallbackAccepted = SetCurrentSelectedFilenameInd;
	
	Movie.Pres.UIInputDialog(kData);
}

simulated public function OnAcceptCamp(optional UIButton control)
{
	if(m_bLoadInProgress)
		return;

	if( control != None && control.Owner != None && UISaveGameCampaignSelectItem(control.Owner.Owner) != None )
	{
		SetSelectionCamp(UISaveGameCampaignSelectItem(control.Owner.Owner).Index);
	}

	if (m_iCurrentSelection < 0 || m_iCurrentSelection >= AvailableCampaignIndex.Length )
	{
		PlaySound(SoundCue'SoundUI.MenuCancelCue', true);
	}
	else
	{
		CurrentlySelectedCampaignIndex = AvailableCampaignIndex[m_iCurrentSelection];
		BuildMenu();
	}
}

simulated function SetSelectionCamp(int currentSelection)
{
	local int i;
	if( currentSelection == m_iCurrentSelection )
	{
		return;
	}

	for (i = 0; i < m_arrListCampaign.Length; i++)
	{
		m_arrListCampaign[i].HideHighlight();
	//	m_arrListCampaign[i].OnLoseFocus();	
	}

	m_iCurrentSelection = currentSelection;
	
	if (m_iCurrentSelection < 0)
	{
		//`log("m_iCurrentSelection is:" @ m_iCurrentSelection);
		m_iCurrentSelection = GetNumSaves();
	}
	else if (m_iCurrentSelection > GetNumSaves())
	{
		m_iCurrentSelection = 0;
	}

	if (m_iCurrentSelection >=0 && m_iCurrentSelection < m_arrListCampaign.Length)
	{
		m_arrListCampaign[m_iCurrentSelection].ShowHighlight();
	}
	if( `ISCONTROLLERACTIVE )
	{
		//m_arrListCampaign[m_iCurrentSelection].OnReceiveFocus();

		List.Scrollbar.SetThumbAtPercent(float(m_iCurrentSelection) / float(m_arrListCampaign.Length - 1));
	}
}

simulated function SetCurrentSelectedFilenameX(string text)
{	
	local int RenameCampaignIndex;
	text = Repl(text, "\n", "", false);
	if (`GETMCMVAR(SEPARATE_BY_CAMPAIGN))
	{
		if (CurrentlySelectedCampaignIndex == -1)
		{
			RenameCampaignIndex = m_arrListCampaign[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.GameNum;
		}
		else
		{
			RenameCampaignIndex = CurrentlySelectedCampaignIndex;
		}
	}
	else
	{
		RenameCampaignIndex = m_arrListItems[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.GameNum;
	}
	class'SaveGameNamingManagerCampaign'.static.SetSaveName(RenameCampaignIndex, text);
	UpdateAllSaves();
}

simulated function SetCurrentSelectedFilenameInd(string text)
{	
	text = Repl(text, "\n", "", false);	
	class'SaveGameNamingManagerIndividual'.static.SetSaveName(m_arrListItems[m_iCurrentSelection].ID,text);
	UpdateAllSaves();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repreats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	
	if( !bIsInited ) 
		return true;

	//if( !QueryAllImagesLoaded() ) return true; //If allow input before the images load, you will crash. Serves you right. -bsteiner
		If(`ISCONTROLLERACTIVE)
		{
		//`log("Controller is active");
		}
		Else
		{
		//`log("Controller is not active, but should be?");
		}

	switch(cmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):		
			//`log("Accept button of over-ride hit");
			If(CurrentlySelectedCampaignIndex == -1)
			{
			OnAcceptCamp();
			}
			Else
			{
			OnAccept();
			}
			return true;
		
		case (class'UIUtilities_Input'.const.FXS_BUTTON_Y):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			//`log("Rename button hit");
			If(CurrentlySelectedCampaignIndex == -1)
			{
			OnRenameCamp();
			}
			Else
			{
			OnRenameInd();
			}
			return true;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		case (class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN):
			//`log("Cancel button of over-ride hit");
			OnCancel();
			return true;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
		case (class'UIUtilities_Input'.const.FXS_KEY_DELETE):			
			If(`GETMCMVAR(SEPARATE_BY_CAMPAIGN) && CurrentlySelectedCampaignIndex == -1 && `GETMCMVAR(ENABLE_DELETE_CAMPAIGN_BUTTON))
			{
			//`log("Delete button hit");
			}
			Else
			{
			OnDelete();
			}
			return true;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			//`log("Pad up method of over-ride hit");
			OnUDPadUp();
			return true;  //bsg-jrebar (4.6.17): return once handled else will get caught in loop of unhandled input causing errors
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			//`log("Pad down method of over-ride hit");
			OnUDPadDown();
			return true;  //bsg-jrebar (4.6.17): return once handled else will get caught in loop of unhandled input causing errors
			break;

		default:
			break;			
	}
	//`log("Deferring to parent class"); // always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return super.OnUnrealCommand(cmd, arg);
}

simulated public function OnUDPadUp()
{
	local int numSaves;
	local int newSel;
	numSaves = GetNumSaves();

	if ( numSaves > 1 )
	{
		PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
	}

	//`log("m_iCurrentSelection =" @ m_iCurrentSelection);
	//`log("NewSel ="@newSel);
	//`log("numSaves="@numSaves);	
	newSel = m_iCurrentSelection - 1;
	
	//`log("LoadNewSel ="@newSel);
	//`log("LoadnumSaves="@numSaves);
	//`log("LoadList item array length =" @ m_arrListItems.length);
	//`log("LoadList item campaign length =" @ m_arrListCampaign.length);

	//`log("List item array length =" @ m_arrListItems.length);
	//`log("List item campaign length =" @ m_arrListCampaign.length);

	if (newSel < 0)
		//if we've gone off the top of the campaign select menu
		If(`GETMCMVAR(SEPARATE_BY_CAMPAIGN) && CurrentlySelectedCampaignIndex == -1)
		{
			newSel = m_arrListCampaign.length - 1;
		}
		Else
		{
		//we've gone off the top of the normal save menu
			newSel = m_arrListItems.length - 1;
		}
	
	//`log("Selected campaign index is:" @ CurrentlySelectedCampaignIndex);
	If(`GETMCMVAR(SEPARATE_BY_CAMPAIGN) && CurrentlySelectedCampaignIndex == -1)
			{
				If (newSel >= m_arrListCampaign.length)
				{
				newSel=0;
				}
			//`log("SetSelectionCamp fired");
			SetSelectionCamp(newSel);
			}
			Else
			{
			If (m_arrListItems.length != 0 && newSel >= m_arrListItems.length)
				{
				newSel=0;
				}								
			//`log("SetSelection Fired");
			SetSelection(newSel);
			}		
}
simulated public function OnUDPadDown()
{
	local int numSaves;
	local int newSel;
	numSaves = GetNumSaves();

	if ( numSaves > 1 )
	{
		PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
	}
	
	//`log("m_iCurrentSelection =" @ m_iCurrentSelection);
	//`log("NewSel ="@newSel);
	//`log("numSaves="@numSaves);	

	//`log("LoadNewSel ="@newSel);
	//`log("LoadnumSaves="@numSaves);
	//`log("LoadList item array length =" @ m_arrListItems.length);
	//`log("LoadList item campaign length =" @ m_arrListCampaign.length);

	newSel = m_iCurrentSelection + 1;	

	if (newSel >= numSaves)
		newSel = 0;

	If(`GETMCMVAR(SEPARATE_BY_CAMPAIGN) && CurrentlySelectedCampaignIndex == -1)
			{
				If (newSel >= m_arrListCampaign.length)
				{
				newSel=0;
				}
			SetSelectionCamp(newSel);
			}
	Else
			{
			If (m_arrListItems.length != 0 && newSel >= m_arrListItems.length)
				{
				newSel=0;
				}								
			SetSelection(newSel);
			}		
}

simulated function UpdateAllSaves()
{
	local int i;
	local UISaveLoadItemWithNames SaveSlot;
	local UISaveGameCampaignSelectItem CampSlot;
	for (i = 0; i < m_arrListItems.Length; i++)
	{
		SaveSlot = UISaveLoadItemWithNames(m_arrListItems[i]);
		if (SaveSlot != none)
			SaveSlot.UpdateDataWithNames(m_arrListItems[i].SaveGame);
	}
	for (i = 0; i < m_arrListCampaign.Length; i++)
	{
		CampSlot = m_arrListCampaign[i];
		if (CampSlot != none)
			CampSlot.UpdateDataCamp(m_arrListCampaign[i].SaveGame);
	}
}

simulated public function OnCancel()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	if (`GETMCMVAR(SEPARATE_BY_CAMPAIGN) && CurrentlySelectedCampaignIndex > -1)
	{
		CurrentlySelectedCampaignIndex = -1;
		BuildMenu();
	}
	else
	{
		NavHelp.ClearButtonHelp();
		`ONLINEEVENTMGR.bInitiateReplayAfterLoad = false;
		Movie.Stack.Pop(self);
	}
}

simulated function  int GetSaveIDSelection(int iIndex)
{
	if (iIndex >= 0 && iIndex < m_arrListItems.Length)
		return `ONLINEEVENTMGR.SaveNameToID(m_arrListItems[iIndex].SaveGame.Filename);

	return -1;      //  if it's not in the save game list it can't be loaded 
}

simulated function LoadSelectedSlot(bool IgnoreVersioning = false)
{
	local int SaveID;
	local TDialogueBoxData DialogData;
	local TProgressDialogData ProgressDialogData;
	local string MissingDLC;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	m_bLoadInProgress = true;
	
	SaveID = GetSaveIDSelection(m_iCurrentSelection);
	if ( !`ONLINEEVENTMGR.CheckSaveVersionRequirements(SaveID) && !IgnoreVersioning)
	{
		DialogData.eType = eDialog_Warning;
		DialogData.strTitle = m_sBadSaveVersionTitle;

	`if(`notdefined(FINAL_RELEASE))
		DialogData.strAccept = m_strLoadAnyway;
		DialogData.strText = m_sBadSaveVersionDevText;
	`else
		DialogData.strText = m_sBadSaveVersionText;
	`endif

		DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		DialogData.fnCallback = DevVersionCheckOverride;

		Movie.Pres.UIRaiseDialog( DialogData );
	}
	else if( !`ONLINEEVENTMGR.CheckSaveDLCRequirements(SaveID, MissingDLC) )
	{
		DialogData.eType = eDialog_Warning;
		DialogData.strTitle = m_sMissingDLCTitle;
		DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
				
		DialogData.strText = Repl(m_sMissingDLCText, "%modnames%", MissingDLC);

		DialogData.strAccept = m_strLoadAnyway;
		DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		DialogData.fnCallback = DevDownloadableContentCheckOverride;

		Movie.Pres.UIRaiseDialog( DialogData );
	}
	else
	{
		`ONLINEEVENTMGR.LoadGame(SaveID, ReadSaveGameComplete);

		// Show a progress dialog if the load is being completed asynchronously
		if( m_bLoadInProgress )
		{
			ProgressDialogData.strTitle = m_sLoadingInProgress;
			Movie.Pres.UIProgressDialog(ProgressDialogData);
		}
	}
}

simulated function DevDownloadableContentCheckOverride(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		`ONLINEEVENTMGR.LoadGame(GetSaveIDSelection(m_iCurrentSelection), ReadSaveGameComplete);
	}
	else
	{
		m_bLoadInProgress = false;
	}
}

simulated function string GetCurrentSelectedFilename()
{
	local string SaveName;
	if(m_arrListItems[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.PlayerSaveDesc != "")
	{
		SaveName = m_arrListItems[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.PlayerSaveDesc;
	}
	else
	{
		SaveName = `ONLINEEVENTMGR.m_sEmptySaveString @ `AUTOSAVEMGR.GetNextSaveID();
	}

	return SaveName;
}

simulated public function OnDelete(optional UIButton control)
{
	local TDialogueBoxData kDialogData;

	if( m_iCurrentSelection >= 0 && m_iCurrentSelection < m_arrListItems.Length )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

		// Warn before deleting save
		kDialogData.eType     = eDialog_Warning;
		kDialogData.strTitle  = class'UISaveGame'.default.m_sDeleteSaveTitle;
		kDialogData.strText   = class'UISaveGame'.default.m_sDeleteSaveText @ GetCurrentSelectedFilename();
		kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
		kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

		kDialogData.fnCallback  = DeleteSaveWarningCallback;
		Movie.Pres.UIRaiseDialog( kDialogData );
	}
	else
	{
		// Can't delete an empty save slot!
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated function DeleteSelectedSaveFile()
{
	`ONLINEEVENTMGR.DeleteSaveGame( GetSaveIDSelection(m_iCurrentSelection) );
}

defaultproperties
{
	CurrentlySelectedCampaignIndex = -1
}