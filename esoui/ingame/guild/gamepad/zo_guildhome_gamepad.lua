GAMEPAD_GUILD_HOME_SCENE_NAME = "gamepad_guild_home"

local ZO_GamepadGuildHome = ZO_Gamepad_ParametricList_Screen:Subclass()

function ZO_GamepadGuildHome:New(...)
    return ZO_Gamepad_ParametricList_Screen.New(self, ...)
end

function ZO_GamepadGuildHome:Initialize(control)
    ZO_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    self.headerData = {}

    GAMEPAD_GUILD_HOME_SCENE = ZO_Scene:New(GAMEPAD_GUILD_HOME_SCENE_NAME, SCENE_MANAGER)
    GAMEPAD_GUILD_HOME_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitializationHome()
            self:PerformUpdate()
            if self.activeScreenCallback then
                self.activeScreenCallback()
            end
            ZO_GamepadGenericHeader_Activate(self.header)
            
            self.control:RegisterForEvent(EVENT_GUILD_DATA_LOADED, function() self:Update() end)
            self.control:RegisterForEvent(EVENT_GUILD_MEMBER_REMOVED, function(_, guildId, displayName) if(self:IsCurrentGuildId(guildId)) then self:Update() end end)
            self.control:RegisterForEvent(EVENT_GUILD_MEMBER_ADDED, function(_, guildId, displayName) if(self:IsCurrentGuildId(guildId)) then self:Update() end end)
            self.control:RegisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED, function(_, guildId, displayName, rankIndex) if(self:IsCurrentGuildId(guildId)) then self:Update() end end)
            self.control:RegisterForEvent(EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED, function(_, guildId, displayName, oldStatus, newStatus) if(self:IsCurrentGuildId(guildId)) then self:Update() end end)

        elseif newState == SCENE_HIDDEN then
            ZO_GamepadGenericHeader_Deactivate(self.header)

            self:RemoveCurrentPage()
            
            self.control:UnregisterForEvent(EVENT_GUILD_DATA_LOADED)
            self.control:UnregisterForEvent(EVENT_GUILD_MEMBER_REMOVED)
            self.control:UnregisterForEvent(EVENT_GUILD_MEMBER_ADDED)
            self.control:UnregisterForEvent(EVENT_GUILD_MEMBER_RANK_CHANGED)
            self.control:UnregisterForEvent(EVENT_GUILD_MEMBER_PLAYER_STATUS_CHANGED)
        end
        
        ZO_Gamepad_ParametricList_Screen.OnStateChanged(self, oldState, newState)
    end)
end

function ZO_GamepadGuildHome:PerformDeferredInitializationHome()
    if self.deferredInitialized then return end
    self.deferredInitialized = true
    
    self.itemList = self:GetMainList()
    self.optionsList = self:AddList("Options", SetupOptionsList)

    self:InitializeHeader()
    self:InitializeFooter()
end

function ZO_GamepadGuildHome:PerformUpdate()
    self:RefreshHeader()
    self:RefreshFooter()
    self:ValidateGuildId() 
end

function ZO_GamepadGuildHome:SetActivateScreenInfo(callback, title)
    self.activeScreenCallback = callback
    self.headerData.titleText = title
end

function ZO_GamepadGuildHome:SetGuildId(guildId)
    self.guildId = guildId
end

function ZO_GamepadGuildHome:IsCurrentGuildId(guildId)
    return self.guildId == guildId
end

function ZO_GamepadGuildHome:ValidateGuildId()
    if(not ZO_ValidatePlayerGuildId(self.guildId)) then
        self.guildId = nil
        SCENE_MANAGER:Hide(GAMEPAD_GUILD_HOME_SCENE_NAME)
    end
end

------------
-- Header --
------------

function ZO_GamepadGuildHome:ShouldShowEditRankHeaderTitle()
    return self.currentFragment == GUILD_RANKS_GAMEPAD_FRAGMENT and GUILD_RANKS_GAMEPAD:IsEditingRank()
end

function ZO_GamepadGuildHome:InitializeHeader()
    local rightPane = self.control:GetNamedChild("RightPane")
    local contentContainer = rightPane:GetNamedChild("ContentHeader")
    self.contentHeader = contentContainer:GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.contentHeader, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE, ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_TOGETHER)

    self.contentHeaderData = {}
end

function ZO_GamepadGuildHome:RefreshHeader(blockTabBarCallbacks)
    -- content header
    local contentHeaderData = self.contentHeaderData
    contentHeaderData.titleText = GetGuildName(self.guildId)

    contentHeaderData.data1HeaderText = nil
    contentHeaderData.data1Text = nil
    if(self.currentFragment == GUILD_HERALDRY_GAMEPAD_FRAGMENT) then
        contentHeaderData.data1HeaderText, contentHeaderData.data1Text = GUILD_HERALDRY_GAMEPAD:GetPurchaseCost()
    end

    ZO_GamepadGenericHeader_Refresh(self.contentHeader, contentHeaderData)

    -- list header
    self.headerData.messageText = nil;
    if(self.currentFragment == GUILD_RANKS_GAMEPAD_FRAGMENT) then
        self.headerData.messageText = GUILD_RANKS_GAMEPAD:GetMessageText()
    end

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData, blockTabBarCallbacks)

    --Roster
    local rosterHeaderData = GUILD_ROSTER_GAMEPAD:GetContentHeaderData()
    rosterHeaderData.data1Text = contentHeaderData.titleText
    rosterHeaderData.data2Text = ZO_FormatUserFacingDisplayName(select(3, GetGuildInfo(self.guildId)))
    ZO_GamepadGenericHeader_Refresh(GUILD_ROSTER_GAMEPAD.contentHeader, rosterHeaderData)
end

function ZO_GamepadGuildHome:InitializeFooter()
    self.footerData = {
        data1HeaderText = GetString(SI_GAMEPAD_GUILD_HEADER_MEMBERS_ONLINE_LABEL),
    }
end

function ZO_GamepadGuildHome:SetHeaderHidden(hide)
    self.header:SetHidden(hide)
end

function ZO_GamepadGuildHome:SetContentHeaderHidden(hide)
    self.contentHeader:SetHidden(hide)
end

function ZO_GamepadGuildHome:RefreshFooter()
    local numGuildMembers, numOnline = GetGuildInfo(self.guildId)
    self.footerData.data1Text = zo_strformat(GetString(SI_GAMEPAD_GUILD_HEADER_MEMBERS_ONLINE_FORMAT), numOnline, numGuildMembers)

    GAMEPAD_GENERIC_FOOTER:Refresh(self.footerData)
end

----------
-- List --
----------

function ZO_GamepadGuildHome:OnTargetChanged(list, selectedData, oldSelectedData)
    if(self.currentScreenObject ~= nil and self.currentScreenObject.OnTargetChanged ~= nil) then
        self.currentScreenObject:OnTargetChanged(list, selectedData, oldSelectedData)
    end
end

-----------
-- Pages --
-----------

function ZO_GamepadGuildHome:RemoveCurrentPage()
    if(self.currentFragment ~= nil) then
        GAMEPAD_GUILD_HOME_SCENE:RemoveFragment(self.currentFragment)
        self.currentFragment = nil
    end
end

function ZO_GamepadGuildHome:SetCurrentPage(fragment, screenObject)
    if self.currentFragment ~= fragment then
        self:RemoveCurrentPage()
        self.currentFragment = fragment
        self.currentScreenObject = screenObject
    
        if(fragment ~= nil and screenObject ~= nil) then
            screenObject:SetGuildId(self.guildId)

            if(screenObject.SetMainList ~= nil) then
                screenObject:SetMainList(self.itemList)
            end

            if(screenObject.SetOptionsList ~= nil) then
                screenObject:SetOptionsList(self.optionsList)
            end

            if(screenObject.SetOwningScreen ~= nil) then
                screenObject:SetOwningScreen(self)
            end

            self.itemList:Clear()
            GAMEPAD_GUILD_HOME_SCENE:AddFragment(fragment)
            self:SetCurrentList(self.itemList)
        end

        self:RefreshHeader()
    end
end

function ZO_GamepadGuildHome:ShowRoster()
    self:SetCurrentPage(GUILD_ROSTER_GAMEPAD:GetListFragment(), GUILD_ROSTER_MANAGER)
end

function ZO_GamepadGuildHome:ShowRanks()
    self:SetCurrentPage(GUILD_RANKS_GAMEPAD_FRAGMENT, GUILD_RANKS_GAMEPAD)
end

function ZO_GamepadGuildHome:ShowHeraldry()
    self:SetCurrentPage(GUILD_HERALDRY_GAMEPAD_FRAGMENT, GUILD_HERALDRY_GAMEPAD)
end

function ZO_GamepadGuildHome:ShowHistory()
    self:SetCurrentPage(GUILD_HISTORY_GAMEPAD_FRAGMENT, GUILD_HISTORY_GAMEPAD)
end

--------------------

function ZO_GamepadGuildHome_OnInitialize(control)
    GAMEPAD_GUILD_HOME = ZO_GamepadGuildHome:New(control)
end