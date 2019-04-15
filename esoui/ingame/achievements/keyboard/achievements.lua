local SUMMARY_CATEGORY_BAR_HEIGHT = 16
local SUMMARY_CATEGORY_PADDING = 50
local SUMMARY_STATUS_BAR_WIDTH = 240

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
local ACHIEVEMENT_STATUS_BAR_WIDTH = 345
local ACHIEVEMENT_STATUS_BAR_HEIGHT = 20
local ACHIEVEMENT_REWARD_LABEL_WIDTH = 230
local ACHIEVEMENT_REWARD_LABEL_HEIGHT = 20
local ACHIEVEMENT_REWARD_ICON_HEIGHT = 45

local ACHIEVEMENT_DATE_LABEL_EXPECTED_WIDTH = 60

local NUM_RECENT_ACHIEVEMENTS_TO_SHOW = 6

local SAVE_EXPANDED = true

local PREFIX_LABEL = 1
local HEADER_LABEL = 2

local FORCE_HIDE_PROGRESS_TEXT = true

ZO_ACHIEVEMENT_DISABLED_COLOR = ZO_ColorDef:New(0.6, 0.6, 0.6)
ZO_ACHIEVEMENT_DISABLED_DESATURATION = 0.5

local function GetTextColor(enabled, normalColor, disabledColor)
    if enabled then
        return (normalColor or ZO_NORMAL_TEXT):UnpackRGBA()
    end
    return (disabledColor or ZO_ACHIEVEMENT_DISABLED_COLOR):UnpackRGBA()
end

function ZO_Achievements_ApplyTextColorToLabel(label, ...)
    label:SetColor(GetTextColor(...))
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

    if self.highlight then
        self.highlight:SetHeight(ACHIEVEMENT_COLLAPSED_HEIGHT)
    end
end

function Achievement:GetId()
    return self.achievementId
end

function Achievement:GetAchievementInfo(achievementId)
    return GetAchievementInfo(achievementId)
end

function Achievement:GetIndex()
    return self.index
end

function Achievement:SetIndex(index)
    self.index = index
end

function Achievement:Show(achievementId)
    self.achievementId = achievementId
    local name, description, points, icon, completed, date, time = self:GetAchievementInfo(achievementId)

    self.title:SetText(zo_strformat(name))
    self.description:SetText(zo_strformat(description))
    self.icon:SetTexture(icon)

    self.points:SetHidden(points == ACHIEVEMENT_POINT_LEGENDARY_DEED)
    self.points:SetText(tostring(points))

    ZO_Achievements_ApplyTextColorToLabel(self.points, completed, ZO_SELECTED_TEXT)
    ZO_Achievements_ApplyTextColorToLabel(self.title, completed, ZO_SELECTED_TEXT)
    ZO_Achievements_ApplyTextColorToLabel(self.description, completed)

    if self.highlight then
        local highlightColor
        if completed then
            highlightColor = ZO_DEFAULT_ENABLED_COLOR
        else
            highlightColor = ZO_ACHIEVEMENT_DISABLED_COLOR
        end
        self.highlight:GetNamedChild("Top"):SetColor(highlightColor:UnpackRGBA())
        self.highlight:GetNamedChild("Middle"):SetColor(highlightColor:UnpackRGBA())
        self.highlight:GetNamedChild("Bottom"):SetColor(highlightColor:UnpackRGBA())
    end
    
    self.completed = completed

    if completed then
        self.date:SetHidden(false)
        self.date:SetText(date)
        self.icon:SetDesaturation(0)
    else
        self.date:SetHidden(true)
        self.icon:SetDesaturation(ZO_ACHIEVEMENT_DISABLED_DESATURATION)
    end
    
    -- Date strings might overlap the description, so apply dimension constraints after setting the completion date
    self:ApplyCollapsedDescriptionConstraints()

    --Whether we need to expand partly depends on if the description will be truncated in collapsed mode which depends on its constraints being set above.
    self.isExpandable = self:IsExpandable()

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
    ZO_Achievements_ApplyTextColorToLabel(bar.label, numCompleted == numRequired, ZO_SELECTED_TEXT)

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
    
    ZO_Achievements_ApplyTextColorToLabel(check.label, checked, ZO_SELECTED_TEXT)
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

    ZO_Achievements_ApplyTextColorToLabel(label, completed)

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
    ZO_Achievements_ApplyTextColorToLabel(dyeSwatch.label, completed)
    
    self.dyeSwatches[#self.dyeSwatches + 1] = dyeSwatch
end

function Achievement:AddCollectibleReward(collectibleId, completed)
    local collectibleNameLabel = self:GetPooledLabel(nil, completed)

    local collectibleData = ZO_COLLECTIBLE_DATA_MANAGER:GetCollectibleDataById(collectibleId)

    collectibleNameLabel:SetText(collectibleData:GetFormattedName())

    local collectiblePrefixLabel = self:GetPooledLabel(PREFIX_LABEL, completed)
    collectiblePrefixLabel:SetText(zo_strformat(SI_ACHIEVEMENTS_COLLECTIBLE_CATEGORY, collectibleData:GetCategoryTypeDisplayName()))
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
            lineThumb.icon:SetDesaturation(0)
            lineThumb.label:SetColor(ZO_DEFAULT_ENABLED_COLOR:UnpackRGBA())
        else
            lineThumb.icon:SetDesaturation(ZO_ACHIEVEMENT_DISABLED_DESATURATION)
            lineThumb.label:SetColor(ZO_ACHIEVEMENT_DISABLED_COLOR:UnpackRGBA())
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

        self:RemoveCollapsedDescriptionConstraints()
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

function Achievement:RemoveCollapsedDescriptionConstraints()
    self.description:SetDimensionConstraints(0, 0, self:CalculateDescriptionWidth(), 0)
end

function Achievement:Collapse()
    if not self.collapsed then
        self.collapsed = true

        if self.rewardThumb then
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

function Achievement:SetAnchoredToAchievement(previous)
    self.control:ClearAnchors()

    -- This ensures that we can't have orphans, but it also means that we must do things in the proper order
    -- So whenever moving an achievement in the list, you must move the achievement to its new spot BEFORE closing the gap
    if self.anchoredToAchievement then
        self.anchoredToAchievement:SetDependentAnchoredAchievement(nil)
        self.anchoredToAchievement = nil
    end

    if previous then
        self.control:SetAnchor(TOP, previous:GetControl(), BOTTOM, 0, ACHIEVEMENT_PADDING)
        previous:SetDependentAnchoredAchievement(self)
        self.anchoredToAchievement = previous
    else
        self.control:SetAnchor(TOPLEFT, nil, TOPLEFT)
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

function Achievement:Reset()
    self.control:SetHidden(true)
    self:SetHighlightHidden(true)
    self:Collapse()
    self.rewardLabel = nil
    self:SetIndex(nil)

    self.anchoredToAchievement = nil
    self:SetDependentAnchoredAchievement(nil)
end

function Achievement:SetHighlightHidden(hidden)
    if self.highlight then
        self.highlight:SetHidden(false) -- let alpha take care of the actual hiding

        if not self.highlightAnimation then
            self.highlightAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("AchievementHighlightAnimation_Keyboard", self.highlight)
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

--[[ Achievement Container ]]--

local AchievementContainer = Achievement:Subclass()

function AchievementContainer:New(...)
    local achievement = Achievement.New(self, ...)
    
    return achievement
end

function AchievementContainer:Initialize(parentControl, ...)
    self.parentControl = parentControl
    local achievementControl = parentControl:GetNamedChild("Achievement")
    Achievement.Initialize(self, achievementControl, ...)
    self.highlight = nil --don't want any highlights on the popup 
end

function AchievementContainer:PerformExpandedLayout()
    Achievement.PerformExpandedLayout(self)
    self.parentControl:SetHeight(self.control:GetDesiredHeight())
end

function AchievementContainer:Show(id, progress, timestamp)
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

function AchievementContainer:Hide()
    self.parentControl:SetHidden(true)
    self:Reset()
end

--[[ Popup Achievement ]]--

local PopupAchievement = AchievementContainer:Subclass()

function PopupAchievement:New(...)
    return AchievementContainer.New(self, ...)
end

function PopupAchievement:Initialize(parentControl, ...)
    AchievementContainer.Initialize(self, parentControl, ...)

    self.parentControl:SetHandler("OnHide", function()
        self.lastShownLink = nil
    end)
end

function PopupAchievement:GetAchievementInfo(achievementId)
    local name, description, points, icon = GetAchievementInfo(achievementId)

    --use the data from the link instead
    local completed = tonumber(self.timestamp) ~= 0
    local date, time = FormatAchievementLinkTimestamp(self.timestamp)

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

function PopupAchievement:HasTangibleReward()
    local hasReward = GetAchievementNumRewards(self.achievementId) > 1
    local hasCompleted = self.completed

    return hasReward, hasCompleted
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

function IconAchievement:Reset()
    self.control:SetHidden(true)
    self.achievementId = nil
    self.name = nil
end

function IconAchievement:SetAnchor(previous)
    self.control:ClearAnchors()
    if previous then
        self.control:SetAnchor(TOPLEFT, previous.control, TOPRIGHT, ACHIEVEMENT_ICON_STYLE_PADDING, 0)
    else
        self.control:SetAnchor(BOTTOMLEFT, nil, BOTTOMLEFT, 0, -32)
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
    if button == MOUSE_BUTTON_INDEX_LEFT then
        self.control.owner:ShowAchievement(self:GetId())
    elseif button == MOUSE_BUTTON_INDEX_RIGHT then
        Achievement.OnClicked(self, button)
    end
end

function IconAchievement:GetId()
    return self.achievementId
end

--[[ Achievements ]]--
local Achievements = ZO_Object:Subclass()

function Achievements:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

do
    local filterData = 
    {
        SI_ACHIEVEMENT_FILTER_SHOW_ALL,
        SI_ACHIEVEMENT_FILTER_SHOW_EARNED,
        SI_ACHIEVEMENT_FILTER_SHOW_UNEARNED,
    }

    function Achievements:Initialize(control)
        self.control = control

        self:InitializeControls()
        self:InitializeCategories()
        self:InitializeSummary()
        self:InitializeFilters(filterData)
        self:InitializeAchievementList(control)

        self.scene = ZO_Scene:New("achievements", SCENE_MANAGER)
        SYSTEMS:RegisterKeyboardRootScene("achievements", self.scene)
        self.scene:RegisterCallback("StateChange", function(oldState, newState)
            if newState == SCENE_SHOWING then
                self.refreshGroups:UpdateRefreshGroups()

                self.queuedScrollToAchievement = nil
                if self.queuedShowAchievement then
                    if not self:ShowAchievement(self.queuedShowAchievement) then
                        self.queuedScrollToAchievement = nil
                    end
                end
                ACHIEVEMENTS_MANAGER:SetSearchString(self.contentSearchEditBox:GetText())
            elseif newState == SCENE_SHOWN then
                if self.achievementsById and self.achievementsById[self.queuedScrollToAchievement] then
                    ZO_Scroll_ScrollControlIntoCentralView(self.contentList, self.achievementsById[self.queuedScrollToAchievement]:GetControl())
                end
            end
        end)

        self:InitializeEvents()

        self:OnAchievementsUpdated()
    end
end

function Achievements:InitializeControls()
    self.contents = self.control:GetNamedChild("Contents")
    self.contentList = self.contents:GetNamedChild("ContentList")
    self.contentListScrollChild = self.contentList:GetNamedChild("ScrollChild")
    self.categoryInset = self.control:GetNamedChild("Category")
    self.categoryLabel = self.categoryInset:GetNamedChild("Title")
    self.categoryProgress = self.categoryInset:GetNamedChild("Progress")
    self.categoryFilter = self.categoryInset:GetNamedChild("Filter")
    self.contentSearchEditBox = self.contents:GetNamedChild("SearchBox")
    ZO_StatusBar_SetGradientColor(self.categoryProgress, ZO_XP_BAR_GRADIENT_COLORS)
end

function Achievements:InitializeCategories()
    self.categories = self.control:GetNamedChild("ContentsCategories")
    self.categoryTree = ZO_Tree:New(self.categories:GetNamedChild("ScrollChild"), 60, -10, 300)
    self.nodeLookupData = {}

    local function BaseTreeHeaderIconSetup(control, data, open)
        local iconTexture = (open and data.pressedIcon or data.normalIcon) or ZO_NO_TEXTURE_FILE
        local mouseoverTexture = data.mouseoverIcon or ZO_NO_TEXTURE_FILE
        
        control.icon:SetTexture(iconTexture)
        control.iconHighlight:SetTexture(mouseoverTexture)

        ZO_IconHeader_Setup(control, open)
    end

    local function BaseTreeHeaderSetup(node, control, data, open)
        control.text:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        control.text:SetText(data.name)
        BaseTreeHeaderIconSetup(control, data, open)
    end

    local function TreeHeaderSetup_Child(node, control, data, open, userRequested)
        BaseTreeHeaderSetup(node, control, data, open)

        if(open and userRequested) then
            self.categoryTree:SelectFirstChild(node)
        end
    end

    local function TreeHeaderSetup_Childless(node, control, data, open)
        BaseTreeHeaderSetup(node, control, data, open)
    end

    local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        control:SetSelected(selected)

        if selected and (not reselectingDuringRebuild or self.forceUpdateContentOnCategoryReselect) then
            local saveExpanded = reselectingDuringRebuild
            self:OnCategorySelected(data, saveExpanded)
        end
    end

    local function TreeEntryOnSelected_Childless(control, data, selected, reselectingDuringRebuild)
        TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
        BaseTreeHeaderIconSetup(control, data, selected)
    end

    local function TreeEntrySetup(node, control, data, open)
        control:SetSelected(false)
        control:SetText(data.name)
    end

    local function TreeEqualityFunction(left, right)
        if left.categoryIndex == right.categoryIndex then
            if left.parentData and right.parentData then
                return left.parentData.categoryIndex == right.parentData.categoryIndex
            elseif not (left.parentData or right.parentData) then
                return true
            end
        end
        return false
    end

    local CHILD_INDENT = 60
    local CHILD_SPACING = 0
    self.categoryTree:AddTemplate("ZO_IconHeader", TreeHeaderSetup_Child, nil, TreeEqualityFunction, CHILD_INDENT, CHILD_SPACING)
    self.categoryTree:AddTemplate("ZO_IconChildlessHeader", TreeHeaderSetup_Childless, TreeEntryOnSelected_Childless, TreeEqualityFunction)
    self.categoryTree:AddTemplate("ZO_TreeLabelSubCategory", TreeEntrySetup, TreeEntryOnSelected, TreeEqualityFunction)

    self.categoryTree:SetExclusive(true)
    self.categoryTree:SetOpenAnimation("ZO_TreeOpenAnimation")
end

function Achievements:InitializeEvents()
    local function OnAchievementsUpdated()
        self.refreshGroups:RefreshAll("FullUpdate")
    end

    local function OnAchievementUpdated(event, id)
        self.refreshGroups:RefreshSingle("AchievementUpdated", id)
    end

    local function OnAchievementAwarded(event, name, points, id)
        self.refreshGroups:RefreshSingle("AchievementAwarded", id)
    end

    local function OnUpdate()
        if not self.control:IsHidden() then
            self.refreshGroups:UpdateRefreshGroups()
        end
    end

    self.control:RegisterForEvent(EVENT_ACHIEVEMENTS_UPDATED, OnAchievementsUpdated)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_UPDATED, OnAchievementUpdated)
    self.control:RegisterForEvent(EVENT_ACHIEVEMENT_AWARDED, OnAchievementAwarded)
    self.control:SetHandler("OnUpdate", OnUpdate)

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

    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, self.OnLinkClicked, self)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.OnLinkClicked, self)

    local function OnUpdateSearchResults()
        if self.scene:IsShowing() then
            self.forceUpdateContentOnCategoryReselect = true
            self:BuildCategories()
            self.forceUpdateContentOnCategoryReselect = false
        end
    end

    ACHIEVEMENTS_MANAGER:RegisterCallback("UpdateSearchResults", OnUpdateSearchResults)
end

function Achievements:InitializeFilters(filterData)
    local comboBox = ZO_ComboBox_ObjectFromContainer(self.categoryFilter)
    comboBox:SetSortsItems(false)
    comboBox:SetFont("ZoFontWinT1")
    comboBox:SetSpacing(4)
    
    local function OnFilterChanged(comboBox, entryText, entry)
        self.categoryFilter.filterType = entry.filterType
        self:RefreshVisibleCategoryFilter()
    end

    for i, stringId in ipairs(filterData) do
        local entry = comboBox:CreateItemEntry(GetString(stringId), OnFilterChanged)
        entry.filterType = stringId
        comboBox:AddItem(entry)
    end

    comboBox:SelectFirstItem()
end

function Achievements:ResetFilters() 
    ZO_ComboBox_ObjectFromContainer(self.categoryFilter):SelectFirstItem()
end

function Achievements:RefreshVisibleCategoryFilter()
    local data = self.categoryTree:GetSelectedData()
    if(data ~= nil) then
        self:OnCategorySelected(data)
    end
end

function Achievements:OnAchievementAwarded(achievementId)
    self:UpdatePointDisplay()
    local updatedAchievement = self:OnAchievementUpdated(achievementId)
    --Move up to the top of the list
    if updatedAchievement then
        local categoryIndex, subCategoryIndex, achievementIndex = GetCategoryInfoFromAchievementId(achievementId)
        local oldIndex = updatedAchievement:GetIndex()

        if oldIndex and achievementIndex == oldIndex then
            -- if the old index of the achievement matches our target index,
            -- then we should already be in the right position
            return
        end

        updatedAchievement:SetIndex(achievementIndex)

        local oldPrevious = updatedAchievement:GetAnchoredToAchievement()
        local oldNext = updatedAchievement:GetDependentAnchoredAchievement()

        -- find the achievement that comes after this one
        -- since we may have a filter applied, it might not be the very next one in the category
        -- so we'll have to search until we find one that is in self.achievementsById (i.e. currently showing)
        local newNext
        local nextAchievementIndex = achievementIndex
        local nextAchievementId = achievementId
        while nextAchievementId ~= 0 do
            nextAchievementIndex = nextAchievementIndex + 1
            nextAchievementId = GetAchievementId(categoryIndex, subCategoryIndex, nextAchievementIndex)
            if nextAchievementId == 0 then
                -- It's possible there is no next achievement, so we'll just bail here since we should be at
                -- the bottom of the list
                break
            end

            -- see if the next achievement id is in self.achievementsById and therefor being shown
            -- if this comes back as nil, then it's probably been filtered out
            newNext = self.achievementsById[self:GetBaseAchievementId(nextAchievementId)]
            if newNext then
                if newNext == updatedAchievement then
                    -- nextAchievementId could be the next achievement in the same line, so newNext could be
                    -- the same achievement as updatedAchievement, in which case we don't need to move
                    return
                else
                    break
                end
            end
        end

        -- Get the achievement that should come before our updated achievement
        -- if we didn't find a newNext then our achievement should be at the end of the list
        local newPrevious
        if newNext then
            newPrevious = newNext:GetAnchoredToAchievement()
        else
            newPrevious = self.achievementsById[#self.achievementsById]
        end

        if newPrevious == updatedAchievement then
            -- If the achievement that is the very next one happens to be anchored to
            -- updatedAchievement then newPrevious would be the same achievement as updatedAchievement
            -- and we don't need to move
            return
        end

        --Update anchors

        -- first we need to remove the updated achievement from the current chain of achievements

        -- clear the linkage between this updated achievement and the previous one (clear updatedAchievement's parent)
        updatedAchievement:SetAnchoredToAchievement(nil)

        if oldNext then
            -- if we have an achievement after the updated achievement then we need
            -- to put it beneath the updated achievement's previous achievement, if any
            -- this will also clear the linkage from oldNext to updatedAchievement (clear updatedAchievement's child)
            oldNext:SetAnchoredToAchievement(oldPrevious)
        elseif oldPrevious then
            -- if there isn't an achievement after the updated achievement
            -- then the updated achievement's previous achievement doesn't have a child achievement now
            oldPrevious:SetDependentAnchoredAchievement(nil)
        end

        -- insert the updated achievement back into the chain
        updatedAchievement:SetAnchoredToAchievement(newPrevious)

        if newNext then
            newNext:SetAnchoredToAchievement(updatedAchievement)
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
                -- We might have filtered the achievement list we are viewing, and since an achievement has updated
                -- it's possible we need to remove it from the list, so we'll just rebuild the whole list
                local dontRebuildContentList = ZO_ShouldShowAchievement(self.categoryFilter.filterType, achievementId)
                self:UpdateCategoryLabels(data, SAVE_EXPANDED, dontRebuildContentList)
                if dontRebuildContentList then
                    local baseAchievementId = self:GetBaseAchievementId(achievementId)

                    -- Must use base here because in a line, all of the remaining achievements get an update,
                    -- but you only want the lowest one that hasn't been completed
                    -- e.g.: Ids 1, 2, 3.  1 complete, 2 and 3 in progress.  2 and 3 both get updates.
                    -- 2 calls ZO_GetNextInProgressAchievementInLine, returns 2 as next in progress (good).
                    -- 3 calls ZO_GetNextInProgressAchievementInLine, returns 3 as next in progress (bad).
                    -- 1 (base for 2 AND 3) calls ZO_GetNextInProgressAchievementInLine, returns 2 as next in progress (best).
                    if ZO_GetNextInProgressAchievementInLine(baseAchievementId) == achievementId then
                        local updatedAchievement = self.achievementsById[baseAchievementId]

                        if not updatedAchievement then
                            updatedAchievement = self.achievementPool:AcquireObject()
                            self.achievementsById[baseAchievementId] = updatedAchievement
                        end

                        updatedAchievement:Show(achievementId)
                        updatedAchievement:RefreshExpandedView()

                        return updatedAchievement
                    end
                end
            end
        end
    end
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
    if node then
        self.categoryTree:SelectNode(node, ZO_TREE_AUTO_SELECT)
        return true
    end
    return false
end

function Achievements:ShowAchievement(achievementId)
    if self.contentSearchEditBox:GetText() ~= "" then
        self.contentSearchEditBox:SetText("")
        local REFRESH_IMMEDIATELY = true
        ACHIEVEMENTS_MANAGER:ClearSearch(REFRESH_IMMEDIATELY)
    end

    if not SCENE_MANAGER:IsShowing("achievements") then
        self.queuedShowAchievement = achievementId
        MAIN_MENU_KEYBOARD:ShowScene("achievements")
    else
        self.queuedShowAchievement = nil
        local lastAchievementIdInLine = GetLastCompletedAchievementInLine(achievementId)
        local categoryIndex, subCategoryIndex, achievementIndex = GetCategoryInfoFromAchievementId(lastAchievementIdInLine)

        if self:OpenCategory(categoryIndex, subCategoryIndex) then
            -- convert the given achievement id into one that exists in the list of achievements
            -- this is mostly for achievements in a line
            local baseAchievementId = self:GetBaseAchievementId(lastAchievementIdInLine)

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
    sharedCheckPool:SetCustomFactoryBehavior(   function(checkControl)
                                                    checkControl.label = checkControl:GetNamedChild("Label")
                                                end)

    local sharedStatusBarPool = ZO_ControlPool:New("ZO_AchievementsStatusBar", self.contentListScrollChild)
    sharedStatusBarPool:SetCustomFactoryBehavior(   function(statusBarControl)
                                                        statusBarControl:SetWidth(ACHIEVEMENT_STATUS_BAR_WIDTH)
                                                        statusBarControl.label = statusBarControl:GetNamedChild("Label")
                                                        statusBarControl.progress = statusBarControl:GetNamedChild("Progress")
                                                        ZO_StatusBar_SetGradientColor(statusBarControl, ZO_XP_BAR_GRADIENT_COLORS)

                                                        statusBarControl:GetNamedChild("BGLeft"):SetDrawLevel(2)
                                                        statusBarControl:GetNamedChild("BGRight"):SetDrawLevel(2)
                                                        statusBarControl:GetNamedChild("BGMiddle"):SetDrawLevel(2)
                                                    end)

    local sharedRewardLabelPool = ZO_ControlPool:New("ZO_AchievementRewardLabel", self.contentListScrollChild)

    local sharedRewardIconPool = ZO_ControlPool:New("ZO_AchievementRewardItem", self.contentListScrollChild)
    sharedRewardIconPool:SetCustomFactoryBehavior(  function(rewardIconControl)
                                                        rewardIconControl.label = rewardIconControl:GetNamedChild("Label")
                                                        rewardIconControl.icon = rewardIconControl:GetNamedChild("Icon")
                                                    end)

    local sharedLineThumbPool = ZO_ControlPool:New("ZO_AchievementLineThumb", self.contentListScrollChild)
    sharedLineThumbPool:SetCustomFactoryBehavior(  function(thumbControl)
                                                        thumbControl.label = thumbControl:GetNamedChild("Label")
                                                        thumbControl.icon = thumbControl:GetNamedChild("Icon")
                                                    end)

    local sharedDyeSwatchPool = ZO_ControlPool:New("ZO_AchievementDyeSwatch", self.contentListScrollChild)

    local function CreateAchievement(objectPool)
        local achievement = ZO_ObjectPool_CreateControl("ZO_Achievement", objectPool, self.contentListScrollChild)
        achievement.owner = self
        return Achievement:New(achievement, sharedCheckPool, sharedStatusBarPool, sharedRewardLabelPool, sharedRewardIconPool, sharedLineThumbPool, sharedDyeSwatchPool)
    end

    local function ResetAchievement(achievement)
        achievement:Reset()
    end

    self.achievementPool = ZO_ObjectPool:New(CreateAchievement, ResetAchievement)

    ZO_AchievementPopup.owner = self
    self.popup = PopupAchievement:New(ZO_AchievementPopup, sharedCheckPool, sharedStatusBarPool, sharedRewardLabelPool, sharedRewardIconPool, sharedLineThumbPool, sharedDyeSwatchPool)

    ZO_AchievementTooltip.owner = self
    self.tooltip = AchievementContainer:New(ZO_AchievementTooltip, sharedCheckPool, sharedStatusBarPool, sharedRewardLabelPool, sharedRewardIconPool, sharedLineThumbPool, sharedDyeSwatchPool)
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
         for i = 1, #achievementsToExpand do
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

        local CONSIDER_SEARCH_RESULTS = true
        self:LayoutAchievements(ZO_GetAchievementIds(categoryIndex, subCategoryIndex, numAchievements, CONSIDER_SEARCH_RESULTS))

        if expandedAchievements then
            ExpandAchievements(self.achievementsById, expandedAchievements)
        end
    end
end

function Achievements:UpdateCategoryLabels(data, saveExpanded, dontRebuildContentList)
    local parentData = data.parentData

    if parentData then
        self.categoryLabel:SetText(zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY_SUBCATEGORY, parentData.name, data.name))
    else
        self.categoryLabel:SetText(zo_strformat(SI_JOURNAL_PROGRESS_CATEGORY, data.name))
    end

    self.categoryFilter:SetHidden(false)

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

function Achievements:OnCategorySelected(data, saveExpanded)
    if data.summary then
        self:ShowSummary()
    else
        self:HideSummary()
        self:UpdateCategoryLabels(data, saveExpanded)
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
    for i = 1, #achievements do
        local id = achievements[i]
        if ZO_ShouldShowAchievement(self.categoryFilter.filterType, id) then
            local achievement = self.achievementPool:AcquireObject()
            local baseAchievementId = self:GetBaseAchievementId(id)
            self.achievementsById[baseAchievementId] = achievement
            -- i here is the same as the achievementIndex for the achievement
            achievement:SetIndex(i)

            achievement:Show(ZO_GetNextInProgressAchievementInLine(id))

            achievement:SetAnchoredToAchievement(previous)
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

function Achievements:InitializeSummary()
    local function InitializeSummaryStatusBar(statusBar)
        ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)
        statusBar.category = statusBar:GetNamedChild("Label")
        statusBar.progress = statusBar:GetNamedChild("Progress")
        statusBar:GetNamedChild("BG"):SetDrawLevel(1)
        statusBar:SetWidth(SUMMARY_STATUS_BAR_WIDTH)

        return statusBar
    end

    local control = self.control
    self.summaryInset = control:GetNamedChild("ContentsSummaryInset")
    self.summaryProgressBarsScrollChild = self.summaryInset:GetNamedChild("ProgressBarsScrollChild")
    self.summaryTotal = InitializeSummaryStatusBar(self.summaryProgressBarsScrollChild:GetNamedChild("Total"))

    self.summaryStatusBarPool = ZO_ControlPool:New("ZO_AchievementsStatusBar", self.summaryProgressBarsScrollChild)
    self.summaryStatusBarPool:SetCustomFactoryBehavior( function(statusBarControl)
                                                            InitializeSummaryStatusBar(statusBarControl)
                                                        end)

    -- Recent achievements as icon displays
    local function CreateIconAchievement(objectPool)
        local achievement = ZO_ObjectPool_CreateControl("ZO_IconAchievement", objectPool, self.summaryInset)
        achievement.owner = self
        return IconAchievement:New(achievement)
    end

    local function DestroyIconAchievement(achievement)
        achievement:Reset()
    end

    self.iconAchievementPool = ZO_ObjectPool:New(CreateIconAchievement, DestroyIconAchievement)

    self.pointsDisplay = self.summaryInset:GetNamedChild("Points")
end

function Achievements:RefreshRecentAchievements()
    self:LayoutAchievementsIconStyle(GetRecentlyCompletedAchievements(NUM_RECENT_ACHIEVEMENTS_TO_SHOW))
end


--[[ Summary ]]--
-----------------

function Achievements:UpdateSummary()
    self.summaryStatusBarPool:ReleaseAllObjects()

    self:UpdateStatusBar(self.summaryTotal, nil, GetEarnedAchievementPoints(), GetTotalAchievementPoints(), 0, nil, FORCE_HIDE_PROGRESS_TEXT)

    local numCategories = GetNumAchievementCategories()
    local yOffset = SUMMARY_CATEGORY_PADDING
    for i = 1, numCategories do
        local name, _, numAchievements, earnedPoints, totalPoints, hidesPoints = GetAchievementCategoryInfo(i)

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
    self.contentList:SetHidden(true)
    self.summaryInset:SetHidden(false)
    self.categoryLabel:SetText(GetString(SI_JOURNAL_PROGRESS_SUMMARY))
    self.categoryProgress:SetHidden(true)
    self.categoryFilter:SetHidden(true)

    self:RefreshRecentAchievements()
    self:UpdateSummary()
end

function Achievements:HideSummary()
    self.contentList:SetHidden(false)
    self.summaryInset:SetHidden(true)
end

function Achievements:IsSummaryOpen()
    local data = self.categoryTree:GetSelectedData()
    return data and data.summary
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

function Achievements:UpdateStatusBar(statusBar, category, earned, total, numEntries, hidesUnearned, hideProgressText)
    if category then
        statusBar.category:SetModifyTextType(MODIFY_TEXT_TYPE_UPPERCASE)
        statusBar.category:SetText(category)
    end

    statusBar:SetMinMax(0, zo_max(hidesUnearned and 1 or total, 1))
    statusBar:SetValue(earned)

    if hideProgressText then
        if hidesUnearned then
            if numEntries > 0 then
                statusBar.progress:SetText(numEntries)
            else
                statusBar.progress:SetHidden(true)
            end
        else
            statusBar.progress:SetText(zo_strformat(SI_JOURNAL_PROGRESS_BAR_PROGRESS, ZO_CommaDelimitNumber(earned), ZO_CommaDelimitNumber(total)))
        end
    else
        statusBar.progress:SetHidden(true)
    end    

    statusBar:SetHidden(false)
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

function Achievements:ShowAchievementDetailedTooltip(id, anchor)
    self.tooltip.parentControl:ClearAnchors()
    anchor:Set(self.tooltip.parentControl)

    local progress = GetAchievementProgress(id)
    local timestamp = GetAchievementTimestamp(id)
    self.tooltip:Show(id, progress, timestamp)
end

function Achievements:HideAchievementDetailedTooltip()
    self.tooltip:Hide()
end

function Achievements:GetAchievementDetailedTooltipControl()
    return self.tooltip.parentControl
end

--[[ Categories ]]--
--------------------

function Achievements:GetCategoryIndicesFromData(data)
    if not data.isFakedSubcategory and data.parentData then
        return data.parentData.categoryIndex, data.categoryIndex
    end
        
    return data.categoryIndex
end

function Achievements:GetCategoryInfoFromData(data, parentData)
    if not data.isFakedSubcategory and parentData then
        return select(2, GetAchievementSubCategoryInfo(parentData.categoryIndex, data.categoryIndex))
    else
        --The general category includes all achievements that aren't assigned a specific subcategory. We get the total number of points
        --under the top level level category then subtracts all of the points that are attributed to a specific subcategory to get the stats for general.
        local numSubCategories, numAchievements, earnedPoints, totalPoints, hidesPoints = select(2, GetAchievementCategoryInfo(data.categoryIndex))
        if parentData then
            for subCategoryIndex = 1, numSubCategories do
                local subCategoryEarned, subCategoryTotal = select(3, GetAchievementSubCategoryInfo(parentData.categoryIndex, subCategoryIndex))
                earnedPoints = earnedPoints - subCategoryEarned
                totalPoints = totalPoints - subCategoryTotal
            end
        end
        return numAchievements, earnedPoints, totalPoints, hidesPoints
    end
end

function Achievements:GetLookupNodeByCategory(categoryIndex, subcategoryIndex)
    if self.nodeLookupData then
        local node = self.nodeLookupData[categoryIndex]
        if node then
            local subNode = node.subCategories[subcategoryIndex or ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY]
            return subNode or node.node
        end
    end
    return nil
end

function Achievements:BuildCategories()
    self.categoryTree:Reset()
    ZO_ClearTable(self.nodeLookupData)

    --Special summary blade
    self:AddTopLevelCategory(nil, GetString(SI_JOURNAL_PROGRESS_SUMMARY), 0)

    local function AddCategoryByCategoryIndex(categoryIndex)
        local name, numSubCategories, _, _, _, hidesUnearned = GetAchievementCategoryInfo(categoryIndex)
        local normalIcon, pressedIcon, mouseoverIcon = GetAchievementCategoryKeyboardIcons(categoryIndex)
        self:AddTopLevelCategory(categoryIndex, name, numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
    end

    local searchResults = ACHIEVEMENTS_MANAGER:GetSearchResults()
    if searchResults then
        for categoryIndex, data in pairs(searchResults) do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    else
        for categoryIndex = 1, GetNumAchievementCategories() do
            AddCategoryByCategoryIndex(categoryIndex)
        end
    end

    self.categoryTree:Commit()
end

do
    local function AddNodeLookup(lookup, node, parent, categoryIndex)
        if(categoryIndex ~= nil) then
            local parentCategory = categoryIndex
            local subCategory

            if(parent) then
                parentCategory = parent.data.categoryIndex
                subCategory = categoryIndex
            end

            local categoryTable = lookup[parentCategory]
            
            if(categoryTable == nil) then
                categoryTable = { subCategories = {} }
                lookup[parentCategory] = categoryTable
            end

            if(subCategory) then
                categoryTable.subCategories[subCategory] = node
            else
                categoryTable.node = node
            end
        end
    end

    function Achievements:AddCategory(lookup, tree, nodeTemplate, parent, categoryIndex, name, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon, isSummary, isFakedSubcategory)
        local entryData = 
        {
            isFakedSubcategory = isFakedSubcategory,
            categoryIndex = categoryIndex, 
            name = name, 
            hidesUnearned = hidesUnearned,
            summary = isSummary,
            parentData = parent and parent.data or nil,
            normalIcon = normalIcon, 
            pressedIcon = pressedIcon, 
            mouseoverIcon = mouseoverIcon,
        }

        local node = tree:AddNode(nodeTemplate, entryData, parent)
        entryData.node = node
        local finalCategoryIndex = isFakedSubcategory and ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY or categoryIndex
        AddNodeLookup(lookup, node, parent, finalCategoryIndex)
        return node
    end

    local SUMMARY_ICONS =
    {
        "esoui/art/treeicons/achievements_indexicon_summary_up.dds",
        "esoui/art/treeicons/achievements_indexicon_summary_down.dds",
        "esoui/art/treeicons/achievements_indexicon_summary_over.dds",
    }

    function Achievements:AddTopLevelCategory(categoryIndex, name, numSubCategories, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon)
        local isSummary = categoryIndex == nil
        local tree = self.categoryTree
        local lookup = self.nodeLookupData
        local searchResults = ACHIEVEMENTS_MANAGER:GetSearchResults()

        local hasChildren = numSubCategories > 0
        local nodeTemplate = hasChildren and "ZO_IconHeader" or "ZO_IconChildlessHeader"
        local hasFakedSubcategory = false

        if isSummary then
            normalIcon, pressedIcon, mouseoverIcon = unpack(SUMMARY_ICONS)
        elseif searchResults then
            hasFakedSubcategory = hasChildren and searchResults[categoryIndex][ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY] ~= nil
        else
            local numTopLevelAchievements = select(3, GetAchievementCategoryInfo(categoryIndex))
            hasFakedSubcategory = hasChildren and numTopLevelAchievements > 0
        end

        local parentNode = self:AddCategory(lookup, tree, nodeTemplate, nil, categoryIndex, name, hidesUnearned, normalIcon, pressedIcon, mouseoverIcon, isSummary)

        -- We only want to add a general subcategory if we have any subcategories and we have any entries in the main category
        -- Otherwise we'd have an emtpy general category
        if hasFakedSubcategory then
            local IS_FAKED_SUBCATEGORY = true
            local NO_ICONS = nil
            self:AddCategory(lookup, tree, "ZO_TreeLabelSubCategory", parentNode, categoryIndex, GetString(SI_JOURNAL_PROGRESS_CATEGORY_GENERAL), hidesUnearned, NO_ICONS, NO_ICONS, NO_ICONS, NOT_SUMMARY, IS_FAKED_SUBCATEGORY)
        end

        if not isSummary then
            if searchResults then
                for subcategoryIndex, data in pairs(searchResults[categoryIndex]) do
                    if subcategoryIndex ~= ZO_COLLECTIONS_SEARCH_ROOT then
                        local subCategoryName, _, _, _, subcategoryHidesUnearned = GetAchievementSubCategoryInfo(categoryIndex, subcategoryIndex)
                        self:AddCategory(lookup, tree, "ZO_TreeLabelSubCategory", parentNode, subcategoryIndex, subCategoryName, subcategoryHidesUnearned)
                    end
                end
            else
                for subcategoryIndex = 1, numSubCategories do
                    local subCategoryName, _, _, _, subcategoryHidesUnearned = GetAchievementSubCategoryInfo(categoryIndex, subcategoryIndex)
                    self:AddCategory(lookup, tree, "ZO_TreeLabelSubCategory", parentNode, subcategoryIndex, subCategoryName, subcategoryHidesUnearned)
                end
            end
        end

        return parentNode
    end
end

--[[ XML Handlers ]]--

function ZO_Achievements_OnInitialize(self)
    ACHIEVEMENTS = Achievements:New(self)
    SYSTEMS:RegisterKeyboardObject("achievements", ACHIEVEMENTS)
end

function ZO_Achievements_OnSearchTextChanged(editBox)
    ZO_EditDefaultText_OnTextChanged(editBox)
    ACHIEVEMENTS_MANAGER:SetSearchString(editBox:GetText())
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