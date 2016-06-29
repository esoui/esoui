local GuildSelector = ZO_Object:Subclass()

function GuildSelector:New(...)
    local selector = ZO_Object.New(self)
    selector:Initialize(...)
    return selector
end

function GuildSelector:Initialize(control)
    self.control = control
    local comboBoxControl = GetControl(control, "ComboBox")
    self.comboBox = ZO_ComboBox_ObjectFromContainer(comboBoxControl)
    self.comboBox:SetSortsItems(false)
    self.comboBox:SetSelectedItemFont("ZoFontWindowTitle")
    self.comboBox:SetDropdownFont("ZoFontHeader2")
    self.comboBox:SetSpacing(8)
    local comboBoxLabel = comboBoxControl:GetNamedChild("SelectedItemText")

    self.allianceIconControl = GetControl(control, "GuildIcon")
    
    self.scenesCreated = false
    self.OnGuildChanged =   function(_, entryText, entry)
                                local changeGuildCallback = function(params)
                                                                self:SelectGuild(params.entry)
                                                            end
                                local changeGuildParams = { entry = entry, }
                                local forcePreviousGuildNameInSelector = true

                                if GUILD_RANKS:CanSave() then
                                    if self.guildId ~= entry.guildId then
                                        GUILD_RANKS:ChangeSelectedGuild(changeGuildCallback, changeGuildParams)
                                    end
                                elseif GUILD_HERALDRY:CanSave() then
                                    if self.guildId ~= entry.guildId then
                                        GUILD_HERALDRY:ChangeSelectedGuild(changeGuildCallback, changeGuildParams)
                                    end
                                else
                                    forcePreviousGuildNameInSelector = false
                                    self:SelectGuild(entry)
                                end

                                if forcePreviousGuildNameInSelector then
                                    -- Force the combo box to not change guild text until the callback is adequately addressed
                                    self.comboBox:SetSelectedItemText(self.currentGuildText)
                                end
                            end

    EVENT_MANAGER:RegisterForEvent("GuildsSelector", EVENT_GUILD_DATA_LOADED, function() self:InitializeGuilds() end)

    local function OnSceneGroupBarLabelTextChanged(labelControl)
        local menuLeft = labelControl:GetLeft()
        local comboLeft = comboBoxLabel:GetLeft()
        local workingWidth = menuLeft - comboLeft
        comboBoxLabel:SetDimensionConstraints(0, 0, workingWidth - 50, 0)
    end

    MAIN_MENU_KEYBOARD:RegisterCallback("OnSceneGroupBarLabelTextChanged", OnSceneGroupBarLabelTextChanged)

    self.guildWindows =
    {
        GUILD_HOME,
        GUILD_ROSTER_MANAGER,
        GUILD_RANKS,
        GUILD_HISTORY,
        GUILD_SHARED_INFO,
        GUILD_HERALDRY,
    }

    self.guildRelatedScenes =
    {
        "guildHome",
        "guildRoster",
        "guildRanks",
        "guildHistory",
        "guildHeraldry",
    }
end

function GuildSelector:SetGuildWindowsToId(guildId)
    for _, window in ipairs(self.guildWindows) do
        window:SetGuildId(guildId)
    end
end

function GuildSelector:IsGuildRelatedSceneShowing()
    for _, sceneName in ipairs(self.guildRelatedScenes) do
        if(SCENE_MANAGER:IsShowing(sceneName)) then
            return true
        end
    end
    return false
end

function GuildSelector:InitializeGuilds()
    if(not self.scenesCreated) then return end

    local selectedEntry
    local lastGuildId = self.guildId
    
    self.guildId = nil
    self.comboBox:ClearItems()
    
    local numGuilds = GetNumGuilds()
    for i = 1, numGuilds do
        local guildId = GetGuildId(i)
        local guildName = GetGuildName(guildId)
        local guildAlliance = GetGuildAlliance(guildId)
        local entryText = zo_strformat(SI_GUILD_SELECTOR_FORMAT, GetAllianceBannerIcon(guildAlliance), i, guildName)
        local entry = self.comboBox:CreateItemEntry(entryText, self.OnGuildChanged)
        entry.guildId = guildId
        entry.selectedText = guildName
		self.comboBox:AddItem(entry)

        if(not selectedEntry or (lastGuildId and guildId == lastGuildId)) then
            selectedEntry = entry
        end

        if(not playerIsGuildMaster) then
            local guildPlayerIndex = GetPlayerGuildMemberIndex(guildId)
            local _, _, rankIndex = GetGuildMemberInfo(guildId, guildPlayerIndex)
            if(IsGuildRankGuildMaster(guildId, rankIndex)) then
                playerIsGuildMaster = true
            end
        end
    end

    local CREATE_WINDOW_TITLE = GetString(SI_GUILD_CREATE_TITLE)
    local entry = self.comboBox:CreateItemEntry(CREATE_WINDOW_TITLE, self.OnGuildChanged)
    entry.selectedText = CREATE_WINDOW_TITLE
    self.comboBox:AddItem(entry)

    if(numGuilds == 0) then
        self.comboBox:SetSelectedItemText(CREATE_WINDOW_TITLE)
        self.OnGuildChanged(nil, CREATE_WINDOW_TITLE, entry)
    else
        self.comboBox:SetSelectedItemText(selectedEntry.selectedText)
        self.OnGuildChanged(nil, selectedEntryText, selectedEntry)
    end
end

function GuildSelector:SetGuildIcon(guildId)
    local validGuildId = guildId ~= nil
    if validGuildId then
        local allianceId = GetGuildAlliance(guildId)
        self.allianceIconControl:SetTexture(GetLargeAllianceSymbolIcon(allianceId))
    end

    self.allianceIconControl:SetHidden(not validGuildId)
end

function GuildSelector:SelectGuild(selectedEntry)
    if(selectedEntry) then
        self.currentGuildText = selectedEntry.selectedText
        self.guildId = selectedEntry.guildId
        self.comboBox:SetSelectedItemText(selectedEntry.selectedText)
        self:SetGuildIcon(selectedEntry.guildId)

        if(self.guildId) then       
            if(SCENE_MANAGER:IsShowing("guildCreate")) then
                MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "guildHome")
            else
                local sceneGroup = SCENE_MANAGER:GetSceneGroup("guildsSceneGroup")
                sceneGroup:SetActiveScene("guildHome")
            end

            self:SetGuildWindowsToId(self.guildId)
        else
            if(self:IsGuildRelatedSceneShowing()) then
                MAIN_MENU_KEYBOARD:ShowSceneGroup("guildsSceneGroup", "guildCreate")
            else
                local sceneGroup = SCENE_MANAGER:GetSceneGroup("guildsSceneGroup")
                sceneGroup:SetActiveScene("guildCreate")
            end
        end

        CALLBACK_MANAGER:FireCallbacks("OnGuildSelected")
    end
end

function GuildSelector:SelectGuildByIndex(index)    
    if(index <= GetNumGuilds()) then
        local entries = self.comboBox:GetItems()
        self:SelectGuild(entries[index])
    end
end

function GuildSelector:OnScenesCreated()
    self.scenesCreated = true
    self:InitializeGuilds()
end

--Global XML

function ZO_GuildSelector_OnInitialized(self)
    GUILD_SELECTOR = GuildSelector:New(self)
end