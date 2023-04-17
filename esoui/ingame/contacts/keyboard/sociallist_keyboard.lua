--Social List

ZO_SocialListKeyboard = ZO_Object.MultiSubclass(ZO_SortFilterList, ZO_SocialListDirtyLogic_Shared)

function ZO_SocialListKeyboard:InitializeSortFilterList(control)
    ZO_SortFilterList.InitializeSortFilterList(self, control)
    self:SetAlternateRowBackgrounds(true)
end

function ZO_SocialListKeyboard:SetUpOnlineData(data, online, secsSinceLogoff)
    ZO_SocialList_SetUpOnlineData(data, online, secsSinceLogoff)
end

function ZO_SocialListKeyboard:GetRowColors(data, selected)
    return ZO_SocialList_GetRowColors(data, selected)
end

function ZO_SocialListKeyboard:ColorRow(control, data, mouseIsOver)
    local textColor, iconColor = self:GetRowColors(data, mouseIsOver)
    ZO_SocialList_ColorRow(control, data, textColor, iconColor, textColor)
end

function ZO_SocialListKeyboard:SharedSocialSetup(control, data)
    ZO_SortFilterList.SetupRow(self, control, data)
    ZO_SocialList_SharedSocialSetup(control, data)
end

function ZO_SocialListKeyboard:UpdateHideOfflineCheckBox(checkBox)
    local hideOfflineSetting = GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE)
    if hideOfflineSetting ~= ZO_CheckButton_IsChecked(checkBox) then
        if hideOfflineSetting then
            ZO_CheckButton_SetChecked(checkBox)
        else
            ZO_CheckButton_SetUnchecked(checkBox)
        end
        self:RefreshFilters()
    end
end

--XML

function ZO_SocialListKeyboard:Note_OnMouseEnter(control)
    local data = ZO_ScrollList_GetData(control:GetParent())
    InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
    SetTooltipText(InformationTooltip, data.note)

    self:EnterRow(control:GetParent())
end

function ZO_SocialListKeyboard:Note_OnMouseExit(control)
    ClearTooltip(InformationTooltip)

    self:ExitRow(control:GetParent())
end

function ZO_SocialListKeyboard:Note_OnClicked(control, noteEditedFunction)
    local data = ZO_ScrollList_GetData(control:GetParent())
    ZO_Dialogs_ShowDialog("EDIT_NOTE", {displayName = data.displayName, note = data.note, changedCallback = noteEditedFunction})
end

function ZO_SocialListKeyboard:DisplayName_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)
    
    if(data.hasCharacter) then
        InitializeTooltip(InformationTooltip)
        local textWidth = control:GetTextDimensions()
        InformationTooltip:ClearAnchors()
        InformationTooltip:SetAnchor(BOTTOM, control, TOPLEFT, textWidth * 0.5, 0)
        SetTooltipText(InformationTooltip, ZO_FormatUserFacingCharacterName(data.characterName))
    end

    self:EnterRow(row)
end

function ZO_SocialListKeyboard:DisplayName_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    local row = control:GetParent()
    self:ExitRow(row)
end

function ZO_SocialListKeyboard:CharacterName_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)
    
    if data.displayName then
        InitializeTooltip(InformationTooltip)
        local textWidth = control:GetTextDimensions()
        InformationTooltip:ClearAnchors()
        InformationTooltip:SetAnchor(BOTTOM, control, TOPLEFT, textWidth * 0.5, 0)
        SetTooltipText(InformationTooltip, data.displayName)
    end

    self:EnterRow(row)
end

function ZO_SocialListKeyboard:CharacterName_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    local row = control:GetParent()
    self:ExitRow(row)
end

function ZO_SocialListKeyboard:Alliance_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)

    if(data.alliance) then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, data.formattedAllianceName)
    end

    self:EnterRow(row)
end

function ZO_SocialListKeyboard:Alliance_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function ZO_SocialListKeyboard:Status_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)

    if(data.status) then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)        
        if(data.status == PLAYER_STATUS_OFFLINE) then
            SetTooltipText(InformationTooltip, zo_strformat(SI_SOCIAL_LIST_LAST_ONLINE, ZO_FormatDurationAgo(data.secsSinceLogoff + GetFrameTimeSeconds() - data.timeStamp)))
        else
            SetTooltipText(InformationTooltip, GetString("SI_PLAYERSTATUS", data.status))
        end
    end

    self:EnterRow(row)
end

function ZO_SocialListKeyboard:Status_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

local function GetClassNameFromData(data)
    local gender = data.gender or GENDER_MALE
    return zo_strformat(SI_CLASS_NAME, GetClassName(gender, data.class))
end

function ZO_SocialListKeyboard:Class_OnMouseEnter(control)
    local row = control:GetParent()
    local data = ZO_ScrollList_GetData(row)

    if(data.class) then
        InitializeTooltip(InformationTooltip, control, BOTTOM, 0, 0)
        SetTooltipText(InformationTooltip, GetClassNameFromData(data))
    end

    self:EnterRow(row)
end

function ZO_SocialListKeyboard:Class_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
    self:ExitRow(control:GetParent())
end

function ZO_SocialListKeyboard:Champion_OnMouseEnter(control)
    local row = control:GetParent()
    self:EnterRow(row)
end

function ZO_SocialListKeyboard:Champion_OnMouseExit(control)
    self:ExitRow(control:GetParent())
end

function ZO_SocialListKeyboard:HideOffline_OnClicked()
	SetSetting(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE, tostring(not GetSetting_Bool(SETTING_TYPE_UI, UI_SETTING_SOCIAL_LIST_HIDE_OFFLINE)))
	self:RefreshFilters()
	self:UpdateKeybinds()
end