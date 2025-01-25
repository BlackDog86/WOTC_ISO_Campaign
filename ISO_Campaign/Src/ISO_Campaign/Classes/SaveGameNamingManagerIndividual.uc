class SaveGameNamingManagerIndividual extends Object config(SaveNamesIndividual);

struct SaveName
{
	var string FileName;
	var string ParsedFileName;
	var string SaveName;
};

var config array<SaveName> SaveNameDictInd;

static function string GetSaveName(string FileName)
{
	local SaveName Save;
	local int i;
	local array<string> splitFileName;

	ParseStringIntoArray(Repl(FileName, "save_Save ", ""), splitFileName, "_", true);
	//`log("GetSaveName is looking for a match for save with Index:" @ SaveIndex,,'BDLOG');

	for (i = 0; i < default.SaveNameDictInd.Length; i++)
	{	
		Save = default.SaveNameDictInd[i];
		if (Save.FileName == FileName)
		{
			`log("GetSaveName found a save - FileName:" @ Save.FileName @ "Description:" @ Save.SaveName,,'BDLOG');
			return default.SaveNameDictInd[i].SaveName;
		}
		else if (Save.ParsedFileName == splitFileName[0])
		{
			return default.SaveNameDictInd[i].SaveName;
		}
	}
	return "";
}

static function SetSaveName(string FileName, string NewName)
{
	local SaveName Save, EmptySave;
	local int i;
	local bool saveNameSet;
	local array<string> splitFileName;
	
	//`log("Seting Save Name: SaveIndex:" @ SaveIndex,,'BDLOG');
	ParseStringIntoArray(Repl(FileName, "save_Save ", ""), splitFileName, "_", true);

	for (i = 0; i < default.SaveNameDictInd.Length; i++)
	{
		Save = default.SaveNameDictInd[i];
		if (Save.ParsedFileName == splitFileName[0])
		{
			`log("SetSaveName: Save Already Exists: Current Name:" @ Save.SaveName,,'BDLOG');
			default.SaveNameDictInd[i].SaveName = NewName;
			saveNameSet = true;
		}
	}
	
	if(saveNameSet)
	{
		StaticSaveConfig();
		return;
	}
	else
	{	
		`log("SetSaveName: Save doesn't already exist, adding entry to dictionary:" @ NewName,,'BDLOG');
		EmptySave.FileName = FileName;
		ParseStringIntoArray(Repl(FileName, "save_Save ", ""), splitFileName, "_", true);
		EmptySave.ParsedFileName = splitFileName[0];
		EmptySave.SaveName = NewName;
		default.SaveNameDictInd.AddItem(EmptySave);
		StaticSaveConfig();
	}
}

static function RemoveSaveName(string FileName)
{
	local SaveName Save;
	local int i;
	local array<string> splitFileName;

	ParseStringIntoArray(Repl(FileName, "save_Save ", ""), splitFileName, "_", true);
	//`log("RemoveSaveName is looking for an entry to remove:" @ SaveIndex,,'BDLOG');	
	for (i = 0; i < default.SaveNameDictInd.Length; i++)
	{
		Save = default.SaveNameDictInd[i];
		if (Save.FileName == FileName || splitFileName[0] == Save.ParsedFileName)
		{
			`log("RemoveSaveName found an entry to delete - Removing from Dictionary: Name:" @ Save.SaveName,,'BDLOG');
			default.SaveNameDictInd.RemoveItem(Save);
		}
	StaticSaveConfig();
	}
}

