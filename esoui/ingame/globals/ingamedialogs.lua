ESO_Dialogs["CHAT_TAB_REMOVE"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_REMOVE_TAB,
    },
    mainText = 
    {
        text = SI_CHAT_DIALOG_REMOVE_TAB,
    },

    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            dialog.data.container:RemoveWindow(dialog.data.index)
                        end,
        },
        
        [2] =
        {
            text =      SI_DIALOG_DECLINE,
        }
    }
}

ESO_Dialogs["CHAT_TAB_RESET"] = 
{
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_RESET_TAB,
    },
    mainText = 
    {
        text = SI_CHAT_DIALOG_RESET_TAB,
    },

    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            CHAT_OPTIONS:Reset()
                        end,
        },
        
        [2] =
        {
            text =      SI_DIALOG_DECLINE,
        }
    }
}

ESO_Dialogs["ABANDON_QUEST"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_ABANDON_QUEST,
    },
    mainText = 
    {
        text = SI_CONFIRM_ABANDON_QUEST,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_ABANDON_QUEST_CONFIRM,
            callback =  function(dialog)
                            AbandonQuest(dialog.data.questIndex)
                        end,
        },
        
        [2] =
        {
            text =      SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["RITUAL_OF_MARA_PROMPT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_RITUAL_OF_MARA_PROMPT,
    },
    mainText = 
    {
        text = SI_RITUAL_OF_MARA_PROMPT,
    },
    noChoiceCallback =  function()
                            SendPledgeOfMaraResponse(PLEDGE_OF_MARA_RESPONSE_DECLINE)
                        end,
    hideSound = SOUNDS.DIALOG_DECLINE,
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            SendPledgeOfMaraResponse(PLEDGE_OF_MARA_RESPONSE_ACCEPT)
                        end,
        },
        [2] =
        {
            text =      SI_NO,
            callback =  function(dialog)
                            SendPledgeOfMaraResponse(PLEDGE_OF_MARA_RESPONSE_DECLINE)
                        end,
        }
    }
}

ESO_Dialogs["DESTROY_ITEM_PROMPT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
        allowRightStickPassThrough = true,
    },
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_DESTROY_ITEM_PROMPT,
    },
    mainText = 
    {
        text = SI_DESTROY_ITEM_PROMPT,
    },
    noChoiceCallback =  function()
                            RespondToDestroyRequest(false)
                        end,
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            RespondToDestroyRequest(true)
                        end,
        },
        [2] =
        {
            text =      SI_NO,
            callback =  function(dialog)
                            RespondToDestroyRequest(false)
                        end,
        }
    }
}

ESO_Dialogs["CONFIRM_DESTROY_ITEM_PROMPT"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_DESTROY_ITEM_PROMPT,
    },
    mainText = 
    {
        text = SI_CONFIRM_DESTROY_ITEM_PROMPT,
    },
	editBox =
    {       
	    matchingString = GetString(SI_DESTROY_ITEM_CONFIRMATION)
    },
    noChoiceCallback =  function()
                            RespondToDestroyRequest(false)
                        end,
    buttons =
    {
        {
            requiresTextInput = true,
            text =      SI_CHAT_DIALOG_CONFIRM_ITEM_DESTRUCTION,
            callback =  function(dialog)
							local confirmDelete = ZO_Dialogs_GetEditBoxText(dialog)
							local compareString = GetString(SI_DESTROY_ITEM_CONFIRMATION)
							if confirmDelete and confirmDelete ~= compareString then
								RespondToDestroyRequest(false)
							else
								RespondToDestroyRequest(true)
							end
                        end,
        },        
        {
            text =       SI_DIALOG_CANCEL,
            callback =  function(dialog)
                            RespondToDestroyRequest(false)
                        end,
        }
    }
}

ESO_Dialogs["KEEP_CLAIM_WRONG_ALLIANCE"] = 
{
    mainText = 
    {
        text = SI_KEEP_CLAIM_WRONG_ALLIANCE,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
        }
    }
}

ESO_Dialogs["KEEP_CLAIM_NOT_IN_GUILD"] = 
{
    mainText = 
    {
        text = SI_KEEP_CLAIM_NOT_IN_GUILD,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
        }
    }
}

ESO_Dialogs["PAY_FOR_CONVERSATION"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_PAY_FOR_CONVERSATION,
    },
    mainText = 
    {
        text = SI_PAY_FOR_CONVERSATION_PROMPT,
    },
    buttons = 
    {
        [1] =
        {
            text = SI_YES,
            callback =  function(dialog)
                            SelectChatterOption(dialog.data.chatterOptionIndex)
                        end,
        },
        [2] =
        {
            text = SI_NO,
        }
    }
}

ESO_Dialogs["CONFIRM_PURCHASE"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_CONFIRM_PURCHASE,
    },
    mainText = 
    {
        text = SI_CONFIRM_PURCHASE
    },
    buttons = 
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                BuyStoreItem(dialog.data.buyIndex, 1)
            end,
        },
        [2] = 
        {
            text = SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["BUY_BANK_SPACE"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_BUY_BANK_SPACE,
    },
    mainText = 
    {
        text = zo_strformat(SI_BUY_BANK_SPACE, NUM_BANK_SLOTS_PER_UPGRADE),
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            BuyBankSpace()
                        end,
        },
        [2] =
        {
            text =       SI_DIALOG_DECLINE,
        },
    },
    updateFn = function(dialog)
        local cost = dialog.data.cost
        if cost > GetCarriedCurrencyAmount(CURT_MONEY) then
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_DISABLED)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_BUY_BANK_SPACE_CANNOT_AFFORD })
        else
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_NORMAL)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = zo_strformat(SI_BUY_BANK_SPACE, NUM_BANK_SLOTS_PER_UPGRADE) })
        end
        ZO_Dialogs_UpdateButtonCost(dialog, 1, cost)
    end,
}

ESO_Dialogs["BUY_BAG_SPACE"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_BUY_BAG_SPACE,
    },
    mainText = 
    {
        text = zo_strformat(SI_BUY_BAG_SPACE, NUM_BACKPACK_SLOTS_PER_UPGRADE),
    },
    noChoiceCallback = function(dialog)
                            INTERACT_WINDOW:OnEndInteraction(BUY_BAG_SPACE_INTERACTION)
                         end,
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            BuyBagSpace()
                            INTERACT_WINDOW:OnEndInteraction(BUY_BAG_SPACE_INTERACTION)
                        end,
        },
        [2] =
        {
            text =       SI_DIALOG_DECLINE,
            callback =   function(dialog)
                            INTERACT_WINDOW:OnEndInteraction(BUY_BAG_SPACE_INTERACTION)
                         end,
        },
    },
    updateFn = function(dialog)
        local cost = dialog.data.cost
        if cost > GetCarriedCurrencyAmount(CURT_MONEY) then
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_DISABLED)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_BUY_BAG_SPACE_CANNOT_AFFORD })
        else
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_NORMAL)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = zo_strformat(SI_BUY_BAG_SPACE, NUM_BACKPACK_SLOTS_PER_UPGRADE) })
        end
        ZO_Dialogs_UpdateButtonCost(dialog, 1, cost)
    end,
}

ESO_Dialogs["REPAIR_ALL"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_REPAIR_ALL,
    },
    mainText = 
    {
        text = SI_REPAIR_ALL,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            RepairAll()
                            PlaySound(SOUNDS.INVENTORY_ITEM_REPAIR)
                        end,
            enabled =   function(dialogOrDescriptor)
                            local dialog = dialogOrDescriptor.dialog or dialogOrDescriptor  -- if .dialog is defined, we're running in Gamepad UI
                            local canAfford = dialog.data.cost <= GetCarriedCurrencyAmount(CURT_MONEY)

                            if canAfford then
                                return true
                            else
                                return false, GetString(SI_REPAIR_ALL_CANNOT_AFFORD)
                            end
                        end,
        },
        [2] =
        {
            text =      SI_DIALOG_DECLINE,
            callback =  function(dialog)
                            if (dialog.data.declineCallback) then
                               dialog.data.declineCallback()
                            end
                        end,
        },
    },
    updateFn = function(dialog)
        local cost = dialog.data.cost
        local buttonState
        
        if cost > GetCarriedCurrencyAmount(CURT_MONEY) then
            buttonState = BSTATE_DISABLED
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_REPAIR_ALL_CANNOT_AFFORD })
        else
            buttonState = BSTATE_NORMAL
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_REPAIR_ALL })
        end

        if not IsInGamepadPreferredMode() then
            ZO_Dialogs_UpdateButtonState(dialog, 1, buttonState)
            ZO_Dialogs_UpdateButtonCost(dialog, 1, cost)
        else
            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups(dialog.keybindStateIndex)
        end
    end,
}

ESO_Dialogs["SELL_ALL_JUNK"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_SELL_ITEMS,
    },
    mainText = 
    {
        text = SI_SELL_ALL_JUNK,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_SELL_ALL_JUNK_CONFIRM,
            callback =  SellAllJunk,
        },
        [2] =
        {
            text =       SI_DIALOG_DECLINE,
        },
    },
}

ESO_Dialogs["DESTROY_ALL_JUNK"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_DESTROY_ITEMS,
    },
    mainText = 
    {
        text = SI_DESTROY_ALL_JUNK,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DESTROY_ALL_JUNK_CONFIRM,
            callback =  DestroyAllJunk,
            clickSound = SOUNDS.INVENTORY_DESTROY_JUNK,
        },
        [2] =
        {
            text =       SI_DIALOG_DECLINE,
        },
    },
}

ESO_Dialogs["CANT_BUYBACK_FROM_FENCE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_STOLEN_ITEM_CANNOT_BUYBACK_TITLE,
    },
    mainText = 
    {
        text = zo_strformat(SI_STOLEN_ITEM_CANNOT_BUYBACK_TEXT),
    },
    buttons =
    {
        [1] =
        {
            text =      SI_ITEM_ACTION_SELL,
            callback =  function(dialog)
                            SellInventoryItem(dialog.data.bag, dialog.data.slot, dialog.data.stackCount)
                        end,
        },
        [2] =
        {
            text =      SI_DIALOG_CANCEL,
        },
    },
    updateFn = function(dialog)
        local itemColor = GetItemQualityColor(dialog.data.quality)
        ZO_Dialogs_RefreshDialogText("CANT_BUYBACK_FROM_FENCE", dialog, { mainTextParams = { itemColor:Colorize(dialog.data.itemName) } } )
    end,
}

ESO_Dialogs["SCRIPT_ACCESS_VIOLATION"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_SCRIPT_ACCESS_VIOLATION,
    },
    mainText = 
    {
        text = SI_SCRIPT_ACCESS_VIOLATION,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
        }    
    },
}

ESO_Dialogs["DELETE_MAIL"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_DELETE_MAIL,
    },
    mainText = 
    {
        text = SI_MAIL_CONFIRM_DELETE,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_MAIL_DELETE,
            callback =  function(dialog)
                            dialog.data.callback(dialog.data.mailId)
                        end
        },
        
        [2] =
        {
            text =      SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["DELETE_MAIL_ATTACHMENTS"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_DELETE_MAIL_ATTACHMENTS,
    },
    mainText = 
    {
        text = SI_MAIL_CONFIRM_DELETE_ATTACHMENTS,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_YES,
            callback =  function(dialog)
                            MAIL_INBOX:ConfirmDelete(dialog.data)
                        end
        },
        
        [2] =
        {
            text =      SI_DIALOG_NO,
        }
    }
}

ESO_Dialogs["DELETE_MAIL_MONEY"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_DELETE_MAIL_MONEY,
    },
    mainText = 
    {
        text = SI_MAIL_CONFIRM_DELETE_MONEY,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_YES,
            callback =  function(dialog)
                            MAIL_INBOX:ConfirmDelete(dialog.data)
                        end
        },
        
        [2] =
        {
            text =      SI_DIALOG_NO,
        }
    }
}

ESO_Dialogs["DELETE_MAIL_ATTACHMENTS_AND_MONEY"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_DELETE_MAIL_ATTACHMENTS,
    },
    mainText = 
    {
        text = SI_MAIL_CONFIRM_DELETE_ATTACHMENTS_AND_MONEY,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_YES,
            callback =  function(dialog)
                            MAIL_INBOX:ConfirmDelete(dialog.data)
                        end
        },
        
        [2] =
        {
            text =      SI_DIALOG_NO,
        }
    }
}

ESO_Dialogs["MAIL_TAKE_ATTACHMENT_COD"] = 
{
    title =
    {
        text = SI_PROMPT_TITLE_MAIL_TAKE_ATTACHMENT_COD,
    },
    mainText = 
    {
        text = SI_MAIL_CONFIRM_TAKE_ATTACHMENT_COD
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function () MAIL_INBOX:ConfirmAcceptCOD() end,
        },
        {
            text = SI_DIALOG_DECLINE,
        }
    },
     
    updateFn = function(dialog)
        local codAmount = dialog.data.codAmount
        if codAmount > GetCarriedCurrencyAmount(CURT_MONEY) then
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_DISABLED)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_MAIL_COD_NOT_ENOUGH_MONEY })
        else
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_NORMAL)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_MAIL_CONFIRM_TAKE_ATTACHMENT_COD })
        end
        ZO_Dialogs_UpdateButtonCost(dialog, 1, codAmount)
    end,
}

ESO_Dialogs["GAMEPAD_MAIL_TAKE_ATTACHMENT_COD"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_MAIL_TAKE_ATTACHMENT_COD,
    },
    mainText = 
    {
        text = SI_MAIL_CONFIRM_TAKE_ATTACHMENT_COD
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog) dialog.data.callback() end,
        },
        {
            text = SI_DIALOG_DECLINE,
        }
    },
}

ESO_Dialogs["MAIL_RETURN_ATTACHMENTS"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_MAIL_CONFIRM_RETURN_ATTACHMENTS_TITLE,
    },
    mainText =
    {
        text = SI_MAIL_CONFIRM_RETURN_ATTACHMENTS,
    },
    buttons =
    {
        {
            text = SI_MAIL_RETURN,
            callback = function(dialog)
                dialog.data.callback(dialog.data.mailId)
            end
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
    finishedCallback = function(dialog)
        if dialog.data.finishedCallback then
            dialog.data.finishedCallback()
        end
    end,
}

ESO_Dialogs["TOO_FREQUENT_BUG_SCREENSHOT"] = 
{
    mainText = 
    {
        text = SI_TOO_FREQUENT_BUG_SCREENSHOT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
        }
    }
}

ESO_Dialogs["FAST_TRAVEL_CONFIRM"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_FAST_TRAVEL_CONFIRM,
    },
    mainText = 
    {
        text = SI_FAST_TRAVEL_DIALOG_MAIN_TEXT,
    },
    buttons =
    {
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                local data = dialog.data
                FastTravelToNode(data.nodeIndex)
                SCENE_MANAGER:ShowBaseScene()
            end,
        },        
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["RECALL_CONFIRM"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_FAST_TRAVEL_CONFIRM,
    },
    mainText = 
    {
        text = function(dialog)
            local cooldown = GetRecallCooldown()
            local destination = dialog.data.nodeIndex
            local cost = GetRecallCost(destination)
            local currency = GetRecallCurrency(destination)
            local canAffordRecall = cost <= GetCarriedCurrencyAmount(currency)

            if cooldown == 0 or cost == 0 then
                if canAffordRecall then
                    return SI_FAST_TRAVEL_DIALOG_MAIN_TEXT
                else
                    return SI_FAST_TRAVEL_DIALOG_CANT_AFFORD
                end
            else
                if canAffordRecall then
                    return SI_FAST_TRAVEL_DIALOG_PREMIUM
                else
                    return SI_FAST_TRAVEL_DIALOG_CANT_AFFORD_PREMIUM
                end
            end
        end,
    },
    buttons =
    {
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                local data = dialog.data
                FastTravelToNode(data.nodeIndex)
                SCENE_MANAGER:ShowBaseScene()
            end,
            visible = function(dialog)
                local destination = dialog.data.nodeIndex
                local currency = GetRecallCurrency(destination)
                return GetRecallCost(destination) <= GetCarriedCurrencyAmount(currency)
            end,
        },        
        {
            text = SI_DIALOG_CANCEL,
        },
    },
    updateFn = function(dialog)
        local destination = dialog.data.nodeIndex
        local wayshrineName = select(2, GetFastTravelNodeInfo(destination))
        local wayshrineNameChanged = not dialog.wayshrineName or dialog.wayshrineName ~= wayshrineName
        local onCooldown = GetRecallCooldown() > 0
        onCooldownChanged = dialog.onCooldown ~= onCooldown

        if wayshrineNameChanged or onCooldownChanged then
            -- Name has changed, update it.
            ZO_Dialogs_UpdateDialogMainText(dialog, nil, { wayshrineName })
            dialog.wayshrineName = wayshrineName
            dialog.onCooldown = onCooldown
        end

        if not IsInGamepadPreferredMode() then
            local cost = GetRecallCost(destination)
            local currency = GetRecallCurrency(destination)
            local canAffordRecall = cost <= GetCarriedCurrencyAmount(currency)

            if canAffordRecall then
                ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_NORMAL)
            else
                ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_DISABLED)
            end
            ZO_Dialogs_UpdateButtonCost(dialog, 1, cost)
        else
            KEYBIND_STRIP:UpdateCurrentKeybindButtonGroups()
        end
    end,
}

ESO_Dialogs["LOG_OUT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_LOG_OUT,
    },
    mainText =
    {
        text = SI_LOG_OUT_DIALOG,
    },
    buttons =
    {
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
	            Logout()
            end
        },
        {
            text = SI_DIALOG_NO,
        }
    },
}

ESO_Dialogs["QUIT"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_QUIT,
    },
    mainText =
    {
        text = SI_QUIT_DIALOG,
    },
    buttons =
    {
        {
            text = SI_DIALOG_YES,
            callback = function(dialog)
		        Quit()
            end
        },
        {
            text = SI_DIALOG_NO,
        }
    },
}

ESO_Dialogs["ADD_IGNORE"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_ADD_IGNORE,
    },
    mainText = 
    {
        text = SI_REQUEST_NAME_INSTRUCTIONS,
    },
    editBox =
    {
        defaultText = SI_REQUEST_NAME_DEFAULT_TEXT,
        autoComplete = 
        { 
            includeFlags = { AUTO_COMPLETE_FLAG_GUILD, AUTO_COMPLETE_FLAG_RECENT, AUTO_COMPLETE_FLAG_RECENT_TARGET, AUTO_COMPLETE_FLAG_RECENT_CHAT },
            excludeFlags = {AUTO_COMPLETE_FLAG_FRIEND },
            onlineOnly = AUTO_COMPLETION_ONLINE_OR_OFFLINE, 
            maxResults = MAX_AUTO_COMPLETION_RESULTS,
        },
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text =      SI_DIALOG_ADD_IGNORE,
            callback =  function (dialog)
                           local playerName = ZO_Dialogs_GetEditBoxText(dialog)
                           if(playerName and playerName ~= "") then
                                AddIgnore(playerName)
                           end
                        end
        },        
        [2] =
        {
            text =       SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["GUILD_INVITE"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_GUILD_INVITE,
    },
    mainText = 
    {
        text = SI_REQUEST_NAME_INSTRUCTIONS,
    },
    editBox =
    {    
        defaultText = SI_REQUEST_NAME_DEFAULT_TEXT,
        autoComplete = 
        { 
            includeFlags = { AUTO_COMPLETE_FLAG_FRIEND, AUTO_COMPLETE_FLAG_RECENT, AUTO_COMPLETE_FLAG_RECENT_TARGET, AUTO_COMPLETE_FLAG_RECENT_CHAT }, 
            -- don't exclude guild, might want to invite a guild member from one guild to another
            onlineOnly = AUTO_COMPLETION_ONLINE_OR_OFFLINE, 
            maxResults = MAX_AUTO_COMPLETION_RESULTS, 
        },
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text =      SI_OK,
            callback =  function (dialog)
                           local displayName = ZO_Dialogs_GetEditBoxText(dialog)
                           if(displayName and displayName ~= "") then
                                local guildId = dialog.data
                                ZO_TryGuildInvite(guildId, displayName)
                           end
                        end
        },
        [2] =
        {
            text =       SI_DIALOG_CANCEL,
        }  
    }
}

ESO_Dialogs["GROUP_INVITE"] =
{
    title =
    {
        text = SI_GROUP_WINDOW_INVITE_PLAYER,
    },
    mainText = 
    {
        text = SI_REQUEST_NAME_INSTRUCTIONS,
    },
    editBox =
    {    
        defaultText = SI_REQUEST_NAME_DEFAULT_TEXT,
        autoComplete = 
        { 
            includeFlags = { AUTO_COMPLETE_FLAG_ALL }, 
            excludeFlags = { AUTO_COMPLETE_FLAG_GUILD_NAMES }, 
            onlineOnly = AUTO_COMPLETION_ONLINE, 
            maxResults = MAX_AUTO_COMPLETION_RESULTS, 
        },
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text =      SI_OK,
            callback =  function (dialog)
                           local displayName = ZO_Dialogs_GetEditBoxText(dialog)
                           if(displayName and displayName ~= "") then
                                local NOT_SENT_FROM_CHAT = false
                                local NOT_DISPLAY_INVITED_MESSAGE = false
                                TryGroupInviteByName(displayName, NOT_SENT_FROM_CHAT, NOT_DISPLAY_INVITED_MESSAGE)
                           end
                        end
        },
        [2] =
        {
            text =       SI_DIALOG_CANCEL,
        }  
    }
}

ESO_Dialogs["GUILD_BANK_ERROR"] =
{
    title =
    {
        text = "<<1>>",
    },
    mainText = 
    {
        text = "<<1>>",
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
        }
    },
}

ESO_Dialogs["GUILD_RANK_SAVE_CHANGES"] =
{
    title =
    {
        text = SI_GUILD_RANKS_CONFIRM_CHANGES_TITLE
    },
    mainText =
    {
        text = SI_GUILD_RANKS_CONFIRM_CHANGES
    },
    buttons =
    {
        {
            text = SI_GUILD_RANKS_SAVE,
            callback = function(dialog)
                           local APPLY_CHANGES = true
                           GUILD_RANKS:ConfirmExit(APPLY_CHANGES)
                           local data = dialog.data
                           if data and data.callback then
                               data.callback(data.params)
                           end
                       end
        },
        {
            text = SI_GUILD_RANKS_CANCEL,
            callback = function(dialog)
                           local DONT_APPLY_CHANGES = false
                           GUILD_RANKS:ConfirmExit(DONT_APPLY_CHANGES)
                           local data = dialog.data
                           if data and data.callback then
                               data.callback(data.params)
                           end
                       end
        },
    },
    noChoiceCallback = function()
                           GUILD_RANKS:CancelExit()
                       end,
}

ESO_Dialogs["LARGE_GROUP_INVITE_WARNING"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_LARGE_GROUP_INVITE_WARNING,
    },
    mainText = 
    {
        text = SI_LARGE_GROUP_INVITE_WARNING,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            local characterOrDisplayName = dialog.data
                            GroupInviteByName(characterOrDisplayName)
                            ZO_Menu_SetLastCommandWasFromMenu(true)
                            ZO_Alert(ALERT, nil, zo_strformat(GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_INVITED), ZO_FormatUserFacingDisplayName(characterOrDisplayName)))
                        end,
        },
        
        [2] =
        {
            text =      SI_NO,
        }
    }
}

ESO_Dialogs["GUILD_REMOVE_MEMBER"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_GUILD_REMOVE_MEMBER,
    },
    mainText =
    {
        text = SI_GUILD_REMOVE_MEMBER_WARNING,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_REMOVE,
            callback =  function(dialog)
                             GuildRemove(dialog.data.guildId, dialog.data.displayName)
                        end,
        },
        
        [2] =
        {
            text =      SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["GUILD_LEAVE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_LEAVE_GUILD,
    },
    mainText =
    {
        text = SI_GUILD_LEAVE_WARNING,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                             GuildLeave(dialog.data.guildId)
                             dialog.hideSceneOnClose = dialog.data.hideSceneOnLeave
                             dialog.data.leaveGuildSuccess = true
                        end,
        },
        
        [2] =
        {
            text =      SI_DIALOG_DECLINE,
        }
    },
    finishedCallback = function(dialog)
        if(dialog.data.leftGuildCallback and dialog.data.leaveGuildSuccess) then
            dialog.data.leftGuildCallback(dialog.data.guildId)
        end
    end,
}

ESO_Dialogs["GUILD_LEAVE_LEADER"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_LEAVE_GUILD,
    },
    mainText =
    {
        text = SI_GUILD_LEAVE_WARNING_LEADER,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                             GuildLeave(dialog.data.guildId)
                             dialog.hideSceneOnClose = dialog.data.hideSceneOnLeave
                             dialog.data.leaveGuildSuccess = true
                        end,
        },
        
        [2] =
        {
            text =      SI_DIALOG_DECLINE,
        }
    },
    finishedCallback = function(dialog)
        if(dialog.data.leftGuildCallback and dialog.data.leaveGuildSuccess) then
            dialog.data.leftGuildCallback(dialog.data.guildId)
        end
    end,
}

ESO_Dialogs["GUILD_DISBAND"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_DISBAND_GUILD,
    },
    mainText =
    {
        text = SI_GUILD_DISBAND,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                             GuildLeave(dialog.data.guildId)
                             dialog.hideSceneOnClose = dialog.data.hideSceneOnLeave
                             dialog.data.leaveGuildSuccess = true
                        end,
        },
        
        [2] =
        {
            text =      SI_DIALOG_DECLINE,
        }
    },
    finishedCallback = function(dialog)
        if(dialog.data.leftGuildCallback and dialog.data.leaveGuildSuccess) then
            dialog.data.leftGuildCallback(dialog.data.guildId)
        end
    end,
}

ESO_Dialogs["PROMOTE_TO_GUILDMASTER"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_GUILD_PROMOTE,
    },
    mainText =
    {
        text = SI_GUILD_PROMOTE_TO_GUILD_MASTER,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                             GuildPromote(dialog.data.guildId, dialog.data.displayName)
                        end,
            clickSound = SOUNDS.GUILD_ROSTER_PROMOTE,
        },
        
        [2] =
        {
            text =      SI_DIALOG_DECLINE,
        }
    }
}

local function UpdateCampaignQueueReadyTimer(dialog)
    local frameTimeSeconds = GetFrameTimeSeconds()

    if (not dialog.data.nextUpdateTimeSeconds or frameTimeSeconds > dialog.data.nextUpdateTimeSeconds) then
        dialog.data.nextUpdateTimeSeconds = zo_floor(frameTimeSeconds + 1)  -- Update on second boundaries
        local timeLeftSeconds = GetCampaignQueueRemainingConfirmationSeconds(dialog.data.campaignId, dialog.data.isGroup)

        if timeLeftSeconds == 0 then
            -- Cancel the dialog if we're out of time
            ZO_Dialogs_ReleaseDialog(dialog)
        elseif (dialog.data.timeLeftSeconds ~= timeLeftSeconds) then
            -- Otherwise update the timer
            dialog.data.timeLeftSeconds = timeLeftSeconds
            local timeString = ZO_FormatTime(timeLeftSeconds, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR)
            ZO_Dialogs_UpdateDialogMainText(dialog, nil, { dialog.textParams.mainTextParams[1], timeString })
        end
    end
end

ESO_Dialogs["CAMPAIGN_QUEUE_READY"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CAMPAIGN_BROWSER_READY_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_CAMPAIGN_BROSWER_READY_DIALOG_PROMPT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            ConfirmCampaignEntry(dialog.data.campaignId, dialog.data.isGroup, true)
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
    updateFn = UpdateCampaignQueueReadyTimer,
}

ESO_Dialogs["CAMPAIGN_QUEUE"] =
{
    canQueue = true,
    title =
    {
        text = SI_CAMPAIGN_BROWSER_QUEUE_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_CAMPAIGN_BROSWER_QUEUE_DIALOG_PROMPT,
    },
    radioButtons =
    {
        [1] =
        {
            text = GetString(SI_CAMPAIGN_BROWSER_QUEUE_GROUP),
            data = true,
        },
        [2] =
        {
            text = GetString(SI_CAMPAIGN_BROWSER_QUEUE_SOLO),
            data = false,
        },
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            local isGroup = ZO_Dialogs_GetSelectedRadioButtonData(dialog)
                            QueueForCampaign(dialog.data.campaignId, isGroup)
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["CONFIRM_RELEASE_KEEP_OWNERSHIP"] =
{
    title =
    {
        text = SI_GUILD_RELEASE_KEEP_CONFIRM_TITLE,
    },
    mainText =
    {
        text = SI_GUILD_RELEASE_KEEP_CONFIRM_PROMPT,
    },
    noChoiceCallback = function()
        INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
    end,
    buttons =
    {
        [1] =
        {
            text = SI_GUILD_RELEASE_KEEP_ACCEPT,
            callback = function(dialog)
                dialog.data.release()
                INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                INTERACT_WINDOW:OnEndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
            end,
            
        },
    },
    updateFn = function(dialog)
        local keepId = dialog.data.keepId
        local keepName = GetKeepName(keepId)    
        local time = GetSecondsUntilKeepClaimAvailable(keepId, BGQUERY_LOCAL)
    
        if(time == 0) then
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_NORMAL)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_GUILD_RELEASE_KEEP_CONFIRM_PROMPT }, { keepName })
        else
            ZO_Dialogs_UpdateButtonState(dialog, 1, BSTATE_DISABLED)
            ZO_Dialogs_UpdateDialogMainText(dialog, { text = SI_GUILD_RELEASE_KEEP_COOLDOWN }, { keepName, ZO_FormatTime(time, TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_TWELVE_HOUR) })
        end
    end,
}

ESO_Dialogs["CONFIRM_CLEAR_MAIL_COMPOSE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_MAIL_CLEAR_MAIL_COMPOSE_TITLE,
    },
    mainText =
    {
        text = SI_MAIL_CLEAR_MAIL_COMPOSE_PROMPT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.callback()
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_IMPROVE_ITEM"] =
{
    canQueue = true,
	gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_SMITHING_IMPROVE_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_SMITHING_IMPROVE_ITEM_CONFIRM,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                ImproveSmithingItem(dialog.data.bagId, dialog.data.slotIndex, dialog.data.boostersToApply)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_CONVERT_IMPERIAL_STYLE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CONVERT_ITEM_STYLE_IMPERIAL_TITLE,
    },
    mainText =
    {
        text = SI_CONVERT_ITEM_STYLE_IMPERIAL_BODY,
    },
    buttons =
    {
        {
            text = SI_CONVERT_ITEM_STYLE_IMPERIAL_BUTTON,
            callback = function(dialog)
                ConvertItemStyleToImperial(dialog.data.bagId, dialog.data.slotIndex)
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["QUIT_PREVENTED"] =
{
    canQueue = true,
    onlyQueueOnce = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
        allowShowOnNextScene = true,
    },
    title =
    {
        text = SI_DIALOG_TITLE_QUIT,
    },
    mainText =
    {
        text = SI_DIALOG_TEXT_QUIT_PREVENTED,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_BUTTON_TEXT_QUIT_FORCE,
            callback = function(dialog)
                ConfirmLogout(true, LOGOUT_TYPE_FORCED, LOGOUT_RESULT_DISALLOWED)
            end,
        },

        [2] =
        {
            text = SI_DIALOG_BUTTON_TEXT_QUIT_CANCEL,
            callback = function() end,
        },
    },
}

local function UpdateLogoutDialogTimer(dialog)
    local timeLeft = dialog.data.endTime - GetFrameTimeMilliseconds()
    local timerActive = timeLeft >= 50
    if timerActive then
        ZO_Dialogs_UpdateDialogMainText(dialog, nil, { timeLeft })
    else
        dialog.data.timerEffectivelyExpired = true
    end
end

local function HandleLogoutQuitAutoDialogRelease(dialog)
    if not dialog.data.timerEffectivelyExpired then
        CancelLogout()
    end
end

ESO_Dialogs["QUIT_DEFERRED"] =
{
    canQueue = true,
    onlyQueueOnce = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
        allowShowOnNextScene = true,
    },
    title =
    {
        text = SI_DIALOG_TITLE_QUIT,
    },
    mainText =
    {
        text = SI_DIALOG_TEXT_QUIT_DEFERRED,
        timer = 1,
        verboseTimer = true,
    },
    noChoiceCallback = HandleLogoutQuitAutoDialogRelease,
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_BUTTON_TEXT_QUIT_FORCE,
            callback = function(dialog)
                ConfirmLogout(true, LOGOUT_TYPE_FORCED, LOGOUT_RESULT_DEFERRED)
            end,
        },

        [2] =
        {
            text = SI_DIALOG_BUTTON_TEXT_QUIT_CANCEL,
            callback = function(dialog)
                CancelLogout()
            end,
        },
    },
    updateFn = UpdateLogoutDialogTimer,
}

ESO_Dialogs["LOGOUT_DEFERRED"] =
{
    canQueue = true,
    onlyQueueOnce = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
        allowShowOnNextScene = true,
    },
    title =
    {
        text = SI_DIALOG_TITLE_LOGOUT,
    },
    mainText =
    {
        text = SI_DIALOG_TEXT_LOGOUT_DEFERRED,
        timer = 1,
        verboseTimer = true,
    },
    noChoiceCallback = HandleLogoutQuitAutoDialogRelease,
    buttons =
    {
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_BUTTON_TEXT_LOGOUT_CANCEL,
            callback = function(dialog)
                CancelLogout()
            end,
        },
    },
    updateFn = UpdateLogoutDialogTimer,
}

ESO_Dialogs["GAMEPAD_CONFIRM_BUY_MOUNT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_STABLE_STABLES_BUY,
    },
    mainText = 
    {
        text = SI_GAMEPAD_STABLE_CONFIRM_BUY_MOUNT,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
            callback =  function(dialog)
                            PlaySound(SOUNDS.STABLE_BUY_MOUNT)
                            BuyStoreItem(dialog.data.storeIndex)
                        end
        },

        [2] =
        {
            text =       SI_DIALOG_CANCEL,
        }  
    }
}

ESO_Dialogs["CONFIRM_REMOVE_FRIEND"] =
{
    gamepadInfo = 
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_DIALOG_TITLE_REMOVE_FRIEND,
    },
    mainText = 
    {
        text = SI_DIALOG_TEXT_REMOVE_FRIEND,
    },
    buttons =
    {
        {
            text =      SI_DIALOG_BUTTON_REMOVE_FRIEND,
            callback =  function(dialog)
                            RemoveFriend(dialog.data.displayName)
                        end
        },
        {
            text =       SI_DIALOG_CANCEL,
        }  
    }
}

ESO_Dialogs["CONFIRM_IGNORE_FRIEND"] =
{
    gamepadInfo = 
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_DIALOG_TITLE_IGNORE_FRIEND,
    },
    mainText = 
    {
        text = SI_DIALOG_TEXT_IGNORE_FRIEND,
    },
    buttons =
    {
        {
            text =      SI_DIALOG_BUTTON_IGNORE_FRIEND,
            callback =  function(dialog)
                            AddIgnore(dialog.data.displayName)
                        end
        },
        {
            text =       SI_DIALOG_CANCEL,
        }  
    }
}

ESO_Dialogs["CONFIRM_INTERACTION"] =
{
    gamepadInfo = 
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = "<<1>>",
    },
    mainText = 
    {
        text = "<<1>>",
    },

    noChoiceCallback = function(dialog)
                            SetPendingInteractionConfirmed(false)
                        end,
    buttons =
    {
        {
            text = SI_CONFIRM_MUNDUS_STONE_ACCEPT,
            callback =  function(dialog)
                            SetPendingInteractionConfirmed(true)
                        end
        },
        {
            text = SI_CONFIRM_MUNDUS_STONE_DECLINE,
            callback =  function(dialog)
                            SetPendingInteractionConfirmed(false)
                        end
        }  
    }
}

ESO_Dialogs["CONFIRM_STUCK"] =
{
    title =
    {
        text = SI_CONFIRM_STUCK_TITLE,
    },
    mainText =
    {
        text = SI_CONFIRM_STUCK_PROMPT,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            SendPlayerStuck()
                        end
        },
        {
            text = SI_DIALOG_CANCEL,
        }  
    },
}

ESO_Dialogs["CONFIRM_STUCK_WITH_TELVAR_COST"] =
{
    title =
    {
        text = SI_CONFIRM_STUCK_TITLE,
    },
    mainText =
    {
        text = SI_CONFIRM_STUCK_PROMPT_TELVAR,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            SendPlayerStuck()
                        end
        },
        {
            text = SI_DIALOG_CANCEL,
        }  
    },
}

ESO_Dialogs["FIXING_STUCK"] =
{
    title =
    {
        text = SI_FIXING_STUCK_TITLE,
    },
    mainText =
    {
        text = SI_FIXING_STUCK_TEXT,
        align = TEXT_ALIGN_CENTER,
    },
    mustChoose = true,
    showLoadingIcon = true,
    buttons =
    { 
    },
}

ESO_Dialogs["CONFIRM_APPLY_DYE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DYEING_APPLY_CHANGE_CONFIRM_TITLE
    },
    mainText = 
    {
        text = SI_DYEING_APPLY_CHANGE_CONFIRM_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmCommitSelection()
                PlaySound(SOUNDS.DYEING_ACCEPT_BINDING)
            end,
            clickSound = SOUNDS.DYEING_APPLY_CHANGES,
        },
        {
            text = SI_DIALOG_DECLINE,
        }  
    }
}

ESO_Dialogs["EXIT_DYE_UI_BIND"] =
{
    title =
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_BIND_CONFIRM_TITLE
    },
    mainText = 
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_BIND_CONFIRM_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmExit(true)
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmExit(false)
            end
        },
    },
    noChoiceCallback = function(dialog)
        SYSTEMS:GetObject("dyeing"):CancelExit()
    end,
}

ESO_Dialogs["EXIT_DYE_UI_DISCARD_GAMEPAD"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_DYEING_DISCARD_CHANGES_TITLE
    },
    mainText = 
    {
        text = zo_strformat(SI_GAMEPAD_DYEING_DISCARD_CHANGES_BODY),
    },

    buttons =
    {
        {
            text = SI_YES,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing").dyeItemsPanel:ExitWithoutSave()
            end
        },
        {
            text = SI_NO,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):CancelExit()
            end
        },
    },
    noChoiceCallback = function(dialog)
        SYSTEMS:GetObject("dyeing"):CancelExit()
    end,
}


ESO_Dialogs["EXIT_DYE_UI_TO_ACHIEVEMENT_BIND"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_BIND_CONFIRM_TITLE
    },
    mainText = 
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_BIND_CONFIRM_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmExit(true)
            end
        },
        {
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):CancelExitToAchievements()
            end
        }  
    },
    noChoiceCallback = function(dialog)
        SYSTEMS:GetObject("dyeing"):CancelExit()
    end,
}

ESO_Dialogs["EXIT_DYE_UI"] =
{
    title =
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_CONFIRM_TITLE
    },
    mainText = 
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_CONFIRM_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmExit(true)
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmExit(false)
            end
        },
    }
}

ESO_Dialogs["EXIT_DYE_UI_TO_ACHIEVEMENT"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_CONFIRM_TITLE
    },
    mainText = 
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_CONFIRM_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmExit(true)
            end
        },
        {
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):CancelExitToAchievements()
            end
        }  
    }
}

ESO_Dialogs["SWTICH_DYE_MODE"] =
{
    title =
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_CONFIRM_TITLE
    },
    mainText = 
    {
        text = SI_DYEING_SWITCH_WITH_CHANGES_CONFIRM_BODY
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmSwitchMode(true)
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmSwitchMode(false)
            end
        },
    }
}

ESO_Dialogs["SWTICH_DYE_MODE_BIND"] =
{
    title =
    {
        text = SI_DYEING_EXIT_WITH_CHANGES_BIND_CONFIRM_TITLE
    },
    mainText = 
    {
        text = SI_DYEING_SWITCH_WITH_CHANGES_BIND_CONFIRM_BODY
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmSwitchMode(true)
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                SYSTEMS:GetObject("dyeing"):ConfirmSwitchMode(false)
            end
        },
    },
    noChoiceCallback = function(dialog)
        SYSTEMS:GetObject("dyeing"):CancelExit()
    end,
}

ESO_Dialogs["MAIL_ATTACHMENTS_CHANGED"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_MAIL_ATTACHMENTS_CHANGED_TITLE,
    },
    mainText = 
    {
        text = SI_MAIL_ATTACHMENTS_CHANGED_MESSAGE,
    },

    buttons =
    {
        {
            text = SI_DIALOG_EXIT,
            keybind = "DIALOG_NEGATIVE",
        }, 
    }
}

ESO_Dialogs["GUILD_REMOVE_RANK_WARNING"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GUILD_RANKS_REMOVE_RANK_WARNING_TITLE,
    },
    mainText =
    {
        text = SI_GUILD_RANKS_REMOVE_RANK_WARNING_TEXT,
    },

    buttons =
    {
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
        },
    },
}

ESO_Dialogs["GROUP_DISBAND_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GROUP_LIST_MENU_DISBAND_GROUP,
    },
    mainText =
    {
        text = zo_strformat(SI_GROUP_DIALOG_DISBAND_GROUP_CONFIRMATION),
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            GroupDisband()
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["GROUP_LEAVE_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GROUP_LIST_MENU_LEAVE_GROUP,
    },
    mainText =
    {
        text = zo_strformat(SI_GROUP_DIALOG_LEAVE_GROUP_CONFIRMATION),
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback =  function(dialog)
                            GroupLeave()
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["JUMP_TO_GROUP_LEADER_OCCURANCE_PROMPT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_JUMP_TO_GROUP_LEADER_TITLE,
    },
    mainText =
    {
        text = SI_JUMP_TO_GROUP_LEADER_OCCURANCE_PROMPT,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                local groupLeaderUnitTag = GetGroupLeaderUnitTag()
                JumpToGroupMember(GetUnitName(groupLeaderUnitTag))
                SCENE_MANAGER:ShowBaseScene()
            end,
        },
        {
            text = SI_DIALOG_DECLINE,
        },
    },
}

ESO_Dialogs["JUMP_TO_GROUP_LEADER_WORLD_PROMPT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_JUMP_TO_GROUP_LEADER_TITLE,
    },
    mainText =
    {
        text = SI_JUMP_TO_GROUP_LEADER_WORLD_PROMPT,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                local groupLeaderUnitTag = GetGroupLeaderUnitTag()
                JumpToGroupMember(GetUnitName(groupLeaderUnitTag))
                SCENE_MANAGER:ShowBaseScene()
            end,
        },
        {
            text = SI_DIALOG_DECLINE,
        },
    },
}

ESO_Dialogs["JUMP_TO_GROUP_LEADER_WORLD_COLLECTIBLE_LOCKED_PROMPT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_JUMP_TO_GROUP_LEADER_COLLECTIBLE_LOCKED_TITLE,
    },
    mainText =
    {
        text = SI_JUMP_TO_GROUP_LEADER_WORLD_COLLECTIBLE_LOCKED_PROMPT,
    },

    buttons =
    {
        {
            text = SI_COLLECTIBLE_ZONE_JUMP_FAILURE_DIALOG_PRIMARY_BUTTON,
            callback = function(dialog)
                            local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, dialog.data.collectibleName)
                            ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_DLC_FAILURE_TELEPORT_TO_GROUP)
                       end,
            clickSound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

ESO_Dialogs["LFG_LEAVE_QUEUE_CONFIRMATION"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_LFG_DIALOG_LEAVE_QUEUE_CONFIRMATION_TITLE,
    },
    mainText = 
    {
        text = SI_LFG_DIALOG_LEAVE_QUEUE_CONFIRMATION_BODY,
    },
    buttons =
    {
        [1] =
        {
            text = SI_YES,
            callback =  function(dialog)
                            CancelGroupSearches()
                        end,
        },
        [2] =
        {
            text = SI_NO,
        }
    }
}

ESO_Dialogs["CHAMPION_CONFIRM_ENTER_RESPEC"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CHAMPION_DIALOG_ENTER_RESPEC_TITLE,
    },
    mainText = 
    {
        text = SI_CHAMPION_DIALOG_ENTER_RESPEC_BODY,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback =  function(dialog)
                            CHAMPION_PERKS:SetInRespecMode(true)
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["CHAMPION_CONFIRM_CANCEL_RESPEC"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CHAMPION_DIALOG_CANCEL_RESPEC_TITLE,
    },
    mainText = 
    {
        text = zo_strformat(SI_CHAMPION_DIALOG_CANCEL_RESPEC_BODY),
    },
    buttons =
    {
        [1] =
        {
            text = SI_YES,
            callback = function(dialog)
                            CHAMPION_PERKS:SetInRespecMode(false)
                       end,
        },
        [2] =
        {
            text = SI_NO,
        }
    }
}

ESO_Dialogs["CHAMPION_CONFIRM_CHANGES"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CHAMPION_DIALOG_CONFIRM_CHANGES_TITLE,
    },
    mainText = 
    {
        text = zo_strformat(SI_CHAMPION_DIALOG_CONFIRM_POINT_COST),
    },
    buttons =
    {
        [1] =
        {
            text = SI_YES,
            callback = function(dialog)
                            CHAMPION_PERKS:SpendPointsConfirmed(dialog.data.respecNeeded)
                        end,
        },
        [2] =
        {
            text = SI_NO,
        }
    }
}

ESO_Dialogs["COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE"] =
{
    title =
    {
        text = SI_COLLECTIONS_INVENTORY_DIALOG_RENAME_COLLECTIBLE_TITLE,
    },
    mainText = 
    {
        text = SI_COLLECTIONS_INVENTORY_DIALOG_RENAME_COLLECTIBLE_MAIN,
    },
    editBox =
    {
        defaultText = "",
        maxInputCharacters = COLLECTIBLE_NAME_MAX_LENGTH,
        textType = TEXT_TYPE_ALL,
        specialCharacters = {'\'', '-', ' '},
        validatesText = true,
        validator = IsValidCollectibleName,
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text = SI_OK,
            noReleaseOnClick = true,
            callback = function (dialog)
                            local inputText = ZO_Dialogs_GetEditBoxText(dialog)
                            if(inputText and inputText ~= "") then
                                local violations = {IsValidCollectibleName(inputText)}
                                if #violations == 0 then
                                    local collectibleId = dialog.data.collectibleId
                                    RenameCollectible(collectibleId, inputText)
                                    ZO_Dialogs_ReleaseDialog("COLLECTIONS_INVENTORY_RENAME_COLLECTIBLE")
                                end
                            end
                        end
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["GAMERCARD_UNAVAILABLE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title = 
    {
        text = GetUIPlatform() == UI_PLATFORM_PS4 and SI_GAMEPAD_PSN_PROFILE_UNAVAILABLE_DIALOG_TITLE or
               SI_GAMEPAD_GAMERCARD_UNAVAILABLE_DIALOG_TITLE,
    },
    mainText = 
    {
        text = GetUIPlatform() == UI_PLATFORM_PS4 and SI_GAMEPAD_PSN_PROFILE_UNAVAILABLE_DIALOG_BODY or
               SI_GAMEPAD_GAMERCARD_UNAVAILABLE_DIALOG_BODY,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
        }
    }
}

ESO_Dialogs["TRADE_CANCEL_TRADE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_TRADE_DIALOG_CANCEL_TRADE_TITLE,
    },
    mainText = 
    {
        text = zo_strformat(SI_GAMEPAD_TRADE_DIALOG_CANCEL_TRADE_BODY),
    },
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            SCENE_MANAGER:Hide("gamepadTrade")
                        end,
        },
        [2] =
        {
            text =      SI_NO,
        }
    }
}

ESO_Dialogs["SPAM_WARNING"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_MESSAGE_SPAM_WARNING_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_MESSAGE_SPAM_WARNING_DIALOG_BODY,
    },
    buttons =
    {
        [1] =
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_OK,
        },
    },
}

ESO_Dialogs["HELP_CUSTOMER_SERVICE_TICKET_FAILED_REASON"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_ERROR,
    },
    mainText = 
    {
        text = SI_ERROR_REASON,
        align = TEXT_ALIGN_CENTER,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    }
}

ESO_Dialogs["HELP_CUSTOMER_SERVICE_GAMEPAD_TICKET_SUBMITTED"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_HELP_TICKET_SUBMITTED_DIALOG_HEADER,
    },
    mainText = 
    {
        text = SI_GAMEPAD_HELP_TICKET_SUBMITTED_DIALOG_BODY,
    },
    buttons =
    {
        [1] =
        {
            text = SI_GAMEPAD_HELP_CUSTOMER_SERVICE_CLOSE_KEYBIND_TEXT,
            callback =  function()
                            SCENE_MANAGER:HideCurrentScene()
                        end,
        },
    },
}

ESO_Dialogs["GAMEPAD_CONFIRM_RESEARCH_ITEM"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_SMITHING_RESEARCH_CONFIRM_DIALOG_TITLE,
    },
    mainText = 
    {
        text = SI_GAMEPAD_SMITHING_RESEARCH_CONFIRM_DIALOG_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.owner:AcceptResearch(dialog.data.bagId, dialog.data.slotIndex)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL
        },
    }
}

ESO_Dialogs["WAIT_FOR_CONSOLE_CHARACTER_INFO"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    mustChoose = true,
    showLoadingIcon = true,
    title =
    {
        text = SI_GAMEPAD_CONSOLE_WAIT_FOR_CONSOLE_CHARACTER_INFO_TITLE,
    },
    mainText = 
    {
        text = SI_GAMEPAD_CONSOLE_WAIT_FOR_CONSOLE_CHARACTER_INFO_TEXT,
    },
    buttons =
    {
    }
}

ESO_Dialogs["GAMEPAD_GENERIC_WAIT"] = 
{
    setup = function(dialog)
        dialog:setupFunc()
    end,
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
    },
    mustChoose = true,
    loading =
    {
        text = GetString(SI_GAMEPAD_GENERIC_WAITING_TEXT),
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CANCEL,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    }
}

ESO_Dialogs["CONSOLE_COMMUNICATION_PERMISSION_ERROR"] = 
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_PROMPT_TITLE_ERROR,
    },
    mainText = 
    {
        text = SI_ERROR_REASON,
        align = TEXT_ALIGN_CENTER,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
            clickSound = SOUNDS.DIALOG_ACCEPT,
        }
    }
}

ESO_Dialogs["KEYBINDINGS_RESET_KEYBOARD_TO_DEFAULTS"] = 
{
    title =
    {
        text = SI_KEYBINDINGS_KEYBOARD_RESET_TITLE,
    },
    mainText = 
    {
        text = zo_strformat(SI_KEYBINDINGS_KEYBOARD_RESET_PROMPT),
    },
    buttons =
    {
        [1] =
        {
            text = SI_OPTIONS_RESET,
            callback =  function(dialog)
                            ResetKeyboardBindsToDefault()
                        end
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["KEYBINDINGS_RESET_GAMEPAD_TO_DEFAULTS"] = 
{
    title =
    {
        text = SI_KEYBINDINGS_GAMEPAD_RESET_TITLE,
    },
    mainText = 
    {
        text = SI_KEYBINDINGS_GAMEPAD_RESET_PROMPT,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OPTIONS_RESET,
            callback =  function(dialog)
                            ResetGamepadBindsToDefault()
                        end
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["ZONE_COLLECTIBLE_REQUIREMENT_FAILED"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
        allowShowOnNextScene = true,
    },
    canQueue = true,
    title =
    {
        text = SI_COLLECTIBLE_ZONE_JUMP_FAILURE_DIALOG_TITLE,
    },
    mainText = 
    {
        text = SI_COLLECTIBLE_ZONE_JUMP_FAILURE_DIALOG_BODY,
    },
    buttons =
    {
        [1] =
        {
            text = SI_COLLECTIBLE_ZONE_JUMP_FAILURE_DIALOG_PRIMARY_BUTTON,
            callback = function(dialog)
                            local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, dialog.data.collectibleName)
                            ShowMarketAndSearch(searchTerm, MARKET_OPEN_OPERATION_DLC_FAILURE_TELEPORT_TO_ZONE)
                       end
        },
        [2] =
        {
            text = SI_DIALOG_EXIT,
        },
    }
}

ESO_Dialogs["CONSOLE_BUY_ESO_PLUS"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GAMEPAD_MARKET_BUY_PLUS_TITLE,
    },
    mainText = 
    {
        text = SI_GAMEPAD_MARKET_BUY_PLUS_TEXT_CONSOLE,
    },
    buttons =
    {
        [1] =
        {
            text = SI_GAMEPAD_MARKET_BUY_PLUS_DIALOG_KEYBIND_LABEL,
            callback =  function(dialog)
                            ShowConsoleESOPlusSubscriptionUI()
                        end
        },
        [2] =
        {
            text = SI_DIALOG_EXIT,
        },
    }
}

ESO_Dialogs["CONFIRM_RESET_TUTORIALS"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_TITLE_TUTORIALS_RESET,
    },
    mainText = 
    {
        text = SI_DESCRIPTION_TUTORIALS_RESET,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OPTIONS_RESET,
            callback =  ResetAllTutorials
        },
        
        [2] =
        {
            text =      SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["CRAFT_CONFIRM_UNIVERSAL_STYLE_ITEM"] = 
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CRAFTING_CONFIRM_USE_UNIVERSAL_STYLE_ITEM_TITLE,
    },
    mainText = 
    {
        text = SI_CRAFTING_CONFIRM_USE_UNIVERSAL_STYLE_ITEM_DESCRIPTION,
        align = TEXT_ALIGN_CENTER,
    },
    buttons =
    {
        [1] =
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_CANCEL,
        },
        [2] =
        {
            keybind = "DIALOG_SECONDARY",
            text = SI_CRAFTING_PERFORM_FREE_CRAFT,
            callback =  function(dialog)
                            CraftSmithingItem(unpack(dialog.data))
                        end
        },
    }
}

ESO_Dialogs["PROMPT_FOR_LFM_REQUEST"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_LFG_FIND_REPLACEMENT_TITLE,
    },
    mainText =
    {
        text = SI_LFG_FIND_REPLACEMENT_TEXT,
    },

    buttons =
    {
        {
            text = SI_LFG_FIND_REPLACEMENT_ACCEPT,
            callback = function(dialog)
                            local ACCEPT = true
                            ZO_ACTIVITY_FINDER_ROOT_MANAGER:HandleLFMPromptResponse(ACCEPT)
                       end,
            clickSound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            text = SI_NOTIFICATIONS_REQUEST_DECLINE,
            callback = function(dialog)
                            local DECLINE = false
                            ZO_ACTIVITY_FINDER_ROOT_MANAGER:HandleLFMPromptResponse(DECLINE)
                       end,
        },
    },
}

ESO_Dialogs["CAMPAIGN_QUEUE_KICKING_FROM_LFG_GROUP_WARNING"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CAMPAIGN_QUEUE_KICKING_FROM_LFG_GROUP_WARNING_TITLE,
    },
    mainText =
    {
        text = SI_CAMPAIGN_QUEUE_KICKING_FROM_LFG_GROUP_WARNING_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            dialog.data.onAcceptCallback()
                       end,
            clickSound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["KEYBIND_STRIP_DISABLED_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_KEYBIND_STRIP_DISABLED_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_KEYBIND_STRIP_DISABLED_DIALOG_TEXT,
    },
    buttons =
    {
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_OK,
        },
    },
}

ESO_Dialogs["DYE_STAMP_CONFIRM_USE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DYE_STAMP_CONFIRMATION_USE_TITLE,
    },
    mainText =
    {
        text = SI_DYE_STAMP_CONFIRMATION_USE_DESCRIPTION,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            dialog.data.onAcceptCallback()
                       end,
            clickSound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_MODIFY_TRADE_BOP"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DAILOG_TRADE_BOP_BINDING_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_DAILOG_TRADE_BOP_MODIFYING_ITEM_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            dialog.data.onAcceptCallback()
                       end,
            clickSound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_EQUIP_TRADE_BOP"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DAILOG_TRADE_BOP_BINDING_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_DAILOG_TRADE_BOP_EQUIPPING_ITEM_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            dialog.data.onAcceptCallback()
                       end,
            clickSound = SOUNDS.DIALOG_ACCEPT,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

do
    ZO_GAMEPAD_INVENTORY_ACTION_DIALOG = "GAMEPAD_INVENTORY_ACTIONS_DIALOG"
    local function ActionsDialogSetup(dialog, data)
        dialog.entryList:SetOnSelectedDataChangedCallback(function(list, selectedData)
                                                                data.itemActions:SetSelectedAction(selectedData and selectedData.action)
                                                            end)
        local parametricList = dialog.info.parametricList
        ZO_ClearNumericallyIndexedTable(parametricList)

        dialog.itemActions = data.itemActions
        local actions = data.itemActions:GetSlotActions()
        local numActions = actions:GetNumSlotActions()

        for i = 1, numActions do
            local action = actions:GetSlotAction(i)
            local actionName = actions:GetRawActionName(action)

            local entryData = ZO_GamepadEntryData:New(actionName)
            entryData:SetIconTintOnSelection(true)
            entryData.action = action
            entryData.setup = ZO_SharedGamepadEntry_OnSetup

            local listItem =
            {
                template = "ZO_GamepadItemEntryTemplate",
                entryData = entryData,
            }
            table.insert(parametricList, listItem)
        end

        dialog.finishedCallback = data.finishedCallback

        dialog:setupFunc()
    end

    ESO_Dialogs[ZO_GAMEPAD_INVENTORY_ACTION_DIALOG] =
    {
        setup = function(...) ActionsDialogSetup(...) end,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND,
        },
        parametricList = {}, --we'll generate the entries on setup
        finishedCallback =  function(dialog)
                                dialog.itemActions = nil
                                if dialog.finishedCallback then
                                    dialog.finishedCallback()
                                end
                                dialog.finishedCallback = nil
                            end,
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },
            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function(dialog)
                    dialog.itemActions:DoSelectedAction()
                end,
            },
        },
    }
end

ESO_Dialogs["EXTRACT_ALL_PROMPT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GEMIFICATION_EXTRACT_ALL_CONFIRM_TITLE,
    },
    mainText = 
    {
        text = SI_GEMIFICATION_EXTRACT_ALL_CONFIRM_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            dialog.data.gemificationSlot:GemifyAll()
                        end,
        },
        [2] =
        {
            text =      SI_NO,
        }
    }
}

ESO_Dialogs["CONFIRM_STOW_GEMIFIABLE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CONFIRM_STOW_GEMIFIABLE_TITLE,
    },
    mainText = 
    {
        text = SI_CONFIRM_STOW_GEMIFIABLE_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            local transferDialog = SYSTEMS:GetObject("ItemTransferDialog")
                            transferDialog:StartTransfer(dialog.data.sourceBagId, dialog.data.sourceSlotIndex, BAG_VIRTUAL)
                        end,
        },
        [2] =
        {
            text =      SI_NO,
        }
    }
}

ESO_Dialogs["CONFIRM_STOW_ALL_GEMIFIABLE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CONFIRM_STOW_ALL_GEMIFIABLE_TITLE,
    },
    mainText = 
    {
        text = SI_CONFIRM_STOW_ALL_GEMIFIABLE_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            StowAllVirtualItems()
                        end,
        },
        [2] =
        {
            text =      SI_NO,
        }
    }
}

ESO_Dialogs["CONFIRM_PRIMARY_RESIDENCE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_HOUSING_PERMISSIONS_PRIMARY_RESIDENCE_DIALOG_TITLE,
    },
    mainText = 
    {
        text = SI_HOUSING_PERMISSIONS_PRIMARY_RESIDENCE_DIALOG_TEXT,
    },
    buttons =
    {
        [1] =
        {
            text =      SI_YES,
            callback =  function(dialog)
                            SetHousingPrimaryHouse(dialog.data.currentHouse)
                        end,
        },
        [2] =
        {
            text =      SI_NO,
        }
    }
}

do
    local function OnBuyHouseForGoldReleased()
        EndInteraction(INTERACTION_VENDOR)
    end

    ESO_Dialogs["CONFIRM_BUY_HOUSE_FOR_GOLD"] =
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            dontEndInWorldInteractions = true,
        },
        title =
        {
            text = SI_HOUSING_PREVIEW_PURCHASE_FOR_GOLD_TITLE,
        },
        mainText = 
        {
            text = SI_HOUSING_PREVIEW_PURCHASE_FOR_GOLD_BODY,
        },
        buttons =
        {
            [1] =
            {
                text = SI_DIALOG_CONFIRM,
                callback =  function(dialog)
                                PlaySound(SOUNDS.HOUSING_BUY_FOR_GOLD)
                                BuyStoreItem(dialog.data.goldStoreEntryIndex, 1)
                            end
            },

            [2] =
            {
                text =  SI_DIALOG_CANCEL,
            }
        },
        finishedCallback = OnBuyHouseForGoldReleased,
        noChoiceCallback = OnBuyHouseForGoldReleased,
    }
end