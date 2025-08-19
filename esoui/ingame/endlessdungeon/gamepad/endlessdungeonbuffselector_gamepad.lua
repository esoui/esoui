ZO_EndlessDungeonBuffSelector_Gamepad = ZO_EndlessDungeonBuffSelector_Shared:Subclass()

function ZO_EndlessDungeonBuffSelector_Gamepad:Initialize(...)
    ZO_EndlessDungeonBuffSelector_Shared.Initialize(self, ...)

    ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_GAMEPAD = self:GetScene()
    SYSTEMS:RegisterGamepadRootScene("endlessDungeonBuffSelector", ENDLESS_DUNGEON_BUFF_SELECTOR_SCENE_GAMEPAD)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:OnDeferredInitialize()
    ZO_EndlessDungeonBuffSelector_Shared.OnDeferredInitialize(self)

    self:RegisterDialog()
    self:InitializeNarrationInfo()
    self:InitializeFooter()
end

function ZO_EndlessDungeonBuffSelector_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return self:IsShowing()
        end,

        headerNarrationFunction = function()
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.titleText)
        end,

        footerNarrationFunction = function()
            return GAMEPAD_GENERIC_FOOTER:GetNarrationText(self.footerData)
        end,

        -- Selection narrated via tooltip
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("EndlessDungeonBuffSelector", narrationInfo)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:InitializeControls()
    local DEFAULT_MOVEMENT_CONTROL = nil
    self.focus = ZO_GamepadFocus:New(self.control, DEFAULT_MOVEMENT_CONTROL, MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.focus:SetPlaySoundFunction(function() PlaySound(SOUNDS.HOR_LIST_ITEM_SELECTED) end)

    ZO_EndlessDungeonBuffSelector_Shared.InitializeControls(self)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:InitializeKeybindStripDescriptor()
    self.keybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
                self:CommitChoice()
            end,
            visible = function()
                return self.selectedBuffControl ~= nil
            end,
        },
        {
            name = function()
                local IS_GAMEPAD = true
                local rerollCost = GetEndlessDungeonBuffSelectorRerollCost()
                local currencyAmount = GetCurrencyAmount(CURT_ARCHIVAL_FORTUNES, GetCurrencyPlayerStoredLocation(CURT_ARCHIVAL_FORTUNES))
                local canAffordReroll = rerollCost <= currencyAmount
                local extraOptions = nil
                if not canAffordReroll then
                    extraOptions =
                    {
                        color = ZO_ERROR_COLOR,
                    }
                end
                local rerollCostText = ZO_Currency_Format(rerollCost, CURT_ARCHIVAL_FORTUNES, ZO_CURRENCY_FORMAT_AMOUNT_ICON, IS_GAMEPAD, extraOptions)
                return zo_strformat(SI_GAMEPAD_ENDLESS_DUNGEON_REROLL_BUFFS_LABEL, rerollCostText)
            end,
            narrationOverrideName = function()
                local costNarration = ZO_Currency_FormatGamepad(CURT_ARCHIVAL_FORTUNES, GetEndlessDungeonBuffSelectorRerollCost(), ZO_CURRENCY_FORMAT_AMOUNT_ICON)
                return zo_strformat(SI_GAMEPAD_ENDLESS_DUNGEON_REROLL_BUFFS_LABEL, costNarration)
            end,
            keybind = "UI_SHORTCUT_SECONDARY",
            callback = function()
                ZO_Dialogs_ShowGamepadDialog("GAMEPAD_ENDLESS_DUNGEON_CONFIRM_REROLL_DIALOG")
            end,
            visible = CanRerollCurrentBuffSelectorOptions,
            enabled = function()
                local rerollCost = GetEndlessDungeonBuffSelectorRerollCost()
                local currencyAmount = GetCurrencyAmount(CURT_ARCHIVAL_FORTUNES, GetCurrencyPlayerStoredLocation(CURT_ARCHIVAL_FORTUNES))
                return rerollCost <= currencyAmount
            end,
        },
    }
end

function ZO_EndlessDungeonBuffSelector_Gamepad:InitializeFooter()
    self.footerData =
    {
        data1Text = function()
            if not CanRerollCurrentBuffSelectorOptions() then
                return ""
            end
            local IS_GAMEPAD = true
            currencyAmount = ZO_Currency_Format(GetCurrencyAmount(CURT_ARCHIVAL_FORTUNES, GetCurrencyPlayerStoredLocation(CURT_ARCHIVAL_FORTUNES)), CURT_ARCHIVAL_FORTUNES, ZO_CURRENCY_FORMAT_AMOUNT_ICON, IS_GAMEPAD)
                
            local IS_PLURAL = false
            local IS_MIXED_CASE = false
            local currencyName = GetCurrencyName(CURT_ARCHIVAL_FORTUNES, IS_PLURAL, IS_MIXED_CASE)

            formattedText = zo_strformat(SI_ENDLESS_DUNGEON_BUFF_SELECTOR_CURRENCY_FORMAT, currencyName, currencyAmount)
            return formattedText
        end,
        data1TextNarration = function()
            if not CanRerollCurrentBuffSelectorOptions() then
                return ""
            end
            currencyAmount = ZO_Currency_FormatGamepad(CURT_ARCHIVAL_FORTUNES, GetCurrencyAmount(CURT_ARCHIVAL_FORTUNES, GetCurrencyPlayerStoredLocation(CURT_ARCHIVAL_FORTUNES)), ZO_CURRENCY_FORMAT_AMOUNT_ICON)

            local IS_PLURAL = false
            local currencyName = GetCurrencyName(CURT_ARCHIVAL_FORTUNES, IS_PLURAL)

            return zo_strformat(SI_ENDLESS_DUNGEON_BUFF_SELECTOR_CURRENCY_FORMAT, currencyName, currencyAmount)
        end,
    }
end

function ZO_EndlessDungeonBuffSelector_Gamepad:RegisterDialog()
    ZO_Dialogs_RegisterCustomDialog("GAMEPAD_ENDLESS_DUNGEON_CONFIRM_REROLL_DIALOG",
    {
        canQueue = true,
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.BASIC,
        },
        title =
        {
            text = GetString(SI_GAMEPAD_ENDLESS_DUNGEON_CONFIRM_REROLL),
        },
        mainText =
        {
            align = TEXT_ALIGN_CENTER,
            text = SI_ENDLESS_DUNGEON_BUFF_SELECTOR_REROLL_INFORMATION,
        },
        buttons =
        {
            {
                text = SI_DIALOG_CONFIRM,
                keybind = "DIALOG_PRIMARY",
                clickSound = SOUNDS.DIALOG_ACCEPT,
                callback = function(dialog)
                    RerollEndlessDungeonBuffSelection()
                    ENDLESS_DUNGEON_BUFF_SELECTOR_GAMEPAD:SetIsRerolling(true)
                end,
            },
            {
                text = SI_GAMEPAD_BACK_OPTION,
                callback = function(dialog)
                    ZO_Dialogs_ReleaseDialogOnButtonPress("GAMEPAD_ENDLESS_DUNGEON_CONFIRM_REROLL_DIALOG")
                end,
            },
        },
    })
end

function ZO_EndlessDungeonBuffSelector_Gamepad:SetupBuffControl(buffControl, previousBuffControl)
    ZO_EndlessDungeonBuffSelector_Shared.SetupBuffControl(self, buffControl, previousBuffControl)

    local focusEntry =
    {
        control = buffControl,
        highlight = buffControl.iconTexture:GetNamedChild("Highlight"),
        canFocus = function(control) return not control:IsHidden() end,
        activate = function(control) self:SelectBuff(control) end,
        deactivate = function(control) self:DeselectBuff(control) end,
    }
    self.focus:AddEntry(focusEntry)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:SelectBuff(buffControl)
    ZO_EndlessDungeonBuffSelector_Shared.SelectBuff(self, buffControl)

    GAMEPAD_TOOLTIPS:LayoutEndlessDungeonBuffAbility(GAMEPAD_RIGHT_TOOLTIP, buffControl.abilityId)
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("EndlessDungeonBuffSelector", self.narrateHeader)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:DeselectBuff(buffControl)
    ZO_EndlessDungeonBuffSelector_Shared.DeselectBuff(self, buffControl)

    GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:OnShowing()
    ZO_EndlessDungeonBuffSelector_Shared.OnShowing(self)
    
    --Narrate the header when first showing
    self.narrateHeader = true
    self.focus:Activate()
    self.narrateHeader = false
end

function ZO_EndlessDungeonBuffSelector_Gamepad:OnHiding()
    ZO_EndlessDungeonBuffSelector_Shared.OnHiding(self)

    self.focus:Deactivate()
end

function ZO_EndlessDungeonBuffSelector_Gamepad:RefreshBuffs()
    ZO_EndlessDungeonBuffSelector_Shared.RefreshBuffs(self)
    GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
end

function ZO_EndlessDungeonBuffSelector_Gamepad:GetSceneName()
    return "endlessDungeonBuffSelectorGamepad"
end

function ZO_EndlessDungeonBuffSelector_Gamepad:GetBuffTemplate()
    return "ZO_EndDunBuffSelectorBuff_Gamepad"
end

function ZO_EndlessDungeonBuffSelector_Gamepad.OnControlInitialized(control)
    ENDLESS_DUNGEON_BUFF_SELECTOR_GAMEPAD = ZO_EndlessDungeonBuffSelector_Gamepad:New(control)
end