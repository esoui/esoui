local TEXTURE_WIDTH = 1680
local TEXTURE_HEIGHT = 1050
local TEXTURE_ASPECT_RATIO = TEXTURE_WIDTH / TEXTURE_HEIGHT
local LOADING_TIP_PERCENTAGE = 0.8
local TARGET_FRAMERATE = 60
local MAX_FRAMES_PER_UPDATE = 5
local MAX_ROTATION = math.pi * 2
local ROTATION_PER_FRAME = -math.pi * .02
local MINIMUM_TIME_TO_HOLD_LOADING_TIP_MS = 15000

-- Instance type icons 
------------------------------

local INSTANCE_DISPLAY_TYPE_ICONS =
{
    [INSTANCE_DISPLAY_TYPE_SOLO] = "EsoUI/Art/loadingTips/loadingTip_soloInstance.dds",
    [INSTANCE_DISPLAY_TYPE_DUNGEON] = "EsoUI/Art/loadingTips/loadingTip_groupInstance.dds",
    [INSTANCE_DISPLAY_TYPE_RAID] = "EsoUI/Art/loadingTips/loadingTip_raidDungeon.dds",
    [INSTANCE_DISPLAY_TYPE_GROUP_DELVE] = "EsoUI/Art/loadingTips/loadingTip_groupDelve.dds",
    [INSTANCE_DISPLAY_TYPE_GROUP_AREA] = "EsoUI/Art/Icons/mapKey/mapKey_groupArea.dds",
    [INSTANCE_DISPLAY_TYPE_PUBLIC_DUNGEON] = "EsoUI/Art/Icons/mapKey/mapKey_publicDungeon.dds",
    [INSTANCE_DISPLAY_TYPE_DELVE] = "EsoUI/Art/Icons/mapKey/mapKey_delve.dds",
    [INSTANCE_DISPLAY_TYPE_HOUSING] = "EsoUI/Art/Icons/mapKey/mapKey_housing.dds",
}

function GetInstanceDisplayTypeIcon(instanceType)
    return INSTANCE_DISPLAY_TYPE_ICONS[instanceType]
end

--Local implementation of object pool for key edge file
------------------------------

local g_keyEdgefileFreeList = {}
local g_keyEdgefileActiveList = {}

local function GetOrCreateKeyEdgefile()
    local keyEdgeFile = next(g_keyEdgefileFreeList) or GetWindowManager():CreateControlFromVirtual("", LoadingScreenZoneDescription, "ZO_LoadingScreen_KeyBackdrop")

    g_keyEdgefileFreeList[keyEdgeFile] = nil
    g_keyEdgefileActiveList[keyEdgeFile] = true

    return keyEdgeFile
end

local function ReleaseAllKeyEdgeFiles()
    for keyEdgeFile in pairs(g_keyEdgefileActiveList) do
        g_keyEdgefileActiveList[keyEdgeFile] = nil
        g_keyEdgefileFreeList[keyEdgeFile] = true
        keyEdgeFile:SetHidden(true)
    end
end

--Loading Screen Object
-- Note: Must provide an InitializeAnimations function in derived classes
------------------------------

LoadingScreen_Base = {}

function LoadingScreen_Base:Initialize()
    self.seenZones = {}
    self.currentRotation = 0
    self.lastUpdate = GetFrameTimeMilliseconds()
    self.timeShowingTipMS = 0
    self.pendingLoadingTips = {}
    self.hasShownFirstTip = false
    self.animations = nil

    local zoneInfoContainer = self:GetNamedChild("ZoneInfoContainer")

    self.art = self:GetNamedChild("Art")
    self.zoneName = zoneInfoContainer:GetNamedChild("ZoneName")
    self.zoneDescription = self:GetNamedChild("ZoneDescription")
    self.descriptionBg = self:GetNamedChild("DescriptionBg")
    self.instanceTypeIcon = zoneInfoContainer:GetNamedChild("InstanceTypeIcon")
    self.instanceType = zoneInfoContainer:GetNamedChild("InstanceType")
    self.spinner = self:GetNamedChild("Spinner") 

    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_AREA_LOAD_STARTED, function(...) self:OnAreaLoadStarted(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_SCREEN_RESIZED, function(...) self:SizeLoadingTexture(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_PREPARE_FOR_JUMP, function(...) self:OnPrepareForJump(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_JUMP_FAILED, function(...) self:HideLoadingScreen(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_DISCONNECTED_FROM_SERVER, function(...) self:HideLoadingScreen(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_RESUME_FROM_SUSPEND, function(...) self:OnResumeFromSuspend(...) end)

    local function OnSubsystemLoadComplete(eventCode, system)
        if LoadingScreen_Base_CanHide() then
            self:Hide()
        end
    end

    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_SUBSYSTEM_LOAD_COMPLETE, OnSubsystemLoadComplete)

    self:SizeLoadingTexture()
    self:InitializeAnimations()
end

function LoadingScreen_Base_CanHide()
    return GetNumTotalSubsystemsToLoad() == GetNumLoadedSubsystems() and not IsWaitingForTeleport()
end

function LoadingScreen_Base:SizeLoadingTexture()
    local screenWidth, screenHeight = GuiRoot:GetDimensions()
    local screenAspectRatio = screenWidth / screenHeight

    if TEXTURE_ASPECT_RATIO > screenAspectRatio then
        local scale = screenHeight / TEXTURE_HEIGHT 
        self.art:SetDimensions(TEXTURE_WIDTH * scale, screenHeight)
    else
        local scale = screenWidth / TEXTURE_WIDTH
        self.art:SetDimensions(screenWidth, TEXTURE_HEIGHT * scale)
    end
end

function LoadingScreen_Base:OnAreaLoadStarted(evt, area, instance, zoneName, zoneDescription, loadingTexture, instanceType)
    self:QueueShow(zoneName, zoneDescription, loadingTexture, instanceType)
end

function LoadingScreen_Base:OnPrepareForJump(evt, zoneName, zoneDescription, loadingTexture, instanceType)
    self:QueueShow(zoneName, zoneDescription, loadingTexture, instanceType)
end

function LoadingScreen_Base:HideLoadingScreen()
    self:Hide()
end

function LoadingScreen_Base:OnResumeFromSuspend(evt)
    self:QueueShow("", "", "", 0)
end

function LoadingScreen_Base:QueueShow(...)
    if self:IsPreferredScreen() then
        if not self.hasShownFirstTip then
            self.hasShownFirstTip = true
            self.lastUpdate = GetFrameTimeMilliseconds()
            self:Show(...)
        else
            table.insert(self.pendingLoadingTips, {...})
        end
    end
end

function LoadingScreen_Base:Show(zoneName, zoneDescription, loadingTexture, instanceType)
    self.timeShowingTipMS = 0
    self.loadScreenTextureLoaded = false
    self:SizeLoadingTexture()

    local isDefaultTexture = "" == loadingTexture

    if(isDefaultTexture) then
        loadingTexture = GetRandomLoadingScreenTexture()
    end

    self.art:SetTexture(loadingTexture)

    self.zoneName:SetHidden(isDefaultTexture)
    self.zoneDescription:SetHidden(isDefaultTexture)
    if self.descriptionBg then
        self.descriptionBg:SetHidden(isDefaultTexture)
    end

    local showInstanceType = instanceType ~= INSTANCE_DISPLAY_TYPE_NONE
    self.instanceTypeIcon:SetHidden(not showInstanceType)
    self.instanceType:SetHidden(not showInstanceType)

    if not isDefaultTexture then
		if(showInstanceType) then
			self.instanceTypeIcon:SetTexture(GetInstanceDisplayTypeIcon(instanceType))
			self.instanceType:SetText(GetString("SI_INSTANCEDISPLAYTYPE", instanceType))
		end
		self.zoneName:SetText(LocalizeString("<<C:1>>", zoneName))

        if self.seenZones[zoneName] and math.random() <= LOADING_TIP_PERCENTAGE then
            local tip = GetLoadingTip()
            if(tip ~= "") then
                self:SetZoneDescription(tip)
            else
                self:SetZoneDescription(LocalizeString("<<1>>", zoneDescription))
            end
        else
            self:SetZoneDescription(LocalizeString("<<1>>", zoneDescription))
        end

        self.seenZones[zoneName] = true
    end

    SetGuiHidden("app", false)
    self:SetHidden(false)

    --fade in the spinner on first showing the screen
    if(self.spinnerFadeAnimation) then
        self.spinnerFadeAnimation:PlayForward()
    end
end

function LoadingScreen_Base:Hide()
    if(self.animations) then
        self.animations:PlayBackward()
    end

    if(self.spinnerFadeAnimation) then
        self.spinnerFadeAnimation:PlayBackward()
    end

    if #self.pendingLoadingTips > 0 then
        -- App doesn't load libraries, so we don't have ZO_ClearTable, and it seems like a huge waste to bring it all over for this one call
        for index in pairs(self.pendingLoadingTips) do
            self.pendingLoadingTips[index] = nil
        end
    end
    self.hasShownFirstTip = false
end

function LoadingScreen_Base:UpdateLoadingTip(delta)
    self.timeShowingTipMS = self.timeShowingTipMS + delta
    if #self.pendingLoadingTips > 0 and self.timeShowingTipMS > MINIMUM_TIME_TO_HOLD_LOADING_TIP_MS then
        local oldestPendingTip = table.remove(self.pendingLoadingTips, 1)
        self:Show(unpack(oldestPendingTip))
    end
end

function LoadingScreen_Base:Update()
    if(self.lastUpdate) then
        local now = GetFrameTimeMilliseconds()
        local delta = now - self.lastUpdate

        local numFramesToIncrease = delta / TARGET_FRAMERATE
        if numFramesToIncrease == 0 then
            return
        elseif numFramesToIncrease > MAX_FRAMES_PER_UPDATE then
            numFramesToIncrease = MAX_FRAMES_PER_UPDATE
        end
        self.lastUpdate = now

        self.currentRotation = (self.currentRotation + numFramesToIncrease * ROTATION_PER_FRAME) % MAX_ROTATION

        self.spinner:SetTextureRotation(self.currentRotation)

        self:UpdateLoadingTip(delta)
    end

    -- hold on other animations till background art is fully loaded
    if(not self.loadScreenTextureLoaded and self.art:IsTextureLoaded()) then
        self.loadScreenTextureLoaded = true

        if(self.animations) then
            self.animations:PlayForward()
        end
    end
end

function LoadingScreen_Base:OnZoneDescriptionNewUserAreaCreated(control, areaData, areaText, left, right, top, bottom)
    if areaData == "key" then
        local keyEdgeFile = GetOrCreateKeyEdgefile()
        keyEdgeFile:SetAnchor(TOPLEFT, control, TOPLEFT, left + 2, top - 1)
        keyEdgeFile:SetAnchor(BOTTOMRIGHT, control, TOPLEFT, right - 2, bottom + 1)
        keyEdgeFile:SetHidden(false)
    end
end

function LoadingScreen_Base:SetZoneDescription(tip)
    self.zoneDescription:SetText(tip)
    ReleaseAllKeyEdgeFiles()
end