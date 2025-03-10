ZO_GAMEPAD_MARKET_PAGE_LEFT_DIRECTION = 1
ZO_GAMEPAD_MARKET_PAGE_RIGHT_DIRECTION = 2
ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION = 3 -- No movement, only fading
ZO_GAMEPAD_MARKET_GRID_INITIAL_X_OFFSET = 22
ZO_GAMEPAD_MARKET_GRID_INITIAL_Y_OFFSET = 62

local NUM_VISIBLE_ROWS = 2
local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100

ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCTS_PER_ROW = 3
ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_PADDING = 5
ZO_GAMEPAD_MARKET_PRODUCT_PADDING = 12

local INDIVIDUAL_PRODUCT_HALF_HEIGHT = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT / 2

local FOCUS_MOVEMENT_TYPES = 
{
    MOVE_NEXT = 1,
    MOVE_PREVIOUS = 2,
}

--[[
    Gamepad Grid Focus

    Similar to ZO_GamepadFocus but supports two dimensional layouts.
    Entries must be added left -> right, top -> bottom, row by row
--]]

local GamepadGridFocus = ZO_GamepadFocus:Subclass()

function GamepadGridFocus:New(...)
    return ZO_GamepadFocus.New(self, ...)
end

function GamepadGridFocus:Initialize(control, gridWidth, gridHeight, leftBoundCallBack, rightBoundCallBack, topBoundCallBack, bottomBoundCallBack)
    ZO_GamepadFocus.Initialize(self, control)

    self.gridWidth = gridWidth
    self.gridHeight = gridHeight
    self.cooldown = 0
    self.leftBoundCallBack = leftBoundCallBack
    self.rightBoundCallBack = rightBoundCallBack
    self.topBoundCallBack = topBoundCallBack
    self.bottomBoundCallBack = bottomBoundCallBack
end

function GamepadGridFocus:InitializeMovementController()
    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
end

function GamepadGridFocus:GetSelectedIndex()
    return self.index
end
 
do
    local LUA_TABLE_OFFSET = 1

    local MOVE_DIRECTION_TABLE =
    {
        [MOVEMENT_CONTROLLER_NO_CHANGE] = 0,
        [MOVEMENT_CONTROLLER_MOVE_NEXT] = 1,
        [MOVEMENT_CONTROLLER_MOVE_PREVIOUS] = -1
    }

    -- Used to map x/y movement to sound direction for sounds: TOPLEFT, TOP, TOPRIGHT // LEFT, MIDDLE, RIGHT // BOTTOMLEFT, BOTTOM, BOTTOMRIGHT
    local DIR_SOUND_MAP_COL_ROW = 
    {
        [-1 ] = { [-1 ] = FOCUS_MOVEMENT_TYPES.MOVE_PREVIOUS, [ 0 ] = FOCUS_MOVEMENT_TYPES.MOVE_PREVIOUS, [ 1 ] = FOCUS_MOVEMENT_TYPES.MOVE_PREVIOUS },
        [ 0 ] = { [-1 ] = FOCUS_MOVEMENT_TYPES.MOVE_PREVIOUS, [ 0 ] = nil,                                [ 1 ] = FOCUS_MOVEMENT_TYPES.MOVE_NEXT     },
        [ 1 ] = { [-1 ] = FOCUS_MOVEMENT_TYPES.MOVE_NEXT,     [ 0 ] = FOCUS_MOVEMENT_TYPES.MOVE_NEXT,     [ 1 ] = FOCUS_MOVEMENT_TYPES.MOVE_NEXT     },
    }

    function GamepadGridFocus:UpdateDirectionalInput()
        if self.index then
            local moveX, moveY = self.horizontalMovementController:CheckMovement(), self.verticalMovementController:CheckMovement()
            if moveX ~= MOVEMENT_CONTROLLER_NO_CHANGE or moveY ~= MOVEMENT_CONTROLLER_NO_CHANGE then
                local dx, dy = MOVE_DIRECTION_TABLE[moveX], MOVE_DIRECTION_TABLE[moveY]
                local gridX = dx + self:GetGridXPosition()
                local gridY = dy + self:GetGridYPosition()
                
                if gridX < 1 then
                    if self.leftBoundCallBack then
                        self.leftBoundCallBack()
                    end
                elseif gridX > self.gridWidth then
                    if self.rightBoundCallBack then
                        self.rightBoundCallBack()
                    end
                elseif gridY < 1 then
                    if self.topBoundCallBack then
                        self.topBoundCallBack()
                    end
                elseif gridY > self.gridHeight then
                    if self.bottomBoundCallBack then
                        self.bottomBoundCallBack()
                    end
                else
                    local newIndex = self.index + dx + (dy * self.gridWidth) -- interleaved index
                    local selectedData = self.data[newIndex]
                    if selectedData then
                        self:SetFocusByIndex(newIndex)
                        self.onPlaySoundFunction(DIR_SOUND_MAP_COL_ROW[dy][dx])
                    end
                end
            end
        end
    end

    function GamepadGridFocus:SetGridDimensions(gridWidth, gridHeight)
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
    end

    function GamepadGridFocus:GetGridWidth()
        return self.gridWidth
    end

    function GamepadGridFocus:GetGridHeight()
        return self.gridHeight
    end

    function GamepadGridFocus:GetGridDimensions()
        return self.gridWidth, self.gridHeight
    end

    function GamepadGridFocus:GetGridXPosition()
        local index = self.active and self.index or self.savedIndex
        return LUA_TABLE_OFFSET + zo_mod(index - LUA_TABLE_OFFSET, self.gridWidth)
    end

    function GamepadGridFocus:GetGridYPosition()
        local index = self.active and self.index or self.savedIndex
        return LUA_TABLE_OFFSET + zo_mod(zo_floor((index - LUA_TABLE_OFFSET) / self.gridWidth), self.gridHeight)
    end 

    function GamepadGridFocus:GetGridPosition()
        return self:GetGridXPosition(), self:GetGridYPosition()
    end

    function GamepadGridFocus:SetGridPosition(gridX, gridY)
        local newIndex = zo_min(gridX + ((gridY  - LUA_TABLE_OFFSET) * self.gridWidth), #self.data) -- interleaved index
        local selectedData = self.data[newIndex]

        if selectedData then
            self:SetFocusByIndex(newIndex)
        end
    end
end

--
--[[ Gamepad Market Page Fragment ]]--
--

ZO_GamepadMarketPageFragment = ZO_ConveyorSceneFragment:Subclass()

function ZO_GamepadMarketPageFragment:New(...)
    return ZO_ConveyorSceneFragment.New(self, ...)
end

do
    local PAGE_IN_ANIMATION = "ZO_GamepadMarket_GridScreen_PageInSceneAnimation"
    local PAGE_OUT_ANIMATION = "ZO_GamepadMarket_GridScreen_PageOutSceneAnimation"
    local FADE_ANIMATION = "FadeSceneAnimation"

    function ZO_GamepadMarketPageFragment:Initialize(control, alwaysAnimate)
        ZO_ConveyorSceneFragment.Initialize(self, control, alwaysAnimate, PAGE_IN_ANIMATION, PAGE_OUT_ANIMATION)
        self.direction = ZO_GAMEPAD_MARKET_PAGE_RIGHT_DIRECTION
    end

    function ZO_GamepadMarketPageFragment:ConfigureTranslateAnimation(...)
        if self.direction ~= ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION then
            ZO_ConveyorSceneFragment.ConfigureTranslateAnimation(self, ...)
        end
    end

    local FORWARD = true
    local BACKWARD = false
    function ZO_GamepadMarketPageFragment:ChooseAnimation()
        if self:GetState() == SCENE_FRAGMENT_SHOWING then
            if self.direction == ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION then
                return FADE_ANIMATION, FORWARD
            elseif self.direction == ZO_GAMEPAD_MARKET_PAGE_LEFT_DIRECTION then
                return PAGE_IN_ANIMATION, FORWARD
            else
                return PAGE_OUT_ANIMATION, BACKWARD
            end
        else
            if self.direction == ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION then
                return FADE_ANIMATION, BACKWARD
            elseif self.direction == ZO_GAMEPAD_MARKET_PAGE_LEFT_DIRECTION then
                return PAGE_OUT_ANIMATION, FORWARD
            else
                return PAGE_IN_ANIMATION, BACKWARD
            end
        end
    end
    
    function ZO_GamepadMarketPageFragment:GetAnimationXOffsets(index, animationTemplate)
        local isValid, point, relTo, relPoint, offsetX, offsetY = self.control:GetAnchor(index - 1)
        if isValid then
            local controlWidth = self.control:GetWidth()
            local middleX = offsetX
            local startX, endX = middleX, middleX

            if animationTemplate == PAGE_IN_ANIMATION then
                startX = middleX + controlWidth
            elseif animationTemplate == PAGE_OUT_ANIMATION then
                endX = middleX - controlWidth
            end

            return startX, endX
        end

        return 0, 0
    end
end

function ZO_GamepadMarketPageFragment:GetBackgroundFragment()
    return GAMEPAD_NAV_QUADRANT_1_2_3_BACKGROUND_FRAGMENT
end

function ZO_GamepadMarketPageFragment:SetDirection(direction)
    self.direction = direction
end

--
--[[ Gamepad Market TabBar ScrollList ]]--
--

-- infinite scrolling header tabbar for the b2p market
local GamepadMarket_TabBarScrollList = ZO_HorizontalScrollList:Subclass()

function GamepadMarket_TabBarScrollList:New(...)
    return ZO_HorizontalScrollList.New(self, ...)
end

do
    local function TabBar_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
        local label = control:GetNamedChild("Label")
        if data.canSelect == nil then
            data.canSelect = true
        end
        
        ZO_GamepadMenuHeaderTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)

        if selected then
            label:SetFont("ZoFontGamepadBold48")
            label:SetColor(ZO_MARKET_SELECTED_COLOR:UnpackRGB())
        else
            label:SetFont("ZoFontGamepadBold34")
            label:SetColor(ZO_MARKET_DIMMED_COLOR:UnpackRGB())
        end
    end

    local function CreateKeybindLabel(name, parent, anchor)
        local keybindLabel = CreateControlFromVirtual(name, parent, "ZO_ClickableKeybindLabel_Gamepad")
        keybindLabel:SetAnchor(anchor, parent, anchor)
        keybindLabel:SetHidden(true)
        return keybindLabel
    end

    local function OnTabChanged(newData)
        if newData.callback then
            newData.callback()
        end
    end

    local NUM_VISIBLE_CATEGORIES = 5
    local OFFSET_BETWEEN_ENTRIES = 100

    function GamepadMarket_TabBarScrollList:Initialize(control)
        self.control = control
        self.leftIcon = CreateKeybindLabel("$(parent)LeftArrow", self.control, LEFT)
        self.rightIcon = CreateKeybindLabel("$(parent)RightArrow", self.control, RIGHT)
        ZO_HorizontalScrollList.Initialize(self, control, "ZO_GamepadMarket_TabBarEntryTemplate", NUM_VISIBLE_CATEGORIES, TabBar_Setup, MenuEntryTemplateEquality)
        self:InitializeKeybindStripDescriptors()
        self:SetOnTargetDataChangedCallback(OnTabChanged)
        self:SetAllowWrapping(true)
        self:SetDisplayEntryType(ZO_HORIZONTAL_SCROLL_LIST_ANCHOR_ENTRIES_AT_FIXED_DISTANCE)
        self:SetOffsetBetweenEntries(OFFSET_BETWEEN_ENTRIES)
    end
end

function GamepadMarket_TabBarScrollList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarket_TabBarScrollList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
end

function GamepadMarket_TabBarScrollList:InitializeKeybindStripDescriptors()
    local leftShoulderKeybind =
    {
        --Even though this is an ethereal keybind, the name will still be read during screen narration
        name = GetString(SI_SCREEN_NARRATION_TABBAR_PREVIOUS_KEYBIND),
        keybind = "UI_SHORTCUT_LEFT_SHOULDER",
        ethereal = true,
        narrateEthereal = function()
            return self:GetNumItems() > 0
        end,
        etherealNarrationOrder = 100,
        enabled = function() return self:GetNumItems() > 0 end,
        handlesKeyUp = true,
        callback = function(isUp)
            -- handled on up due to the potential chord with GAMEPAD_BUTTON_3 causing ordering issues
            -- when previewing and attempting to change categories
            if not isUp then
                return
            end

            self:MoveRight()
            PlaySound(SOUNDS.GAMEPAD_PAGE_BACK)
        end,
    }

    local rightShoulderKeybind =
    {
        --Even though this is an ethereal keybind, the name will still be read during screen narration
        name = GetString(SI_SCREEN_NARRATION_TABBAR_NEXT_KEYBIND),
        keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
        ethereal = true,
        narrateEthereal = function()
            return self:GetNumItems() > 0
        end,
        etherealNarrationOrder = 101,
        enabled = function() return self:GetNumItems() > 0 end,
        handlesKeyUp = true,
        callback = function(isUp)
            -- handled on up due to the potential chord with GAMEPAD_BUTTON_3 causing ordering issues
            -- when previewing and attempting to change categories
            if not isUp then
                return
            end

            self:MoveLeft()
            PlaySound(SOUNDS.GAMEPAD_PAGE_FORWARD)
        end,
    }

    self.keybindStripDescriptors = 
    {
        leftShoulderKeybind,
        rightShoulderKeybind,
    }

    self.leftIcon:SetKeybindButtonDescriptor(leftShoulderKeybind)
    self.rightIcon:SetKeybindButtonDescriptor(rightShoulderKeybind)
end

function GamepadMarket_TabBarScrollList:GetNarrationText()
    local selectedData = self:GetSelectedData()
    if selectedData then
        --If the selected data has a custom narration function, use that
        if selectedData.narrationText then
            return selectedData.narrationText()
        else
            --Otherwise just form a narration from the text
            local text = selectedData.text or ""
            if type(text) == "function" then
                text = text(selectedData)
            end
            return SCREEN_NARRATION_MANAGER:CreateNarratableObject(text)
        end
    end
end

--
--[[ Gamepad Market Grid Screen ]]--
--

ZO_GamepadMarket_GridScreen = ZO_InitializingObject:Subclass()

function ZO_GamepadMarket_GridScreen:Initialize(control, initialTabBarEntries)
    control.owner = self
    self.control = control
    self.fullPane = self.control:GetNamedChild("FullPane")
    self.contentContainer = self.fullPane:GetNamedChild("ContainerContent")
    self.scrollbar = self.contentContainer:GetNamedChild("ScrollBar")
    self.scrollbar:SetHandler("OnUpdate", function (_, timeSecs) self:OnScrollBarDimAlphaUpdate(timeSecs) end)
    self.scrollbar:SetMinMax(MIN_SCROLL_VALUE, MAX_SCROLL_VALUE)
    self.scrollbar:SetEnabled(true)
    self.scrollbar:SetAllowDraggingFromThumb(false)
    ZO_Scroll_Initialize(self.contentContainer)
    self.contentContainer.scrollChild = self.contentContainer:GetNamedChild("ScrollChild")
    self.currentCategoryControl = self.contentContainer.scrollChild -- Used for product parenting, may be updated by subclass
    self.lastAlphaUpdateTime = 0
    self.showScrollbar = false
    self.selectingItem = false
    self.lastGridY = 1
    self.gridScrollYPosition = 1
    self.currentItemAnchor = ZO_Anchor:New(TOPLEFT, self.contentContainer, TOPLEFT)
    self.focusList = GamepadGridFocus:New(control, 0, 0)
    self.focusList:SetFocusChangedCallback(function(...) self:OnSelectionChanged(...) end)
    self.gridEntries = {}
    self.previewProductIds = {}

    self.headerContainer = self.fullPane:GetNamedChild("ContainerHeaderContainer")
    self.header = self.headerContainer.header
    self:InitializeHeader(initialTabBarEntries)

    self.headerNarrationFunction = function()
        local narrations = {}
        ZO_AppendNarration(narrations, self.header.tabBar:GetNarrationText())
        ZO_AppendNarration(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(self.headerData.titleText))
        return narrations
    end

    self.subHeaderNarrationFunction = function(focusItem)
        return SCREEN_NARRATION_MANAGER:CreateNarratableObject(focusItem.categoryName)
    end

    self.footerNarrationFunction = function()
        if MARKET_CURRENCY_GAMEPAD_FRAGMENT:IsShowing() then
            return MARKET_CURRENCY_GAMEPAD:GetNarrationText()
        end
    end
end

-- calculate offset needed to scroll grid entries to the absolute screen center instead of the relative container center
function ZO_GamepadMarket_GridScreen:CalculateScrollToCenterOffsetY()
    local screenCenterY = GuiRoot:GetHeight() / 2
    local contentOffsetY = self.contentContainer:GetTop()
    local relativeContentCenterY = self.contentContainer:GetHeight() / 2
    local absoluteContentCenterY = contentOffsetY + relativeContentCenterY
    self.scrollToCenterOffsetY = relativeContentCenterY - (absoluteContentCenterY - screenCenterY)
end

function ZO_GamepadMarket_GridScreen:Activate()
    if not self.selectingItem then
        self.focusList:Activate()
        self.header.tabBar:Activate()
        self.selectingItem = true
        --Narrate both the header and subheader when the screen is activated
        local NARRATE_HEADER = true
        local NARRATE_SUB_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueFocus(self.focusList, NARRATE_HEADER, NARRATE_SUB_HEADER)
    end
end

function ZO_GamepadMarket_GridScreen:Deactivate()
    if self.selectingItem then
        self.focusList:Deactivate()
        self.header.tabBar:Deactivate()
        self.selectingItem = false
    end
end

function ZO_GamepadMarket_GridScreen:ClearGridList()
    self.focusList:RemoveAllEntries()
end

function ZO_GamepadMarket_GridScreen:SetGridDimensions(gridWidth, gridHeight)
    self.focusList:SetGridDimensions(gridWidth, gridHeight)
end

function ZO_GamepadMarket_GridScreen:PrepareGridForBuild(itemsPerRow, itemWidth, itemHeight, itemPadding)
    ZO_ClearNumericallyIndexedTable(self.gridEntries)
    self.currentItemAnchor:SetTarget(self.currentCategoryControl)
    self.itemsPerRow = itemsPerRow
    self.itemsPerColumn = 0
    self.itemWidth = itemWidth
    self.itemHeight = itemHeight
    self.itemPadding = itemPadding
    self.gridYPaddingOffset = ZO_GAMEPAD_MARKET_GRID_INITIAL_Y_OFFSET
    self.gridYHeight = 0
end

function ZO_GamepadMarket_GridScreen:ResetGrid()
    ZO_ClearNumericallyIndexedTable(self.gridEntries)
    self.currentItemAnchor:SetTarget(self.currentCategoryControl)
    self.itemsPerRow = 0
    self.itemsPerColumn = 0
    self.itemWidth = 0
    self.itemHeight = 0
    self.itemPadding = 0
    self.gridYPaddingOffset = ZO_GAMEPAD_MARKET_GRID_INITIAL_Y_OFFSET
    self.gridYHeight = 0
end

function ZO_GamepadMarket_GridScreen:AddEntry(entryObject, control, categoryName)
    control:ClearAnchors()
    local row, col, _, gridYHeight = ZO_Anchor_BoxLayout(self.currentItemAnchor, control, #self.gridEntries, self.itemsPerRow, self.itemPadding, self.itemPadding, self.itemWidth, self.itemHeight, ZO_GAMEPAD_MARKET_GRID_INITIAL_X_OFFSET, self.gridYPaddingOffset)
    self.gridYHeight = gridYHeight
    control:SetDimensions(self.itemWidth, self.itemHeight)
    control:SetParent(self.currentCategoryControl)
    table.insert(self.gridEntries, entryObject)
    entryObject:SetListIndex(#self.gridEntries)
    local focusData = entryObject:GetFocusData()
    focusData.gridY = row + 1
    focusData.gridX = col + 1
    focusData.centerScrollHeight = gridYHeight + INDIVIDUAL_PRODUCT_HALF_HEIGHT
    focusData.categoryName = categoryName
    focusData.headerNarrationFunction = self.headerNarrationFunction
    focusData.subHeaderNarrationFunction = self.subHeaderNarrationFunction
    focusData.footerNarrationFunction = self.footerNarrationFunction
    self.focusList:AddEntry(focusData)
    self.itemsPerColumn = row + 1

    if entryObject:GetEntryType() == ZO_GAMEPAD_MARKET_ENTRY_MARKET_PRODUCT then
        local marketProductId = entryObject:GetId()
        if CanPreviewMarketProduct(marketProductId) then
            table.insert(self.previewProductIds, marketProductId)
            entryObject:SetPreviewIndex(#self.previewProductIds)
        end
    end
end

do
    local SLIDER_MIN_VALUE = 0
    function ZO_GamepadMarket_GridScreen:FinishBuild()
        self.focusList:SetFocusToFirstEntry()
        self.lastGridY = 1
        self.gridScrollYPosition = 1
        self:SetGridDimensions(self.itemsPerRow, self.itemsPerColumn)
        self.contentContainer.scrollChild:SetHeight(self.gridYHeight + INDIVIDUAL_PRODUCT_HALF_HEIGHT + (ZO_GAMEPAD_MARKET_PRODUCT_PADDING * 2) + (self.contentContainer:GetHeight() / 2))
        ZO_Scroll_UpdateScrollBar(self.contentContainer)
        ZO_Scroll_ResetToTop(self.contentContainer)
        self.contentContainer.scrollValue = SLIDER_MIN_VALUE
        self.showScrollbar = self.itemsPerColumn > NUM_VISIBLE_ROWS
        self:UpdateScrollbarAlpha()
        self:CalculateScrollToCenterOffsetY()
    end
end

function ZO_GamepadMarket_GridScreen:InitializeHeader(initialTabBarEntries)
    local header = self.header
    header.tabBarControl = header:GetNamedChild("TabBar")

    header.tabBar = GamepadMarket_TabBarScrollList:New(header.tabBarControl)

    self.headerData =
    {
        tabBarEntries = initialTabBarEntries
    }

    self:RefreshHeader()
end

function ZO_GamepadMarket_GridScreen:RefreshHeader()
    if self.isInitialized then
        local headerData = self.headerData
        if headerData then
            local tabBar = self.header.tabBar
            local tabBarEntries = headerData.tabBarEntries

            if tabBarEntries then
                tabBar:Clear()
                for _, tabData in pairs(tabBarEntries) do
                    tabBar:AddEntry(tabData)
                end

                tabBar:Commit()
            end
        end
    end
end

function ZO_GamepadMarket_GridScreen:RefreshTabBarVisible()
    if self.isInitialized then
        self.header.tabBar:RefreshVisible()
    end
end

function ZO_GamepadMarket_GridScreen:OnPreviewChanged(previewData)
    self.lastPreviewedMarketProductId = previewData
end

function ZO_GamepadMarket_GridScreen:ClearLastPreviewedMarketProductId()
    self.lastPreviewedMarketProductId = nil
end

function ZO_GamepadMarket_GridScreen:BeginPreview(selectedEntry)
    if selectedEntry:GetEntryType() == ZO_GAMEPAD_MARKET_ENTRY_MARKET_PRODUCT then
        local previewIndex = selectedEntry:GetPreviewIndex()
        ZO_MARKET_PREVIEW_GAMEPAD:BeginPreview(self.previewProductIds, previewIndex, function(...) self:OnPreviewChanged(...) end)
    end
end

function ZO_GamepadMarket_GridScreen:EndCurrentPreview()
    EndCurrentMarketPreview()
end

function ZO_GamepadMarket_GridScreen:TrySelectLastPreviewedProduct()
    local marketProductId = self.lastPreviewedMarketProductId
    if marketProductId and self.selectedGridEntry and (self.selectedGridEntry:GetEntryType() ~= ZO_GAMEPAD_MARKET_ENTRY_MARKET_PRODUCT or marketProductId ~= self.selectedGridEntry:GetId()) then
        self.focusList:SetFocusToMatchingEntry(marketProductId,
        function(comparisonValue, focusListEntry)
            if focusListEntry.object:GetEntryType() == ZO_GAMEPAD_MARKET_ENTRY_MARKET_PRODUCT then
                return focusListEntry.object:GetId() == comparisonValue
            end

            return false
        end)

        if self.showScrollbar then
            -- If the selection has changed instantly scroll to the new position before the scene is visible
            local maxY = self.focusList:GetGridHeight()
            local gridY = self.focusList:GetGridYPosition()
            self.gridScrollYPosition = zo_min(maxY - (NUM_VISIBLE_ROWS - 1), gridY)
            self.lastGridY = gridY

            local INCLUDE_SAVED_FOCUS = true
            local focusedEntry = self.focusList:GetFocusItem(INCLUDE_SAVED_FOCUS)
            local focusedObject = focusedEntry.object
            local SCROLL_INSTANTLY = true
            self:ScrollToGridEntry(focusedObject:GetFocusData(), SCROLL_INSTANTLY)
        end
    end
end

function ZO_GamepadMarket_GridScreen:ClearProducts()
    self:ClearGridList()
    ZO_ClearTable(self.previewProductIds)
end

-- meant to override ZO_Market_Shared:RefreshProducts()
function ZO_GamepadMarket_GridScreen:RefreshProducts()
    for _, entry in ipairs(self.gridEntries) do
        entry:Refresh()
    end
end

function ZO_GamepadMarket_GridScreen:UpdatePreviousAndNewlySelectedProducts(previousSelectedProduct, newlySelectedProduct)
    if previousSelectedProduct and previousSelectedProduct ~= newlySelectedProduct then
        previousSelectedProduct:SetIsFocused(false)
    end

    if newlySelectedProduct then
        newlySelectedProduct:SetIsFocused(true)
    end
end

function ZO_GamepadMarket_GridScreen:ScrollToGridEntry(entryData, scrollInstantly)
    ZO_Scroll_ScrollControlIntoCentralView(self.contentContainer, entryData.control, scrollInstantly)
    self:UpdateScrollbarAlpha()
end

do
    local DIM_ALPHA_TIME_OUT = 1.25 -- This is in seconds as OnUpdate passes seconds for the time argument
    local PROGRESS_COMPLETE = 1
    local DIM_ALPHA = 0.5
    function ZO_GamepadMarket_GridScreen:OnScrollBarDimAlphaUpdate(timeSeconds)
        local scrollbar = self.scrollbar
        local timeline = scrollbar.timeline
        if self.showScrollbar and (timeSeconds - self.lastAlphaUpdateTime) > DIM_ALPHA_TIME_OUT and timeline:GetFullProgress() == PROGRESS_COMPLETE and scrollbar:GetAlpha() ~= DIM_ALPHA then
            self.lastAlphaUpdateTime = timeSeconds
            scrollbar.alphaAnimation:SetAlphaValues(scrollbar:GetAlpha(), DIM_ALPHA)
            timeline:PlayFromStart()
        end
    end
end

function ZO_GamepadMarket_GridScreen:UpdateScrollbarAlpha()
    local scrollbar = self.scrollbar
    scrollbar.timeline:Stop()
    scrollbar.alphaAnimation:SetAlphaValues(scrollbar:GetAlpha(), self.showScrollbar and 1 or 0)
    scrollbar.timeline:PlayFromStart()
    self.lastAlphaUpdateTime = GetFrameTimeSeconds()
end

function ZO_GamepadMarket_GridScreen:OnSelectionChanged(selectedData)
    if selectedData and self.showScrollbar then
        self:ScrollToGridEntry(selectedData)
    end
end

function ZO_GamepadMarket_GridScreen:SetQueuedTutorial(queuedTutorial)
    local tutorialId = TUTORIAL_MANAGER:GetTutorialId(queuedTutorial)
    if not HasSeenTutorial(tutorialId) then
        self.queuedTutorial = queuedTutorial
    end
end

function ZO_GamepadMarket_GridScreen:HasQueuedTutorial()
    return self.queuedTutorial ~= nil
end

function ZO_GamepadMarket_GridScreen:OnShown()
    if self.queuedTutorial then
        TUTORIAL_MANAGER:ShowTutorial(self.queuedTutorial)
        self.queuedTutorial = nil
    end
end
