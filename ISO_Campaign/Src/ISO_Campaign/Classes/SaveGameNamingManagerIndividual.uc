class SaveGameNamingManagerIndividual extends Object config(SaveNamesIndividual);

struct SaveName
{
	var int SaveIndex;
	var string SaveName;
};

var config array<SaveName> SaveNameDictInd;

static function string GetSaveName(int SaveIndex)
{
	local SaveName Save;
	local int i;
	//`log("GetSaveNaame SaveIndex: " @ SaveIndex,,'BDLOG');

	for (i = 0; i < default.SaveNameDictInd.Length; i++)
	{
	//	`log("GetSaveName Iterating through dictionary - Index:" @ Save.SaveIndex @ "Name:" @ Save.SaveName,,'BDLOG');
		Save = default.SaveNameDictInd[i];
		if (Save.SaveIndex == SaveIndex)
			return default.SaveNameDictInd[i].SaveName;
	}
	return "";
}

static function SetSaveName(int SaveIndex, string NewName)
{
	local SaveName Save, EmptySave;
	local int i;
	//`log("SetSaveName SaveIndex:" @ SaveIndex,,'BDLOG');

	for (i = 0; i < default.SaveNameDictInd.Length; i++)
	{
		Save = default.SaveNameDictInd[i];
	//	`log("SetSaveName Iterating through dictionary - Index:" @ Save.SaveIndex @ "Name:" @ Save.SaveName,,'BDLOG');
		if (Save.SaveIndex == SaveIndex)
		{
			default.SaveNameDictInd[i].SaveName = NewName;
			StaticSaveConfig();
			return;
		}
	}
	
	EmptySave.SaveIndex = SaveIndex;
	EmptySave.SaveName = NewName;
	default.SaveNameDictInd.AddItem(EmptySave);
	StaticSaveConfig();
}