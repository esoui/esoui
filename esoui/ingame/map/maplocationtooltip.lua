local function HasMapLocationTooltip(self, locationIndex)
    local headerText = GetMapLocationTooltipHeader(locationIndex)
    if(headerText == "") then
        return false
    end

    local numTooltipLines = GetNumMapLocationTooltipLines(locationIndex)
    if(numTooltipLines == 0) then
        return false
    end

    return true
end

local MIN_HEADER_WIDTH = 150

local function SortGroupings(a, b)
    return a.id < b.id
end

local function SortGrouping(a, b)
    return a.name < b.name
end

local function GetMapLocationLines(locationIndex)
    local groupings = {}

    local numTooltipLines = GetNumMapLocationTooltipLines(locationIndex)
    for lineIndex = 1, numTooltipLines do
        if(IsMapLocationTooltipLineVisible(locationIndex, lineIndex)) then
            --Create labels for the lines. The size of the header depends on the lines.
            local icon, name, groupingId, categoryName = GetMapLocationTooltipLineInfo(locationIndex, lineIndex)

            --Search for an existing grouping
            local grouping
            for groupingIndex = 1, #groupings do
                if(groupings[groupingIndex].id == groupingId) then
                    grouping = groupings[groupingIndex]
                end
            end

            --if there isn't an existing one, make it
            if(grouping == nil) then
                grouping = {}
                grouping.id = groupingId
                table.insert(groupings, grouping)
            end

            table.insert(grouping, {name = name, categoryName = categoryName, icon = icon})
        end
    end

    table.sort(groupings, SortGroupings)

    for groupingIndex = 1, #groupings do
        local grouping = groupings[groupingIndex]
        table.sort(grouping, SortGrouping)
    end

    return groupings
end

local function SetMapLocation(self, locationIndex)
    self:ClearLines()

    local maxWidth = MIN_HEADER_WIDTH

    --add header
    local headerText = GetMapLocationTooltipHeader(locationIndex)
    if(headerText ~= "") then
        self.header:SetText(headerText)
        self:AddControl(self.header)
        self.header:SetAnchor(CENTER)

        self:AddVerticalPadding(-5)
        self:AddControl(self.divider)
        self.divider:SetAnchor(CENTER)
    end

    --add lines
    local groupings = GetMapLocationLines(locationIndex)
    for groupingIndex = 1, #groupings do
        if(groupingIndex > 1) then
            self:AddVerticalPadding(15)
        end

        local grouping = groupings[groupingIndex]
        for textIndex = 1, #grouping do
            local name = grouping[textIndex].name
            local icon = grouping[textIndex].icon
            local text = string.format("|t32:32:%s|t%s", icon, name)

            local label = self.labelPool:AcquireObject()
            label:SetDimensions(0,0)
            label:SetText(text)
            local labelWidth = label:GetTextDimensions()
            maxWidth = zo_max(labelWidth, maxWidth)

            self:AddControl(label)
            label:SetAnchor(CENTER)
            self:AddVerticalPadding(-8)
        end
    end

    self.header:SetWidth(maxWidth)
    self.divider:SetWidth(maxWidth)
    local labels = self.labelPool:GetActiveObjects()
    for _, label in pairs(labels) do
        label:SetWidth(maxWidth)
    end
end

local function SetMapLocation_Gamepad(self, locationIndex)
    local mainSection = self.tooltip:AcquireSection(self.tooltip:GetStyle("mapLocationSection"))

    --add header
    local headerText = GetMapLocationTooltipHeader(locationIndex)
    if headerText ~= "" then
        self:LayoutGroupHeader(mainSection, nil, headerText, self.tooltip:GetStyle("mapTitle"))
    end

    local groupsSection = self.tooltip:AcquireSection(self.tooltip:GetStyle("mapGroupsSection"))

    local groupSectionStyle = self.tooltip:GetStyle("mapLocationGroupSection")
    local entryStyle = self.tooltip:GetStyle("mapLocationTooltipContent")

    --add lines
    local groupings = GetMapLocationLines(locationIndex)
    for _, grouping in ipairs(groupings) do
        local groupSection = groupsSection:AcquireSection(groupSectionStyle)

        for _, entry in ipairs(grouping) do
            local name = zo_strformat(SI_TOOLTIP_UNIT_NAME, entry.name)
            local icon = entry.icon

            icon = icon:gsub("servicetooltipicons/", "servicetooltipicons/gamepad/gp_")

            self:LayoutLargeIconStringLine(groupSection, icon, name, entryStyle)
        end

        groupsSection:AddSection(groupSection)
    end

    mainSection:AddSection(groupsSection)
    self.tooltip:AddSection(mainSection)
end

--Global XML

function ZO_MapLocationTooltip_OnCleared(self)
    self.labelPool:ReleaseAllObjects()
end

function ZO_MapLocationTooltip_OnInitialized(self)
    self.SetMapLocation = SetMapLocation
    self.HasMapLocationTooltip = HasMapLocationTooltip
    self.labelPool = ZO_ControlPool:New("ZO_MapLocationTooltipLabel", self, "Label")

    self.header = self:GetNamedChild("Header")
    self.divider = self:GetNamedChild("Divider")
end

function ZO_MapLocationTooltip_Gamepad_OnInitialized(self)
    ZO_ScrollTooltip_Gamepad:Initialize(self, ZO_TOOLTIP_STYLES, "worldMapTooltip")

    ZO_KeepTooltip_Gamepad_OnInitialized(self)

    self.SetMapLocation = SetMapLocation_Gamepad
    self.HasMapLocationTooltip = HasMapLocationTooltip

    zo_mixin(self, ZO_MapInformationTooltip_Gamepad_Mixin)

    local ALWAYS_ANIMATE = true
    GAMEPAD_WORLD_MAP_TOOLTIP_FRAGMENT = ZO_FadeSceneFragment:New(self:GetParent(), ALWAYS_ANIMATE)

    ZO_Scroll_Gamepad_SetScrollIndicatorSide(self.scrollIndicator, self:GetParent(), LEFT)
end
