local CATEGORY_LIST_HEIGHT = 335

local MAX_SUMMARY_CATEGORIES = 12
local SUMMARY_CATEGORY_BAR_HEIGHT = 16
local SUMMARY_CATEGORY_PADDING = 50

local ACHIEVEMENT_PADDING = 0
local ACHIEVEMENT_ICON_STYLE_PADDING = 20
local ACHIEVEMENT_WIDTH = 550
local ACHIEVEMENT_COLLAPSED_HEIGHT = 88
local ACHIEVEMENT_DESC_COLLAPSED_HEIGHT = 45
local ACHIEVEMENT_DESC_WIDTH = 380
local ACHIEVEMENT_INITIAL_CRITERIA_OFFSET = 10
local ACHIEVEMENT_LINE_PADDING = 5
local ACHIEVEMENT_LINE_PADDING_VERTICAL = 8
local ACHIEVEMENT_CRITERIA_PADDING = 10
local ACHIEVEMENT_REWARD_PADDING = 5
local ACHIEVEMENT_LINE_THUMB_WIDTH = 45
local ACHIEVEMENT_LINE_THUMB_HEIGHT = 68
local ACHIEVEMENT_STATUS_BAR_HEIGHT = 20
local ACHIEVEMENT_REWARD_LABEL_WIDTH = 230
local ACHIEVEMENT_REWARD_LABEL_HEIGHT = 20
local ACHIEVEMENT_REWARD_ICON_HEIGHT = 45

local ACHIEVEMENT_DATE_LABEL_EXPECTED_WIDTH = 60

local NUM_RECENT_ACHIEVEMENTS_TO_SHOW = 6

local SAVE_EXPANDED = true
local DONT_REBUILD_CONTENT_LIST = true

local PREFIX_LABEL = 1
local HEADER_LABEL = 2

local FORCE_HIDE_PROGRESS_TEXT = true

local function GetTextColor(enabled, normalColor, disabledColor)
    if enabled then
        return (normalColor or ZO_NORMAL_TEXT):UnpackRGBA()
    end
    return (disabledColor or ZO_DISABLED_TEXT):UnpackRGBA()
end

local function ApplyTextColorToLabel(label, ...)
    label:SetColor(GetTextColor(...))
end

local function ApplyColorToAchievementIcon(base, color)
    local r, g, b, a = color:UnpackRGBA()

    base.icon:SetColor(r, g, b, a)
    base.icon:GetNamedChild("EmergencyBG"):SetColor(r, g, b, a)
end

local function GetLastCompletedAchievementInLine(achievementId)
    local lastCompleted = achievementId

    while(achievementId ~= 0) do
        local _, _, _, _, completed, _, _= GetAchievementInfo(achievementId)

        if(not completed) then
            return lastCompleted
        end

        lastCompleted = achievementId
        achievementId = GetNextAchievementInLine(achievementId)
    end

    return lastCompleted
end

--[[ Achievement ]]--
local Achievement = ZO_Object:Subclass()

function Achievement:New(...)
    local achievement = ZO_Object.New(self)
    achievement:Initialize(...)
    
    return achievement
end

function Achievement:Initialize(control, checkPool, statusBarPool, rewardLabelPool, rewardIconPool, lineThumbPool, dyeSwatchPool)
    control.achievement = self
    self.control = control
    ZO_InventorySlot_SetType(self.control, SLOT_TYPE_ACHIEVEMENT_REWARD)
    self.checkPool = checkPool
    self.statusBarPool = statusBarPool
    self.rewardLabelPool = rewardLabelPool
    self.rewardIconPool = rewardIconPool
    self.lineThumbPool = lineThumbPool
    self.dyeSwatchPool = dyeSwatchPool
    
    self.checkBoxes = {}
    self.progressBars = {}
    self.rewardIcons = {}
    self.rewardLabels = {}
    self.headerLabels = {}
    self.lineThumbs = {}
    self.dyeSwatches = {}
    self.collapsed = true
    
    self.title = control:GetNamedChild("Title")
    self.highlight = control:GetNamedChild("Highlight")
    self.description = control:GetNamedChild("Description")
    self.icon = control:GetNamedChild("Icon")
    self.points = control:GetNamedChild("Points")
    self.date = control:GetNamedChild("Date")
    self.rewardThumb = control:GetNamedChild("RewardThumb")
    self.expandedStateIcon = control:GetNamedChild("ExpandedState")

    self.anchoredToAchievement = nil
    self.dependentAnchoredAchievement = nil

    if(self.highlight) then
        self.highlight:SetHeight(ACHIEVEMENT_COLLAPSED_HEIGHT)
    end
end

function Achievement:GetId()
    return self.achievementId
end

function Achievement:GetAchievementInfo(achievementId)
    return GetAchievementInfo(achievementId)
end

function Achievement:Show(achievementId)
    self.achievementId = achievementId
    local name, description, points, icon, completed, date, time = self:GetAchievementInfo(achievementId)
    
    self.title:SetText(zo_strformat(name))
    self.description:SetText(zo_strformat(description))
    self.icon:SetTexture(icon)

    self.points:SetHidden(points == ACHIEVEMENT_POINT_LEGENDARY_DEED)
    self.points:SetText(tostring(points))

    ApplyTextColorToLabel(self.points, completed, ZO_SELECTED_TEXT, ZO_DISABLED_TEXT)
    ApplyTextColorToLabel(self.title, completed, ZO_SELECTED_TEXT, ZO_DISABLED_TEXT)
    ApplyTextColorToLabel(self.description, completed, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)
    
    self.completed = completed
    self.isExpandable = self:IsExpandable()
    
    if completed then
        self.date:SetHidden(false)        
        self.date:SetText(date)

        ApplyColorToAchievementIcon(self, ZO_DEFAULT_ENABLED_COLOR)
    else
        self.date:SetHidden(true)
        ApplyColorToAchievementIcon(self, ZO_DEFAULT_DISABLED_COLOR)
    end
    
    -- Date strings might overlap the description, so apply dimension constraints after setting the completion date
    self:ApplyCollapsedDescriptionConstraints()

    self:SetRewardThumb(achievementId)
    self:UpdateExpandedStateIcon()
    
    self.control:SetHidden(false)
end

function Achievement:SetRewardThumb(achievementId)
    local hasReward, completedReward = self:HasTangibleReward() -- achievements always award points, account for that
    self.rewardThumb:SetHidden(not hasReward)

    if(hasReward) then
        if(completedReward) then
            self.rewardThumb:SetTexture("EsoUI/Art/Achievements/achievements_reward_earned.dds")
        else
            self.rewardThumb:SetTexture("EsoUI/Art/Achievements/achievements_reward_unearned.dds")
        end
    end
end

do
    local function LayoutLineSection(controls, yOffset, parent, controlWidth, controlHeight)
        local numControls = #controls
        if numControls > 0 then            
            local previous
            for i = 1, numControls do
                if previous then
                    controls[i]:SetAnchor(LEFT, previous, RIGHT, ACHIEVEMENT_LINE_PADDING, 0)
                else
                    local totalLineWidth = (numControls * (controlWidth + ACHIEVEMENT_LINE_PADDING)) - ACHIEVEMENT_LINE_PADDING
                    local startX = (ACHIEVEMENT_WIDTH - totalLineWidth) / 2
                    controls[i]:SetAnchor(TOPLEFT, parent, TOPLEFT, startX, yOffset)
                end
                previous = controls[i]
            end
            
            yOffset = yOffset + controlHeight + ACHIEVEMENT_LINE_PADDING_VERTICAL
        end
        
        return yOffset
    end
    
    local function LayoutCriteriaSection(controls, yOffset, parent, controlHeight)
        local useFunctionToGetHeight = type(controlHeight) == "function"
        local numControls = #controls
        if numControls > 0 then            
            for i, control in ipairs(controls) do
                yOffset = yOffset + (control.additionalVerticalPadding or 0)
                control:SetAnchor(TOPLEFT, parent, TOPLEFT, 90, yOffset)

                local currentHeight = controlHeight

                if(useFunctionToGetHeight) then
                    currentHeight = currentHeight(control)
                end

                yOffset = yOffset + ACHIEVEMENT_CRITERIA_PADDING + currentHeight
            end
        end
        
        return yOffset
    end
    
    local function LayoutRewardSection(controls, yOffset, parent, controlHeight)
        local numControls = #controls
        if numControls > 0 then
            local numRewards = 0          
            for i, control in ipairs(controls) do
                if not control.isHeader then
                    if control.prefix then
                        control:SetAnchor(LEFT, control.prefix, RIGHT, 5, 0)
                    else
                        numRewards = numRewards + 1
                        local padding = 0
                        if numRewards > 1 then
                            padding = ACHIEVEMENT_REWARD_PADDING
                        end
                        control:SetAnchor(TOPLEFT, parent, TOPLEFT, 90, yOffset + padding)
                        yOffset = yOffset + padding + controlHeight
                    end
                end
            end
            
            yOffset = yOffset + ACHIEVEMENT_REWARD_PADDING
        end
        
        return yOffset
    end

    local function AddSectionPadding(controls, yOffset, padAmount)
        if(#controls > 0) then
            return yOffset + padAmount
        end

        return yOffset
    end

    local function GetCriteriaHeightCheckBox(control)
        local labelHeight = select(2, control.label:GetTextDimensions())
        return zo_max(control:GetHeight(), labelHeight)
    end

    function Achievement:HasAnyVisibleCriteriaOrRewards()
        return (#self.lineThumbs + #self.progressBars + #self.checkBoxes + #self.rewardLabels + #self.rewardIcons + #self.dyeSwatches) > 0
    end

    function Achievement:PerformExpandedLayout()
        local drawnHeight = select(2, self.description:GetTextDimensions())
        local controlTop = self.control:GetTop()
        local yOffset = self.description:GetBottom() - controlTop -- always try to start right after the bottom of the description
        local footerPad = self.title:GetTop() - controlTop

        if(self:HasAnyVisibleCriteriaOrRewards()) then
            -- If you have other things in the expanded view, pad out a little after the description
            yOffset = yOffset + ACHIEVEMENT_INITIAL_CRITERIA_OFFSET
        else
            -- If you don't have anything else to show, at least show the full description, but if the full description
            -- fits in the collapsed view, don't expand the window at all.
            yOffset = zo_max(ACHIEVEMENT_COLLAPSED_HEIGHT, yOffset + footerPad)
        end
        
        yOffset = LayoutCriteriaSection(self.progressBars, yOffset, self.control, ACHIEVEMENT_STATUS_BAR_HEIGHT)
        yOffset = AddSectionPadding(self.progressBars, yOffset, ACHIEVEMENT_CRITERIA_PADDING)        
        yOffset = LayoutCriteriaSection(self.checkBoxes, yOffset, self.control, GetCriteriaHeightCheckBox)
        yOffset = LayoutLineSection(self.lineThumbs, yOffset, self.control, ACHIEVEMENT_LINE_THUMB_WIDTH, ACHIEVEMENT_LINE_THUMB_HEIGHT)

        local hasRewards = (#self.rewardLabels > 0 or #self.rewardIcons > 0 or #self.dyeSwatches > 0)
        
        if hasRewards then            
            yOffset = yOffset + 15 -- push down a little from the criteria
            self.yOffsetWhereRewardsStart = yOffset
            yOffset = LayoutRewardSection(self.rewardLabels, yOffset, self.control, ACHIEVEMENT_REWARD_LABEL_HEIGHT)
            yOffset = LayoutRewardSection(self.rewardIcons, yOffset, self.control, ACHIEVEMENT_REWARD_ICON_HEIGHT)
            yOffset = LayoutRewardSection(self.dyeSwatches, yOffset, self.control, ACHIEVEMENT_REWARD_ICON_HEIGHT)
        end

        footerPad = hasRewards and footerPad or 0
        self.control:SetHeight(yOffset + footerPad)
    end
end

function Achievement:AddProgressBar(description, numCompleted, numRequired, showBarDescription)
    local bar, key = self.statusBarPool:AcquireObject()
    bar.key = key

    bar.label:SetText(showBarDescription and zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description) or "")
    ApplyTextColorToLabel(bar.label, numCompleted == numRequired, ZO_SELECTED_TEXT, ZO_DISABLED_TEXT)

    local numCompletedAsString = ZO_CommaDelimitNumber(numCompleted)
    local numRequiredAsString = ZO_CommaDelimitNumber(numRequired)

    bar.additionalVerticalPadding = select(2, bar.label:GetTextDimensions()) + 4 -- add for for the anchor offset of the label from the bar
    bar.progress:SetText(zo_strformat(SI_JOURNAL_PROGRESS_BAR_PROGRESS, numCompletedAsString, numRequiredAsString))
    bar:SetMinMax(0, numRequired)
    bar:SetValue(numCompleted)
    bar:SetParent(self.control)
    
    bar:SetHidden(false)
    
    self.progressBars[#self.progressBars + 1] = bar
end

function Achievement:AddCheckBox(description, checked)
    local check, key = self.checkPool:AcquireObject()
    check.key = key
    
    ApplyTextColorToLabel(check.label, checked, ZO_SELECTED_TEXT, ZO_DISABLED_TEXT)
    check.label:SetText(zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description))
    check:SetParent(self.control)
    check:SetAlpha(checked and 1 or 0)
    check:SetHidden(false)
    
    self.checkBoxes[#self.checkBoxes + 1] = check
end

function Achievement:AddIconReward(name, icon, quality, rewardIndex)
    local iconControl, key = self.rewardIconPool:AcquireObject()
    iconControl.key = key

    iconControl.icon:SetTexture(icon)
    iconControl:SetHidden(false)
    iconControl.rewardIndex = rewardIndex
    iconControl.owner = self
    iconControl:SetParent(self.control)

    ZO_Inventory_BindSlot(iconControl, SLOT_TYPE_ACHIEVEMENT_REWARD, rewardIndex, self.achievementId)
    
    iconControl.label:SetText(name) -- Already localized
    iconControl.label:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality))
    
    self.rewardIcons[#self.rewardIcons + 1] = iconControl
end

function Achievement:GetPooledLabel(labelType, completed)
    local label, key = self.rewardLabelPool:AcquireObject()
    label.key = key
    label:SetParent(self.control)
    
    label:SetDimensions(ACHIEVEMENT_REWARD_LABEL_WIDTH, ACHIEVEMENT_REWARD_LABEL_HEIGHT)
    if labelType == PREFIX_LABEL then
        label:SetDimensions(0, ACHIEVEMENT_REWARD_LABEL_HEIGHT)
    end

    ApplyTextColorToLabel(label, completed, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)

    label.prefix = nil
    label.isHeader = labelType == HEADER_LABEL
    label:SetMouseEnabled(false)
    label:SetHidden(false)
    self.rewardLabels[#self.rewardLabels + 1] = label
    return label
end

function Achievement:AddTitleReward(name, completed)
    local title = self:GetPooledLabel(nil, completed)
    title:SetText(name) -- already localized
    
    local titlePrefix = self:GetPooledLabel(PREFIX_LABEL, completed)
    titlePrefix:SetText(GetString(SI_ACHIEVEMENTS_TITLE))
    title.prefix = titlePrefix
end

function Achievement:AddDyeReward(dyeId, completed)
    local dyeName, known, rarity, hueCategory, achievementId, r, g, b, sortKey = GetDyeInfoById(dyeId)

    local dyeSwatch, key = self.dyeSwatchPool:AcquireObject()
    dyeSwatch.key = key

    dyeSwatch.icon:SetColor(1, r, g, b)

    local dyeNamePrefix = self:GetPooledLabel(PREFIX_LABEL, completed)
    dyeNamePrefix:SetText(GetString(SI_ACHIEVEMENTS_DYE))
    dyeSwatch.prefix = dyeNamePrefix

    dyeSwatch:SetHidden(false)
    dyeSwatch.owner = self
    dyeSwatch:SetParent(self.control)
    
    dyeSwatch.label:SetText(zo_strformat(SI_DYEING_SWATCH_TOOLTIP_TITLE, dyeName))
    ApplyTextColorToLabel(dyeSwatch.label, completed, ZO_NORMAL_TEXT, ZO_DISABLED_TEXT)
    
    self.dyeSwatches[#self.dyeSwatches + 1] = dyeSwatch
end

function Achievement:AddCollectibleReward(collectibleId, completed)
    local collectibleNameLabel = self:GetPooledLabel(nil, completed)

    local collectibleName, _, _, _, _, _, _, categoryType = GetCollectibleInfo(collectibleId)
    collectibleNameLabel:SetText(zo_strformat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName))

    local collectiblePrefixLabel = self:GetPooledLabel(PREFIX_LABEL, completed)
    collectiblePrefixLabel:SetText(zo_strformat(SI_ACHIEVEMENTS_COLLECTIBLE_CATEGORY, GetString("SI_COLLECTIBLECATEGORYTYPE", categoryType)))
    collectibleNameLabel.prefix = collectiblePrefixLabel
end

do
    local ORDER_PREFIX = 1
    local ORDER_POSTFIX = 2

    local function AddAchievementLineThumb(owner, achievementId, lineThumbPool, lineThumbs, queryFunction, order)
        if achievementId == 0 then return end

        if(order == ORDER_PREFIX) then        
            AddAchievementLineThumb(owner, queryFunction(achievementId), lineThumbPool, lineThumbs, queryFunction, order)
        end
        
        local points, icon, completed = select(3, GetAchievementInfo(achievementId))
    
        local lineThumb, key = lineThumbPool:AcquireObject()
        lineThumb.key = key
        
        lineThumb.icon:SetTexture(icon)
        lineThumb.label:SetText(points)
        lineThumb.achievementId = achievementId
        lineThumb.owner = owner

        if(completed) then
            ApplyColorToAchievementIcon(lineThumb, ZO_DEFAULT_ENABLED_COLOR)
            lineThumb.label:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            ApplyColorToAchievementIcon(lineThumb, ZO_DEFAULT_DISABLED_COLOR)
            lineThumb.label:SetColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
        end
        
        lineThumb:SetHidden(false)
        
        lineThumbs[#lineThumbs + 1] = lineThumb

        if(order == ORDER_POSTFIX) then        
            AddAchievementLineThumb(owner, queryFunction(achievementId), lineThumbPool, lineThumbs, queryFunction, order)
        end
    end
    
    function Achievement:RefreshExpandedLineView()
        local lineThumbPool = self.lineThumbPool
        local lineThumbs = self.lineThumbs
        local achievementId = self.achievementId
        local previousInLine = GetPreviousAchievementInLine(achievementId)
        local nextInLine = GetNextAchievementInLine(achievementId)
        local shouldAddSelfAsLine = (previousInLine ~= 0) or (nextInLine ~= 0)

        AddAchievementLineThumb(self, previousInLine, lineThumbPool, lineThumbs, GetPreviousAchievementInLine, ORDER_PREFIX)

        if(shouldAddSelfAsLine) then
            AddAchievementLineThumb(self, achievementId, lineThumbPool, lineThumbs)
        end

        AddAchievementLineThumb(self, nextInLine, lineThumbPool, lineThumbs, GetNextAchievementInLine, ORDER_POSTFIX)
    end
end

function Achievement:WouldShowLines()
    local achievementId = self.achievementId
    return GetPreviousAchievementInLine(achievementId) ~= 0 or GetNextAchievementInLine(achievementId) ~= 0
end

function Achievement:WouldHaveVisibleCriteria()
    local numCriteria = GetAchievementNumCriteria(self.achievementId)
    if(numCriteria > 1) then return true end
    if(numCriteria == 0) then return false end
    
    local _, _, numRequired = GetAchievementCriterion(self.achievementId, 1)
    if(numRequired == 1) then return false end -- This would be the only checkbox, it doesn't count as a visible criteria

    return true
end

function Achievement:HasTangibleReward()
    local hasReward = GetAchievementNumRewards(self.achievementId) > 1
    local hasCompleted = self.completed

    local prevAchievement = GetPreviousAchievementInLine(self.achievementId)
    while prevAchievement ~= 0 do
        hasReward = hasReward or GetAchievementNumRewards(prevAchievement) > 1
        hasCompleted = hasCompleted or select(5, GetAchievementInfo(prevAchievement))
        prevAchievement = GetPreviousAchievementInLine(prevAchievement)
    end

    local nextAchievement = GetNextAchievementInLine(self.achievementId)
    while nextAchievement ~= 0 do
        hasReward = hasReward or GetAchievementNumRewards(nextAchievement) > 1
        hasCompleted = hasCompleted or select(5, GetAchievementInfo(nextAchievement))
        nextAchievement = GetNextAchievementInLine(nextAchievement)
    end

    return hasReward, hasCompleted
end

function Achievement:IsExpandable()
    return self.description:WasTruncated() or self:WouldHaveVisibleCriteria() or self:HasTangibleReward() or self:WouldShowLines()
end

function Achievement:RefreshExpandedCriteria()
    local numCriteria = GetAchievementNumCriteria(self.achievementId)
    local hasMultipleCriteria = (numCriteria > 1)
    local showProgressBarDescriptions = hasMultipleCriteria
    for i = 1, numCriteria do
        local description, numCompleted, numRequired = GetAchievementCriterion(self.achievementId, i)

        if(numRequired > 1) then
            self:AddProgressBar(description, numCompleted, numRequired, showProgressBarDescriptions)
        elseif(hasMultipleCriteria and (numRequired == 1)) then
            self:AddCheckBox(description, numCompleted == 1)
        end
    end
end

local function AddRewards(self, achievementId)
    local completed = select(5, GetAchievementInfo(achievementId))
    -- get item reward
    local hasRewardItem, itemName, iconTextureName, quality = GetAchievementRewardItem(achievementId)
    if hasRewardItem then
        self:AddIconReward(itemName, iconTextureName, quality, 1)
    end

    -- get title reward
    local hasRewardTitle, titleName = GetAchievementRewardTitle(achievementId)
    if hasRewardTitle then
        self:AddTitleReward(titleName, completed)
    end

    -- get dye reward
    local hasRewardDye, dyeId = GetAchievementRewardDye(achievementId)
    if hasRewardDye then
        self:AddDyeReward(dyeId, completed)
    end

    -- get collectible reward
    local hasRewardCollectible, collectibleId = GetAchievementRewardCollectible(achievementId)
    if hasRewardCollectible then
        self:AddCollectibleReward(collectibleId, completed)
    end 
end

function Achievement:RefreshExpandedRewards()
    local numLineThumbs = #self.lineThumbs

    if numLineThumbs > 0 then
        for _, lineThumb in ipairs(self.lineThumbs) do
            local achievementId = lineThumb.achievementId
            AddRewards(self, lineThumb.achievementId)
        end
    else
        AddRewards(self, self.achievementId)
    end
end

function Achievement:RefreshRewardThumb()
    if(self.rewardThumb and self.yOffsetWhereRewardsStart) then
        self.rewardThumb:ClearAnchors()
        self.rewardThumb:SetAnchor(TOPLEFT, self.control, TOPLEFT, 42, self.yOffsetWhereRewardsStart - 6)
    end
end

function Achievement:RefreshExpandedView()
    if self.collapsed then return end
    
    self:ReleaseSharedControls()

    self:RefreshExpandedCriteria()
    self:RefreshExpandedLineView()
    self:RefreshExpandedRewards()
    
    self:PerformExpandedLayout()
    self:RefreshRewardThumb()
end

function Achievement:PlayExpandCollapseSound()
    if(not self.isExpandable) then return end

    if(self.collapsed) then
        PlaySound(SOUNDS.ACHIEVEMENT_COLLAPSED)
    else
        PlaySound(SOUNDS.ACHIEVEMENT_EXPANDED)
    end
end

function Achievement:UpdateExpandedStateIcon()
    if(self.expandedStateIcon) then
        if self.isExpandable then
            if(self.collapsed) then
                ZO_ToggleButton_SetState(self.expandedStateIcon, TOGGLE_BUTTON_CLOSED)
            else
                ZO_ToggleButton_SetState(self.expandedStateIcon, TOGGLE_BUTTON_OPEN)
            end
        else
            self.expandedStateIcon:SetHidden(true)
        end
    end
end

function Achievement:CalculateDescriptionWidth()
    local descriptionWidth = ACHIEVEMENT_DESC_WIDTH

    if self.completed then
        local widthModifier = zo_max(0, self.date:GetWidth() - ACHIEVEMENT_DATE_LABEL_EXPECTED_WIDTH)

        if widthModifier ~= 0 then
            descriptionWidth = descriptionWidth - widthModifier
        end
    end

    return descriptionWidth
end

function Achievement:Expand()
    if self.collapsed then
        self.collapsed = false

        self.description:SetDimensionConstraints(0, 0, self:CalculateDescriptionWidth(), 0)
        self:RefreshExpandedView()
        self:UpdateExpandedStateIcon()
        self:PlayExpandCollapseSound()
    end
end

function Achievement:ApplyCollapsedDescriptionConstraints()
    if self.title:DidLineWrap() then
        self.description:SetDimensionConstraints(0, 0, self:CalculateDescriptionWidth(), ACHIEVEMENT_DESC_COLLAPSED_HEIGHT / 2)
    else
        self.description:SetDimensionConstraints(0, 0, self:CalculateDescriptionWidth(), ACHIEVEMENT_DESC_COLLAPSED_HEIGHT)
    end
end

function Achievement:Collapse()
    if not self.collapsed then
        self.collapsed = true

        if(self.rewardThumb) then
            self.rewardThumb:ClearAnchors()
            self.rewardThumb:SetAnchor(TOPLEFT, self.control, TOPLEFT, 42, 58)
        end

        self:ApplyCollapsedDescriptionConstraints()
        self.control:SetHeight(ACHIEVEMENT_COLLAPSED_HEIGHT)
        self:UpdateExpandedStateIcon()
        self:PlayExpandCollapseSound()
        self:ReleaseSharedControls()
    end
end

do
    local function ReleaseControls(pool, controls)
        for i = #controls, 1, -1 do
            pool:ReleaseObject(controls[i].key)
            controls[i] = nil
        end
    end
    function Achievement:ReleaseSharedControls()
        ReleaseControls(self.checkPool, self.checkBoxes)
        ReleaseControls(self.statusBarPool, self.progressBars)
        ReleaseControls(self.rewardIconPool, self.rewardIcons)
        ReleaseControls(self.rewardLabelPool, self.rewardLabels)
        ReleaseControls(self.lineThumbPool, self.lineThumbs)
        ReleaseControls(self.dyeSwatchPool, self.dyeSwatches)
        
        self.rewardLabel = nil
    end
end

function Achievement:SetAnchor(previous)
    self.control:ClearAnchors()

    -- This ensures that we can't have orphans, but it also means that we must do things in the proper order
    -- So whenever moving an achievement in the list, you must move the achievement to its new spot BEFORE closing the gap
    if self.anchoredToAchievement then
        self.anchoredToAchievement:SetDependentAnchoredAchievement(nil)
    end

    if previous then
        self.control:SetAnchor(TOP, previous:GetControl(), BOTTOM, 0, ACHIEVEMENT_PADDING)
        previous:SetDependentAnchoredAchievement(self)
        self.anchoredToAchievement = previous
    else
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT)
        self.anchoredToAchievement = nil
    end
end

function Achievement:GetAnchoredToAchievement()
    return self.anchoredToAchievement
end

function Achievement:SetDependentAnchoredAchievement(dependentAchievement)
    self.dependentAnchoredAchievement = dependentAchievement
end

function Achievement:GetDependentAnchoredAchievement()
    return self.dependentAnchoredAchievement
end

function Achievement:GetControl()
    return self.control
end 

function Achievement:ToggleCollapse()
    if self.collapsed then
        self:Expand()
    else
        self:Collapse()
    end
end

function Achievement:Destroy()
    self.control:SetHidden(true)
    self:SetHighlightHidden(true)
    self:Collapse()
    self.rewardLabel = nil
end

function Achievement:SetHighlightHidden(hidden)
    if self.highlight then
        self.highlight:SetHidden(false) -- let alpha take care of the actual hiding

        if not self.highlightAnimation then
            self.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("JournalProgressHighlightAnimation", self.highlight)
        end

        if(hidden) then
            self.highlightAnimation:PlayBackward()
        else
            self.highlightAnimation:PlayForward()
        end
    end
end

function Achievement:OnMouseEnter()
    self:SetHighlightHidden(false)
end

function Achievement:OnMouseExit()
    self:SetHighlightHidden(true)
end

function Achievement:OnClicked(button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        self:ToggleCollapse()
    elseif(button == MOUSE_BUTTON_INDEX_RIGHT and IsChatSystemAvailableForCurrentPlatform()) then
        ClearMenu()
        AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(ZO_LinkHandler_CreateChatLink(GetAchievementLink, self:GetId())) end)
        ShowMenu(self.control)
    end
end

--[[ Popup Achievement ]]--

local PopupAchievement = Achievement:Subclass()

function PopupAchievement:New(...)
    local achievement = Achievement.New(self, ...)
    
    return achievement
end

function PopupAchievement:Initialize(parentControl, ...)
    self.parentControl = parentControl
    local achievementControl = parentControl:GetNamedChild("Achievement")
    Achievement.Initialize(self, achievementControl, ...)
    self.highlight = nil --don't want any highlights on the popup 

    self.parentControl:SetHandler("OnHide", function()
        self.lastShownLink = nil
    end)
end

function PopupAchievement:GetAchievementInfo(achievementId)
    local name, description, points, icon, completed, date, time = GetAchievementInfo(achievementId)

    --use the data from the link instead
    completed = tonumber(self.timestamp) ~= 0
    date, time = FormatAchievementLinkTimestamp(self.timestamp)

    return name, description, points, icon, completed, date, time
end

function PopupAchievement:RefreshExpandCriteriaFromDataLink(...)
    local numCriteria = select("#", ...)
    local showProgressDescriptions = (numCriteria > 1)
    for i = 1, numCriteria do
        local description, numCompleted, numRequired = GetAchievementCriterion(self.achievementId, i)
        --overwrite with data from the link
        numCompleted = select(i, ...)

        if numRequired > 1 then
            self:AddProgressBar(description, numCompleted, numRequired, showProgressDescriptions)
        elseif numRequired == 1 and showProgressDescriptions then
            --We only show basic steps if there's more than one step, otherwise the step is just the achievement
            self:AddCheckBox(description, numCompleted == 1)
        end
    end
end

function PopupAchievement:RefreshExpandedCriteria()
    self:RefreshExpandCriteriaFromDataLink(GetAchievementProgressFromLinkData(self.achievementId, self.progress))
end

function PopupAchievement:RefreshExpandedLineView()
    --Do nothing, popup achievements don't show their line information
end

function PopupAchievement:PerformExpandedLayout()
    Achievement.PerformExpandedLayout(self)
    self.parentControl:SetHeight(self.control:GetDesiredHeight())
end

function PopupAchievement:Show(id, progress, timestamp)
    self.parentControl:SetHidden(false)
    self.parentControl:BringWindowToTop()
    self.progress = progress
    self.timestamp = timestamp

    Achievement.Show(self, id)

    if self.collapsed then
        self:Expand()
    else
        self:RefreshExpandedView()
    end
end

function PopupAchievement:Hide()
    self.parentControl:SetHidden(true)
    self:Destroy()
end

--[[ Icon Achievement ]]--

local IconAchievement = ZO_Object:Subclass()

function IconAchievement:New(...)
    local iconAchievement = ZO_Object.New(self)
    iconAchievement:Initialize(...)
    return iconAchievement
end

function IconAchievement:Initialize(control)
    self.control = control
    self.icon = control:GetNamedChild("Icon")
    control.achievement = self
end

function IconAchievement:Show(achievementId)
    self.achievementId = achievementId
    local name, description, points, icon, completed, date, time = GetAchievementInfo(achievementId)
    self.name = name
    self.icon:SetTexture(icon)
    self.control:SetHidden(false)
end

function IconAchievement:Destroy()
    self.control:SetHidden(true)
    self.achievementId = nil
    self.name = nil
end

function IconAchievement:SetAnchor(previous)
    self.control:ClearAnchors()
    if previous then
        self.control:SetAnchor(TOPLEFT, previous.control, TOPRIGHT, ACHIEVEMENT_ICON_STYLE_PADDING, 0)
    else
        self.control:SetAnchor(BOTTOMLEFT, nil, BOTTOMLEFT, 0, -42)
    end
end

function IconAchievement:OnMouseEnter()
    if(self.name) then
        InitializeTooltip(AchievementTooltip, self.control, BOTTOM, 0, -5, TOP)
        AchievementTooltip:SetAchievement(self:GetId())
    end
end

function IconAchievement:OnMouseExit()
    ClearTooltip(AchievementTooltip)
end

function IconAchievement:OnClicked(button)
    if(button == MOUSE_BUTTON_INDEX_LEFT) then
        self.control.owner:ShowAchievement(GetLastCompletedAchievementInLine(self:GetId()))
    elseif(button == MOUSE_BUTTON_INDEX_RIGHT) then
        Achievement.OnClicked(self, button)
    end
end

function IconAchievement:GetId()
    return self.achievementId
end

--[[ Achievements ]]--
local Achievements = ZO_JournalProgressBook_Common:Subclass()

function Achievements:New(...)
    return ZO_JournalProgressBook_Common.New(self, ...)
end

do
    local filterData = 
    {
        SI_ACHIEVEMENT_FILTER_SHOW_ALL,
        SI_ACHIEVEMENT_FILTER_SHOW_EARNED,
        SI_ACHIEVEMENT_FILTER_SHOW_UNEARNED,
    }

    function Achievements:Initialize(control)
        ZO_JournalProgressBook_Common.Initialize(self, control)
    
        self:InitializeSummary(control)
        self:InitializeFilters(filterData)
        self:InitializeAchievementList(control)

        local achievementsScene = ZO_Scene:New("achievements", SCENE_MANAGER)
        SYSTEMS:RegisterKeyboardRootScene("achievements", achievementsScene)
        achievementsScene:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING then
                self.refreshGroups:UpdateRefreshGroups()

                self.queuedScrollToAchievement = nil
                if self.queuedShowAchievement then
                    local queuedShowAchievement = self.queuedShowAchievement
                    if not self:ShowAchievement(self.queuedShowAchievement) then
                        self.queuedScrollToAchievement = nil
                    end 
                end
            elseif newState == SCENE_SHOWN then
                if self.achievementsById and self.achievementsById[self.queuedScrollToAchievement] then
                    ZO_Scroll_ScrollControlIntoCentralView(self.contentList, self.achievementsById[self.queuedScrollToAchievement]:GetControl())
                end
            end
        end)

        LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
        LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)

        self:OnAchievementsUpdated()
    end
end

function Achievements:InitializeControls()
    ZO_JournalProgressBook_Common.InitializeControls(self)

    self.pointsDisplay = self.contents:GetNamedChild("Points")
end

function Achievements:InitializeEvents()
    local function OnAchievementsUpdated()
        if self.control:IsHidden() then
            self.refreshGroups:RefreshAll("FullUpdate")
        else
            self:OnAchievementsUpdated()
        end
    end
    
    local function OnAchievementUpdated(event, id)
        if self.control:IsHidden() then
            self.refreshGroups:RefreshSingle("AchievementUpdated", id)
        else
            self:OnAchievementUpdated(id)
        end
    end
    
    local function OnAchievementAwarded(event, name, points, id)
        if self.control:IsHidden() then
            self.refreshGroups:RefreshSingle("AchievementAwarded", id)
        else
            self:OnAchievementAwarded(id)
        end
    end
    
    self.control:RegisterForEvent(EVENT_ACHIEVEMENTS_UPDATED, OnAchievementsUpdated)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_UPDATED, OnAchievementUpdated)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_AWARDED, OnAchievementAwarded)

    self.refreshGroups = ZO_Refresh:New()
    self.refreshGroups:AddRefreshGroup("FullUpdate",
    {
        RefreshAll = function()
            self:OnAchievementsUpdated()
        end,
    })

    self.refreshGroups:AddRefreshGroup("AchievementUpdated",
    {
        RefreshSingle = function(achievementId)
            self:OnAchievementUpdated(achievementId)
        end,
    })

    self.refreshGroups:AddRefreshGroup("AchievementAwarded",
    {
        RefreshSingle = function(achievementId)
            self:OnAchievementAwarded(achievementId)
        end,
    })
end

function Achievements:OnAchievementAwarded(achievementId)
    self:UpdatePointDisplay()
    local updatedAchievement = self:OnAchievementUpdated(achievementId)
    --Move up to the top of the list
    if updatedAchievement then
        local categoryIndex, subCategoryIndex, achievementIndex = GetCategoryInfoFromAchievementId(achievementId)
        local oldIndex = updatedAchievement.index

        updatedAchievement.index = achievementIndex

        if achievementIndex >= oldIndex then
            -- there's no way for us to move down in the list, unless there's an update pending after this
            -- that will insert before this entry and push it down
            return
        end

        local oldPrevious = updatedAchievement:GetAnchoredToAchievement()
        local oldNext = updatedAchievement:GetDependentAnchoredAchievement()

        local nextAchievementId = GetAchievementId(categoryIndex, subCategoryIndex, achievementIndex + 1)
        local newNext = self.achievementsById[self:GetBaseAchievementId(nextAchievementId)]
        local newPrevious = newNext:GetAnchoredToAchievement()

        --Update anchors
        if oldNext then
            oldNext:SetAnchor(oldPrevious)
        elseif oldPrevious then
            oldPrevious:SetDependentAnchoredAchievement(nil)
        end

        updatedAchievement:SetAnchor(newPrevious)

        if newNext then
            newNext:SetAnchor(updatedAchievement)
        end
    end
end

function Achievements:OnAchievementUpdated(achievementId)
    if self:IsSummaryOpen() then
        self:UpdateSummary()
        self:RefreshRecentAchievements()
    else
        local data = self.categoryTree:GetSelectedData()
        if data then
            local selectedCategoryIndex, selectedSubCategoryIndex = self:GetCategoryIndicesFromData(data)
            local categoryIndex, subCategoryIndex = GetCategoryInfoFromAchievementId(achievementId)
            -- Only update if the achievement is in the category you're currently viewing
            -- An achievement can only be in one category, and switching categories does a full refresh anyway
            if categoryIndex == selectedCategoryIndex and subCategoryIndex == selectedSubCategoryIndex then
                self:UpdateCategoryLabels(data, SAVE_EXPANDED, DONT_REBUILD_CONTENT_LIST)
                local baseAchievementId = self:GetBaseAchievementId(achievementId)
                local updatedAchievement = self.achievementsById[baseAchievementId]

                if not updatedAchievement then
                    updatedAchievement = self.achievementPool:AcquireObject()
                    self.achievementsById[baseAchievementId] = updatedAchievement
                end

                -- Must use base here because in a line, all of the remaining achievements get an update,
                -- but you only want the lowest one that hasn't been completed
                -- e.g.: Ids 1, 2, 3.  1 complete, 2 and 3 in progress.  2 and 3 both get updates.
                -- 2 calls ZO_GetNextInProgressAchievementInLine, returns 2 as next in progress (good).
                -- 3 calls ZO_GetNextInProgressAchievementInLine, returns 3 as next in progress (bad).
                -- 1 (base for 2 AND 3) calls ZO_GetNextInProgressAchievementInLine, returns 2 as next in progress (best).
                updatedAchievement:Show(ZO_GetNextInProgressAchievementInLine(baseAchievementId))
                updatedAchievement:RefreshExpandedView()

                return updatedAchievement
            end
        end
    end
end

function Achievements:GetNumCategories()
    return GetNumAchievementCategories()
end

function Achievements:GetCategoryInfo(categoryIndex)
    return GetAchievementCategoryInfo(categoryIndex)
end

function Achievements:GetCategoryIcons(categoryIndex)
    return GetAchievementCategoryKeyboardIcons(categoryIndex)
end

function Achievements:GetSubCategoryInfo(categoryIndex, i)
    return GetAchievementSubCategoryInfo(categoryIndex, i)
end

function Achievements:LookupTreeNodeForData(categoryIndex, subCategoryIndex)
    if(categoryIndex ~= nil) then
        local categoryTable = self.nodeLookupData[categoryIndex]
        if(categoryTable ~= nil) then
            if(subCategoryIndex ~= nil) then
                return categoryTable.subCategories[subCategoryIndex]
            else
                if(categoryTable.node:IsLeaf()) then
                    return categoryTable.node
                else
                    return categoryTable.node:GetChildren()[1]
                end
            end
        end
    end
end

function Achievements:OpenCategory(categoryIndex, subCategoryIndex)
    local node = self:LookupTreeNodeForData(categoryIndex, subCategoryIndex)
    if(node) then
        self.categoryTree:SelectNode(node, ZO_TREE_AUTO_SELECT)
        return true
    end
    return false
end

function Achievements:ShowAchievement(achievementId)
    if not SCENE_MANAGER:IsShowing("achievements") then
        self.queuedShowAchievement = achievementId
        MAIN_MENU_KEYBOARD:ShowScene("achievements")

    else
        self.queuedShowAchievement = nil

        local categoryIndex, subCategoryIndex, achievementIndex = GetCategoryInfoFromAchievementId(achievementId)

        if self:OpenCategory(categoryIndex, subCategoryIndex) then
            -- convert the given achievement id into one that exists in the list of achievements
            -- this is mostly for achievements in a line
            local baseAchievementId = self:GetBaseAchievementId(achievementId)

            -- Reset filters if this achievement isn't showing
            if not self.achievementsById[baseAchievementId] then
                self:ResetFilters()
            end

            self.achievementsById[baseAchievementId]:Expand()
            self.queuedScrollToAchievement = baseAchievementId
            return true
        end
    end
    return false
end

function Achievements:InitializeAchievementList(control)
    self.achievementsById = {}

    local sharedCheckPool = ZO_ControlPool:New("ZO_AchievementCheckbox", self.contentListScrollChild)
    sharedCheckPool:SetCustomFactoryBehavior(   function(control)
                                                    control.label = control:GetNamedChild("Label")
                                                end)
    
    local sharedStatusBarPool = ZO_ControlPool:New("ZO_AchievementsAchievementStatusBar", self.contentListScrollChild)
    sharedStatusBarPool:SetCustomFactoryBehavior(   function(control)
                                                        control.label = control:GetNamedChild("Label")
                                                        control.progress = control:GetNamedChild("Progress")
                                                        ZO_StatusBar_SetGradientColor(control, ZO_XP_BAR_GRADIENT_COLORS)

                                                        control:GetNamedChild("BGLeft"):SetDrawLevel(2)
                                                        control:GetNamedChild("BGRight"):SetDrawLevel(2)
                                                        control:GetNamedChild("BGMiddle"):SetDrawLevel(2)
                                                    end)
    
    local sharedRewardLabelPool = ZO_ControlPool:New("ZO_AchievementRewardLabel", self.contentListScrollChild)
  
    local sharedRewardIconPool = ZO_ControlPool:New("ZO_AchievementRewardItem", self.contentListScrollChild)
    sharedRewardIconPool:SetCustomFactoryBehavior(  function(control)
                                                        control.label = control:GetNamedChild("Label")
                                                        control.icon = control:GetNamedChild("Icon")
                                                    end)
  
    local sharedLineThumbPool = ZO_ControlPool:New("ZO_AchievementLineThumb", self.contentListScrollChild)
    sharedLineThumbPool:SetCustomFactoryBehavior(  function(control)
                                                        control.label = control:GetNamedChild("Label")
                                                        control.icon = control:GetNamedChild("Icon")
                                                    end)

    local sharedDyeSwatchPool = ZO_ControlPool:New("ZO_AchievementDyeSwatch", self.contentListScrollChild)
                                                    
    
    local function CreateAchievement(objectPool)
        local achievement = ZO_ObjectPool_CreateControl("ZO_Achievement", objectPool, self.contentListScrollChild)
        achievement.owner = self
        return Achievement:New(achievement, sharedCheckPool, sharedStatusBarPool, sharedRewardLabelPool, sharedRewardIconPool, sharedLineThumbPool, sharedDyeSwatchPool)
    end
    
    local function DestroyAchievement(achievement)
        achievement:Destroy()
    end

    self.achievementPool = ZO_ObjectPool:New(CreateAchievement, DestroyAchievement)

    ZO_AchievementPopup.owner = self
    self.popup = PopupAchievement:New(ZO_AchievementPopup, sharedCheckPool, sharedStatusBarPool, sharedRewardLabelPool, sharedRewardIconPool, sharedLineThumbPool, sharedDyeSwatchPool)
end

do
    local function SaveExpandedAchievements(achievements)
        local expandedAchievements
        for achievementId, achievement in pairs(achievements) do
            if not achievement.collapsed then
                if not expandedAchievements then
                    expandedAchievements = {}
                end
                expandedAchievements[#expandedAchievements + 1] = achievementId
            end
        end
        return expandedAchievements
    end
    
    local function ExpandAchievements(achievements, achievementsToExpand)
         for i=1, #achievementsToExpand do
            local achievementId = achievementsToExpand[i]
            if achievements[achievementId] then
                achievements[achievementId]:Expand()
            end
        end
    end

    function Achievements:BuildContentList(data, keepExpanded)
        local parentData = data.parentData
        local categoryIndex, subCategoryIndex = self:GetCategoryIndicesFromData(data)
        local numAchievements = self:GetCategoryInfoFromData(data, parentData)
        
        local expandedAchievements = keepExpanded and SaveExpandedAchievements(self.achievementsById)
        
        self:LayoutAchievements(ZO_GetAchievementIds(categoryIndex, subCategoryIndex, numAchievements))
        
        if expandedAchievements then
            ExpandAchievements(self.achievementsById, expandedAchievements)
        end
    end
end

function Achievements:UpdateCategoryLabels(data, saveExpanded, dontRebuildContentList)
    ZO_JournalProgressBook_Common.UpdateCategoryLabels(self, data)
    local parentData = data.parentData

    local numEntries, earnedPoints, totalPoints, hidesEarned = self:GetCategoryInfoFromData(data, parentData)

    self.categoryProgress:SetHidden(hidesEarned)

    if not hidesEarned then
        self.categoryProgress:SetMinMax(0, totalPoints)
        self.categoryProgress:SetValue(earnedPoints)
    end

    if not dontRebuildContentList then
        self:BuildContentList(data, saveExpanded)
    end
end

function Achievements:GetBaseAchievementId(achievementId)
    local baseAchievementId = GetFirstAchievementInLine(achievementId)
    -- the achievement might not be in a line so return the achievementId itself
    if baseAchievementId == 0 then
        baseAchievementId = achievementId
    end

    return baseAchievementId
end

function Achievements:LayoutAchievements(achievements)
    self.achievementPool:ReleaseAllObjects()
    ZO_ClearTable(self.achievementsById)
    ZO_Scroll_ResetToTop(self.contentList)

    local previous
    for i=1, #achievements do
        local id = achievements[i]
        if(ZO_ShouldShowAchievement(self.categoryFilter.filterType, id)) then
            local achievement = self.achievementPool:AcquireObject()
            local baseAchievementId = self:GetBaseAchievementId(id)
            self.achievementsById[baseAchievementId] = achievement
            achievement.index = i

            achievement:Show(ZO_GetNextInProgressAchievementInLine(id))

            achievement:SetAnchor(previous)
            previous = achievement
        end
    end
end

function Achievements:LayoutAchievementsIconStyle(...)
    self.iconAchievementPool:ReleaseAllObjects()

    local previous
    for i = 1, select("#", ...) do
        local id = select(i, ...)
        local achievement = self.iconAchievementPool:AcquireObject()
        achievement:Show(id)
        
        achievement:SetAnchor(previous)
        previous = achievement
    end
end

function Achievements:InitializeSummary(control)
    ZO_JournalProgressBook_Common.InitializeSummary(self, control, GetString(SI_ACHIEVEMENTS_OVERALL), GetString(SI_ACHIEVEMENTS_RECENT))

    -- Recent achievements as icon displays
    local function CreateIconAchievement(objectPool)
        local achievement = ZO_ObjectPool_CreateControl("ZO_IconAchievement", objectPool, self.summaryInset)
        achievement.owner = self
        return IconAchievement:New(achievement)
    end

    local function DestroyIconAchievement(achievement)
        achievement:Destroy()
    end

    self.iconAchievementPool = ZO_ObjectPool:New(CreateIconAchievement, DestroyIconAchievement)
end

function Achievements:RefreshRecentAchievements()
    self:LayoutAchievementsIconStyle(GetRecentlyCompletedAchievements(NUM_RECENT_ACHIEVEMENTS_TO_SHOW))
end

function Achievements:UpdateSummary()
    self.summaryStatusBarPool:ReleaseAllObjects()
    
    self:UpdateStatusBar(self.summaryTotal, nil, GetEarnedAchievementPoints(), GetTotalAchievementPoints(), 0, nil, FORCE_HIDE_PROGRESS_TEXT)
    
    local numCategories = zo_min(self:GetNumCategories(), MAX_SUMMARY_CATEGORIES)
    local secondColumnStart = zo_ceil(numCategories / 2)
    
    local yOffset = SUMMARY_CATEGORY_PADDING
    for i=1, numCategories do
        local name, _, numAchievements, earnedPoints, totalPoints, hidesPoints = self:GetCategoryInfo(i)
        
        local statusBar = self.summaryStatusBarPool:AcquireObject()
        self:UpdateStatusBar(statusBar, name, earnedPoints, totalPoints, numAchievements, hidesPoints, FORCE_HIDE_PROGRESS_TEXT)
        statusBar:ClearAnchors()

        if i % 2 == 0 then
            statusBar:SetAnchor(TOPRIGHT, self.summaryTotal, BOTTOMRIGHT, 0, yOffset)
            yOffset = yOffset + SUMMARY_CATEGORY_PADDING + SUMMARY_CATEGORY_BAR_HEIGHT
        else
            statusBar:SetAnchor(TOPLEFT, self.summaryTotal, BOTTOMLEFT, 0, yOffset)
        end
    end
end

function Achievements:ShowSummary()
    ZO_JournalProgressBook_Common.ShowSummary(self)
    self:RefreshRecentAchievements()
end

function Achievements:OnAchievementsUpdated()
    self:BuildCategories()
    self:UpdateSummary()
    self:UpdatePointDisplay()
    if self:IsSummaryOpen() then
        self:RefreshRecentAchievements()
    end
end

function Achievements:UpdatePointDisplay()
    local points = zo_strformat(SI_ACHIEVEMENTS_POINTS_LABEL, GetEarnedAchievementPoints(), GetTotalAchievementPoints())
    self.pointsDisplay:SetText(points)
end

function Achievements:ShowAchievementPopup(id, progress, timestamp)
    self.popup:Show(id, progress, timestamp)
end

function Achievements:OnLinkClicked(link, button, text, color, linkType, ...)
    if linkType == ACHIEVEMENT_LINK_TYPE and button == MOUSE_BUTTON_INDEX_LEFT then
        if self.popup.lastShownLink == link then
            self.popup:Hide()
        else
            local id, progress, timestamp = ...
            self:ShowAchievementPopup(tonumber(id), progress, timestamp)
            self.popup.lastShownLink = link
            ZO_PopupTooltip_Hide()
        end
        return true
    else
        self.popup:Hide()
    end
end

--[[ XML Handlers ]]--
function ZO_Achievements_OnInitialize(self)
    ACHIEVEMENTS = Achievements:New(self)
    SYSTEMS:RegisterKeyboardObject("achievements", ACHIEVEMENTS)
end

function ZO_Achievement_OnMouseEnter(control)
    control.achievement:OnMouseEnter()
end

function ZO_Achievement_OnMouseExit(control)
    control.achievement:OnMouseExit()
end

function ZO_Achievement_Reward_OnMouseEnter(control)
    local parent = control.owner.control
    parent.rewardIndex = control.rewardIndex
    ZO_InventorySlot_OnMouseEnter(parent)
    ZO_Achievement_OnMouseEnter(parent)
end

function ZO_Achievement_Reward_OnMouseExit(control)
    local parent = control.owner.control
    ZO_InventorySlot_OnMouseExit(parent)
    ZO_Achievement_OnMouseExit(parent)
end

function ZO_Achievement_Reward_OnMouseUp(control)
    ZO_InventorySlot_OnSlotClicked(control, 2)
end

function ZO_Achievement_Line_OnMouseEnter(control)
    local parent = control.owner.control
    
    InitializeTooltip(AchievementTooltip, control, BOTTOM, 0, -5, TOP)
    AchievementTooltip:SetAchievement(control.achievementId)

    ZO_Achievement_OnMouseEnter(parent)
end

function ZO_Achievement_Line_OnMouseExit(control)
    local parent = control.owner.control
    ZO_Achievement_OnMouseExit(parent)
    
    SetTooltipText(AchievementTooltip, nil)
end