ZO_BUFF_DEBUFF_FRAME_DIMENSIONS_KEYBOARD = 40
ZO_BUFF_DEBUFF_ICON_DIMENSIONS_KEYBOARD = ZO_BUFF_DEBUFF_FRAME_DIMENSIONS_KEYBOARD - 4
ZO_BUFF_DEBUFF_FRAME_DIMENSIONS_GAMEPAD = 46
ZO_BUFF_DEBUFF_ICON_DIMENSIONS_GAMEPAD = ZO_BUFF_DEBUFF_FRAME_DIMENSIONS_GAMEPAD - 8

ZO_BUFF_DEBUFF_KEYBOARD_STYLE =
{
    CONTAINER_HEIGHT = ZO_BUFF_DEBUFF_FRAME_DIMENSIONS_KEYBOARD,
}

ZO_BUFF_DEBUFF_GAMEPAD_STYLE =
{
    CONTAINER_HEIGHT = ZO_BUFF_DEBUFF_FRAME_DIMENSIONS_GAMEPAD,
}

local PLAYER_UNIT_TAG = "player"
local TARGET_UNIT_TAG = "reticleover"
local BUFF_PADDING = 5

-------------------------
--Unit Container Object--
-------------------------

ZO_BuffDebuff_ContainerObject = ZO_Object:Subclass()

function ZO_BuffDebuff_ContainerObject:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_BuffDebuff_ContainerObject:Initialize(control, buffControlPool, unitTag, initEvent)
    self.control = control
    self.unitTag = unitTag

    self.buffPool = self:CreateMetaPool(control:GetNamedChild("Container1"), buffControlPool)
    self.debuffPool = self:CreateMetaPool(control:GetNamedChild("Container2"), buffControlPool)
    self.fadeTimeline = ANIMATION_MANAGER:CreateTimelineFromVirtual("ZO_BuffDebuff_FadeAnimation", control)

    self.settings =
    {
        [BUFFS_SETTING_ALL_ENABLED] = BUFF_DEBUFF_ENABLED_CHOICE_DONT_SHOW,
        [BUFFS_SETTING_BUFFS_ENABLED] = true,
        [BUFFS_SETTING_DEBUFFS_ENABLED] = true,
        [BUFFS_SETTING_LONG_EFFECTS] = true,
        [BUFFS_SETTING_PERMANENT_EFFECTS] = true,
        [BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS] = false,
        [BUFFS_SETTING_BUFFS_ENABLED_FOR_TARGET] = false,
    }

    local function MarkDirty()
        self.isDirty = true
    end

    if initEvent then
        self.control:RegisterForEvent(initEvent, MarkDirty)
    end

    local function OnUpdate()
        if self.isDirty then
            self:Update()
        end
        self:UpdateTime()
    end

    self.control:RegisterForEvent(EVENT_EFFECTS_FULL_UPDATE, MarkDirty)
    self.control:RegisterForEvent(EVENT_EFFECT_CHANGED, MarkDirty)
    self.control:AddFilterForEvent(EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, self.unitTag)
    self.control:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_ADDED, MarkDirty)
    self.control:RegisterForEvent(EVENT_ARTIFICIAL_EFFECT_REMOVED, MarkDirty)
    if unitTag == PLAYER_UNIT_TAG then
        self.control:RegisterForEvent(EVENT_PLAYER_COMBAT_STATE, MarkDirty)
    end
    control:SetHandler("OnUpdate", OnUpdate)

    ZO_PlatformStyle:New(function(style) self:ApplyPlatformStyle(style) end, ZO_BUFF_DEBUFF_KEYBOARD_STYLE, ZO_BUFF_DEBUFF_GAMEPAD_STYLE)
end

function ZO_BuffDebuff_ContainerObject:CreateMetaPool(container, buffControlPool)
    local metaPool = ZO_MetaPool:New(buffControlPool)
    metaPool.container = container

    local function OnAcquired(control)
        control:ClearAnchors()

        if control.platformStyle ~= self.currentPlatformStyle then
            control.platformStyle = self.currentPlatformStyle
            ApplyTemplateToControl(control, ZO_GetPlatformTemplate("ZO_BuffDebuffIcon"))
        end

        if not metaPool.firstControl then
            metaPool.firstControl = control
            control:SetAnchor(LEFT, container)
        else
            control:SetAnchor(LEFT, metaPool.lastControl, RIGHT, BUFF_PADDING, 0)
        end

        metaPool.lastControl = control

        control:SetParent(container)
    end

    local function OnReset(control)
        control.blinkAnimation:Stop()

        control.cooldown:ResetCooldown()
        control.cooldown:SetHidden(true)
    end

    metaPool:SetCustomAcquireBehavior(OnAcquired)
    metaPool:SetCustomResetBehavior(OnReset)

    return metaPool
end

function ZO_BuffDebuff_ContainerObject_ResetPool(pool)
    pool:ReleaseAllObjects()
    pool.firstControl = nil
end

function ZO_BuffDebuff_ContainerObject:Update()
    local buffPool = self.buffPool
    local debuffPool = self.debuffPool

    -- TODO: Investigate a more performant solution if necessary
    ZO_BuffDebuff_ContainerObject_ResetPool(buffPool)
    ZO_BuffDebuff_ContainerObject_ResetPool(debuffPool)

    self:UpdateContextualFading()

    self.styleObject:UpdateContainer(self)

    buffPool.container:SetHidden(buffPool:GetActiveObjectCount() == 0)
    debuffPool.container:SetHidden(debuffPool:GetActiveObjectCount() == 0)
    self.isDirty = false
end

function ZO_BuffDebuff_ContainerObject:UpdateContextualFading()
    local shouldContextuallyShow = self:ShouldContextuallyShow()
    if shouldContextuallyShow ~= self.isContextuallyShown then
        if shouldContextuallyShow then
            self.fadeTimeline:PlayForward()
        else
            self.fadeTimeline:PlayBackward()
        end
        self.isContextuallyShown = shouldContextuallyShow
    end
end

function ZO_BuffDebuff_ContainerObject:UpdateTime()
    self.styleObject:UpdateDurations(self)
end

function ZO_BuffDebuff_ContainerObject:ApplyPlatformStyle(style)
    self.currentPlatformStyle = style
    self.control:SetHeight(style.CONTAINER_HEIGHT)
    self.isDirty = true
end

function ZO_BuffDebuff_ContainerObject:SetStyleObject(styleObject, shouldBlockUpdate)
    if self.styleObject ~= styleObject then
        self.styleObject = styleObject
        local template = styleObject:GetTemplate()
        ApplyTemplateToControl(self.control, template)

        if not shouldBlockUpdate then
            self.isDirty = true
        end
    end
end

function ZO_BuffDebuff_ContainerObject:UpdateVisibilitySettings(settingId, settingValue)
    if self.settings[settingId] ~= settingValue then
        self.settings[settingId] = settingValue
        self.isDirty = true
    end
end

function ZO_BuffDebuff_ContainerObject:GetVisibilitySetting(settingId)
    if self:ShouldContextuallyShow() then
        return self.settings[settingId]
    else
        return false
    end
end

function ZO_BuffDebuff_ContainerObject:ShouldContextuallyShow()
    if self.settings[BUFFS_SETTING_ALL_ENABLED] == BUFF_DEBUFF_ENABLED_CHOICE_AUTOMATIC then
        if self.fadeTimeline:IsPlaying() then
            return true
        else
            return IsUnitInCombat(self.unitTag)
        end
    else
        return self.settings[BUFFS_SETTING_ALL_ENABLED] ~= BUFF_DEBUFF_ENABLED_CHOICE_DONT_SHOW
    end
end

function ZO_BuffDebuff_ContainerObject:GetControl()
    return self.control
end

function ZO_BuffDebuff_ContainerObject:GetUnitTag()
    return self.unitTag
end

function ZO_BuffDebuff_ContainerObject:GetPools()
    return self.buffPool, self.debuffPool
end

-------------------
--Top Level Class--
-------------------

ZO_BuffDebuff = ZO_Object:Subclass()

function ZO_BuffDebuff:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function ZO_BuffDebuff:Initialize(control)
    self.control = control
    self.controlPool = ZO_ControlPool:New("ZO_BuffDebuffIcon", nil, "Buff")

    local selfContainer = ZO_BuffDebuff_ContainerObject:New(control:GetNamedChild("SelfContainer"), self.controlPool, PLAYER_UNIT_TAG, EVENT_PLAYER_ACTIVATED)
    local targetContainer = ZO_BuffDebuff_ContainerObject:New(control:GetNamedChild("TargetContainer"), self.controlPool, TARGET_UNIT_TAG, EVENT_RETICLE_TARGET_CHANGED)

    self.containerObjectsByUnitTag =
    {
        [PLAYER_UNIT_TAG] = selfContainer,
        [TARGET_UNIT_TAG] = targetContainer,
    }

    local BLOCK_UPDATE = true
    self:SetStyle(ZO_BUFF_DEBUFF_EXPIRES_IN_STYLE, BLOCK_UPDATE)

    self:RegisterForEvents()

    BUFF_DEBUFF_FRAGMENT = ZO_HUDFadeSceneFragment:New(control)
end

local function GetBuffSettingValue(settingId)
    if settingId == BUFFS_SETTING_ALL_ENABLED then
        return tonumber(GetSetting(SETTING_TYPE_BUFFS, settingId))
    else
        return GetSetting_Bool(SETTING_TYPE_BUFFS, settingId)
    end
end

function ZO_BuffDebuff:RegisterForEvents()
    local function OnInterfaceSettingChanged(settingId)
        local settingValue = GetBuffSettingValue(settingId)
        if settingId == BUFFS_SETTING_ALL_ENABLED or settingId == BUFFS_SETTING_BUFFS_ENABLED or settingId == BUFFS_SETTING_DEBUFFS_ENABLED
            or settingId == BUFFS_SETTING_LONG_EFFECTS or settingId == BUFFS_SETTING_PERMANENT_EFFECTS or settingId == BUFFS_SETTING_DEBUFFS_ENABLED_FOR_TARGET_FROM_OTHERS then
            for _, container in pairs(self.containerObjectsByUnitTag) do
                container:UpdateVisibilitySettings(settingId, settingValue)
            end
        else
            local parentSettingId
            local relevantContainer
            if settingId == BUFFS_SETTING_BUFFS_ENABLED_FOR_SELF or settingId == BUFFS_SETTING_DEBUFFS_ENABLED_FOR_SELF then
                parentSettingId = (settingId == BUFFS_SETTING_BUFFS_ENABLED_FOR_SELF) and BUFFS_SETTING_BUFFS_ENABLED or BUFFS_SETTING_DEBUFFS_ENABLED
                relevantContainer = self.containerObjectsByUnitTag[PLAYER_UNIT_TAG]
            else
                parentSettingId = (settingId == BUFFS_SETTING_BUFFS_ENABLED_FOR_TARGET) and BUFFS_SETTING_BUFFS_ENABLED or BUFFS_SETTING_DEBUFFS_ENABLED
                relevantContainer = self.containerObjectsByUnitTag[TARGET_UNIT_TAG]
            end
            settingValue = settingValue and GetBuffSettingValue(parentSettingId) or false
            relevantContainer:UpdateVisibilitySettings(parentSettingId, settingValue)
        end
    end

    local function OnAddOnLoaded(event, name)
        if name == "ZO_Ingame" then
            for i = BUFFS_SETTING_ITERATION_BEGIN, BUFFS_SETTING_ITERATION_END do
                OnInterfaceSettingChanged(i)
            end
            self.control:UnregisterForEvent(EVENT_ADD_ON_LOADED)
        end
    end

    local function OnTargetFrameCreated(targetFrame)
        local targetFrameControl = targetFrame:GetPrimaryControl()

        local targetContainerControl = self.containerObjectsByUnitTag[TARGET_UNIT_TAG]:GetControl()
        targetContainerControl:SetAnchor(CENTER, targetFrameControl:GetNamedChild("Caption"), BOTTOM, 0, 40)
        targetContainerControl:SetParent(targetFrameControl)
    end

    self.control:RegisterForEvent(EVENT_INTERFACE_SETTING_CHANGED, function(_, _, settingId) OnInterfaceSettingChanged(settingId) end)
    self.control:AddFilterForEvent(EVENT_INTERFACE_SETTING_CHANGED, REGISTER_FILTER_SETTING_SYSTEM_TYPE, SETTING_TYPE_BUFFS)
    self.control:RegisterForEvent(EVENT_ADD_ON_LOADED, OnAddOnLoaded)
    CALLBACK_MANAGER:RegisterCallback("TargetFrameCreated", OnTargetFrameCreated)
end

function ZO_BuffDebuff:GetBuffControlPool()
    return self.controlPool
end

function ZO_BuffDebuff:SetStyle(styleObject, shouldBlockUpdate)
    if self.styleObject ~= styleObject then
        self.styleObject = styleObject
        for _, container in pairs(self.containerObjectsByUnitTag) do
            container:SetStyleObject(styleObject, shouldBlockUpdate)
        end
    end
end

function ZO_BuffDebuff:AddContainerObject(unitTag, containerObject)
    self.containerObjectsByUnitTag[unitTag] = containerObject
end

-- XML Handlers

function ZO_BuffDebuff_OnInitialized(control)
    BUFF_DEBUFF = ZO_BuffDebuff:New(control)
end

function ZO_BuffDebuffIcon_OnInitialized(control)
    control.duration = control:GetNamedChild("Duration")

    local blinkAnimation = GetAnimationManager():CreateTimelineFromVirtual("ZO_BuffDebuffIcon_BlinkAnimation")
    blinkAnimation:GetAnimation(1):SetAnimatedControl(control)
    blinkAnimation:GetAnimation(2):SetAnimatedControl(control)
    local function OnBlinkAnimationStop()
        control:SetAlpha(1)
    end
    blinkAnimation:SetHandler("OnStop", OnBlinkAnimationStop)
    control.blinkAnimation = blinkAnimation

    control.cooldown = control:GetNamedChild("Cooldown")
    control.showCooldown = false
end

function ZO_BuffDebuffIcon_OnMouseEnter(control)
    InitializeTooltip(InformationTooltip, control, BOTTOM)
    local formattedName = zo_strformat(SI_ABILITY_TOOLTIP_NAME, control.data.buffName)
    InformationTooltip:AddLine(formattedName)
end

function ZO_BuffDebuffIcon_OnMouseExit(control)
    ClearTooltip(InformationTooltip)
end