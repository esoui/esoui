ZO_GAMEPAD_MARKET_PAGE_LEFT_DIRECTION = 1
ZO_GAMEPAD_MARKET_PAGE_RIGHT_DIRECTION = 2
ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION = 3 -- No movement, only fading
ZO_GAMEPAD_MARKET_GRID_INITIAL_X_OFFSET = 22
ZO_GAMEPAD_MARKET_GRID_INITIAL_Y_OFFSET = 62

local SCROLL_BOTTOM_PADDING = 50
local NUM_VISIBLE_ROWS = 2
local MIN_SCROLL_POSITION = 0
local MIN_SCROLL_VALUE = 0
local MAX_SCROLL_VALUE = 100

ZO_GAMEPAD_MARKET_BUNDLE_PRODUCTS_PER_ROW = 2
ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCTS_PER_ROW = 3
ZO_GAMEPAD_MARKET_BUNDLE_PRODUCT_PADDING = 5
ZO_GAMEPAD_MARKET_PRODUCT_PADDING  = 12
ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN = 2
ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN_MINUS_ONE = ZO_GAMEPAD_MARKET_PRODUCTS_PER_COLUMN - 1

local INDIVIDUAL_PRODUCT_HALF_HEIGHT = ZO_GAMEPAD_MARKET_INDIVIDUAL_PRODUCT_HEIGHT / 2
local HIGHLIGHT_BOUNDARY_PADDING = 10

local FOCUS_MOVEMENT_TYPES = 
{
    MOVE_NEXT = 1,
    MOVE_PREVIOUS = 2,
}

-- copy the standard gamepad style but change the center and right offsets
ZO_GAMEPAD_KEYBIND_STRIP_MARKET_GAMEPAD_STYLE = ZO_ShallowTableCopy(KEYBIND_STRIP_GAMEPAD_STYLE)
ZO_GAMEPAD_KEYBIND_STRIP_MARKET_GAMEPAD_STYLE.centerAnchorOffset = -230

function ZO_GamepadMarketKeybindStrip_RefreshStyle()
    local iconWidth = ZO_GamepadMarket_CrownsFooterIcon:GetWidth()
    local crownsAmountWidth = ZO_GamepadMarket_CrownsFooterAmount:GetTextWidth()
    local crownsLabelWidth = ZO_GamepadMarket_CrownsFooterLabel:GetTextWidth()
    ZO_GAMEPAD_KEYBIND_STRIP_MARKET_GAMEPAD_STYLE.rightAnchorOffset = -iconWidth - crownsAmountWidth - crownsLabelWidth - ZO_GamepadMarket_DummyKeybindLabelTemplate:GetTextWidth()
    KEYBIND_STRIP:SetStyle(ZO_GAMEPAD_KEYBIND_STRIP_MARKET_GAMEPAD_STYLE)
end

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
    self.data = {}
    self.control = control
    self.index = nil
    self.savedIndex = nil
    self.gridWidth = gridWidth
    self.gridHeight = gridHeight
    self.horizontalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
    self.verticalMovementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_VERTICAL)
    self:SetActive(false)
    self.cooldown = 0
    self.leftBoundCallBack = leftBoundCallBack
    self.righBoundCallBack = rightBoundCallBack
    self.topBoundCallBack = topBoundCallBack
    self.bottomBoundCallBack = bottomBoundCallBack
    self.directionalInputEnabled = true

    local function GamepadListPlaySound(movementType)
        if movementType == FOCUS_MOVEMENT_TYPES.MOVE_NEXT then
            PlaySound(SOUNDS.GAMEPAD_MENU_DOWN)
        elseif movementType == FOCUS_MOVEMENT_TYPES.MOVE_PREVIOUS then
            PlaySound(SOUNDS.GAMEPAD_MENU_UP)
        end
    end

    self:SetPlaySoundFunction(GamepadListPlaySound)
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
    local DIR_SOUND_MAP = 
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
                    if self.righBoundCallBack then
                        self.righBoundCallBack()
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
                        self.onPlaySoundFunction(DIR_SOUND_MAP[dy][dx])
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
    local FORWARD = true
    local BACKWARD = false

    function ZO_GamepadMarketPageFragment:Initialize(control, alwaysAnimate)
        ZO_ConveyorSceneFragment.Initialize(self, control, alwaysAnimate, PAGE_IN_ANIMATION, PAGE_OUT_ANIMATION)
        self.direction = ZO_GAMEPAD_MARKET_PAGE_RIGHT_DIRECTION
    end

    function ZO_GamepadMarketPageFragment:GetAnimationTemplates()
        return { PAGE_IN_ANIMATION, PAGE_OUT_ANIMATION }
    end

    function ZO_GamepadMarketPageFragment:ConfigureTranslateAnimation(...)
        if self.direction ~= ZO_GAMEPAD_MARKET_PAGE_NO_DIRECTION then
            ZO_ConveyorSceneFragment.ConfigureTranslateAnimation(self, ...)
        end
    end

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

    local function CreateButtonIcon(name, parent, keycode, anchor)
        local buttonIcon = CreateControl(name, parent, CT_BUTTON)
        buttonIcon:SetNormalTexture(ZO_Keybindings_GetTexturePathForKey(keycode))
        buttonIcon:SetDimensions(ZO_TABBAR_ICON_WIDTH, ZO_TABBAR_ICON_HEIGHT)
        buttonIcon:SetAnchor(anchor, control, anchor)
        buttonIcon:SetHidden(true) -- hidden by default
        return buttonIcon
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
        self.leftIcon = CreateButtonIcon("$(parent)LeftArrow", self.control, KEY_GAMEPAD_LEFT_SHOULDER, LEFT)
        self.rightIcon = CreateButtonIcon("$(parent)RightArrow", self.control, KEY_GAMEPAD_RIGHT_SHOULDER, RIGHT)
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
    self.keybindStripDescriptors = 
    {
        {
            keybind = "UI_SHORTCUT_LEFT_SHOULDER",
            ethereal = true,
            enabled = function() return self:GetNumItems() > 0 end,
            callback = function()
                self:MoveRight()
                PlaySound(SOUNDS.GAMEPAD_PAGE_BACK)
            end,
        },

        {
            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
            ethereal = true,
            enabled = function() return self:GetNumItems() > 0 end,
            callback = function()
                self:MoveLeft()
                PlaySound(SOUNDS.GAMEPAD_PAGE_FORWARD)
            end,
        },
    }
end

--
--[[ Gamepad Market Grid Screen ]]--
--

ZO_GamepadMarket_GridScreen = ZO_Object:Subclass()

function ZO_GamepadMarket_GridScreen:Initialize(control, gridWidth, gridHeight, initialTabBarEntries)
    control.owner = self
    self.control = control
    local controlName = control:GetName()
    self.productName = controlName .. ZO_GAMEPAD_MARKET_PRODUCT_TEMPLATE
    self.blankProductName = controlName .. ZO_GAMEPAD_MARKET_BLANK_TILE_TEMPLATE
    self.fullPane = self.control:GetNamedChild("FullPane")
    self.contentContainer = self.fullPane:GetNamedChild("ContainerContent")
    self.scrollbar = self.contentContainer:GetNamedChild("ScrollBar")
    self.scrollbar:SetHandler("OnUpdate", function (_, timeSecs) self:OnScrollBarDimAlphaUpdate(timeSecs) end)
    self.scrollbar:SetMinMax(MIN_SCROLL_VALUE, MAX_SCROLL_VALUE)
    self.scrollbar:SetEnabled(true)
    self.scrollbar:SetAllowDraggingFromThumb(false)
    self.scrollUpButton = self.scrollbar:GetNamedChild("Up")
    self.scrollDownButton = self.scrollbar:GetNamedChild("Down")
    self.scrollUpButton:SetHidden(true)
    self.scrollDownButton:SetHidden(true)
    ZO_Scroll_Initialize(self.contentContainer)
    self.contentContainer.scrollChild = self.contentContainer:GetNamedChild("ScrollChild")
    self.currentCategoryControl = self.contentContainer.scrollChild -- Used for product parenting, may be updated by subclass
    self.lastAlphaUpdateTime = 0
    self.showScrollbar = false
    self.currencyAmountControl = ZO_GamepadMarket_CrownsFooter:GetNamedChild("Amount")
    self.selectingItem = false
    self.lastGridY = 1
    self.gridScrollYPosition = 1
    self.currentItemAnchor = ZO_Anchor:New(TOPLEFT, self.contentContainer, TOPLEFT)
    self.focusList = GamepadGridFocus:New(control, gridWidth, gridHeight, nil, nil)
    self.focusList:SetFocusChangedCallback(function(...) self:OnSelectionChanged(...)  end)
    self.previewProducts = {}
    self:InitializeMarketProductPool()
    self.headerContainer = self.fullPane:GetNamedChild("ContainerHeaderContainer")
    self.header = self.headerContainer.header
    self:InitializeHeader(initialTabBarEntries)
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

function ZO_GamepadMarket_GridScreen:PrepareGridForBuild(itemsPerRow, itemsPerColumn, itemWidth, itemHeight, itemPadding, isBundle)
    self.totalItems = 0
    self.currentItemAnchor:SetTarget(self.currentCategoryControl)
    self.itemsPerRow = itemsPerRow
    self.itemsPerColumn = itemsPerColumn
    self.itemWidth = itemWidth
    self.itemHeight = itemHeight
    self.itemPadding = itemPadding
    self.isBundle = isBundle
    self.gridYPaddingOffset = ZO_GAMEPAD_MARKET_GRID_INITIAL_Y_OFFSET
    self.gridYHeight = 0
end

function ZO_GamepadMarket_GridScreen:AddEntry(marketProduct, control)
    control:ClearAnchors()
    local row, col, _, gridYHeight = ZO_Anchor_BoxLayout(self.currentItemAnchor, control, self.totalItems, self.itemsPerRow, self.itemPadding, self.itemPadding, self.itemWidth, self.itemHeight, ZO_GAMEPAD_MARKET_GRID_INITIAL_X_OFFSET, self.gridYPaddingOffset)
    self.gridYHeight = gridYHeight
    control:SetDimensions(self.itemWidth, self.itemHeight)
    control:SetParent(self.currentCategoryControl)
    self.totalItems = self.totalItems + 1
    marketProduct:SetListIndex(self.totalItems)
    marketProduct:SetRenderSize(self.isBundle and ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_WIDE or ZO_GAMEPAD_MARKET_PRODUCT_RENDER_SIZE_STANDARD)
    local focusData = marketProduct:GetFocusData()
    focusData.gridY = row + 1
    focusData.gridX = col + 1
    focusData.centerScrollHeight = gridYHeight + INDIVIDUAL_PRODUCT_HALF_HEIGHT
    self.focusList:AddEntry(focusData)
    self.itemsPerColumn = row + 1

    if marketProduct:HasPreview() then
        table.insert(self.previewProducts, marketProduct)
        marketProduct:SetPreviewIndex(#self.previewProducts)
    end
end

function ZO_GamepadMarket_GridScreen:AcquireBlankTile()
    return self.blankTilePool:AcquireObject()
end

function ZO_GamepadMarket_GridScreen:FinishRowWithBlankTiles()
    local currentItemRowIndex = self.totalItems % self.itemsPerRow
    
    if currentItemRowIndex > 0 then
        for i = currentItemRowIndex, self.itemsPerRow - 1 do
            local blankTile = self:AcquireBlankTile()
            blankTile:Show()
            self:AddEntry(blankTile, blankTile:GetControl())
        end
    end
end

do
    local USE_FADE_GRADIENT = true
    local UPDATE_THUMB = true
    local SLIDER_MIN_VALUE = 0
    function ZO_GamepadMarket_GridScreen:FinishBuild()
        self.focusList:SetFocusToFirstEntry()
        self:RefreshKeybinds()
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

function ZO_GamepadMarket_GridScreen:RefreshKeybinds()
    ZO_GamepadMarketKeybindStrip_RefreshStyle()
    KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptors)
end

function ZO_GamepadMarket_GridScreen:InitializeHeader(initialTabBarEntries)
    local header = self.header
    header.tabBarControl = header:GetNamedChild("TabBar")

    header.tabBarControl:SetHidden(false)
    header.tabBar = GamepadMarket_TabBarScrollList:New(header.tabBarControl)
        
    self.headerData = 
    {
        tabBarEntries = initialTabBarEntries
    }

    self:RefreshHeader()
end

function ZO_GamepadMarket_GridScreen:RefreshHeader()
    if self.isInitialized then
        local header = self.header
        local headerData = self.headerData
        if headerData then
            local tabBar = header.tabBar
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

function ZO_GamepadMarket_GridScreen:BeginPreview()
    self.previewIndex = self.selectedMarketProduct:GetPreviewIndex()
    ZO_GAMEPAD_MARKET_PREVIEW:SetPreviewProductsContainer(self)
    self.isPreviewing = true

    if IsCharacterPreviewingAvailable() then
        ZO_GAMEPAD_MARKET_PREVIEW:Activate()
        self.selectedMarketProduct:Preview()
    end
    self:Deactivate()
    SCENE_MANAGER:Push(ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME)
end

function ZO_GamepadMarket_GridScreen:EndCurrentPreview()
    EndCurrentItemPreview()
    self:RefreshKeybinds()
end

function ZO_GamepadMarket_GridScreen:HasMultiplePreviewProducts()
    return #self.previewProducts > 1
end

function ZO_GamepadMarket_GridScreen:GetCurrentPreviewProduct()
    return self.previewProducts[self.previewIndex]
end
   
-- Supports wrapping around the preview list
function ZO_GamepadMarket_GridScreen:MoveToPreviousPreviewProduct()
    self.previewIndex = self.previewIndex - 1

    if self.previewIndex < 1 then
        self.previewIndex = #self.previewProducts - self.previewIndex
    end

    return self:GetCurrentPreviewProduct()
end

-- Supports wrapping around the preview list
function ZO_GamepadMarket_GridScreen:MoveToNextPreviewProduct()
    self.previewIndex = self.previewIndex + 1

    if self.previewIndex > #self.previewProducts then
        self.previewIndex = self.previewIndex - #self.previewProducts
    end

    return self:GetCurrentPreviewProduct()
end

function ZO_GamepadMarket_GridScreen:OnShowing()
    self:EndCurrentPreview()
    self:PerformDeferredInitialization()
    self:RefreshHeader()
end

function ZO_GamepadMarket_GridScreen:SelectAfterPreview()
    if self.isPreviewing then
        self:Activate()
        local marketProduct = self:GetCurrentPreviewProduct()
        if marketProduct ~= self.selectedMarketProduct then
            local listIndex = marketProduct:GetListIndex()
            self.focusList:SetFocusByIndex(listIndex)

            if self.showScrollbar then
                -- If the selection has changed instantly scroll to the new position before the scene is visible
                local maxY = self.focusList:GetGridHeight()
                local gridY = self.focusList:GetGridYPosition()
                self.gridScrollYPosition = zo_min(maxY - (NUM_VISIBLE_ROWS - 1), gridY)
                self.lastGridY = gridY
                self:ScrollToGridEntry(marketProduct:GetFocusData())
            end
        end

        self:ClearPreviewVars()
    end
end

function ZO_GamepadMarket_GridScreen:ClearPreviewVars()
    self.isPreviewing = false
    self.previewIndex = nil
end

function ZO_GamepadMarket_GridScreen:PerformDeferredInitialization()
    self.isInitialized = true -- May be overriden
end

function ZO_GamepadMarket_GridScreen:InitializeBlankProductPool()
    local function CreateBlankTile(objectPool)
        return ZO_GamepadMarketBlankProduct:New(objectPool:GetNextControlId(), self.currentCategoryControl, self, self.blankProductName)
    end

    local function ResetBlankTile(blankTile)
        blankTile:Reset()
    end

     self.blankTilePool = ZO_ObjectPool:New(CreateBlankTile, ResetBlankTile)
 end

function ZO_GamepadMarket_GridScreen:InitializeMarketProductPool()
    local function CreateMarketProduct(objectPool)
        return ZO_GamepadMarketProduct:New(objectPool:GetNextControlId(), self.currentCategoryControl, self, self.productName)
    end

    local function ResetMarketProduct(marketProduct)
        marketProduct:Reset()
    end

    self.marketProductPool = ZO_ObjectPool:New(CreateMarketProduct, ResetMarketProduct)
    
    self:InitializeBlankProductPool()
end

function ZO_GamepadMarket_GridScreen:ReleaseAllProducts()
    self.marketProductPool:ReleaseAllObjects()
    self.blankTilePool:ReleaseAllObjects()
end

function ZO_GamepadMarket_GridScreen:ClearProducts()
    self:ReleaseAllProducts()
    self:ClearGridList()
    ZO_ClearTable(self.previewProducts)
end

function ZO_GamepadMarket_GridScreen:RefreshProducts()
    for _, entry in ipairs(self.focusList.data) do
        entry.marketProduct:Refresh()
    end
end

function ZO_GamepadMarket_GridScreen:UpdateTooltip()
    self:LayoutSelectedMarketProduct()
end

do
    local g_purchaseManager = ZO_GamepadMarketPurchaseManager:New() -- Singleton purchase manager
    function ZO_GamepadMarket_GridScreen:BeginPurchase(marketProduct, onPurchaseSuccessCallback, onPurchaseEndCallback)
        g_purchaseManager:BeginPurchase(marketProduct:GetProductForSell(), onPurchaseSuccessCallback, onPurchaseEndCallback)
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

function ZO_GamepadMarket_GridScreen:ScrollToGridEntry(entryData)
    local scrollPosition = entryData.gridY == 1 and 0 or (entryData.centerScrollHeight - self.scrollToCenterOffsetY)
    if self.control:IsHidden() then -- Play animation instantly if the market control is hidden
        ZO_Scroll_ScrollAbsoluteInstantly(self.contentContainer, scrollPosition)
    else
        ZO_Scroll_ScrollAbsolute(self.contentContainer, scrollPosition) -- Animate to scroll position
    end

    self:UpdateScrollbarAlpha()
end

function ZO_GamepadMarket_GridScreen:ScrollToGridScrollYPosition()
    local scrollPosition = (self.gridScrollYPosition - 1) * (self.itemHeight + self.itemPadding)
    
    if self.control:IsHidden() then -- Play animation instantly if the market control is hidden
        ZO_Scroll_ScrollAbsoluteInstantly(self.contentContainer, scrollPosition)
    else
        ZO_Scroll_ScrollAbsolute(self.contentContainer, scrollPosition) -- Animate to scroll position
    end

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

function ZO_GamepadMarket_GridScreen:AddKeybinds()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptors)
end

function ZO_GamepadMarket_GridScreen:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptors)
end

function ZO_GamepadMarket_GridScreen:SetQueuedTutorial(queuedTutorial)
    self.queuedTutorial = queuedTutorial
end

function ZO_GamepadMarket_GridScreen:HasQueuedTutorial()
    return self.queuedTutorial ~= nil
end

function ZO_GamepadMarket_GridScreen:OnShown()
    if self.queuedTutorial then
        ZO_GAMEPAD_MARKET:ShowTutorial(self.queuedTutorial)
        self.queuedTutorial = nil
    end
end

function ZO_GamepadMarket_GridScreen:LayoutSelectedMarketProduct()
    -- may be overridden
end