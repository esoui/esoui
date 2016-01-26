-- This file will store the different Save Load dialogs
-- using ESO_Dialogs

ESO_Dialogs["OUT_OF_SPACE"] =
{
	gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title = 
	{
		text = SI_SAVE_ERROR_TITLE,
	},
	mainText =
	{
		text = SI_OUT_OF_SPACE,
	},

	mustChoose = true,
	
	buttons = 
	{
		[1] =
		{
			text = SI_DIALOG_YES,
			callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_OUT_OF_SPACE, SLD_ANSWER_YES)
			end

		},

		[2] =
		{
			text = SI_DIALOG_NO,
			callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_OUT_OF_SPACE, SLD_ANSWER_NO)
			end
		}
	}
}

ESO_Dialogs["CORRUPT_SAVE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title = 
    {
        text = SI_SAVE_ERROR_TITLE,
    },
    mainText = 
    {
        text = SI_CORRUPT_SAVE,
    },

    mustChoose = true,

    buttons = 
    {
        [1] =
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_FILE_CORRUPT, SLD_ANSWER_YES)
            end
        },
        
        [2] =
        {
            text = SI_DIALOG_NO,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_FILE_CORRUPT, SLD_ANSWER_NO)
            end
        }
    }
}

ESO_Dialogs["FAILED_LOAD"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_LOAD_ERROR_TITLE,
    },

    mainText = 
    {
        text = SI_FAILED_LOAD,
    },

    mustChoose = true,

    buttons = 
    {
        [1] =
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_FAILED_LOAD, SLD_ANSWER_YES)
            end
        },
        
        [2] =
        {
            text = SI_DIALOG_NO,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_FAILED_LOAD, SLD_ANSWER_NO)
            end
        }
    }
}

ESO_Dialogs["FAILED_SAVE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_SAVE_ERROR_TITLE,
    },

    mainText = 
    {
        text = SI_FAILED_SAVE,
    },

    mustChoose = true,

    buttons = 
    {
        [1] =
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_FAILED_SAVE, SLD_ANSWER_YES)
            end
        },
        
        [2] =
        {
            text = SI_DIALOG_NO,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_FAILED_SAVE, SLD_ANSWER_NO)
            end
        }
    }
}

ESO_Dialogs["SAVE_DEST_REMOVED_STORAGE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_SAVE_ERROR_TITLE,
    },

    mainText = 
    {
        text = SI_SAVE_DEST_REMOVED_STORAGE,
    },

    mustChoose = true,

    buttons = 
    {
        [1] =
        {
            text = SI_OK,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_SAVE_DEST_REMOVED, SLD_ANSWER_YES)
            end
        }
    }
}

ESO_Dialogs["NO_SAVE_CONTINUE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_SAVE_ERROR_TITLE,
    },

    mainText = 
    {
        text = SI_NO_SAVE_CONTINUE,
    },

    mustChoose = true,

    buttons = 
    {
        [1] =
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_NO_SAVE_CREATED, SLD_ANSWER_YES)
            end
        },
        
        [2] =
        {
            text = SI_DIALOG_NO,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_NO_SAVE_CREATED, SLD_ANSWER_NO)
            end
        }
    }
}

ESO_Dialogs["NO_SAVE_DEVICE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_SAVE_ERROR_TITLE,
    },

    mainText = 
    {
        text = SI_NO_SAVE_DEVICE,
    },

    mustChoose = true,

    buttons = 
    {
        [1] =
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_NO_SAVE_DEVICE_SELECTED, SLD_ANSWER_YES)
            end
        },
        
        [2] =
        {
            text = SI_DIALOG_NO,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_NO_SAVE_DEVICE_SELECTED, SLD_ANSWER_NO)
            end
        }
    }
}

ESO_Dialogs["ALLOW_OVERWRITE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_SAVE_ERROR_TITLE,
    },

    mainText = 
    {
        text = SI_ALLOW_OVERWRITE,
    },

    mustChoose = true,

    buttons = 
    {
        [1] =
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_ALLOW_OVERWRITE, SLD_ANSWER_YES)
            end
        },
        
        [2] =
        {
            text = SI_DIALOG_NO,
            callback = function(dialog)
                SaveLoadDialogResult(SLD_ERROR_ALLOW_OVERWRITE, SLD_ANSWER_NO)
            end
        }
    }
}

local DIALOG_TABLE = {
	[SLD_ERROR_OUT_OF_SPACE] = "OUT_OF_SPACE",
	[SLD_ERROR_FILE_CORRUPT] = "CORRUPT_SAVE",
	[SLD_ERROR_FAILED_LOAD] = "FAILED_LOAD",
	[SLD_ERROR_FAILED_SAVE] = "FAILED_SAVE",
	[SLD_ERROR_SAVE_DEST_REMOVED] = "SAVE_DEST_REMOVED_STORAGE",
	[SLD_ERROR_NO_SAVE_CREATED] = "NO_SAVE_CONTINUE",
	[SLD_ERROR_NO_SAVE_DEVICE_SELECTED] = "NO_SAVE_DEVICE",
	[SLD_ERROR_ALLOW_OVERWRITE] = "ALLOW_OVERWRITE",
}



local function HandleSaveLoadError(eventCode, errorCode)
    local profile = GetOnlineIdForActiveProfile()
    if profile ~= "" then
        -- only show this dialog if we still have a profile
        local dialogName = DIALOG_TABLE[errorCode]
        if(dialogName) then
            ZO_Dialogs_ShowPlatformDialog(dialogName)
        end
    end
end

EVENT_MANAGER:RegisterForEvent("SaveLoadDialog", EVENT_SLD_SAVE_LOAD_ERROR, HandleSaveLoadError)
