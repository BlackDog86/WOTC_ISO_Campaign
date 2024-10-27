class WOTC_ISO_Campaign_MCMScreen extends Object config(XComWOTC_ISO_Campaign);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;

`include(ISO_Campaign\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(SEPARATE_BY_CAMPAIGN);
`MCM_API_AutoCheckBoxVars(ENABLE_DELETE_CAMPAIGN_BUTTON);
`MCM_API_AutoCheckBoxVars(TWENTY_FOUR_HOUR_CLOCK);
`MCM_API_AutoCheckBoxVars(SHOW_MISSION_LOCATION_ON_CAMPAIGN_SCREEN);
`MCM_API_AutoCheckBoxVars(SHOW_MISSION_LOCATION_ON_SAVE_LOAD);

`include(ISO_Campaign\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(SEPARATE_BY_CAMPAIGN, 1);
`MCM_API_AutoCheckBoxFns(ENABLE_DELETE_CAMPAIGN_BUTTON, 1);
`MCM_API_AutoCheckBoxFns(TWENTY_FOUR_HOUR_CLOCK, 1);
`MCM_API_AutoCheckBoxFns(SHOW_MISSION_LOCATION_ON_CAMPAIGN_SCREEN, 1);
`MCM_API_AutoCheckBoxFns(SHOW_MISSION_LOCATION_ON_SAVE_LOAD, 1);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

//Simple one group framework code
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	LoadSavedSettings();
	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	
	//Uncomment to enable reset
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeader);

	`MCM_API_AutoAddCheckBox(Group, SEPARATE_BY_CAMPAIGN);	
	`MCM_API_AutoAddCheckBox(Group, ENABLE_DELETE_CAMPAIGN_BUTTON);	
	`MCM_API_AutoAddCheckBox(Group, TWENTY_FOUR_HOUR_CLOCK);
	`MCM_API_AutoAddCheckBox(Group, SHOW_MISSION_LOCATION_ON_CAMPAIGN_SCREEN);
	`MCM_API_AutoAddCheckBox(Group, SHOW_MISSION_LOCATION_ON_SAVE_LOAD);

	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	SEPARATE_BY_CAMPAIGN = `GETMCMVAR(SEPARATE_BY_CAMPAIGN);
	ENABLE_DELETE_CAMPAIGN_BUTTON = `GETMCMVAR(ENABLE_DELETE_CAMPAIGN_BUTTON);
	TWENTY_FOUR_HOUR_CLOCK = `GETMCMVAR(TWENTY_FOUR_HOUR_CLOCK);
	SHOW_MISSION_LOCATION_ON_CAMPAIGN_SCREEN = `GETMCMVAR(SHOW_MISSION_LOCATION_ON_CAMPAIGN_SCREEN);
	SHOW_MISSION_LOCATION_ON_SAVE_LOAD = `GETMCMVAR(SHOW_MISSION_LOCATION_ON_SAVE_LOAD);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(SEPARATE_BY_CAMPAIGN);
	`MCM_API_AutoReset(ENABLE_DELETE_CAMPAIGN_BUTTON);
	`MCM_API_AutoReset(TWENTY_FOUR_HOUR_CLOCK);
	`MCM_API_AutoReset(SHOW_MISSION_LOCATION_ON_CAMPAIGN_SCREEN);
	`MCM_API_AutoReset(SHOW_MISSION_LOCATION_ON_SAVE_LOAD);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}

