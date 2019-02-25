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
    [INSTANCE_DISPLAY_TYPE_PUBLIC_DUNGEON] = "EsoUI/Art/loadingTips/loadingTip_dungeon.dds",
    [INSTANCE_DISPLAY_TYPE_DELVE] = "EsoUI/Art/loadingTips/loadingTip_delve.dds",
    [INSTANCE_DISPLAY_TYPE_HOUSING] = "EsoUI/Art/Icons/mapKey/mapKey_housing.dds",
    [INSTANCE_DISPLAY_TYPE_ZONE_STORY] = "EsoUI/Art/Icons/mapKey/mapKey_zoneStory.dds",
}

function GetInstanceDisplayTypeIcon(instanceDisplayType)
    return INSTANCE_DISPLAY_TYPE_ICONS[instanceDisplayType]
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

function LoadingScreen_Base:Log(text)
    local gamepadMode = IsInGamepadPreferredMode()
    if gamepadMode and self == GamepadLoadingScreen or
    not gamepadMode and self == LoadingScreen then         
        WriteToInterfaceLog(text)
    end
end

function LoadingScreen_Base:Initialize()
    self.seenZones = {}
    self.currentRotation = 0
    self.lastUpdate = GetFrameTimeMilliseconds()
    self.animations = nil

    local zoneInfoContainer = self:GetNamedChild("ZoneInfoContainer")

    self.bgTexture = self:GetNamedChild("Bg")
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
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_JUMP_FAILED, function(...) self:OnJumpFailed(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_DISCONNECTED_FROM_SERVER, function(...) self:OnDisconnectedFromServer(...) end)
    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_RESUME_FROM_SUSPEND, function(...) self:OnResumeFromSuspend(...) end)

    local function OnSubsystemLoadComplete(eventCode, system)
        self:Log(string.format("Load Screen - %s Complete", GetLoadingSystemName(system)))
        if GetNumTotalSubsystemsToLoad() == GetNumLoadedSubsystems() then
            if not IsWaitingForTeleport() then
                --If the last systems we were waiting on all finish in the same frame we could call Hide several times
                self:Log("Load Screen - Systems Loaded And Not Waiting For Teleport")
                self:Hide()
            else
                self:Log("Load Screen - Systems Loaded But Waiting For Teleport")
            end
        else
            local remainingText = "Load Screen - Waiting On: "
            for i = 1, GetNumTotalSubsystemsToLoad() do
                if not IsSystemLoaded(i) then
                    remainingText = remainingText .. GetLoadingSystemName(i) .. ", "
                end
            end
            self:Log(remainingText)
        end
    end

    EVENT_MANAGER:RegisterForEvent(self:GetSystemName(), EVENT_SUBSYSTEM_LOAD_COMPLETE, OnSubsystemLoadComplete)

    self:SizeLoadingTexture()
    self:InitializeAnimations()
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

function LoadingScreen_Base:OnAreaLoadStarted(evt, worldId, instanceNum, zoneName, zoneDescription, loadingTexture, instanceDisplayType)
    self:Log(string.format("Load Screen - OnAreaLoadStarted - (%d) %s", worldId, zoneName == "" and "Unknown Zone" or zoneName))
    self:UpdateBattlegroundId(instanceDisplayType)
    self:Show(zoneName, zoneDescription, loadingTexture, instanceDisplayType)
end

function LoadingScreen_Base:OnPrepareForJump(evt, zoneName, zoneDescription, loadingTexture, instanceDisplayType)
    self:Log(string.format("Load Screen - OnPrepareForJump - %s", zoneName == "" and "Unknown Zone" or zoneName))
    self:UpdateBattlegroundId(instanceDisplayType)
    self:Show(zoneName, zoneDescription, loadingTexture, instanceDisplayType)
end

function LoadingScreen_Base:OnJumpFailed()
    self:Log("Load Screen - OnJumpFailed")
    self:Hide()
end

function LoadingScreen_Base:OnDisconnectedFromServer()
    self:Log("Load Screen - OnDisconnectedFromServer")
    self:Hide()

    --Hack to run to code that would execute on the hide animation complete immediately
    self.animations.control:SetHidden(true)
    SetGuiHidden("app", true)
    RemoveActionLayerByNameApp("LoadingScreen")
end

function LoadingScreen_Base:OnResumeFromSuspend(evt)
    self:Log("Load Screen - OnResumeFromSuspend")
    self:Show("", "", "", INSTANCE_DISPLAY_TYPE_NONE)
end

local BATTLEGROUND_TEAM_TEXTURES =
{
    [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/battlegrounds_teamIcon_orange.dds",
    [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/battlegrounds_teamIcon_purple.dds",
    [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/battlegrounds_teamIcon_green.dds",
}

local GAMEPAD_BATTLEGROUND_TEAM_TEXTURES =
{
    [BATTLEGROUND_ALLIANCE_FIRE_DRAKES] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_teamIcon_orange.dds",
    [BATTLEGROUND_ALLIANCE_STORM_LORDS] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_teamIcon_purple.dds",
    [BATTLEGROUND_ALLIANCE_PIT_DAEMONS] = "EsoUI/Art/Battlegrounds/Gamepad/gp_battlegrounds_teamIcon_green.dds",
}

function LoadingScreen_Base:Show(zoneName, zoneDescription, loadingTexture, instanceDisplayType)
    if self:IsPreferredScreen() then
        self:Log("Load Screen - Show")
        self.lastUpdate = GetFrameTimeMilliseconds()

        local wasAppGuiHidden = GetGuiHidden("app")

        --First configure the visuals
        self:SizeLoadingTexture()

        local isDefaultTexture = "" == loadingTexture
        if isDefaultTexture then
            if not self.randomLoadingTexture then
                self.randomLoadingTexture = GetRandomLoadingScreenTexture()
            end
            loadingTexture = self.randomLoadingTexture
        end

        self.art:SetTexture(loadingTexture)

        self.zoneName:SetHidden(isDefaultTexture)
        self.zoneDescription:SetHidden(isDefaultTexture)
        if self.descriptionBg then
            self.descriptionBg:SetHidden(isDefaultTexture)
        end

        local showInstanceDisplayType = instanceDisplayType ~= INSTANCE_DISPLAY_TYPE_NONE and instanceDisplayType ~= INSTANCE_DISPLAY_TYPE_BATTLEGROUND
        self.instanceTypeIcon:SetHidden(not showInstanceDisplayType)
        self.instanceType:SetHidden(not showInstanceDisplayType)

        if not isDefaultTexture then
            if self.battlegroundId ~= 0 then
                local gameType = GetBattlegroundGameType(self.battlegroundId)
                local gameTypeString = GetString("SI_BATTLEGROUNDGAMETYPE", gameType)
                local battlegroundDescription = GetBattlegroundDescription(self.battlegroundId)

                self.zoneName:SetText(LocalizeString("<<C:1>>", gameTypeString))
                self:SetZoneDescription(LocalizeString("<<1>>", battlegroundDescription))

                local activityAlliance = GetLatestActivityAlliance()
                if activityAlliance ~= BATTLEGROUND_ALLIANCE_NONE then
                    local r, g, b, a = GetInterfaceColor(INTERFACE_COLOR_TYPE_BATTLEGROUND_ALLIANCE, activityAlliance)
                    local battlegroundTeamName = ZO_ColorizeString(r, g, b, GetString("SI_BATTLEGROUNDALLIANCE", activityAlliance))

                    local teamIcon
                    if IsInGamepadPreferredMode() then
                        teamIcon = GAMEPAD_BATTLEGROUND_TEAM_TEXTURES[activityAlliance]
                    else
                        teamIcon = BATTLEGROUND_TEAM_TEXTURES[activityAlliance]
                    end

                    self.instanceType:SetText(LocalizeString("<<1>>", battlegroundTeamName))
                    self.instanceType:SetHidden(false)
                    self.instanceTypeIcon:SetTexture(teamIcon)
                    self.instanceTypeIcon:SetHidden(false)
                end
            else
                if showInstanceDisplayType then
                    self.instanceTypeIcon:SetTexture(GetInstanceDisplayTypeIcon(instanceDisplayType))
                    self.instanceType:SetText(GetString("SI_INSTANCEDISPLAYTYPE", instanceDisplayType))
                end

                self.zoneName:SetText(LocalizeString("<<C:1>>", zoneName))

                --Only do this random roll once when the load screen is first brought up, not everytime the info changes
                if wasAppGuiHidden then
                    self.preferTipOverZoneDescriptionIfZoneHasBeenSeen = math.random() <= LOADING_TIP_PERCENTAGE
                end

                --Only update this on a new zone
                if self.lastZoneName ~= zoneName then
                    local showTipInsteadOfZoneDescription
                    if self.seenZones[zoneName] then
                        showTipInsteadOfZoneDescription = self.preferTipOverZoneDescriptionIfZoneHasBeenSeen
                    else
                        showTipInsteadOfZoneDescription = false
                    end
                    self.lastZoneName = zoneName
                    self.seenZones[zoneName] = true

                    if showTipInsteadOfZoneDescription then
                        if not self.tip then
                            self.tip = GetLoadingTip()
                        end

                        if self.tip ~= "" then
                            self:SetZoneDescription(self.tip)
                        else
                            self:SetZoneDescription(LocalizeString("<<1>>", zoneDescription))
                        end
                    else
                        self:SetZoneDescription(LocalizeString("<<1>>", zoneDescription))
                    end
                end
            end
        end

        --Then if we are presently hiding the UI then stop that and reset it to the start. This will trigger the actions on the
        --animation finishing causing it to hide the load screen and remove the keybinds so this needs to be done before we show
        --the load screen and add the keybinds
        if self.animations:IsPlaying() then
            self.animations:PlayInstantlyToStart()
        end

        --Here we begin showing the load screen.

        --First show the whole GUI, this needs to be done immediately to show anything
        SetGuiHidden("app", false)
        --also show the loadscreen top level
        self:SetHidden(false)
        --also show the solid black texture that blocks out the world
        self.bgTexture:SetHidden(false)
        --also add the keybinds
        if not IsActionLayerActiveByNameApp("LoadingScreen") then
            PushActionLayerByNameApp("LoadingScreen")
        end
        --also fade in the spinner
        self.spinnerFadeAnimation:PlayForward()

        --For the main animation that brings in the art (as well as some other things) we are waiting until the texture is loaded in memory. This
        --is checked continuously in update
        self.loadScreenTextureLoaded = false
    end
end

function LoadingScreen_Base:Hide()
    self:Log("Load Screen - Hide")

    --if it is hidden or already hiding then return
    if self:IsHidden() or
        (self.animations:IsPlaying() and self.animations:IsPlayingBackward()) or
        (self.spinnerFadeAnimation:IsPlaying() and self.spinnerFadeAnimation:IsPlayingBackward()) then
            return
    end

    self:Log("Load Screen - Hide - Wasn't Already Hiding")

    --Hide the black BG on the start of hiding so the load screen fades with the world
    self.bgTexture:SetHidden(true)
    self.animations:PlayBackward()
    self.spinnerFadeAnimation:PlayBackward()
    
    self:ClearBattlegroundId()

    --State for controlling the description or loading tip decision
    self.preferTipOverZoneDescriptionIfZoneHasBeenSeen = nil
    self.tip = nil
    self.lastZoneName = nil

    --State for controlling the load screen texture when it isn't set by a def
    self.randomLoadingTexture = nil
end

function LoadingScreen_Base:Update()
    -- hold on other animations till background art is fully loaded
    if not self.loadScreenTextureLoaded and self.art:IsTextureLoaded() then
        self.loadScreenTextureLoaded = true
        self.animations:PlayForward()
    end

    if self.lastUpdate then
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

function LoadingScreen_Base:UpdateBattlegroundId(instanceDisplayType)
    if instanceDisplayType == INSTANCE_DISPLAY_TYPE_BATTLEGROUND then
        self.battlegroundId = GetActivityBattlegroundId(GetCurrentLFGActivityId())
    else
        self:ClearBattlegroundId()
    end
end

function LoadingScreen_Base:ClearBattlegroundId()
    self.battlegroundId = 0
end

function LoadingScreen_Base:LoadingCompleteAnimation_OnStop(timeline)
    --We finally get rid of the load screen entirely when it is animated out
    self:Log("Load Screen - Show/Hide - Animation Complete")
    if timeline:IsPlayingBackward() then
        self:Log("Load Screen - Hide - Animation Complete")
        timeline.control:SetHidden(true)
        SetGuiHidden("app", true)
        RemoveActionLayerByNameApp("LoadingScreen")
    end
end