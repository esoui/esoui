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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            dialog.data.container:RemoveWindow(dialog.data.index)
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_DECLINE,
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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            CHAT_OPTIONS:Reset()
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_DECLINE,
        }
    }
}

ESO_Dialogs["CHAT_RESET"] =
{
    title =
    {
        text = SI_PROMPT_TITLE_RESET_CHAT,
    },
    mainText =
    {
        text = SI_CHAT_DIALOG_RESET_CHAT,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function()
                            CHAT_SYSTEM:ResetChat()
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_DECLINE,
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
            text = SI_ABANDON_QUEST_CONFIRM,
            callback = function(dialog)
                            AbandonQuest(dialog.data.questIndex)
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
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
    noChoiceCallback = function()
                            SendPledgeOfMaraResponse(PLEDGE_OF_MARA_RESPONSE_DECLINE)
                        end,
    hideSound = SOUNDS.DIALOG_DECLINE,
    buttons =
    {
        [1] =
        {
            text = SI_YES,
            callback = function(dialog)
                            SendPledgeOfMaraResponse(PLEDGE_OF_MARA_RESPONSE_ACCEPT)
                        end,
        },
        [2] =
        {
            text = SI_NO,
            callback = function(dialog)
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
    noChoiceCallback = function()
                            RespondToDestroyRequest(false)
                        end,
    buttons =
    {
        [1] =
        {
            text = SI_YES,
            callback = function(dialog)
                            RespondToDestroyRequest(true)
                        end,
        },
        [2] =
        {
            text = SI_NO,
            callback = function(dialog)
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
    noChoiceCallback = function()
        RespondToDestroyRequest(false)
    end,
    buttons =
    {
        {
            requiresTextInput = true,
            text = SI_CHAT_DIALOG_CONFIRM_ITEM_DESTRUCTION,
            callback = function(dialog)
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
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                RespondToDestroyRequest(false)
            end,
        }
    }
}

ESO_Dialogs["CONFIRM_DESTROY_ARMORY_ITEM_PROMPT"] =
{
    title =
    {
        text = SI_DIALOG_DESTROY_ARMORY_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_ARMORY_CONFIRM_DESTROY_ITEM_BODY,
    },
    editBox =
    {
        matchingString = GetString(SI_DESTROY_ITEM_CONFIRMATION)
    },
    noChoiceCallback = function()
        RespondToDestroyRequest(false)
    end,
    buttons =
    {
        {
            requiresTextInput = true,
            text = SI_CHAT_DIALOG_CONFIRM_ITEM_DESTRUCTION,
            callback = function(dialog)
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
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                RespondToDestroyRequest(false)
            end,
        }
    }
}

ESO_Dialogs["CONFIRM_ENDLESS_DUNGEON_COMPANION_SUMMONING"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ENDLESS_DUNGEON_CONFIRM_COMPANION_SUMMONING_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_ENDLESS_DUNGEON_CONFIRM_COMPANION_SUMMONING_DIALOG_BODY,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                            -- Confirm Companion Summoning for this Endless Dungeon instance
                            -- and attempt to use the companion collectible again.
                            SetPlayerConfirmedEndlessDungeonCompanionSummoning(true)
                            UseCollectible(dialog.data.collectibleId)
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
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
            callback = function(dialog)
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
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
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
                BuyStoreItem(dialog.data.buyIndex, dialog.data.quantity or 1)
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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            BuyBankSpace()
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_DECLINE,
        },
    },
    updateFn = function(dialog)
        local cost = dialog.data.cost
        if cost > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) then
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
                            INTERACT_WINDOW:EndInteraction(BUY_BAG_SPACE_INTERACTION)
                         end,
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            BuyBagSpace()
                            INTERACT_WINDOW:EndInteraction(BUY_BAG_SPACE_INTERACTION)
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                            INTERACT_WINDOW:EndInteraction(BUY_BAG_SPACE_INTERACTION)
                         end,
        },
    },
    updateFn = function(dialog)
        local cost = dialog.data.cost
        if cost > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) then
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
        {
            text = function(dialog)
                if IsInGamepadPreferredMode() then
                    local costString = ZO_CurrencyControl_FormatCurrency(dialog.data.cost)
                    return zo_strformat(SI_GAMEPAD_REPAIR_ALL_ACCEPT, costString, ZO_Currency_GetGamepadFormattedCurrencyIcon(CURT_MONEY))
                else
                    return GetString(SI_DIALOG_ACCEPT)
                end
            end,
            narrationOverrideText = function(dialog)
                if IsInGamepadPreferredMode() then
                    local costString = ZO_Currency_FormatGamepad(CURT_MONEY, dialog.data.cost, ZO_CURRENCY_FORMAT_AMOUNT_NAME)
                    return zo_strformat(SI_GAMEPAD_REPAIR_ALL_ACCEPT, costString)
                end
            end,
            callback = function(dialog)
                            RepairAll()
                            PlaySound(SOUNDS.INVENTORY_ITEM_REPAIR)
                        end,
            enabled = function(dialogOrDescriptor)
                            local dialog = dialogOrDescriptor.dialog or dialogOrDescriptor  -- if .dialog is defined, we're running in Gamepad UI
                            local canAfford = dialog.data.cost <= GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)

                            if canAfford then
                                return true
                            else
                                return false, GetString(SI_REPAIR_ALL_CANNOT_AFFORD)
                            end
                        end,
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                            if (dialog.data.declineCallback) then
                               dialog.data.declineCallback()
                            end
                        end,
        },
    },
    updateFn = function(dialog)
        local cost = dialog.data.cost
        local buttonState

        if cost > GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) then
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
            text = SI_SELL_ALL_JUNK_CONFIRM,
            callback = SellAllJunk,
        },
        [2] =
        {
            text = SI_DIALOG_DECLINE,
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
            text = SI_DESTROY_ALL_JUNK_CONFIRM,
            callback = DestroyAllJunk,
            clickSound = SOUNDS.INVENTORY_DESTROY_JUNK,
        },
        [2] =
        {
            text = SI_DIALOG_DECLINE,
        },
    },
}

ESO_Dialogs["CONFIRM_SELL_ARMORY_ITEM_PROMPT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_DIALOG_SELL_ARMORY_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_DIALOG_SELL_ARMORY_ITEM_BODY,
    },
    buttons =
    {
        {
            text = SI_ITEM_ACTION_SELL,
            callback = function(dialog)
                local bagId = dialog.data.bag or dialog.data.bagId
                local slotIndex = dialog.data.slot or dialog.data.slotIndex
                SellInventoryItem(bagId, slotIndex, dialog.data.stackCount)
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
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
        text = SI_STOLEN_ITEM_CANNOT_BUYBACK_TEXT,
    },
    buttons =
    {
        {
            text = SI_ITEM_ACTION_SELL,
            callback = function(dialog)
                SellInventoryItem(dialog.data.bag, dialog.data.slot, dialog.data.stackCount)
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
    updateFn = function(dialog)
        -- dialog.data.quality is deprecated, included here for addon backwards compatibility
        local displayQuality = dialog.data.displayQuality or dialog.data.quality
        local itemColor = GetItemQualityColor(displayQuality)
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
            text = SI_MAIL_DELETE,
            callback = function(dialog)
                dialog.data.confirmationCallback(dialog.data.mailId)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
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
    canQueue = true,
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

ESO_Dialogs["MAIL_CONFIRM_TAKE_ALL"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = function(dialog)
            local category = dialog.data.category
            return zo_strformat(SI_MAIL_CONFIRM_TAKE_ALL_TITLE, GetString("SI_MAILCATEGORY", category))
        end,
    },
    mainText =
    {
        text = function(dialog)
            local category = dialog.data.category
            local shouldDeleteOnClaim = MAIL_MANAGER:ShouldDeleteOnClaim()
            local descriptionText = GetString("SI_MAILCATEGORY_CONFIRMTAKEALLPROMPT", category)

            if category == MAIL_CATEGORY_SYSTEM_MAIL and shouldDeleteOnClaim then
               return ZO_GenerateParagraphSeparatedList({ descriptionText, GetString(SI_MAIL_CONFIRM_TAKE_ALL_DELETE_AFTER_CLAIM_ENABLED) })
            else
                return descriptionText
            end
        end,
    },
    buttons =
    {
        {
            text = function(dialog)
                return GetString("SI_MAILCATEGORY_TAKEALL", dialog.data.category)
            end,
            callback = function(dialog)
                TakeAllMailAttachmentsInCategory(dialog.data.category, MAIL_MANAGER:ShouldDeleteOnClaim())
            end
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["TOO_FREQUENT_BUG_SCREENSHOT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
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

ESO_Dialogs["CUSTOMER_SERVICE_TICKET_SCREENSHOT_COOLDOWN"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    mainText =
    {
        text = SI_CUSTOMER_SERVICE_TICKET_SCREENSHOT_COOLDOWN,
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
    canQueue = true,
    setup = function(dialog, data)
        data.confirmedFastTravel = false
    end,
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
                data.confirmedFastTravel = true
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                local data = dialog.data
                data.confirmedFastTravel = false
            end,
        },
    },
    finishedCallback = function(dialog)
        -- ESO-796774
        -- defer the call to FastTravelToNode until the dialog is hidden
        -- to avoid an issue where the dialog can hide after the load screen
        -- appears, resulting in the dialog action layer not getting removed
        local data = dialog.data
        if data.confirmedFastTravel then
            FastTravelToNode(data.nodeIndex)
            SCENE_MANAGER:ShowBaseScene()
        end
    end
}

ESO_Dialogs["RECALL_CONFIRM"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
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
            local canAffordRecall = cost <= GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)

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
                -- this call to FastTravelToNode will play a player animation before the jump occurs
                -- so we don't need to defer the call until the dialog hides
                local data = dialog.data
                FastTravelToNode(data.nodeIndex)
                SCENE_MANAGER:ShowBaseScene()
            end,
            visible = function(dialog)
                local destination = dialog.data.nodeIndex
                local currency = GetRecallCurrency(destination)
                return GetRecallCost(destination) <= GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)
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
        local onCooldownChanged = dialog.onCooldown ~= onCooldown

        if wayshrineNameChanged or onCooldownChanged then
            -- Name has changed, update it.
            ZO_Dialogs_UpdateDialogMainText(dialog, nil, { wayshrineName })
            dialog.wayshrineName = wayshrineName
            dialog.onCooldown = onCooldown
        end

        if not IsInGamepadPreferredMode() then
            local cost = GetRecallCost(destination)
            local currency = GetRecallCurrency(destination)
            local canAffordRecall = cost <= GetCurrencyAmount(currency, CURRENCY_LOCATION_CHARACTER)

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

ESO_Dialogs["TRAVEL_TO_HOUSE_CONFIRM"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_PROMPT_TITLE_FAST_TRAVEL_CONFIRM,
    },
    mainText =
    {
        text = function(dialog)
            if dialog.data.travelOutside then
                return SI_TRAVEL_TO_HOUSE_OUTSIDE_DIALOG_MAIN_TEXT
            else
                return SI_TRAVEL_TO_HOUSE_INSIDE_DIALOG_MAIN_TEXT
            end
        end,
    },
    buttons =
    {
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                -- RequestJumpToHouse will play a player animation before the jump occurs
                -- so we don't need to defer the call until the dialog hides
                local data = dialog.data
                RequestJumpToHouse(data.houseId, data.travelOutside)
                SCENE_MANAGER:ShowBaseScene()
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
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
            text = SI_DIALOG_ADD_IGNORE,
            callback = function (dialog)
                           local playerName = ZO_Dialogs_GetEditBoxText(dialog)
                           if(playerName and playerName ~= "") then
                                AddIgnore(playerName)
                           end
                        end
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
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
            text = SI_OK,
            callback = function (dialog)
                           local displayName = ZO_Dialogs_GetEditBoxText(dialog)
                           if(displayName and displayName ~= "") then
                                local guildId = dialog.data
                                ZO_TryGuildInvite(guildId, displayName)
                           end
                        end
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
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
            text = SI_OK,
            callback = function (dialog)
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
            text = SI_DIALOG_CANCEL,
        }
    }
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
            text = SI_YES,
            callback = function(dialog)
                            local characterOrDisplayName = dialog.data
                            GroupInviteByName(characterOrDisplayName)
                            ZO_Menu_SetLastCommandWasFromMenu(true)
                            ZO_Alert(ALERT, nil, zo_strformat(GetString("SI_GROUPINVITERESPONSE", GROUP_INVITE_RESPONSE_INVITED), ZO_FormatUserFacingDisplayName(characterOrDisplayName)))
                        end,
        },

        [2] =
        {
            text = SI_NO,
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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                             GuildLeave(dialog.data.guildId)
                             dialog.hideSceneOnClose = dialog.data.hideSceneOnLeave
                             dialog.data.leaveGuildSuccess = true
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_DECLINE,
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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                             GuildLeave(dialog.data.guildId)
                             dialog.hideSceneOnClose = dialog.data.hideSceneOnLeave
                             dialog.data.leaveGuildSuccess = true
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_DECLINE,
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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                             GuildLeave(dialog.data.guildId)
                             dialog.hideSceneOnClose = dialog.data.hideSceneOnLeave
                             dialog.data.leaveGuildSuccess = true
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_DECLINE,
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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            local GUILD_MASTER_RANK = 1
                            GuildSetRank(dialog.data.guildId, dialog.data.displayName, GUILD_MASTER_RANK)
                        end,
            clickSound = SOUNDS.GUILD_ROSTER_PROMOTE,
        },

        [2] =
        {
            text = SI_DIALOG_DECLINE,
        }
    }
}

ESO_Dialogs["CAMPAIGN_ALLIANCE_LOCKED"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ALLIANCE_LOCKED_DIALOG_TITLE,
    },
    mainText =
    {
        text = function(dialog)
            local data = dialog.data
            local campaignData = data.campaignData
            local campaignName = ZO_SELECTED_TEXT:Colorize(campaignData.name)
            local allianceString = ZO_SELECTED_TEXT:Colorize(ZO_CampaignBrowser_FormatPlatformAllianceIconAndName(campaignData.lockedToAlliance))
            local campaignEndCooldownString = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(data.secondsUntilCampaignEnd, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))

            local lockedCampaignMessage = zo_strformat(SI_ALLIANCE_LOCKED_DIALOG_CAMPAIGN_MESSAGE, campaignName, allianceString, campaignEndCooldownString)

            local lockedReasonFormatString = GetString("SI_CAMPAIGNALLIANCELOCKREASON_DIALOGMESSAGE", campaignData.allianceLockReason)
            local lockedReasonMessage
            if campaignData.allianceLockReason == CAMPAIGN_ALLIANCE_LOCK_REASON_ENTERED_CAMPAIGN then
                lockedReasonMessage = zo_strformat(lockedReasonFormatString, campaignEndCooldownString)
            elseif campaignData.allianceLockReason == CAMPAIGN_ALLIANCE_LOCK_REASON_CHARACTER_ASSIGNED then
                lockedReasonMessage = lockedReasonFormatString
            elseif campaignData.allianceLockReason == CAMPAIGN_ALLIANCE_LOCK_REASON_CAMPAIGN_ENTERED_AND_ASSIGNED then
                lockedReasonMessage = zo_strformat(lockedReasonFormatString, campaignEndCooldownString)
            end

            return ZO_GenerateParagraphSeparatedList({lockedCampaignMessage, lockedReasonMessage})
        end,
    },
    buttons =
    {
        [1] =
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_EXIT,
        },
    },
    updateFn = function(dialog)
        local campaignData = dialog.data.campaignData
        local _, secondsUntilCampaignEnd = GetSelectionCampaignTimes(campaignData.selectionIndex)
        if dialog.data.secondsUntilCampaignEnd ~= secondsUntilCampaignEnd then
            dialog.data.secondsUntilCampaignEnd = secondsUntilCampaignEnd
            ZO_Dialogs_RefreshDialogText("CAMPAIGN_ALLIANCE_LOCKED", dialog)
        end
    end,
}

ESO_Dialogs["CAMPAIGN_ABOUT_TO_ALLIANCE_LOCK"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ABOUT_TO_ALLIANCE_LOCK_DIALOG_TITLE,
    },
    mainText =
    {
        text = function(dialog)
            local data = dialog.data
            local allianceString = ZO_SELECTED_TEXT:Colorize(ZO_CampaignBrowser_FormatPlatformAllianceIconAndName(GetUnitAlliance("player")))

            local campaignEndCooldownString = ZO_SELECTED_TEXT:Colorize(ZO_FormatTime(data.secondsUntilCampaignEnd, TIME_FORMAT_STYLE_SHOW_LARGEST_TWO_UNITS, TIME_FORMAT_PRECISION_TWELVE_HOUR, TIME_FORMAT_DIRECTION_DESCENDING))

            return zo_strformat(SI_ABOUT_TO_ALLIANCE_LOCK_CAMPAIGN_WARNING, allianceString, campaignEndCooldownString)
        end,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                CAMPAIGN_BROWSER_MANAGER:ContinueQueueForCampaignFlow(dialog.data.campaignData, ZO_CAMPAIGN_QUEUE_STEP_ALLIANCE_LOCK_CHECK)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
    updateFn = function(dialog)
        local campaignData = dialog.data.campaignData
        local _, secondsUntilCampaignEnd = GetSelectionCampaignTimes(campaignData.selectionIndex)
        if dialog.data.secondsUntilCampaignEnd ~= secondsUntilCampaignEnd then
            dialog.data.secondsUntilCampaignEnd = secondsUntilCampaignEnd
            ZO_Dialogs_RefreshDialogText("CAMPAIGN_ABOUT_TO_ALLIANCE_LOCK", dialog)
        end
    end,
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
        INTERACT_WINDOW:EndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
    end,
    buttons =
    {
        [1] =
        {
            text = SI_GUILD_RELEASE_KEEP_ACCEPT,
            callback = function(dialog)
                dialog.data.release()
                INTERACT_WINDOW:EndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                INTERACT_WINDOW:EndInteraction(GUILD_KEEP_RELEASE_INTERACTION)
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

do
    local function GetImproveWarningText(data)
        if data.chance == 100 then
            return ""
        else
            return zo_strformat(SI_SMITHING_IMPROVE_ITEM_WARNING, GetItemLink(data.bagId, data.slotIndex))
        end
    end

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
        warning =
        {
            text = function(dialog)
                return GetImproveWarningText(dialog.data)
            end
        },
        buttons =
        {
            [1] =
            {
                text = SI_DIALOG_ACCEPT,
                callback = function(dialog)
                    local data = dialog.data
                    ImproveSmithingItem(data.bagId, data.slotIndex, data.boostersToApply)
                end,
            },
            [2] =
            {
                text = SI_DIALOG_CANCEL,
            },
        },
    }

    ESO_Dialogs["CONFIRM_IMPROVE_LOCKED_ITEM"] =
    {
        canQueue = true,
        title =
        {
            text = SI_SMITHING_IMPROVE_ITEM_TITLE,
        },
        mainText =
        {
            text = SI_SMITHING_IMPROVE_LOCKED_ITEM_CONFIRM,
        },
        editBox =
        {
            matchingString = GetString(SI_PERFORM_ACTION_CONFIRMATION)
        },
        warning =
        {
            text = function(dialog)
                return GetImproveWarningText(dialog.data)
            end
        },
        buttons =
        {
            [1] =
            {
                requiresTextInput = true,
                text = SI_DIALOG_ACCEPT,
                callback = function(dialog)
                    local data = dialog.data
                    ImproveSmithingItem(data.bagId, data.slotIndex, data.boostersToApply)
                end,
            },
            [2] =
            {
                text = SI_DIALOG_CANCEL,
            },
        },
    }

    ESO_Dialogs["GAMEPAD_CONFIRM_IMPROVE_LOCKED_ITEM"] =
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
            text = SI_GAMEPAD_CRAFTING_CONFIRM_IMPROVE_LOCKED_ITEM,
        },
        warning =
        {
            text = function(dialog)
                return GetImproveWarningText(dialog.data)
            end
        },
        buttons =
        {
            [1] =
            {
                onShowCooldown = 2000,
                text = SI_DIALOG_ACCEPT,
                callback = function(dialog)
                    local data = dialog.data
                    ImproveSmithingItem(data.bagId, data.slotIndex, data.boostersToApply)
                end,
            },
            [2] =
            {
                text = SI_DIALOG_CANCEL,
            },
        },
    }
end

ESO_Dialogs["CONFIRM_CREATE_NONSET_ITEM"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_SMITHING_CREATE_NONSET_ITEM_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_SMITHING_CREATE_NONSET_ITEM_DIALOG_DESCRIPTION,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                CraftSmithingItem(unpack(dialog.data.craftingParams))
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_DECONSTRUCT_ARMORY_ITEM"] =
{
    title =
    {
        text = function(dialog)
            return GetString("SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE", dialog.data.verb)
        end,
    },
    mainText =
    {
        text = function(dialog)
            local deconstructVerify = zo_strformat(SI_DECONSTRUCT_ARMORY_EQUIPMENT_KEYBOARD_VERIFY, GetString(SI_PERFORM_ACTION_CONFIRMATION))
            return ZO_GenerateParagraphSeparatedList({ GetString(SI_DECONSTRUCT_ARMORY_EQUIPMENT_WARNING), deconstructVerify })
        end,
    },
    editBox =
    {
        matchingString = GetString(SI_PERFORM_ACTION_CONFIRMATION)
    },
    buttons =
    {
        {
            requiresTextInput = true,
            text = SI_CHAT_DIALOG_CONFIRM_ITEM_DESTRUCTION,
            callback = function(dialog)
                dialog.data.deconstructFn()
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["CONFIRM_DECONSTRUCT_ARMORY_ITEM_GAMEPAD"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = function(dialog)
            return GetString("SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE", dialog.data.verb)
        end,
    },
    mainText =
    {
        text = function(dialog)
            return ZO_GenerateParagraphSeparatedList({ GetString(SI_DECONSTRUCT_ARMORY_EQUIPMENT_WARNING), GetString(SI_DECONSTRUCT_ARMORY_EQUIPMENT_GAMEPAD_CONTINUE) })
        end,
    },
    setup = function(dialog)
        local headerData =
        {
            data1 =
            {
                header = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
                value = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK)),
            }
        }
        dialog:setupFunc(headerData)
    end,
    buttons =
    {
        {
            requiresTextInput = true,
            text = SI_CHAT_DIALOG_CONFIRM_ITEM_DESTRUCTION,
            callback = function(dialog)
                dialog.data.deconstructFn()
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["CONFIRM_MULTI_DECONSTRUCT_ARMORY_ITEM"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = function(dialog)
            return GetString("SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE", dialog.data.verb)
        end,
    },
    mainText =
    {
        text = function(dialog)
            local baseDialogContent = GetString("SI_DECONSTRUCTACTIONNAME_CONFIRMMULTIPLE", dialog.data.verb)
            local deconstructVerify = zo_strformat(SI_DECONSTRUCT_ARMORY_EQUIPMENT_KEYBOARD_VERIFY, GetString(SI_PERFORM_ACTION_CONFIRMATION))
            return ZO_GenerateParagraphSeparatedList({ baseDialogContent, GetString(SI_DECONSTRUCT_ARMORY_EQUIPMENT_WARNING), deconstructVerify })
        end,
    },
    editBox =
    {
        matchingString = GetString(SI_PERFORM_ACTION_CONFIRMATION)
    },
    setup = function(dialog)
        local headerData =
        {
            data1 =
            {
                header = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
                value = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK)),
            }
        }
        dialog:setupFunc(headerData)
    end,
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.deconstructFn()
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_DECONSTRUCT_MULTIPLE_ITEMS"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = function(dialog)
            return GetString("SI_DECONSTRUCTACTIONNAME_PERFORMMULTIPLE", dialog.data.verb)
        end,
    },
    mainText =
    {
        text = function(dialog)
            local baseDialogContent = GetString("SI_DECONSTRUCTACTIONNAME_CONFIRMMULTIPLE", dialog.data.verb)
            if dialog.data.isAnyItemInArmoryBuild then
                return ZO_GenerateParagraphSeparatedList({ baseDialogContent, GetString(SI_DECONSTRUCT_ARMORY_EQUIPMENT_WARNING) })
            else
                return baseDialogContent
            end
        end,
    },
    setup = function(dialog)
        local headerData =
        {
            data1 =
            {
                header = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
                value = zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK)),
            }
        }
        dialog:setupFunc(headerData)
    end,
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.deconstructFn()
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONVERT_STYLE_MOVED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
        allowShowOnNextScene = true,
    },
    title =
    {
        text = SI_ITEM_ACTION_CONVERT_STYLE_MOVED_TITLE,
    },
    mainText =
    {
        text = SI_ITEM_ACTION_CONVERT_STYLE_MOVED_DESCRIPTION,
    },
    buttons =
    {
        [1] =
        {
            text = SI_OK,
            keybind = "DIALOG_NEGATIVE",
        }
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
            text = SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
            callback = function(dialog)
                            PlaySound(SOUNDS.STABLE_BUY_MOUNT)
                            BuyStoreItem(dialog.data.storeIndex)
                        end
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
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
            text = SI_DIALOG_BUTTON_REMOVE_FRIEND,
            callback = function(dialog)
                            RemoveFriend(dialog.data.displayName)
                        end
        },
        {
            text = SI_DIALOG_CANCEL,
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
            text = SI_DIALOG_BUTTON_IGNORE_FRIEND,
            callback = function(dialog)
                            AddIgnore(dialog.data.displayName)
                        end
        },
        {
            text = SI_DIALOG_CANCEL,
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
                            ReplyToPendingInteraction(false)
                        end,
    buttons =
    {
        {
            text = SI_CONFIRM_MUNDUS_STONE_ACCEPT,
            callback = function(dialog)
                            ReplyToPendingInteraction(true)
                        end
        },
        {
            text = SI_CONFIRM_MUNDUS_STONE_DECLINE,
            callback = function(dialog)
                            ReplyToPendingInteraction(false)
                        end
        }
    },
    updateFn = function(dialog)
                    -- Kill dialog if it is no longer valid
                    if not IsPendingInteractionConfirmationValid() then
                        ZO_Dialogs_ReleaseDialog(dialog)
                    end
                end,
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
                SYSTEMS:GetObject("restyle"):ConfirmCommitSelection()
                PlaySound(SOUNDS.DYEING_ACCEPT_BINDING)
            end,
            clickSound = SOUNDS.DYEING_APPLY_CHANGES,
        },
        {
            text = SI_DIALOG_DECLINE,
        }
    }
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
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.confirmCallback()
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                if dialog.data.declineCallback then
                    dialog.data.declineCallback()
                end
            end
        },
    },
    noChoiceCallback = function(dialog)
        SYSTEMS:GetObject("restyle"):CancelExit()
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
        text = function()
            --These have gender switches, which is why they need to use zo_strformat instead of GetString
            if IsActiveWorldGroupOwnable() then
                return zo_strformat(SI_GROUP_DIALOG_DISBAND_GROUP_INSTANCE_CONFIRMATION)
            else
                return zo_strformat(SI_GROUP_DIALOG_DISBAND_GROUP_CONFIRMATION)
            end
        end,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
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
        text = function()
            --These have gender switches, which is why they need to use zo_strformat instead of GetString
            if IsActiveWorldBattleground() then
                return zo_strformat(SI_GROUP_DIALOG_LEAVE_GROUP_BATTLEGROUND_CONFIRMATION)
            elseif IsActiveWorldGroupOwnable() then
                return zo_strformat(SI_GROUP_DIALOG_LEAVE_GROUP_INSTANCE_CONFIRMATION)
            else
                return zo_strformat(SI_GROUP_DIALOG_LEAVE_GROUP_CONFIRMATION)
            end
        end,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            GroupLeave()
                        end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["INSTANCE_LEAVE_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GROUP_MENU_LEAVE_INSTANCE_DIALOG_TITLE,
    },
    mainText =
    {
        text = SI_GROUP_MENU_LEAVE_INSTANCE_DIALOG_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                ExitInstanceImmediately()
            end,
        },

        {
            text = SI_DIALOG_CANCEL,
        },
    }
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
            callback = function(dialog)
                            CancelGroupSearches()
                        end,
        },
        [2] =
        {
            text = SI_NO,
        }
    }
}

ESO_Dialogs["LFG_DECLINE_READY_CHECK_CONFIRMATION"] =
{
    canQueue = true,
    onlyQueueOnce = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_LFG_DIALOG_DECLINE_READY_CHECK_CONFIRMATION_TITLE,
    },
    mainText =
    {
        text = function(dialog)
            if dialog.data and dialog.data.incomingType == ZO_INTERACT_TYPE.GROUP_ELECTION then
                return GetString(SI_LFG_DIALOG_DECLINE_GROUP_ELECTION_READY_CHECK_CONFIRMATION_BODY)
            else
                return GetString(SI_LFG_DIALOG_DECLINE_READY_CHECK_CONFIRMATION_BODY)
            end
        end,
    },
    buttons =
    {
        {
            text = SI_YES,
            callback = function(dialog)
                local queueEntry = PLAYER_TO_PLAYER:GetFromIncomingQueue(ZO_INTERACT_TYPE.LFG_READY_CHECK)

                if dialog.data then
                    if dialog.data.openedFromKeybind then
                        if IsInGamepadPreferredMode() then
                            GAMEPAD_NOTIFICATIONS:DeclineRequest(dialog.data.data, dialog.data.control, dialog.data.openedFromKeybind)
                        else
                            NOTIFICATIONS:DeclineRequest(dialog.data.data, dialog.data.control, dialog.data.openedFromKeybind)
                        end
                        return
                    else
                        dialog.data.dontRemoveOnDecline = false
                    end
                else
                    if queueEntry then
                        queueEntry.dontRemoveOnDecline = false
                    end
                end

                PLAYER_TO_PLAYER:Decline(dialog.data or queueEntry)
                DeclineLFGReadyCheckNotification()
            end,
        },
        {
            text = SI_NO,
            callback = function(dialog)
                if dialog.data and dialog.data.openedFromKeybind then
                    -- We opened the dialog from notification, canceling will take us back to that screen.
                    return
                else
                    local queueEntry = PLAYER_TO_PLAYER:GetFromIncomingQueue(ZO_INTERACT_TYPE.LFG_READY_CHECK)
                    if queueEntry then
                        -- This will let PLAYER_TO_PLAYER determine what to do. If we're in a menu,
                        -- it will re-trigger the dialog form of the PTP_TIMED_RESPONSE_PROMPT dialog.
                        -- If another dialog had already come along during this flow, it will get a chance to display before we start the ready check dialog flow again.
                        -- This is better than the alternative: getting stuck in a state where the dialog queue is paused forever (ESO-898098)
                        queueEntry.seen = false
                        queueEntry.dontRemoveOnDecline = false
                        PLAYER_TO_PLAYER:OnGroupingToolsReadyCheckUpdated()
                    end
                end
            end,
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
            callback = function(dialog)
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

ESO_Dialogs["GAMEPAD_TRAVEL_TO_HOUSE_OPTIONS_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
    },

    title =
    {
        text = SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE,
    },

    setup = function(dialog)
        dialog:setupFunc()
    end,

    parametricList =
    {
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData =
            {
                text = GetString(SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE_INSIDE),
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function(dialog)
                    local TRAVEL_INSIDE = false
                    RequestJumpToHouse(dialog.data:GetReferenceId(), TRAVEL_INSIDE)
                    SCENE_MANAGER:ShowBaseScene()
                end,
            },
        },
        {
            template = "ZO_GamepadMenuEntryTemplate",
            templateData =
            {
                text = GetString(SI_HOUSING_BOOK_ACTION_TRAVEL_TO_HOUSE_OUTSIDE),
                setup = ZO_SharedGamepadEntry_OnSetup,
                callback = function(dialog)
                    local TRAVEL_OUTSIDE = true
                    RequestJumpToHouse(dialog.data:GetReferenceId(), TRAVEL_OUTSIDE)
                    SCENE_MANAGER:ShowBaseScene()
                end,
            },
        },
    },

    buttons =
    {
        {
            text = SI_GAMEPAD_SELECT_OPTION,
            callback = function(dialog)
                local data = dialog.entryList:GetTargetData()
                data.callback(dialog)
            end,
        },

        {
            text = SI_DIALOG_CANCEL,
        },
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
            text = SI_YES,
            callback = function(dialog)
                            SCENE_MANAGER:Hide("gamepadTrade")
                        end,
        },
        [2] =
        {
            text = SI_NO,
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

ESO_Dialogs["HELP_CUSTOMER_SERVICE_GAMEPAD_SUBMITTING_TICKET"] =
{
    setup = function(dialog)
        dialog:setupFunc()
    end,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.COOLDOWN,
        allowShowOnNextScene = true,
    },
    showLoadingIcon = true,
    canQueue = true,
    title =
    {
        text = GetString(SI_CUSTOMER_SERVICE_SUBMITTING_TICKET),
    },
    loading =
    {
        text = GetString(SI_CUSTOMER_SERVICE_SUBMITTING),
    },
}

ESO_Dialogs["HELP_CUSTOMER_SERVICE_GAMEPAD_TICKET_SUBMITTED"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
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
            callback = function()
                            SCENE_MANAGER:HideCurrentScene()
                        end,
        },
    },
}

ESO_Dialogs["HELP_SUBMIT_FEEDBACK_SUBMIT_TICKET_SUCCESSFUL_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    mustChoose = true,
    title =
    {
        text = GetString(SI_CUSTOMER_SERVICE_SUBMIT_CONFIRMATION),
    },
    mainText =
    {
        text = GetString(SI_CUSTOMER_SERVICE_SUBMIT_FEEDBACK_SUBMIT_CONFIRMATION),
    },

    buttons =
    {
        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_EXIT,
        },
    },
}

ESO_Dialogs["HELP_CUSTOMER_SERVICE_SUBMIT_TICKET_ERROR_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    mustChoose = true,
    title =
    {
        text = GetString(SI_CUSTOMER_SERVICE_SUBMIT_FAILED),
    },
    mainText =
    {
        text = zo_strformat(SI_CUSTOMER_SERVICE_SUBMIT_FAILED_BODY, GetURLTextByType(APPROVED_URL_ESO_HELP))
    },

    buttons =
    {
        {
            text = SI_CUSTOMER_SERVICE_OPEN_WEB_BROWSER,
            visible = function()
                return not IsConsoleUI()
            end,
            callback = function(...)
                ZO_PlatformOpenApprovedURL(APPROVED_URL_ESO_HELP, GetString(SI_CUSTOMER_SERVICE_ESO_HELP_LINK_TEXT), GetString(SI_URL_APPLICATION_WEB))
            end,
        },
        {
            text = SI_DIALOG_EXIT,
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
        text = function(dialog)
            local researchText = GetString(SI_GAMEPAD_SMITHING_RESEARCH_CONFIRM_DIALOG_TEXT)
            if IsItemInArmory(dialog.data.bagId, dialog.data.slotIndex) then
                local armoryBuildList = { GetItemArmoryBuildList(dialog.data.bagId, dialog.data.slotIndex) }
                local armoryBuildString = ZO_GenerateCommaSeparatedListWithAnd(armoryBuildList)
                local armoryBuildText = zo_strformat(SI_RESEARCH_ARMORY_EQUIPMENT_NOTICE, ZO_SELECTED_TEXT:Colorize(armoryBuildString), #armoryBuildList)
                return ZO_GenerateParagraphSeparatedList({ researchText, armoryBuildText })
            else
                return researchText
            end
        end,
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
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
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
        {
            text = SI_OPTIONS_RESET,
            callback = function(dialog)
                ResetKeyboardBindsToDefault()
            end
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["KEYBINDINGS_RESET_GAMEPAD_TO_DEFAULTS"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
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
        {
            text = SI_OPTIONS_RESET,
            callback = function(dialog)
                ResetGamepadBindsToDefault()
            end
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["COLLECTIBLE_REQUIREMENT_FAILED"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
        allowShowOnNextScene = true,
    },
    canQueue = true,
    title =
    {
        text = SI_COLLECTIBLE_LOCKED_FAILURE_DIALOG_TITLE,
    },
    mainText =
    {
        text = function(dialog)
            local collectibleData = dialog.data.collectibleData
            if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                return SI_COLLECTIBLE_LOCKED_FAILURE_CHAPTER_DIALOG_BODY
            elseif collectibleData:IsUnlockedViaSubscription() then
                return SI_COLLECTIBLE_LOCKED_FAILURE_DLC_DIALOG_BODY
            else
                return SI_COLLECTIBLE_LOCKED_FAILURE_NON_ESO_PLUS_DIALOG_BODY
            end
        end,
    },
    buttons =
    {
        {
            text = function(dialog)
                if dialog.data.collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                    return GetString(SI_DLC_BOOK_ACTION_CHAPTER_UPGRADE)
                else
                    return GetString(SI_COLLECTIBLE_LOCKED_FAILURE_DIALOG_PRIMARY_BUTTON)
                end
            end,
            callback = function(dialog)
                local openSource = dialog.data.marketOpenOperation or MARKET_OPEN_OPERATION_COLLECTIBLE_FAILURE
                local collectibleData = dialog.data.collectibleData
                if collectibleData:IsCategoryType(COLLECTIBLE_CATEGORY_TYPE_CHAPTER) then
                    ZO_ShowChapterUpgradePlatformScreen(openSource)
                else
                    local searchTerm = zo_strformat(SI_CROWN_STORE_SEARCH_FORMAT_STRING, collectibleData:GetName())
                    ShowMarketAndSearch(searchTerm, openSource)
                end
            end,
        },
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

function ZO_Dialogs_ShowCollectibleRequirementFailedPlatformDialog(collectibleData, message, marketOpenOperation)
    local relevantCollectibleData = collectibleData
    local purchasableCollectibleId = collectibleData:GetPurchasableCollectibleId()
    if purchasableCollectibleId ~= 0 and purchasableCollectibleId ~= collectibleData:GetId() then
        relevantCollectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(purchasableCollectibleId)
    end
    local collectibleName = relevantCollectibleData:GetName()
    local categoryName = relevantCollectibleData:GetCategoryData():GetName()
    ZO_Dialogs_ShowPlatformDialog("COLLECTIBLE_REQUIREMENT_FAILED", { collectibleData = relevantCollectibleData, marketOpenOperation = marketOpenOperation }, { mainTextParams = { message, collectibleName, categoryName } })
end

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
            callback = ResetAllTutorials
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
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
            callback = function(dialog)
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
        text = SI_DIALOG_CONFIRM_BINDING_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_DIALOG_TRADE_BOP_MODIFYING_ITEM_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            dialog.data.onAcceptCallback()
                       end,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_EQUIP_ITEM"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DIALOG_CONFIRM_BINDING_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_DIALOG_CONFIRM_EQUIPPING_ITEM_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                            dialog.data.onAcceptCallback()
                       end,
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_BIND_ITEM"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DIALOG_CONFIRM_BINDING_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_DIALOG_CONFIRM_BIND_ITEM_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.onAcceptCallback()
            end,
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
            allowRightStickPassThrough = true,
        },
        title =
        {
            text = SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND,
        },
        parametricList = {}, --we'll generate the entries on setup
        finishedCallback = function(dialog)
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

ESO_Dialogs["GAMEPAD_CRAFTING_OPTIONS_DIALOG"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        allowRightStickPassThrough = true,
    },

    setup = function(dialog, data)
        dialog.entryList:SetOnTargetDataChangedCallback(function(owner, targetData)
            if targetData.onSelected ~= nil then
                targetData.onSelected()
            end
        end)
        dialog.info.parametricList = data.parametricList
        dialog:setupFunc()

        local targetData = dialog.entryList:GetTargetData()
        if targetData.onSelected ~= nil then
            targetData.onSelected()
        end
    end,
    onHidingCallback = function(dialog)
        if dialog.data.finishedCallback then
            dialog.data.finishedCallback(dialog)
        end
    end,
    title =
    {
        text = SI_GAMEPAD_OPTIONS_MENU,
    },
    blockDialogReleaseOnPress = true,
    buttons =	
    {
        {
            text = SI_GAMEPAD_SELECT_OPTION,
            callback  = function(dialog)
                local targetData = dialog.entryList:GetTargetData()
                targetData.callback(dialog)
            end
        },

        {
            text = SI_GAMEPAD_BACK_OPTION,
            callback = function(dialog)
                ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_CRAFTING_OPTIONS_DIALOG")
            end
        },
    },
}

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
            text = SI_YES,
            callback = function(dialog)
                            dialog.data.gemificationSlot:GemifyAll()
                        end,
        },
        [2] =
        {
            text = SI_NO,
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
            text = SI_YES,
            callback = function(dialog)
                            local transferDialog = SYSTEMS:GetObject("ItemTransferDialog")
                            transferDialog:StartTransfer(dialog.data.sourceBagId, dialog.data.sourceSlotIndex, BAG_VIRTUAL)
                        end,
        },
        [2] =
        {
            text = SI_NO,
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
            text = SI_YES,
            callback = function(dialog)
                            StowAllVirtualItems()
                        end,
        },
        [2] =
        {
            text = SI_NO,
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
            text = SI_YES,
            callback = function(dialog)
                            SetHousingPrimaryHouse(dialog.data.currentHouse)
                        end,
        },
        [2] =
        {
            text = SI_NO,
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
                callback = function(dialog)
                                PlaySound(SOUNDS.HOUSING_BUY_FOR_GOLD)
                                BuyStoreItem(dialog.data.goldStoreEntryIndex, 1)
                            end
            },

            [2] =
            {
                text = SI_DIALOG_CANCEL,
            }
        },
        finishedCallback = OnBuyHouseForGoldReleased,
        noChoiceCallback = OnBuyHouseForGoldReleased,
    }
end

ESO_Dialogs["CONFIRM_LEAVE_BATTLEGROUND"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_BATTLEGROUND_CONFIRM_LEAVE_TITLE,
    },
    mainText =
    {
        text = SI_BATTLEGROUND_CONFIRM_LEAVE_DESCRIPTION,
    },
    buttons =
    {
        [1] =
        {
            text = SI_YES,
            callback = function(dialog)
                            LeaveBattleground()
                        end,
        },
        [2] =
        {
            text = SI_NO,
        }
    }
}

ESO_Dialogs["CONFIRM_CANCEL_RESEARCH"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_CRAFTING_CONFIRM_CANCEL_RESEARCH_TITLE,
    },
    mainText =
    {
        text = SI_CRAFTING_CONFIRM_CANCEL_RESEARCH_DESCRIPTION,
    },
    editBox =
    {
        matchingString = GetString(SI_PERFORM_ACTION_CONFIRMATION)
    },
    warning =
    {
        text = SI_CRAFTING_CONFIRM_CANCEL_RESEARCH_WARNING
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text = SI_YES,
            callback = function(dialog)
                            local data = dialog.data
                            CancelSmithingTraitResearch(data.craftingType, data.researchLineIndex, data.traitIndex)
                        end,
        },
        [2] =
        {
            text = SI_NO,
        }
    }
}

ESO_Dialogs["PTP_TIMED_RESPONSE_PROMPT"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = function(dialog)
            return dialog.data.dialogTitle
        end,
    },
    mainText =
    {
        text = function(dialog)
            return ZO_PlayerToPlayer_GetIncomingEntryDisplayText(dialog.data)
        end,
    },
    buttons =
    {
        {
            onShowCooldown = 2000,
            keybind = "DIALOG_TERTIARY",
            gamepadPreferredKeybind = "DIALOG_PRIMARY",
            text = function(dialog)
                local dialogData = dialog.data
                return dialogData.acceptText or GetString(SI_DIALOG_ACCEPT)
            end,
            callback = function(dialog)
                PLAYER_TO_PLAYER:Accept(dialog.data)
            end,
            visible = function(dialog)
                return PLAYER_TO_PLAYER:ShouldShowAccept(dialog.data)
            end,
        },
        {
            onShowCooldown = 2000,
            keybind = "DIALOG_RESET",
            gamepadPreferredKeybind = "DIALOG_NEGATIVE",
            text = function(dialog)
                local dialogData = dialog.data
                return dialogData.declineText or GetString(SI_DIALOG_DECLINE)
            end,
            callback = function(dialog)
                if dialog.data.incomingType == ZO_INTERACT_TYPE.LFG_READY_CHECK then
                    -- Pause the queue to force this followup to the front, then immediately unpause again
                    local EXEMPTION_LIST =
                    {
                        "LFG_DECLINE_READY_CHECK_CONFIRMATION",
                    }
                    ZO_Dialogs_SetDialogQueuePaused(true, EXEMPTION_LIST)
                    ZO_Dialogs_ShowPlatformDialog("LFG_DECLINE_READY_CHECK_CONFIRMATION", dialog.data)
                    ZO_Dialogs_SetDialogQueuePaused(false)
                elseif dialog.data.declineCallback then
                    dialog.data.declineCallback()
                end
            end,
            visible = function(dialog)
                return PLAYER_TO_PLAYER:ShouldShowDecline(dialog.data)
            end,
        }
    },
    updateFn = function(dialog)
        ZO_Dialogs_RefreshDialogText("PTP_TIMED_RESPONSE_PROMPT", dialog)

        local dialogData = dialog.data
        if dialogData.expirationCallback and GetFrameTimeSeconds() > dialogData.expiresAtS then
            dialogData.expirationCallback()
        end
    end,
}

ESO_Dialogs["CONFIRM_ENCHANT_LOCKED_ITEM"] =
{
    canQueue = true,
    title =
    {
        text = SI_ENCHANTING_CONFIRM_LOCKED_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_ENCHANTING_CONFIRM_LOCKED_ITEM_DESCRIPTION,
    },
    editBox =
    {
        matchingString = GetString(SI_PERFORM_ACTION_CONFIRMATION)
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                local data = dialog.data
                data.onAcceptCallback()
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    }
}

ESO_Dialogs["GAMEPAD_CONFIRM_ENCHANT_LOCKED_ITEM"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ENCHANTING_CONFIRM_LOCKED_ITEM_TITLE,
    },
    mainText =
    {
        text = SI_GAMEPAD_ENCHANTING_CONFIRM_ENCHANT_LOCKED_ITEM,
    },
    buttons =
    {
        [1] =
        {
            onShowCooldown = 2000,
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.onAcceptCallback()
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_RETRAIT_ITEM"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_RETRAIT_STATION_PERFORM_RETRAIT_DIALOG_TITLE,
    },
    mainText =
    {
        text = function(dialog)
                    local data = dialog.data
                    if IsItemBound(data.bagId, data.slotIndex) then
                        return SI_RETRAIT_STATION_PERFORM_RETRAIT_DIALOG_CONFIRM
                    else
                        return SI_RETRAIT_STATION_PERFORM_RETRAIT_AND_BIND_DIALOG_CONFIRM
                    end
                end,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_ACCEPT,
            clickSound = SOUNDS.RETRAITING_START_RETRAIT,
            callback = function(dialog)
                local data = dialog.data
                RequestItemTraitChange(data.bagId, data.slotIndex, data.trait)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_RETRAIT_LOCKED_ITEM"] =
{
    canQueue = true,
    title =
    {
        text = SI_RETRAIT_STATION_PERFORM_RETRAIT_DIALOG_TITLE,
    },
    mainText =
    {
        text = function(dialog)
                    local data = dialog.data
                    if IsItemBound(data.bagId, data.slotIndex) then
                        return SI_RETRAIT_STATION_PERFORM_RETRAIT_DIALOG_LOCKED_ITEM_CONFIRM
                    else
                        return SI_RETRAIT_STATION_PERFORM_RETRAIT_AND_BIND_DIALOG_LOCKED_ITEM_CONFIRM
                    end
                end,
    },
    editBox =
    {
        matchingString = GetString(SI_PERFORM_ACTION_CONFIRMATION)
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text = SI_DIALOG_ACCEPT,
            clickSound = SOUNDS.RETRAITING_START_RETRAIT,
            callback = function(dialog)
                local data = dialog.data
                RequestItemTraitChange(data.bagId, data.slotIndex, data.trait)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["GAMEPAD_CONFIRM_RETRAIT_LOCKED_ITEM"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_RETRAIT_STATION_PERFORM_RETRAIT_DIALOG_TITLE,
    },
    mainText =
    {
        text = function(dialog)
                    local data = dialog.data
                    if IsItemBound(data.bagId, data.slotIndex) then
                        return SI_GAMEPAD_RETRAIT_STATION_PERFORM_RETRAIT_DIALOG_LOCKED_ITEM_CONFIRM
                    else
                        return SI_GAMEPAD_RETRAIT_STATION_PERFORM_RETRAIT_AND_BIND_DIALOG_LOCKED_ITEM_CONFIRM
                    end
                end,
    },
    buttons =
    {
        [1] =
        {
            onShowCooldown = 2000,
            text = SI_DIALOG_ACCEPT,
            clickSound = SOUNDS.RETRAITING_START_RETRAIT,
            callback = function(dialog)
                local data = dialog.data
                RequestItemTraitChange(data.bagId, data.slotIndex, data.trait)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_REVERT_CHANGES"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_REVERT_CHANGES_DIALOG_TITLE
    },
    mainText =
    {
        text = SI_REVERT_CHANGES_DIALOG_DESCRIPTION
    },
    mustChoose = true,
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.confirmCallback()
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                if dialog.data.declineCallback then
                    dialog.data.declineCallback()
                end
            end
        },
    }
}

ESO_Dialogs["CONFIRM_APPLY_OUTFIT_STYLE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_OUTFIT_CONFIRM_COMMIT_TITLE,
    },
    mainText =
    {
        text = SI_OUTFIT_CONFIRM_COMMIT_DESCRIPTION,
    },
    buttons =
    {
        [1] =
        {
            onShowCooldown = 2000,
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                -- This dialog is only used when there is
                -- no cost involved with confirming an outfit change
                local USE_ITEMIZED_CURRENCY = false
                dialog.data.outfitManipulator:SendOutfitChangeRequest(USE_ITEMIZED_CURRENCY)
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["CONFIRM_REVERT_OUTFIT_ON_CHANGE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_OUTFIT_REVERT_ON_CHANGE_TITLE
    },
    mainText =
    {
        text = SI_OUTFIT_REVERT_ON_CHANGE_DESCRIPTION
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.confirmCallback()
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                if dialog.data.declineCallback then
                    dialog.data.declineCallback()
                end
            end
        },
    }
}

ESO_Dialogs["CONFIRM_REVERT_OUTFIT_CHANGES"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_OUTFIT_REVERT_PENDING_CHANGES_TITLE
    },
    mainText =
    {
        text = SI_OUTFIT_REVERT_PENDING_CHANGES_DESCRIPTION
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                dialog.data.confirmCallback()
            end
        },
        {
            text = SI_DIALOG_DECLINE,
            callback = function(dialog)
                if dialog.data.declineCallback then
                    dialog.data.declineCallback()
                end
            end
        },
    }
}

ESO_Dialogs["RENAME_OUFIT"] =
{
    title =
    {
        text = SI_OUTFIT_RENAME_TITLE,
    },
    mainText =
    {
        text = SI_OUTFIT_RENAME_DESCRIPTION,
    },
    editBox =
    {
        defaultText = "",
        maxInputCharacters = OUTFIT_NAME_MAX_LENGTH,
        textType = TEXT_TYPE_ALL,
        specialCharacters = {'\'', '-', ' '},
        validatesText = true,
        validator = IsValidOutfitName,
        instructions = nil,
        selectAll = true,
    },
    buttons =
    {
        [1] =
        {
            requiresTextInput = true,
            text = SI_OK,
            noReleaseOnClick = true,
            callback = function(dialog)
                local inputText = ZO_Dialogs_GetEditBoxText(dialog)
                if inputText and inputText ~= "" then
                    local violations = { IsValidOutfitName(inputText) }
                    if #violations == 0 then
                        local actorCategory = dialog.data.actorCategory
                        local outfitIndex = dialog.data.outfitIndex
                        local outfitManipulator = ZO_OUTFIT_MANAGER:GetOutfitManipulator(actorCategory, outfitIndex)
                        outfitManipulator:SetOutfitName(inputText)
                        ZO_Dialogs_ReleaseDialog("RENAME_OUFIT")
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

ESO_Dialogs["UNABLE_TO_CLAIM_GIFT"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_UNABLE_TO_CLAIM_GIFT_TITLE_FORMATTER
    },
    mainText =
    {
        text = SI_UNABLE_TO_CLAIM_GIFT_DEFAULT_ERROR_TEXT
    },
    warning =
    {
        text = SI_UNABLE_TO_CLAIM_GIFT_TEXT_FORMATTER
    },
    buttons =
    {
        {
            text = SI_DIALOG_EXIT,
        },
    },
}

ESO_Dialogs["WORLD_MAP_CHOICE_FAILED"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_WORLD_MAP_CHOICE_DIALOG_FAILED_TITLE,
    },
    mainText =
    {
        text = SI_WORLD_MAP_CHOICE_DIALOG_FAILED_FORMATTER,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
        },
    }
}

ESO_Dialogs["SKILL_RESPEC_CONFIRM_FREE"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_SKILL_RESPEC_CONFIRM_DIALOG_TITLE,
    },

    mainText =
    {
        text = function()
            local introText = GetString(SI_SKILL_RESPEC_CONFIRM_DIALOG_BODY_INTRO)
            local noCostText = GetString(SI_SKILL_RESPEC_CONFIRM_DIALOG_BODY_COST_FREE)
            return ZO_GenerateParagraphSeparatedList({ introText, noCostText })
        end,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback = function()
                SKILLS_AND_ACTION_BAR_MANAGER:ApplyChanges()
            end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["SKILL_RESPEC_CONFIRM_SCROLL"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_SKILL_RESPEC_CONFIRM_DIALOG_TITLE,
    },

    mainText =
    {
        text = function(dialog)
            local introText = GetString(SI_SKILL_RESPEC_CONFIRM_DIALOG_BODY_INTRO)
            local scrollItemLink = GetPendingSkillRespecScrollItemLink()
            local scrollName = GetItemLinkName(scrollItemLink)
            local scrollDisplayQuality = GetItemLinkDisplayQuality(scrollItemLink)
            local qualityColor = GetItemQualityColor(scrollDisplayQuality)
            local costText = zo_strformat(SI_SKILL_RESPEC_CONFIRM_DIALOG_BODY_COST_SCROLL, qualityColor:Colorize(scrollName))
            return ZO_GenerateParagraphSeparatedList({ introText, costText })
        end,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback = function()
                SKILLS_AND_ACTION_BAR_MANAGER:ApplyChanges()
            end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["STAT_ASSIGNMENT_CONFIRM"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_STATS_ASSIGNMENT_CONFIRM_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_STATS_ASSIGNMENT_CONFIRM_DIALOG_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_CONFIRM,
            callback = function()
                STATS:PurchaseAttributes()
            end,
        },

        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["STAT_EDIT_CONFIRM"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_STATS_ASSIGNMENT_CONFIRM_DIALOG_TITLE,
    },

    mainText =
    {
        text = function()
            local introText = GetString(SI_STATS_ASSIGNMENT_CONFIRM_DIALOG_BODY)
            local scrollItemLink = GetPendingAttributeRespecScrollItemLink()
            local scrollName = GetItemLinkName(scrollItemLink)
            local scrollDisplayQuality = GetItemLinkDisplayQuality(scrollItemLink)
            local qualityColor = GetItemQualityColor(scrollDisplayQuality)
            local costText = zo_strformat(SI_ATTRIBUTE_RESPEC_CONFIRM_DIALOG_BODY_COST_SCROLL, qualityColor:Colorize(scrollName))
            return ZO_GenerateParagraphSeparatedList({ introText, costText })
        end,
    },

    buttons =
    {
        {
            text = SI_DIALOG_CONFIRM,
            callback = function()
                if IsInGamepadPreferredMode() then
                    GAMEPAD_STATS:RespecAttributes()
                else
                    STATS:RespecAttributes()
                end
            end,
        },

        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["GUILD_ACCEPT_APPLICATION"] =
{
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    canQueue = true,
    title =
    {
        text = SI_GUILD_RECRUITMENT_APPLICATION_ACCEPT_TITLE,
    },
    mainText =
    {
        text = SI_GUILD_RECRUITMENT_APPLICATION_ACCEPT_DESCRIPTION,
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                            local acceptApplicationResult = AcceptGuildApplication(dialog.data.guildId, dialog.data.index)
                            if ZO_GuildFinder_Manager.IsFailedApplicationResult(acceptApplicationResult) then
                                ZO_Dialogs_ShowPlatformDialog("GUILD_FINDER_PROCESS_APPLICATION_FAILED", nil, { mainTextParams = { acceptApplicationResult } })
                            end
                        end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
        }
    }
}

ESO_Dialogs["GUILD_FINDER_APPLICATION_SUBMITTED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_BROWSER_APPLICATIONS_SUBMITTED_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_BROWSER_APPLICATIONS_SUBMITTED_DIALOG_DESCRIPTION,
    },

    buttons =
    {
        [1] =
        {
            text = SI_GUILD_BROWSER_APPLICATIONS_SUBMITTED_DIALOG_VIEW_APPLICATIONS_BUTTON,
            callback = function()
                if IsInGamepadPreferredMode() then
                    if SCENE_MANAGER:IsSceneOnStack("guildBrowserGamepad") then
                        GUILD_BROWSER_GAMEPAD:ReturnWithAppliedGuild()
                        SCENE_MANAGER:HideCurrentScene()
                    else
                        SCENE_MANAGER:Show("guildBrowserGamepad")
                    end
                else
                    GUILD_SELECTOR:SelectGuildFinder()
                    MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "guildBrowserKeyboard")
                    GUILD_BROWSER_KEYBOARD:ShowApplicationsList()
                end
            end,
        },

        [2] =
        {
            text = SI_DIALOG_CLOSE,
            callback = function()
                if IsInGamepadPreferredMode() then
                    SCENE_MANAGER:HideCurrentScene()
                end
            end
        },
    },
}

ESO_Dialogs["GUILD_FINDER_RESCIND_APPLICATION"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_BROWSER_APPLICATIONS_RESCIND_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_BROWSER_APPLICATIONS_RESCIND_DIALOG_DESCRIPTION,
    },

    buttons =
    {
        [1] =
        {
            text = SI_GUILD_BROWSER_APPLICATIONS_RESCIND_DIALOG_CANCEL_BUTTON,
            callback = function(dialog)
                RescindGuildFinderApplication(dialog.data.index)
            end,
        },

        [2] =
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}

ESO_Dialogs["GUILD_FINDER_APPLICATION_FAILED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_BROWSER_GUILD_INFO_APPLICATION_FAILED_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_FINDER_ERROR_DIALOG_BODY_FORMATTER,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}

ESO_Dialogs["GUILD_FINDER_APPLICATION_STALE"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_BROWSER_GUILD_INFO_APPLICATION_FAILED_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_FINDER_ERROR_DIALOG_BODY_FORMATTER,
    },

    buttons =
    {
        [1] =
        {
            text = SI_GUILD_BROWSER_APPLICATION_DIALOG_REFRESH_GUILD,
            callback = function(dialog)
                GUILD_BROWSER_MANAGER:RequestGuildData(dialog.data.guildId)
            end
        },
        [2] =
        {
            text = SI_DIALOG_CLOSE,
            callback = function(dialog)
                if dialog.data.onCloseFunction then
                    dialog.data.onCloseFunction()
                end
            end
        },
    },
}

ESO_Dialogs["GUILD_FINDER_APPLICATION_DECLINED_FAILED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_RECRUITMENT_APPLICATION_DECLINE_FAILED_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_FINDER_ERROR_DIALOG_BODY_FORMATTER,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}

ESO_Dialogs["UNINVITE_GUILD_PLAYER"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_UNINVITE_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_UNINVITE_PLAYER_WARNING,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                GuildUninvite(dialog.data.guildId, dialog.data.displayName)
            end,
        },

        [2] =
        {
            text = SI_DIALOG_CANCEL,
        },
    },
}

ESO_Dialogs["GUILD_FINDER_BLACKLIST_FAILED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_RECRUITMENT_BLACKLIST_FAILED_TITLE,
    },

    mainText =
    {
        text = function(dialog)
            return GetString("SI_GUILDBLACKLISTRESPONSE", dialog.textParams.mainTextParams[1])
        end,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}

ESO_Dialogs["GUILD_FINDER_PROCESS_APPLICATION_FAILED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_RECRUITMENT_ACCEPT_APPLICATION_FAILED_TITLE,
    },

    mainText =
    {
        text = function(dialog)
            return GetString("SI_GUILDPROCESSAPPLICATIONRESPONSE", dialog.textParams.mainTextParams[1])
        end,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}

ESO_Dialogs["GUILD_FINDER_SAVE_FROM_RECRUITMENT_STATUS_LISTED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_RECRUITMENT_LISTED_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_RECRUITMENT_LISTED_DIALOG_DESCRIPTION,
    },

    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}

ESO_Dialogs["GUILD_FINDER_SAVE_FROM_RECRUITMENT_STATUS_UNLISTED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GUILD_RECRUITMENT_UNLISTED_DIALOG_TITLE,
    },

    mainText =
    {
        text = SI_GUILD_RECRUITMENT_UNLISTED_DIALOG_DESCRIPTION,
    },

    buttons =
    {
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}
ESO_Dialogs["CONFIRM_CLEAR_UNUSED_KEYBINDS"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_CONFIRM_CLEAR_UNUSED_KEYBINDS_TITLE,
    },

    mainText =
    {
        text = SI_CONFIRM_CLEAR_UNUSED_KEYBINDS_BODY,
    },

    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                ClearBindsForUnknownActions()
                if ADD_ON_MANAGER then
                    ADD_ON_MANAGER:RefreshSavedKeybindsLabel()
                end
                ADDON_MANAGER_GAMEPAD:RefreshFooter()
            end,
        },
        {
            text = SI_DIALOG_DECLINE,
        }
    },
}

ESO_Dialogs["CONFIRM_COMPLETE_QUEST_MAX_WARNINGS"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_QUEST_COMPLETE_CONFIRM_TITLE,
    },

    mainText =
    {
        text = function(dialog)
            if dialog.data then
                local questName = GetJournalQuestInfo(dialog.data.journalQuestIndex)
                local questionText = zo_strformat(SI_QUEST_COMPLETE_CONFIRM_QUESTION, ZO_WHITE:Colorize(questName))

                local capacityList = ZO_GenerateCommaSeparatedListWithAnd(dialog.data.currenciesWithMaxWarning)
                local capacityText = zo_strformat(SI_QUEST_COMPLETE_CONFIRM_CAPACITY, capacityList)

                local acquireList = ZO_GenerateCommaSeparatedListWithAnd(dialog.data.amountsAcquiredWithMaxWarning)
                local acquireText = zo_strformat(SI_QUEST_COMPLETE_CONFIRM_ACQUIRE, acquireList)

                return ZO_GenerateParagraphSeparatedList({questionText, ZO_ERROR_COLOR:Colorize(capacityText), ZO_ERROR_COLOR:Colorize(acquireText)})
            end
            return ""
        end,
    },

    buttons =
    {
        {
            onShowCooldown = 2000,
            text = SI_DIALOG_YES,
            callback = function(dialog)
                CompleteQuest()
            end,
        },
        {
            text = SI_DIALOG_NO,
        }
    },
}

ESO_Dialogs["GROUP_FINDER_CREATE_EDIT_FAILED"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = function(dialog)
            if dialog.data and dialog.data.isEdit then
                return SI_GROUP_FINDER_EDIT_FAILED_TITLE
            end
            return SI_GROUP_FINDER_CREATE_FAILED_TITLE
        end
    },

    mainText =
    {
        text = function(dialog)
            return GetString("SI_GROUPFINDERACTIONRESULT", dialog.textParams.mainTextParams[1])
        end,
    },

    buttons =
    {
        {
            text = SI_DIALOG_CLOSE,
        },
    },
}

ESO_Dialogs["GROUP_FINDER_CREATE_RESCIND_APPLICATION"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },

    title =
    {
        text = SI_GROUP_FINDER_CREATE_RESCIND_APPLICATION_TITLE,
    },

    mainText =
    {
        text = SI_GROUP_FINDER_CREATE_RESCIND_APPLICATION_DESCRIPTION,
    },

    buttons =
    {
        {
            text = SI_DIALOG_CONFIRM,
            callback = function(dialog)
                RequestResolveGroupListingApplication(RESOLVE_GROUP_LISTING_APPLICATION_REQUEST_RESCIND)
                if IsInGamepadPreferredMode() then
                    GROUP_FINDER_GAMEPAD.createEditDialogObject:ShowDialog()
                else
                    GROUP_FINDER_KEYBOARD:SetMode(ZO_GROUP_FINDER_MODES.CREATE_EDIT)
                end
            end,
        },
        {
            text = SI_DIALOG_CANCEL,
        }
    },
}

ESO_Dialogs["GAMEPAD_HOUSING_EDITOR_LINK_INVITE"] =
{
    buttons =
    {
        {
            keybind = "DIALOG_PRIMARY",
            text = SI_OK,
            callback = function(dialog)
                local data = dialog.entryList:GetTargetData()
                data.callback(dialog)
            end,
        },

        {
            keybind = "DIALOG_NEGATIVE",
            text = SI_DIALOG_CANCEL,
        },
    },

    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
    },

    parametricList =
    {
        -- Link Invite In Chat
        {
            template = "ZO_GamepadMenuEntryTemplate",

            templateData =
            {
                callback = function(dialog)
                    ZO_HousingBook_LinkCurrentHouseInChat()
                end,
                setup = ZO_SharedGamepadEntry_OnSetup,
                text = GetString(SI_HOUSING_LINK_IN_CHAT),
                visible = function(dialog)
                    return HOUSING_EDITOR_STATE:IsHouse() and not HOUSING_EDITOR_STATE:IsHousePreview() and IsChatSystemAvailableForCurrentPlatform()
                end,
            },
        },

        -- Link Invite In Mail
        {
            template = "ZO_GamepadMenuEntryTemplate",

            templateData =
            {
                callback = function(dialog)
                    ZO_HousingBook_LinkCurrentHouseInMail()
                end,
                setup = ZO_SharedGamepadEntry_OnSetup,
                text = GetString(SI_HOUSING_LINK_IN_MAIL),
                visible = function(dialog)
                    return HOUSING_EDITOR_STATE:IsHouse() and not HOUSING_EDITOR_STATE:IsHousePreview()
                end,
            },
        },
    },

    setup = function(dialog)
        dialog:setupFunc()
    end,

    title =
    {
        text = SI_GAMEPAD_HOUSING_SEND_INVITE,
    },
}

ESO_Dialogs["GROUP_PROMOTE_LEADER"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER,
    },
    mainText =
    {
        text = SI_GROUP_LIST_MENU_PROMOTE_TO_LEADER_DIALOG_BODY,
    },
    buttons =
    {
        {
            text = SI_DIALOG_ACCEPT,
            callback = function(dialog)
                GroupPromote(dialog.data.unitTag)
            end,
        },
        {
            text = SI_DIALOG_DECLINE,
        }
    }
}

ESO_Dialogs["CONFIRM_CHANGE_DEFAULT_HOUSING_PERMISSION"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_DIALOG_CHANGE_DEFAULT_HOUSING_PERMISSION_TITLE,
    },
    mainText =
    {
        text = function(dialog)
            if dialog.data then
                local housePermissionDefaultAccessSetting = dialog.data.housePermissionDefaultAccessSetting
                local permissionName = GetString("SI_HOUSEPERMISSIONDEFAULTACCESSSETTING", housePermissionDefaultAccessSetting)
                local permissionDescription = GetString("SI_HOUSEPERMISSIONDEFAULTACCESSSETTING_DESCRIPTION", housePermissionDefaultAccessSetting)
                return zo_strformat(SI_DIALOG_CHANGE_DEFAULT_HOUSING_PERMISSION_TEXT, ZO_SELECTED_TEXT:Colorize(permissionName), ZO_SELECTED_TEXT:Colorize(permissionName), ZO_HIGHLIGHT_TEXT:Colorize(permissionDescription))
            end
        end,
    },
    warning =
    {
        text = function(dialog)
            local data = dialog.data
            if data and IsHouseListed(data.houseId) and not IsHouseDefaultAccessSettingValidForHouseToursListing(data.housePermissionDefaultAccessSetting) then
                return GetString(SI_DIALOG_CHANGE_DEFAULT_HOUSING_PERMISSION_LISTED_HOUSE_WARNING)
            end
            return ""
        end
    },
    buttons =
    {
        [1] =
        {
            text = SI_DIALOG_CHANGE_DEFAULT_HOUSING_PERMISSION_CONFIRM_BUTTON,
            callback = function(dialog)
                local data = dialog.data
                if not (data and data.houseId and data.housePermissionDefaultAccessSetting) then
                    internalassert(false, "Dialog data is missing 'houseId' and/or 'housePermissionDefaultAccessSetting'.")
                    if data and data.failureCallback then
                        data.failureCallback(data)
                    end
                    return
                end

                local canAccess, presetPermissionSetting = HOUSE_SETTINGS_MANAGER:GetHousingPermissionsFromDefaultAccess(data.housePermissionDefaultAccessSetting)
                local DO_NOT_UPDATE_ALL_HOUSES = false
                AddHousingPermission(data.houseId, HOUSE_PERMISSION_USER_GROUP_GENERAL, canAccess, presetPermissionSetting, DO_NOT_UPDATE_ALL_HOUSES)
                if data.successCallback then
                    data.successCallback(data)
                end
            end,
        },
        [2] =
        {
            text = SI_DIALOG_CANCEL,
            callback = function(dialog)
                local data = dialog.data
                if data and data.failureCallback then
                    data.failureCallback(data)
                end
            end,
        }
    }
}

ESO_Dialogs["GAMEPAD_CONFIRM_LEAVE_ADDON_MANAGER"] =
{
    canQueue = true,
    gamepadInfo =
    {
        dialogType = GAMEPAD_DIALOGS.BASIC,
    },
    title =
    {
        text = SI_ADDON_MANAGER_RELOAD,
    },
    mainText =
    {
        text = SI_GAMEPAD_ADDON_MANAGER_CONFIRM_LEAVE_DIALOG_DESCRIPTION,
    },
    mustChoose = true,
    buttons =
    {
        {
            text = SI_ADDON_MANAGER_RELOAD,
            callback = function(dialog)
                dialog.data.confirmCallback()
            end
        },
        {
            text = SI_DIALOG_EXIT,
            callback = function(dialog)
                if dialog.data.declineCallback then
                    dialog.data.declineCallback()
                end
            end
        },
    }
}