class WOTC_ISO_Campaign_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local WOTC_ISO_Campaign_MCMScreen MCMScreen;

	if (ScreenClass==none)
	{
		if (MCM_API(Screen) != none)
			ScreenClass=Screen.Class;
		else return;
	}

	MCMScreen = new class'WOTC_ISO_Campaign_MCMScreen';
	MCMScreen.OnInit(Screen);
}

defaultproperties
{
    ScreenClass = none;
}
