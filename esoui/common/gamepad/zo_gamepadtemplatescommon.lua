--
-- Global Gamepad Entry Template Setup
--

local NEW_ICON_TEXTURE = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new.dds"
local STOLEN_ICON_TEXTURE = "EsoUI/Art/Inventory/inventory_stolenItem_icon.dds"
local EQUIPPED_THIS_SLOT_TEXTURE = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local EQUIPPED_OTHER_SLOT_TEXTURE = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"    --same for now
local MAIL_ATTACHED_TEXTURE = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local TRADE_ITEM_TEXTURE = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local ACHIEVEMENT_EARNED_TEXTURE = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local CAN_LEVEL_TEXTURE = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_statusIcon_pointsToSpend.dds"
local UPGRADE_SKILL_TEXTURE = "EsoUI/Art/Progression/Gamepad/gp_purchase.dds"
local ASSISTED_TEXTURE = "EsoUI/Art/Journal/Gamepad/gp_trackedQuestIcon.dds"
local SPEAKER_TEXTURE = "EsoUI/Art/VOIP/Gamepad/gp_VOIP_speaking.dds"
local SELECTED_TEXTURE = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
local LOCK_TEXTURE = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_locked32.dds"
local SPEAKER_TEXTURE = "EsoUI/Art/VOIP/Gamepad/gp_VOIP_speaking.dds"

function ZO_SharedGamepadEntry_OnInitialized(control)
    --icon and highlights
    control.icon = control:GetNamedChild("Icon")
    if control.icon then
        control.highlight = control.icon:GetNamedChild("Highlight")
        control.stackCountLabel = control.icon:GetNamedChild("StackCount")
    end
    control.checkBox = control:GetNamedChild("CheckBox")
    control.label = control:GetNamedChild("Label")
    control.header = control:GetNamedChild("Header")  
    --cooldown timer
    control.cooldown = control:GetNamedChild("Cooldown")

    --general item indicators
    control.statusIndicator = control:GetNamedChild("StatusIndicator")

    ZO_PregameGamepadEntry_OnInitialized(control)
    ZO_CraftingGamepadEntry_OnInitialized(control)
    ZO_SkillsGamepadEntry_OnInitialized(control)
    ZO_CharacterGamepadEntry_OnInitialized(control)
    ZO_GamepadGuildHubRow_OnInitialized(control)
end

function ZO_PregameGamepadEntry_OnInitialized(control)
    control.description = control:GetNamedChild("Description")
end

function ZO_CraftingGamepadEntryTraits_OnInitialized(control)
    local trait1 = control:GetNamedChild("Trait1")
    local trait2 = control:GetNamedChild("Trait2")
    local trait3 = control:GetNamedChild("Trait3")
    local trait4 = control:GetNamedChild("Trait4")

    if trait1 then 
        control.traits =
        {
            trait1,
            trait2,
            trait3,
            trait4,
        }
    end
end

function ZO_CraftingGamepadEntry_OnInitialized(control)
    control.craftingInfo = control:GetNamedChild("CraftingInfo")
    control.selectedItems = control:GetNamedChild("Selected")
    control.unselectedItems = control:GetNamedChild("Unselected")
    control.descriptionLabel = control:GetNamedChild("DescriptionLabel")
    
    local subLabel = control:GetNamedChild("SubLabel1")
    local subLabel2 = control:GetNamedChild("SubLabel2")

    if subLabel2 then 
        control.subLabelCount = 2
        control.subLabels = {}
        table.insert(control.subLabels, subLabel)
        table.insert(control.subLabels, subLabel2)
    else
        control.subLabel = subLabel
    end
    control.numInfoLabelsUsed = 0
    control.optionEnabledIcon = control:GetNamedChild("EnabledIcon")
end

function ZO_SkillsGamepadEntry_OnInitialized(control)
    control.barContainer = control:GetNamedChild("BarContainer")
    --skill lines
    control.rank = control:GetNamedChild("Rank")
    --abilities
    control.alert = control:GetNamedChild("Alert")
    control.lock = control:GetNamedChild("Lock")
    control.frame = control:GetNamedChild("Frame") --not sure if still needed by other menus
    control.circleFrame = control:GetNamedChild("CircleFrame")
    control.edgeFrame = control:GetNamedChild("EdgeFrame")
    control.skillRankHeader = control:GetNamedChild("SkillRankHeader")
    control.keybind = control:GetNamedChild("Keybind")
end

function ZO_CharacterGamepadEntry_OnInitialized(control)
    control.readyForTrain = control:GetNamedChild("ReadyForTrain")
    control.spinner = control:GetNamedChild("Spinner")
    if(control.spinner ~= nil) then
        control.spinnerDecrease = control.spinner:GetNamedChild("Decrease")
        control.spinnerIncrease = control.spinner:GetNamedChild("Increase")
    end

    local dropdown = control:GetNamedChild("Dropdown")
    if(dropdown ~= nil) then
        control.dropdown = ZO_ComboBox_ObjectFromContainer(dropdown)
    end
end

--Height Computers
-------------------------------
--Resize to fit controls have a bad interaction with labels where they cannot instantly determine their height. This is a problem when the parametric
--scroll list sets up an entry and then queries its height right afterwards, before the height is resolved. For this reason, when label height is the
--determining factor for the height of an entry, we replace the GetHeight function with our own function that uses GetTextHeight (which does resolve
--instantly). The GetHeight function should be able to compute what the height of the entry will be.

do
    local function ComputeHeightFromLabel(control)
        return control.label:GetTextHeight()
    end

    function ZO_SharedGamepadEntry_SetHeightFromLabel(control)
        control.GetHeight = ComputeHeightFromLabel
    end
end

do
    local function ComputeHeightFromLabelAndSubLabels(control)
        local height = control.label:GetTextHeight()
        for i = 1, control.subLabelCount do
            local subLabelControl = control:GetNamedChild("SubLabel"..i)
            if not subLabelControl:IsHidden() then
                height = height + subLabelControl:GetTextHeight()
            end
        end
        return height
    end

    function ZO_SharedGamepadEntry_SetHeightFromSubLabels(control)
        control.GetHeight = ComputeHeightFromLabelAndSubLabels
    end
end

--Setup Subfunctions

local function ZO_SharedGamepadEntryLabelSetup(label, data, selected)
    if label then
        if data.fontScaleOnSelection then 
            SetMenuEntryFontFace(label, selected)
        end

        if data.modifyTextType then
            label:SetModifyTextType(data.modifyTextType)
        end

        label:SetText(data.text)
        local labelColor = data:GetNameColor(selected)
        if type(labelColor) == "function" then
            labelColor = labelColor(data)
        end
        label:SetColor(labelColor:UnpackRGBA())

        if ZO_ItemSlot_SetupTextUsableAndLockedColor then -- Not available pre-game.
            ZO_ItemSlot_SetupTextUsableAndLockedColor(label, data.meetsUsageRequirements)
        end
    end
end

local PRESERVE_PREVIOUS_COOLDOWN = true
local OVERWRITE_PREVIOUS_COOLDOWN = false
local USE_LEADING_EDGE = true
local DONT_USE_LEADING_EDGE = false

function ZO_SharedGamepadEntry_Cooldown(control, remaining, duration, cooldownType, timeType, useLeadingEdge, alpha, desaturation, preservePreviousCooldown)
    local inCooldownNow = remaining > 0 and duration > 0
    if inCooldownNow then
        local timeLeftOnPreviousCooldown = control.cooldown:GetTimeLeft()
        if not preservePreviousCooldown or timeLeftOnPreviousCooldown == 0 then
            control.cooldown:SetDesaturation(desaturation)
            control.cooldown:SetAlpha(alpha)
            control.cooldown:StartCooldown(remaining, duration, cooldownType, timeType, useLeadingEdge)
        end
    else
        control.cooldown:ResetCooldown()
    end
    control.cooldown:SetHidden(not inCooldownNow)
end

local function ZO_SharedGamepadEntryCooldownSetup(control, data)
    local GAMEPAD_DEFAULT_COOLDOWN_TEXTURE = "EsoUI/Art/Mounts/timer_icon.dds"

    if control.cooldown then
        local currentTime = GetFrameTimeMilliseconds()
        local timeOffset = currentTime - (data.timeCooldownRecorded or 0)
        local remaining = (data.cooldownRemaining or 0) - timeOffset
        local duration = (data.cooldownDuration or 0)

        control.inCooldown = (remaining > 0) and (duration > 0)
        control.cooldown:SetTexture(data.cooldownIcon or GAMEPAD_DEFAULT_COOLDOWN_TEXTURE)
        
        if data.cooldownIcon then
            control.cooldown:SetFillColor(ZO_SELECTED_TEXT:UnpackRGBA())
            control.cooldown:SetVerticalCooldownLeadingEdgeHeight(4)
            ZO_SharedGamepadEntry_Cooldown(control, remaining, duration, CD_TYPE_VERTICAL_REVEAL, CD_TIME_TYPE_TIME_UNTIL, USE_LEADING_EDGE, 1, 1, PRESERVE_PREVIOUS_COOLDOWN)
        else
            ZO_SharedGamepadEntry_Cooldown(control, remaining, duration, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, DONT_USE_LEADING_EDGE, 0.85, 0, OVERWRITE_PREVIOUS_COOLDOWN)
        end
    end
end

local function ZO_SharedGamepadEntryIconSetup(icon, stackCountLabel, data, selected)
    if icon then
        if data.iconUpdateFn then
            data.iconUpdateFn()
        end

        --multi-icons control their own alpha, don't set it directly on the icon if you're using a multi-icon
        local numIcons = data:GetNumIcons()
        icon:SetMaxAlpha(data.maxIconAlpha)
        icon:ClearIcons()
        if numIcons > 0 then
            for i = 1, numIcons do
                local iconTexture = data:GetIcon(i, selected)
                icon:AddIcon(iconTexture)
            end
            icon:Show()

            if data.iconDesaturation then
                icon:SetDesaturation(data.iconDesaturation)
            end

            if stackCountLabel then
                if data.stackCount and data.stackCount > 1 then
                    stackCountLabel:SetText(data.stackCount)
                else
                    stackCountLabel:SetText("")
                end
            end

            local r, g, b = 1, 1, 1
            if data.enabled then
                if selected and data.selectedIconTint then
                    r, g, b = data.selectedIconTint:UnpackRGBA()
                elseif (not selected) and data.unselectedIconTint then
                    r, g, b = data.unselectedIconTint:UnpackRGBA()
                end
            else
                if selected and data.selectedIconDisabledTint then
                    r, g, b = data.selectedIconDisabledTint:UnpackRGBA()
                elseif (not selected) and data.unselectedIconDisabledTint then
                    r, g, b = data.unselectedIconDisabledTint:UnpackRGBA()
                end
            end

            if data.meetsUsageRequirement == false then
                icon:SetColor(r, 0, 0, icon:GetControlAlpha())
            else 
                icon:SetColor(r, g, b, icon:GetControlAlpha())
            end
        end
    end
end

local function ZO_SharedGamepadEntryStatusIndicatorSetup(statusIndicator, data)
    if statusIndicator then
        --multi-icons control their own alpha, don't set it directly on the icon if you're using a multi-icon
        statusIndicator:ClearIcons()
        
        if data.isEquippedInCurrentCategory then
            statusIndicator:AddIcon(EQUIPPED_THIS_SLOT_TEXTURE)
        elseif data.isEquippedInAnotherCategory then
            statusIndicator:AddIcon(EQUIPPED_OTHER_SLOT_TEXTURE)
        end

        local isItemNew
        if type(data.brandNew) == "function" then
            isItemNew = data.brandNew()
        else 
            isItemNew = data.brandNew
        end

        if isItemNew and data.enabled then
            statusIndicator:AddIcon(NEW_ICON_TEXTURE)
        end

        if (data.stolen) then
            statusIndicator:AddIcon(STOLEN_ICON_TEXTURE)
        end

        if data.isMailAttached then
            statusIndicator:AddIcon(MAIL_ATTACHED_TEXTURE)
        end

        if data.isTradeItem then
            statusIndicator:AddIcon(TRADE_ITEM_TEXTURE)
        end
                
        if data.isEarnedAchievement then
            statusIndicator:AddIcon(ACHIEVEMENT_EARNED_TEXTURE)
        end

        if data.canLevel and data.canLevel() then
            statusIndicator:AddIcon(CAN_LEVEL_TEXTURE)
        end

        if data.isSkillTrainable then
            statusIndicator:AddIcon(UPGRADE_SKILL_TEXTURE)
        end
        
        if data.isAssisted then
            statusIndicator:AddIcon(ASSISTED_TEXTURE)
        end
	
	    if data.isChannelActive then
            statusIndicator:AddIcon(SPEAKER_TEXTURE)
        end

        if data.isChannelActive then
            statusIndicator:AddIcon(SPEAKER_TEXTURE)
        end     
 
        if data.isSelected then
            statusIndicator:AddIcon(SELECTED_TEXTURE)
        end

        if data.isLocked then
            statusIndicator:AddIcon(LOCK_TEXTURE)
        end

        statusIndicator:Show()
    end
end

--NOTE: This is the beginning of the gamepad template setup refactor.
--The data received by this function is an object defined in ZO_GamepadEntryData,
--creating a new one will get you everything needed for a basic entry.
--To add further visual data you need to define a Initialize helper function
--similar to InitializeInventoryVisualData().  

function ZO_GamepadGuildHubRow_OnInitialized(control)
    control.guildName = control:GetNamedChild("GuildName")
    control.guildMaster = control:GetNamedChild("GuildMaster")
    control.membersOnline = control:GetNamedChild("MembersOnline")

    local bankIconContainer = control:GetNamedChild("BankIconContainer")
    if(bankIconContainer ~= nil) then
        control.bankIcon = bankIconContainer:GetNamedChild("Bank")
    end
    
    local heraldryIconContainer = control:GetNamedChild("HeraldryIconContainer")
    if(heraldryIconContainer ~= nil) then
        control.heraldryIcon = heraldryIconContainer:GetNamedChild("Heraldry")
    end
    
    local storeIconContainer = control:GetNamedChild("StoreIconContainer")
    if(storeIconContainer ~= nil) then
        control.tradingHouseIcon = storeIconContainer:GetNamedChild("TradingHouse")
    end
end

--
--This function is intended to only set visual information about the entryData, 
--which is should have stored on it from your helper function.
--
--If you find yourself adding something specific to your new system see if it
--can be created in a generic way and added to the GamepadEntryData class.
--For instance control.craftingInfo was turned into a subLabel for
--future use by other systems and Timer/TimerOverlay was turned into control.cooldown
function ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    
    if data.heightScaleOnSelection then
        control:SetDimensions(ZO_GAMEPAD_CONTENT_WIDTH, selected and ZO_GAMEPAD_DEFAULT_LIST_ENTRY_SELECTED_HEIGHT or ZO_GAMEPAD_DEFAULT_LIST_ENTRY_HEIGHT)
    end

    if data.alphaChangeOnSelection or data.disabled then
        control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))
    else
        control:SetAlpha(1)
    end
    
    ZO_SharedGamepadEntryLabelSetup(control.label, data, selected)
    
    ZO_SharedGamepadEntryIconSetup(control.icon, control.stackCountLabel, data, selected)

    if control.highlight then
        if selected and data.highlight then
            control.highlight:SetTexture(data.highlight)
        end

        control.highlight:SetHidden(not selected or not data.highlight)
    end

    ZO_SharedGamepadEntryCooldownSetup(control, data)

    ZO_SharedGamepadEntryStatusIndicatorSetup(control.statusIndicator, data)

    if control.subLabel and data.custom then
        if not selected then
            control.subLabel:SetText(nil)
        else
            control.subLabel:SetText(data.custom)
            local labelColor = data:GetSubLabelColor(selected)
            if type(labelColor) == "function" then
                labelColor = labelColor(data)
            end
            control.subLabel:SetColor(labelColor:UnpackRGBA())
        end
    end

    if control.subLabelCount then
        local labelColor = data:GetSubLabelColor(selected)
        if type(labelColor) == "function" then
            labelColor = labelColor(data)
        end

        local subLabels = data.subLabels
        for i = 1, control.subLabelCount do
            local label = control:GetNamedChild("SubLabel" .. i)
            if label then
                local text
                if subLabels then
                    local subLabel = subLabels[i]
                    if type(subLabel) == "function" then
                        text = subLabel()
                    else
                        text = subLabel
                    end
                end

                if (selected or data.showUnselectedSublabels) and (text and text ~= "") then
                    label:SetText(text)
                    label:SetHidden(false)
                    label:SetColor(labelColor:UnpackRGBA())
                else
                    label:SetHidden(true)
                end
            end
        end
    end
end

--[[ Global Helper Functions ]]--

GAMEPAD_HEADER_DEFAULT_PADDING = 80
GAMEPAD_HEADER_SELECTED_PADDING = -40
GAMEPAD_DEFAULT_POST_PADDING = 16

function SetDefaultColorOnLabel(label, selected)
    local r, g, b = (selected and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT):UnpackRGB()
    label:SetColor(r, g, b, 1)
end

local function SetDefaultColorOnCheckbox(checkbox, selected)
    local r, g, b = (selected and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT):UnpackRGB()
    ZO_CheckButtonLabel_SetTextColor(checkbox, r, g, b)
end

function SetMenuEntryFontFace(label, selected)
    label:SetFont(selected and "ZoFontGamepad42" or "ZoFontGamepad34")
end

function SetMenuEntrySmallFontFace(label, selected)
    label:SetFont(selected and "ZoFontGamepad27" or "ZoFontGamepad20")
end

function ZO_GamepadMenuEntryTemplate_GetAlpha(selected, disabled)
    if not selected or disabled then
        return .64
    else
        return 1
    end
end

function SharedGamepadEntryTemplateSetup(control, text, pressedTexture, normalTexture, highlightTexture, selected, activated, stackCount)
    if text then
        control.label:SetText(text)
    end

    if control.label then
        SetDefaultColorOnLabel(control.label, selected)
    end

    control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected))

    if control.icon then
        if pressedTexture and normalTexture then
            control.icon:SetHidden(false)
            control.icon:SetTexture(selected and pressedTexture or normalTexture)
        else
            control.icon:SetHidden(true)
        end

        if control.stackCountLabel then
            if stackCount and stackCount > 1 then
                control.stackCountLabel:SetText(stackCount)
            else
                control.stackCountLabel:SetText("")
            end
        end
    end

    if control.highlight then
        if selected and highlightTexture then
            control.highlight:SetTexture(highlightTexture)
        end

        control.highlight:SetHidden(not selected or not highlightTexture)
    end
end

function ZO_GamepadMenuEntryTemplate_Setup(control, text, pressedTexture, normalTexture, highlightTexture, selected, activated, stackCount)
    SharedGamepadEntryTemplateSetup(control, text, pressedTexture, normalTexture, highlightTexture, selected, activated, stackCount)
    SetMenuEntryFontFace(control.label, selected)
end

--TODO: This function shouldn't be used anymore (update GamepadProvisioner.lua)
function ZO_GamepadSubMenuEntryTemplate_Setup(control, text, pressedTexture, normalTexture, highlightTexture, selected, activated, stackCount)
    SharedGamepadEntryTemplateSetup(control, text, pressedTexture, normalTexture, highlightTexture, selected, activated, stackCount)
end

function ZO_GamepadOnDefaultActivatedChanged(control, activated)
    if not control.focusedChangedAnimation then
        control.focusedChangedAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("GamepadMenuEntryFocusedAnimation", control)
    end
    
    if activated then
        control.focusedChangedAnimation:PlayForward()
    else
        control.focusedChangedAnimation:PlayBackward()
    end
end

function ZO_GamepadOnDefaultScrollListActivatedChanged(list, activated)
    ZO_GamepadOnDefaultActivatedChanged(list:GetControl(), activated)
end

-- Checkbox
function ZO_GamepadCheckBoxTemplate_OnInitialized(control)
    control.checkBox = control:GetNamedChild("CheckBox")
    control.label = control:GetNamedChild("Label")
end

function ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    local text = data.text
    if type(text) == "function" then
        text = text(data)
    end
    control.label:SetText(text)
    SetDefaultColorOnCheckbox(control, selected)
    control.checkBox.toggleFunction = data.setChecked

    if data.checked ~= nil then
        local checked = data.checked
        if type(checked) == "function" then
            checked = checked(data)
        end
        if checked == true then
            ZO_CheckButton_SetChecked(control.checkBox)
        else
            ZO_CheckButton_SetUnchecked(control.checkBox)
        end
    end
end

function ZO_GamepadCheckBoxListEntryTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_GamepadCheckBoxTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)

    -- labelOffset comes from ZO_GamepadCheckBoxTemplate anchor offset + labels anchor offset set in ZO_CheckButton_SetLabelText()
    -- Need to set the width of dynamically created label control here so long labels dont overrun the list control
    local labelOffset = 35 
    local labelLeft = data.list:GetControl():GetLeft() + labelOffset
    local listRight = data.list:GetControl():GetRight()
    ZO_CheckButton_SetLabelWidth(control.checkBox, listRight - labelLeft)
end


function ZO_GamepadCheckBoxTemplate_OnClicked(control)
    ZO_CheckButton_OnClicked(control.checkBox)
end

function ZO_GamepadCheckBoxTemplate_IsChecked(control)
    return ZO_CheckButton_IsChecked(control.checkBox)
end

-- Header Label
function ZO_GamepadMenuHeaderTemplate_OnInitialized(control)
    control.text = control:GetNamedChild("Label")
end

function ZO_GamepadMenuHeaderTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    -- The header can not be selected, unless explicitly overriden by the user.
    if data.canSelect == nil then
        data.canSelect = false 
    end

    -- Set the header's text. If it is a function, call it and use it's return value.
    local text = data.text or ""
    if type(text) == "function" then
        text = text(data)
    end
    if text then
        control.text:SetText(text)
    end

    -- Set the header's text color. If it is a function, call it and use it's return value.
    local color = data.color
    if type(color) == "function" then
        color = color(data)
    end
    if color then
        if type(color) == "table" then
            control.text:SetColor(unpack(color))
        else
            control.text:SetColor(color)
        end
    end
end

function ZO_GamepadTabBarTemplate_OnInitialized(self)
    ZO_GamepadMenuHeaderTemplate_OnInitialized(self)
end

function ZO_GamepadTabBarTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if data.canSelect == nil then
        data.canSelect = true
    end
    ZO_GamepadMenuHeaderTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    SetDefaultColorOnLabel(control.text, selected)
end

--[[ Pip Code ]]--
ZO_GamepadPipCreator = ZO_Object:Subclass()

function ZO_GamepadPipCreator:New(control, drawLayer)
    local pipCreator = ZO_Object.New(self)
    pipCreator.control = control
    pipCreator.pool = ZO_ControlPool:New("ZO_GamepadTabBarPip", control)
    pipCreator.drawLayer = drawLayer
    return pipCreator
end

local PIP_WIDTH = 32 --This is the width taken up by a pip in the control.  It is independant of whatever size dds is being used
function ZO_GamepadPipCreator:RefreshPips(numPips, activePipIndex)
    self.pool:ReleaseAllObjects()
    if (not numPips) or (numPips == 0) then
        return
    end

    for i = 1,numPips do
        local pip = self.pool:AcquireObject()
        pip:SetParent(self.control)
        pip:SetAnchor(CENTER, self.control, CENTER, (i - 1 - (numPips - 1) / 2) * PIP_WIDTH, 0)

        local active = (activePipIndex == i)

        pip:GetNamedChild("Active"):SetHidden(not active)
        pip:GetNamedChild("Inactive"):SetHidden(active)

        if self.drawLayer then
            pip:GetNamedChild("Active"):SetDrawLayer(self.drawLayer)
            pip:GetNamedChild("Inactive"):SetDrawLayer(self.drawLayer)
        end
    end
end

function ZO_GetPlatformTemplate(baseTemplate)
    return IsInGamepadPreferredMode() and baseTemplate.."_Gamepad_Template" or baseTemplate.."_Keyboard_Template"
end

function ZO_GamepadDefaultHorizontalListEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, selectedFromParent)
 	control:SetText(data.text)
    
    local color = selectedFromParent and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
    control:SetColor(color:UnpackRGBA())
end

function ZO_GamepadHorizontalListRow_Initialize(self, setupFunction, equalityFunction)
    self.GetHeight = function(control)
                         return control.label:GetTextHeight() + control.horizontalListControl:GetHeight()
                     end
    self.label = self:GetNamedChild("Name")
    self.horizontalListControl = self:GetNamedChild("HorizontalList")
    self.horizontalListObject = ZO_HorizontalScrollList_Gamepad:New(self.horizontalListControl, "ZO_GamepadHorizontalListEntry", 1, setupFunction, equalityFunction)
    self.horizontalListObject:SetAllowWrapping(true)
end