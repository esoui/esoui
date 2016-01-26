CHAT_OPTIONS = nil
local FILTERS_PER_ROW = 2
local GUILDS_PER_ROW = 2

--defines channels to be combined under one button
local COMBINED_CHANNELS = {
    [CHAT_CATEGORY_WHISPER_INCOMING] = {parentChannel = CHAT_CATEGORY_WHISPER_INCOMING, name = SI_CHAT_CHANNEL_NAME_WHISPER},
    [CHAT_CATEGORY_WHISPER_OUTGOING] = {parentChannel = CHAT_CATEGORY_WHISPER_INCOMING, name = SI_CHAT_CHANNEL_NAME_WHISPER},

    [CHAT_CATEGORY_MONSTER_SAY] = {parentChannel = CHAT_CATEGORY_MONSTER_SAY, name = SI_CHAT_CHANNEL_NAME_NPC},
    [CHAT_CATEGORY_MONSTER_YELL] = {parentChannel = CHAT_CATEGORY_MONSTER_SAY, name = SI_CHAT_CHANNEL_NAME_NPC},
    [CHAT_CATEGORY_MONSTER_WHISPER] = {parentChannel = CHAT_CATEGORY_MONSTER_SAY, name = SI_CHAT_CHANNEL_NAME_NPC},
    [CHAT_CATEGORY_MONSTER_EMOTE] = {parentChannel = CHAT_CATEGORY_MONSTER_SAY, name = SI_CHAT_CHANNEL_NAME_NPC},
}

-- defines channels to skip when building the filter (non guild) section
local SKIP_CHANNELS = {
    [CHAT_CATEGORY_SYSTEM] = true,
    [CHAT_CATEGORY_GUILD_1] = true,
    [CHAT_CATEGORY_GUILD_2] = true,
    [CHAT_CATEGORY_GUILD_3] = true,
    [CHAT_CATEGORY_GUILD_4] = true,
    [CHAT_CATEGORY_GUILD_5] = true,
    [CHAT_CATEGORY_OFFICER_1] = true,
    [CHAT_CATEGORY_OFFICER_2] = true,
    [CHAT_CATEGORY_OFFICER_3] = true,
    [CHAT_CATEGORY_OFFICER_4] = true,
    [CHAT_CATEGORY_OFFICER_5] = true,
}

-- defines the ordering of the filter categories
local CHANNEL_ORDERING_WEIGHT = {
    [CHAT_CATEGORY_SAY] = 10,
    [CHAT_CATEGORY_YELL] = 20,

    [CHAT_CATEGORY_WHISPER_INCOMING] = 30,
    [CHAT_CATEGORY_PARTY] = 40,

    [CHAT_CATEGORY_EMOTE] = 50,
    [CHAT_CATEGORY_MONSTER_SAY] = 60,

    [CHAT_CATEGORY_ZONE] = 80,

    [CHAT_CATEGORY_ZONE_ENGLISH] = 90,
    [CHAT_CATEGORY_ZONE_FRENCH] = 100,

    [CHAT_CATEGORY_ZONE_GERMAN] = 110,
}


--[[ Chat Options Panel ]]--
local ChatOptions = ZO_Object:Subclass()

function ChatOptions:New(...)
    local options = ZO_Object.New(self)   
    return options
end

local function SetupChatOptionsDialog(control)
    ZO_Dialogs_RegisterCustomDialog("CHAT_OPTIONS_DIALOG",
    {
        customControl = control,
        title =
        {
            text = SI_WINDOW_TITLE_CHAT_CHANNEL_OPTIONS,
        },
        setup = function(self) CHAT_OPTIONS:Initialize(control) end,
        buttons =
        {
            {

                control =   GetControl(control, "Commit"),
                text =      SI_DIALOG_EXIT,
                keybind =   "DIALOG_NEGATIVE",
                callback =  function(dialog)
                                ZO_ChatOptions_OnCommitClicked()
                            end,
            },  

            {
                control =   GetControl(control, "Reset"),
                text =      SI_OPTIONS_DEFAULTS,
                keybind =   "DIALOG_RESET",
                callback =  function(dialog)
                                ZO_ChatOptions_OnResetClicked()
                            end,
            },
        }
    })
end

function ChatOptions:Initialize(control)
    if(not self.initialized) then
    	self.control = control
	    control.owner = self
        self.filterSection = control:GetNamedChild("FilterSection")
        self.guildSection = control:GetNamedChild("GuildSection")

        local function Reset(control)
            control:SetHidden(true)
        end
    
        local function FilterFactory(pool)
            return ZO_ObjectPool_CreateControl("ZO_ChatOptionsFilterEntry", pool, self.filterSection)
        end

        local function GuildFactory(pool)
            return ZO_ObjectPool_CreateControl("ZO_ChatOptionsGuildFilters", pool, self.guildSection)
        end
    
        self.filterPool = ZO_ObjectPool:New(FilterFactory, Reset)
        self.guildPool = ZO_ObjectPool:New(GuildFactory, Reset)

        self.filterButtons = {}
        self.guildNameLabels = {}
	    self:InitializeNameControl(control)
        self:InitializeFilterButtons(control)
        self:InitializeGuildFilters(control)
        self.initialized = true
    end

    self:UpdateGuildNames()
end

function ChatOptions:InitializeNameControl(control)
	self.tabName = control:GetNamedChild("NameEdit")

	local function UpdateTabName()
		self:UpdateTabName()
	end

	self.tabName:SetHandler("OnTextChanged", UpdateTabName)
end

function ChatOptions:UpdateTabName()
	self.chatContainer:SetTabName(self.chatTabIndex, self.tabName:GetText())
end

local function FilterComparator(left, right)
    local leftPrimaryCategory = left.channels[1]
    local rightPrimaryCategory = right.channels[1]

    local leftWeight = CHANNEL_ORDERING_WEIGHT[leftPrimaryCategory]
    local rightWeight = CHANNEL_ORDERING_WEIGHT[rightPrimaryCategory]

    if leftWeight and rightWeight then
        return leftWeight < rightWeight
    elseif not leftWeight and not rightWeight then
        return false
    elseif leftWeight then
        return true
    end

    return false
end

do
    local FILTER_PAD_X = 90
    local FILTER_PAD_Y = 0
    local FILTER_WIDTH = 150
    local FILTER_HEIGHT = 27
    local INITIAL_XOFFS = 0
    local INITIAL_YOFFS = 0

    function ChatOptions:InitializeFilterButtons(dialogControl)
        --generate a table of entry data from the chat category header information
        local entryData = {}
        local lastEntry = CHAT_CATEGORY_HEADER_COMBAT - 1

        for i = CHAT_CATEGORY_HEADER_CHANNELS, lastEntry do
            if(SKIP_CHANNELS[i] == nil and GetString("SI_CHATCHANNELCATEGORIES", i) ~= "") then

                if(COMBINED_CHANNELS[i] == nil) then
                    entryData[i] = 
                    {
                        channels = { i },
                        name = GetString("SI_CHATCHANNELCATEGORIES", i),
                    }                
                else
                    --create the entry for those with combined channels just once
                    local parentChannel = COMBINED_CHANNELS[i].parentChannel

                    if(not entryData[parentChannel]) then
                        entryData[parentChannel] = 
                        {
                            channels = { },
                            name = GetString(COMBINED_CHANNELS[i].name),
                        }
                    end

                    table.insert(entryData[parentChannel].channels, i)
                end
            end
        end

        --now generate and anchor buttons
        local filterAnchor = ZO_Anchor:New(TOPLEFT, self.filterSection, TOPLEFT, 0, 0)
        local count = 0

        local sortedEntries = {}
        for _, entry in pairs(entryData) do
            sortedEntries[#sortedEntries + 1] = entry
        end

        table.sort(sortedEntries, FilterComparator)

        for _, entry in ipairs(sortedEntries) do
            local filter, key = self.filterPool:AcquireObject()
            filter.key = key

            local button = filter:GetNamedChild("Check")
            button.channels = entry.channels
            table.insert(self.filterButtons, button)

            local label = filter:GetNamedChild("Label")
            label:SetText(entry.name)

            ZO_Anchor_BoxLayout(filterAnchor, filter, count, FILTERS_PER_ROW, FILTER_PAD_X, FILTER_PAD_Y, FILTER_WIDTH, FILTER_HEIGHT, INITIAL_XOFFS, INITIAL_YOFFS)
            count = count + 1
        end
    end

    local GUILD_PAD_X = 90
    local GUILD_PAD_Y = 0
    local GUILD_WIDTH = 150
    local GUILD_HEIGHT = 90

    function ChatOptions:InitializeGuildFilters(dialogControl)
        local guildAnchor = ZO_Anchor:New(TOPLEFT, self.guildSection, TOPLEFT, 0, 0)
        local count = 0

        -- setup and anchor the guild sections
        local maxGuild = CHAT_CATEGORY_HEADER_GUILDS + MAX_GUILDS - 1
        for k = CHAT_CATEGORY_HEADER_GUILDS, maxGuild do
            local guild, key = self.guildPool:AcquireObject()
            guild.key = key

            local guildFilter = guild:GetNamedChild("Guild")
            local guildButton = guildFilter:GetNamedChild("Check")
            guildButton.channels = {k}
            table.insert(self.filterButtons, guildButton)
            local guildLabel = guildFilter:GetNamedChild("Label")
            guildLabel:SetText(GetString("SI_CHATCHANNELCATEGORIES", k))

            local officerFilter = guild:GetNamedChild("Officer")
            local officerButton = officerFilter:GetNamedChild("Check")
            local officerChannel = k + MAX_GUILDS
            officerButton.channels = {officerChannel}
            table.insert(self.filterButtons, officerButton)
            local officerLabel = officerFilter:GetNamedChild("Label")
            officerLabel:SetText(GetString("SI_CHATCHANNELCATEGORIES", officerChannel))

            local nameLabel = guild:GetNamedChild("GuildName")
            table.insert(self.guildNameLabels, nameLabel)

            ZO_Anchor_BoxLayout(guildAnchor, guild, count, GUILDS_PER_ROW, GUILD_PAD_X, GUILD_PAD_Y, GUILD_WIDTH, GUILD_HEIGHT, INITIAL_XOFFS, INITIAL_YOFFS)
            count = count + 1
        end
    end
end

function ChatOptions:UpdateGuildNames()
    for i,label in ipairs(self.guildNameLabels) do
        local guildID = GetGuildId(i)
        local guildName = GetGuildName(guildID)
        local alliance = GetGuildAlliance(guildID)

        if(guildName ~= "") then
            local r,g,b = GetAllianceColor(alliance):UnpackRGB()
            label:SetText(guildName)
            label:SetColor(r, g, b, 1)
        else
            label:SetText(zo_strformat(SI_EMPTY_GUILD_CHANNEL_NAME, i))
        end
    end
end

function ChatOptions:GetCurrentTabIndex()
    return self.chatTabIndex
end

function ChatOptions:GetCurrentContainer()
    return self.chatContainer
end

function ChatOptions:Show(chatContainer, chatTabIndex)
    -- If options are switched before closing the window, allow the previously selected window to fade out...
    self:FadeOutCurrentContainer()
        
    ZO_Dialogs_ShowDialog("CHAT_OPTIONS_DIALOG")

	self.chatContainer = chatContainer
	self.chatTabIndex = chatTabIndex

	chatContainer:SetAllowSaveSettings(false)

    local tabName = chatContainer:GetTabName(chatTabIndex)
    self.tabName:SetText(tabName)

    self:SetCurrentChannelSelections(chatContainer, chatTabIndex)
end

function ChatOptions:SetCurrentChannelSelections(container, chatTabIndex) 
    -- Iterate each button's channel list and check just the first entry in each as they are all toggled together       
    for i, button in ipairs(self.filterButtons) do
        if(IsChatContainerTabCategoryEnabled(container.id, chatTabIndex, button.channels[1])) then
            ZO_CheckButton_SetCheckState(button, true)
        else
            ZO_CheckButton_SetCheckState(button, false)
        end
    end   
end

function ChatOptions:ShowResetDialog()
    local tabName = self.chatContainer:GetTabName(self.chatTabIndex)
    ZO_Dialogs_ShowDialog("CHAT_TAB_RESET", nil, {mainTextParams = {tabName}} )
end

function ChatOptions:Reset()
	local system = self.chatContainer:GetChatSystem()

	self.chatContainer:ResetToDefaults(self.chatTabIndex)

    local tabName = self.chatContainer:GetTabName(self.chatTabIndex)
    self.tabName:SetText(tabName)


    --set all channel buttons selected active
    for i, button in ipairs(self.filterButtons) do
        ZO_CheckButton_SetCheckState(button, true)
    end  
 
	system:ResetContainerPositionAndSize(self.chatContainer)
end

function ChatOptions:FadeOutCurrentContainer()
    if self.chatContainer then
        self.chatContainer:RemoveFadeInReference()
    end
end

function ChatOptions:Commit()
	self.chatContainer:SetAllowSaveSettings(true)
    self.chatContainer:SaveWindowSettings(self.chatTabIndex)
	self.chatContainer:SaveSettings()
    self:FadeOutCurrentContainer()

    ZO_Dialogs_ReleaseDialog("CHAT_OPTIONS_DIALOG")
end

--[[ XML Handlers ]]--
function ZO_ChatOptions_OnInitialized(dialogControl)
    SetupChatOptionsDialog(dialogControl)
	CHAT_OPTIONS = ChatOptions:New(dialogControl)
end

function ZO_ChatOptions_OnCommitClicked()
	CHAT_OPTIONS:Commit()
end

function ZO_ChatOptions_OnResetClicked()
	CHAT_OPTIONS:ShowResetDialog()
end

function ZO_ChatOptions_ToggleChannel(buttonControl, checked)
    local channels = buttonControl.channels
    local container = CHAT_OPTIONS:GetCurrentContainer()
    local tabIndex = CHAT_OPTIONS:GetCurrentTabIndex()

    for i,channel in ipairs(channels) do
       container:SetWindowFilterEnabled(tabIndex, channel, checked) 
    end
end