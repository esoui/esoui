local WorldMapQuests = ZO_WorldMapQuests_Shared:Subclass()

local QUEST_DATA = 1

function WorldMapQuests:New(...)
    local object = ZO_WorldMapQuests_Shared.New(self, ...)
    return object
end

function WorldMapQuests:Initialize(control)
    ZO_WorldMapQuests_Shared.Initialize(self, control)
    self.control = control
    self.noQuestsLabel = control:GetNamedChild("NoQuests")

    self.headerPool = ZO_ControlPool:New("ZO_WorldMapQuestHeader", control:GetNamedChild("PaneScrollChild"), "Header")

    WORLD_MAP_QUESTS_FRAGMENT = ZO_FadeSceneFragment:New(control)
    QUEST_TRACKER:RegisterCallback("QuestTrackerAssistStateChanged", function(...) self:RefreshHeaders() end)
end

function WorldMapQuests:LayoutList()
    self:RefreshNoQuestsLabel()
    
    local prevHeader
    self.headerPool:ReleaseAllObjects()
    for i, data in ipairs(self.data.masterList) do
        local header = self.headerPool:AcquireObject(i)
        if(prevHeader) then
            header:SetAnchor(TOPLEFT, prevHeader, BOTTOMLEFT, 0, 4)
        else
            header:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        end
        prevHeader = header
    end

    self:RefreshHeaders()
end

function WorldMapQuests:RefreshHeaders()
    for i, header in ipairs(self.headerPool:GetActiveObjects()) do
        self:SetupQuestHeader(header, self.data.masterList[i])
    end
end

function WorldMapQuests:SetupQuestHeader(control, data)
    if (data == nil) then return end

    --Quest Name
    local nameControl = GetControl(control, "Name")
    nameControl:SetText(data.name)
    ZO_SelectableLabel_SetNormalColor(nameControl, ZO_ColorDef:New(GetColorForCon(GetCon(data.level))))
        
    --Assisted State
    local isAssisted = ZO_QuestTracker.tracker:IsTrackTypeAssisted(TRACK_TYPE_QUEST, data.questIndex)
    local assistedTexture = GetControl(control, "AssistedIcon")
    assistedTexture:SetHidden(not isAssisted)

    control.data = data

    local nameWidth, nameHeight = nameControl:GetTextDimensions()
    control:SetHeight(zo_max(24, nameHeight))
end

function WorldMapQuests:QuestHeader_OnClicked(header, button)
    if button == MOUSE_BUTTON_INDEX_LEFT then
        local data = header.data
        ZO_WorldMap_PanToQuest(data.questIndex)
        QUEST_TRACKER:ForceAssist(data.questIndex)
    end
end

function WorldMapQuests:QuestHeader_OnMouseEnter(header)
    InitializeTooltip(ZO_MapQuestDetailsTooltip, header, RIGHT, -25)
    ZO_MapQuestDetailsTooltip:SetQuest(header.data.questIndex)
end

--Local XML

function ZO_WorldMapQuestHeader_OnMouseEnter(header)
    WORLD_MAP_QUESTS:QuestHeader_OnMouseEnter(header)
end

function ZO_WorldMapQuestHeader_OnMouseExit(header)
    ClearTooltip(ZO_MapQuestDetailsTooltip)
end

function ZO_WorldMapQuestHeader_OnMouseDown(header, button)
    local name = GetControl(header, "Name")
    name:SetAnchor(TOPLEFT, nil, TOPLEFT, 26, 2)
end

function ZO_WorldMapQuestHeader_OnMouseUp(header, button, upInside)
    local name = GetControl(header, "Name")
    name:SetAnchor(TOPLEFT, nil, TOPLEFT, 26, 0)
    WORLD_MAP_QUESTS:QuestHeader_OnClicked(header, button)
end

--Global XML

function ZO_WorldMapQuests_OnInitialized(self)
    WORLD_MAP_QUESTS = WorldMapQuests:New(self)
end


--Quest Tooltip
-------------------

do
    local function SetQuest(self, questIndex)
        local labels, width = ZO_WorldMapQuests_Shared_SetupQuestDetails(self, questIndex)

        for i = 1, #labels do
            local label = labels[i]
            label:SetWidth(width)
            self:AddControl(label)
            label:SetAnchor(CENTER)
            self:AddVerticalPadding(-8)
        end
    end

    function ZO_MapQuestDetailsTooltip_OnCleared(self)
        self.labelPool:ReleaseAllObjects()
    end

    function ZO_MapQuestDetailsTooltip_OnInitialized(self)
        self.labelPool = ZO_ControlPool:New("ZO_MapQuestDetailsCondition", self, "Label")
        self.SetQuest = SetQuest
    end
end