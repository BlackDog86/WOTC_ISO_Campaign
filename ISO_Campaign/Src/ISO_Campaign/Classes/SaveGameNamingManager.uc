class SaveGameNamingManager extends Object config(SaveNames);

struct SaveName
{
	var int CampaignIndex;
	var string CampaignName;
};

var config array<SaveName> SaveNameDict;

static function string GetSaveName(int CampaignIndex)
{
	local SaveName Save;
	local int i;

	for (i = 0; i < default.SaveNameDict.Length; i++)
	{
		Save = default.SaveNameDict[i];
		if (Save.CampaignIndex == CampaignIndex)
			return default.SaveNameDict[i].CampaignName;
	}
	return "";
}

static function SetSaveName(int CampaignIndex, string NewName)
{
	local SaveName Save, EmptySave;
	local int i;

	for (i = 0; i < default.SaveNameDict.Length; i++)
	{
		Save = default.SaveNameDict[i];
		if (Save.CampaignIndex == CampaignIndex)
		{
			default.SaveNameDict[i].CampaignName = NewName;
			StaticSaveConfig();
			return;
		}
	}
	
	EmptySave.CampaignIndex = CampaignIndex;
	EmptySave.CampaignName = NewName;
	default.SaveNameDict.AddItem(EmptySave);
	StaticSaveConfig();
}