class UISaveProperSort extends UISaveGame;

var localized string m_RenameCampaign;
var localized string m_SaveToCampaign;
var int RenameCampaignIndex;

var int CurrentlySelectedCampaignIndex;
var array<int> AvailableCampaignIndex;
var array<UISaveGameCampaignSelectItem> m_arrListCampaign;

var bool hasRefreshed;

simulated function OnInit()
{
	local XComGameState_CampaignSettings CampaignSetting;

		If(`ISCONTROLLERACTIVE)
		{
		`log("Controller is active");
		}
		Else
		{
		`log("Controller is not active, but should be?");
		}

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

	class'UILoadProperSort'.static.FilterSaveGameList( m_arrSaveGames, m_bBlockingSavesFromOtherLanguages, FilterLadders );
	
	//`ONLINEEVENTMGR.SortSavedGameListByTimestamp(m_arrSaveGames);		
	//m_arrSaveGames.Sort(class'UILoadProperSort'.static.SortByDate);
	class'UILoadProperSort'.static.QuickSort(0, m_arrSaveGames.Length, m_arrSaveGames); 

	AvailableCampaignIndex.Length = 0;
	for (i = 0; i < m_arrSaveGames.Length; i ++)
	{
		if (AvailableCampaignIndex.Find(m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum) == INDEX_NONE)
			AvailableCampaignIndex.AddItem(m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum);
	}

	BuildMenu();
	SetTimer(0.25f, false, nameof(UpdateAllSaves));

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

	if (class'UILoadProperSort'.default.SeparateSaveGamesByCampaign)
	{
		if (CurrentlySelectedCampaignIndex == -1)
		{
			AS_SetTitle(m_sSaveTitle);
			for( i = 0; i < m_arrSaveGames.Length; i++ )
			{
				Index = m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum;
				if (ShownIndex.Find(Index) == INDEX_NONE && AvailableCampaignIndex.Find(Index) != INDEX_NONE)
				{
					ShownIndex.AddItem(Index);
					
					m_arrListCampaign.AddItem(Spawn(class'UISaveGameCampaignSelectItem', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_arrSaveGames[i], true, OnAcceptCamp, OnRename, SetSelectionCamp));
					m_arrListCampaign[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);
				}
			}
		}
		else
		{
			m_arrListItems.AddItem(Spawn(class'UISaveLoadGameListItem', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_BlankSaveGame, true, OnAccept, OnDelete, OnRename, SetSelection));
			m_arrListItems[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);

			AS_SetTitle(m_SaveToCampaign @ CurrentlySelectedCampaignIndex $ ":" @ class'SaveGameNamingManager'.static.GetSaveName(CurrentlySelectedCampaignIndex));
			for( i = 0; i < m_arrSaveGames.Length; i++ )
			{
				if (CurrentlySelectedCampaignIndex == m_arrSaveGames[i].SaveGames[0].SaveGameHeader.GameNum)
				{
					m_arrListItems.AddItem(Spawn(class'UISaveLoadGameListItem', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_arrSaveGames[i],true, OnAccept, OnDelete, OnRename, SetSelection));
					m_arrListItems[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);
				}
			}
		}
	}
	else
	{
		m_arrListItems.AddItem(Spawn(class'UISaveLoadGameListItem', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_BlankSaveGame, true, OnAccept, OnDelete, OnRename, SetSelection));
		m_arrListItems[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);

		AS_SetTitle(m_sSaveTitle);
		for( i = 0; i < m_arrSaveGames.Length; i++ )
		{
			m_arrListItems.AddItem(Spawn(class'UISaveLoadGameListItem', List.ItemContainer).InitSaveLoadItem(ItemIndex, m_arrSaveGames[i], true, OnAccept, OnDelete, OnRename, SetSelection));
			m_arrListItems[ItemIndex++].ProcessMouseEvents(List.OnChildMouseEvent);
		}
	}
	
	m_iCurrentSelection = -1;
	SetTimer(0.25f, false, nameof(UpdateAllSaves));
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}

simulated function string GetCurrentSelectedCampaignName()
{
	local string SaveName;

	if (class'UILoadProperSort'.default.SeparateSaveGamesByCampaign && CurrentlySelectedCampaignIndex == -1)
	{
		SaveName = class'SaveGameNamingManager'.static.GetSaveName(m_arrListCampaign[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.GameNum);
	}
	else
	{
		SaveName = class'SaveGameNamingManager'.static.GetSaveName(m_arrListItems[m_iCurrentSelection].SaveGame.SaveGames[0].SaveGameHeader.GameNum);
	}

	return SaveName;
}

simulated public function OnRename(optional UIButton control)
{
	local TInputDialogData kData;

	if (m_iCurrentSelection == 0 && (!class'UILoadProperSort'.default.SeparateSaveGamesByCampaign || CurrentlySelectedCampaignIndex != -1)) // New Save
	{
		kData.strTitle = m_sNameSave;
		kData.iMaxChars = 40;
		kData.strInputBoxText = GetCurrentSelectedFilename();
		kData.fnCallbackAccepted = SetCurrentSelectedFilename;
	}
	else
	{
		kData.strTitle = m_RenameCampaign;
		kData.iMaxChars = 40;
		kData.strInputBoxText = GetCurrentSelectedCampaignName();
		kData.fnCallbackAccepted = SetCurrentSelectedFilenameX;
	}
	
	Movie.Pres.UIInputDialog(kData);
}

simulated function SetCurrentSelectedFilenameX(string text)
{	
	text = Repl(text, "\n", "", false);
	if (class'UILoadProperSort'.default.SeparateSaveGamesByCampaign)
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
	class'SaveGameNamingManager'.static.SetSaveName(RenameCampaignIndex, text);
	UpdateAllSaves();
}

simulated function UpdateAllSaves()
{
	local int i;
	local UISaveLoadItemWithNames SaveSlot;
	local UISaveGameCampaignSelectItem CampSlot;
	for (i = 1; i < m_arrListItems.Length; i++)
	{
		SaveSlot = UISaveLoadItemWithNames(m_arrListItems[i]);
		if (SaveSlot != none)
			SaveSlot.UpdateDataWithNames(m_arrListItems[i].SaveGame);
	}
	for (i = 0; i < m_arrListCampaign.Length; i++)
	{
		CampSlot = m_arrListCampaign[i];
		if (CampSlot != none)
			CampSlot.UpdateData(m_arrListCampaign[i].SaveGame);
	}
}

simulated public function OnAcceptCamp(optional UIButton control)
{
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
	`log("SetSelectionCamp on UISave entered");
	if (m_iCurrentSelection >=0 && m_iCurrentSelection < m_arrListCampaign.Length)
	{
		m_arrListCampaign[m_iCurrentSelection].HideHighlight();
	}
	for (i = 0; i < m_arrListCampaign.Length; i++)
	{
		m_arrListCampaign[i].OnLoseFocus();	
	}

	m_iCurrentSelection = currentSelection;
	
	if (m_iCurrentSelection < 0)
	{
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
		m_arrListCampaign[m_iCurrentSelection].OnReceiveFocus();

		List.Scrollbar.SetThumbAtPercent(float(m_iCurrentSelection) / float(m_arrListCampaign.Length - 1));
	}
}

simulated public function OnCancel()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	//if (class'UILoadProperSort'.default.SeparateSaveGamesByCampaign && CurrentlySelectedCampaignIndex > -1)
	//{
		//CurrentlySelectedCampaignIndex = -1;
		//BuildMenu();
	//}
	//else
	//{
		NavHelp.ClearButtonHelp();
		`ONLINEEVENTMGR.bInitiateReplayAfterLoad = false;
		Movie.Stack.Pop(self);
	//}
}

simulated function  int GetSaveIDSelection(int iIndex)
{
	if (iIndex >= 0 && iIndex < m_arrListItems.Length)
		return `ONLINEEVENTMGR.SaveNameToID(m_arrListItems[iIndex].SaveGame.Filename);

	return -1;      //  if it's not in the save game list it can't be loaded 
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

simulated public function OnUDPadUp()
{
	local int numSaves;
	local int newSel;
	numSaves = GetNumSaves();

	if ( numSaves > 1 )
	{
		PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
	}

	newSel = m_iCurrentSelection - 1;
	
	`log("NewSel ="@newSel);
	`log("numSaves="@numSaves);
	`log("List item array length =" @ m_arrListItems.length);
	`log("List item campaign length =" @ m_arrListCampaign.length);

	if (newSel < 0)
		//if we've gone off the top of the campaign select menu
		If(class'UILoadProperSort'.default.SeparateSaveGamesByCampaign && CurrentlySelectedCampaignIndex == -1)
		{
			newSel = m_arrListCampaign.length - 1;
		}
		Else
		{
		//we've gone off the top of the normal save menu
			newSel = m_arrListItems.length - 1;
		}
	
	`log("Selected campaign index is:" @ CurrentlySelectedCampaignIndex);
	If(class'UILoadProperSort'.default.SeparateSaveGamesByCampaign && CurrentlySelectedCampaignIndex == -1)
			{
				If (newSel >= m_arrListCampaign.length)
				{
				newSel=0;
				}
			`log("SetSelectionCamp fired");
			SetSelectionCamp(newSel);
			}
			Else
			{
			If (m_arrListItems.length != 0 && newSel >= m_arrListItems.length)
				{
				newSel=0;
				}								
			`log("SetSelection Fired");
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
	
	newSel = m_iCurrentSelection + 1;
	`log("NewSel ="@newSel);
	`log("numSaves="@numSaves);
	if (newSel >= numSaves)
		newSel = 0;

	If(class'UILoadProperSort'.default.SeparateSaveGamesByCampaign && CurrentlySelectedCampaignIndex == -1)
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