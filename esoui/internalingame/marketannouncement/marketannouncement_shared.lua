----
-- ZO_MarketAnnouncement_Shared
----

ZO_ACTION_TILE_TYPE = 
{
    DAILY_REWARDS = 1
}

ZO_MarketAnnouncement_Shared = ZO_Object:Subclass()

function ZO_MarketAnnouncement_Shared:New(...)
    local announcement = ZO_Object.New(self)
    announcement:Initialize(...)
    return announcement
end

function ZO_MarketAnnouncement_Shared:InitializeKeybindButtons()
    self.closeButton = self.controlContainer:GetNamedChild("Close")
    self.closeButton:SetKeybind("MARKET_ANNOUNCEMENT_CLOSE")
    self.closeButton:SetClickSound(SOUNDS.DIALOG_ACCEPT)
    self.closeButton:SetCallback(function()
        self:OnMarketAnnouncementCloseKeybind()
    end)
end

function ZO_MarketAnnouncement_Shared:Initialize(control, fragmentConditionFunction)
    self.control = control

    local container = control:GetNamedChild("Container")
    self.titleLabel = container:GetNamedChild("Title")
    self.carouselControl = container:GetNamedChild("Carousel")
    self.scrollContainer = container:GetNamedChild("ScrollContainer")
    self.actionTileListControl = container:GetNamedChild("ActionTileList")
    self.crownStoreLockedControl = container:GetNamedChild("LockedCrownStore")
    self.crownStoreLockedTexture = self.crownStoreLockedControl:GetNamedChild("Background")

    self.controlContainer = container

    self.actionTileList = {}
    self.actionTileObjectPoolMap = {}
    for _, tileType in pairs(ZO_ACTION_TILE_TYPE) do
        local function FactoryFunction(objectPool)
            return self:CreateActionTile(tileType, objectPool)
        end
        local function ResetFunction(tileObject)
            return tileObject:Reset()
        end
        self.actionTileObjectPoolMap[tileType] = ZO_ObjectPool:New(FactoryFunction, ResetFunction)
    end

    self:InitializeKeybindButtons()
    local fragment = ZO_FadeSceneFragment:New(control)
    fragment:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
    if fragmentConditionFunction then
        fragment:SetConditional(fragmentConditionFunction)
    end
    self.fragment = fragment

    self.marketProductSelectedCallback = function(...) self:UpdateLabels(...) end

    local function OnDailyLoginRewardsUpdated() 
        if self.fragment:IsShowing() then 
            self:LayoutActionTiles() 
        end
    end

    ZO_MARKET_ANNOUNCEMENT_MANAGER:RegisterCallback("OnMarketAnnouncementDataUpdated", function() self:UpdateMarketCarousel() end)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_UPDATED, OnDailyLoginRewardsUpdated)
end

function ZO_MarketAnnouncement_Shared:CreateActionTile(tileType, objectPool)
    if self.actionTileControlByType[tileType] then
        local tile = ZO_ObjectPool_CreateControl(self.actionTileControlByType[tileType], objectPool, self.actionTileListControl)
        tile.owner = self
        return tile.object
    else
        assert(false, "Could not find Control " .. self.actionTileControlByType[tileType] " to create Action Tile " .. tileType)
    end
end

function ZO_MarketAnnouncement_Shared:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:OnShowing()
    elseif newState == SCENE_SHOWN then
        self:OnShown()
    elseif newState == SCENE_HIDING then
        self:OnHiding()
    elseif newState == SCENE_HIDDEN then
        self:OnHidden()
    end
end

function ZO_MarketAnnouncement_Shared:UpdateLabels(productData)
    self:UpdatePositionLabel(productData.index)
end

function ZO_MarketAnnouncement_Shared:UpdatePositionLabel(index)
    self.carousel:UpdateSelection(index)
end

function ZO_MarketAnnouncement_Shared:GetFragment()
    return self.fragment
end

function ZO_MarketAnnouncement_Shared:OnShowing()
    PlaySound(SOUNDS.DEFAULT_WINDOW_OPEN)
    self:LayoutActionTiles()

    if GetMarketAnnouncementCrownStoreLocked() then
        self.carouselControl:SetHidden(true)
        self.crownStoreLockedControl:SetHidden(false)
        self.crownStoreLockedTexture:SetTexture(GetMarketAnnouncementCrownStoreLockedBackground())
    else 
        self:UpdateMarketCarousel()
        self.carousel:Activate()
        self.carouselControl:SetHidden(false)
        self.crownStoreLockedControl:SetHidden(true)
    end
end

function ZO_MarketAnnouncement_Shared:OnShown()
end

function ZO_MarketAnnouncement_Shared:OnHiding()
    PlaySound(SOUNDS.DEFAULT_WINDOW_CLOSE)
    self.carousel:Deactivate()
end

function ZO_MarketAnnouncement_Shared:OnHidden()
end

function ZO_MarketAnnouncement_Shared:UpdateMarketCarousel()
    if self.fragment:IsShowing() then
        local productInfoTable = ZO_MARKET_ANNOUNCEMENT_MANAGER.productInfoTable
        self.numAnnouncementProducts = #productInfoTable
        if self.numAnnouncementProducts > 0 then
            self.carousel:SetNumProductAnnouncements(self.numAnnouncementProducts)
            self.carousel:UpdateSelection(1)
        end
        
        self.carousel:Clear()
        for i = 1, #productInfoTable do
            local marketProduct = self:CreateMarketProduct(productInfoTable[i].productId) 
            self.carousel:AddEntry({marketProduct = marketProduct, callback = self.marketProductSelectedCallback, index = i})
        end
        self.carousel:Commit()
    end
end

function ZO_MarketAnnouncement_Shared:OnSelectionClicked()
    -- To be overridden
end

function ZO_MarketAnnouncement_Shared:OnCloseClicked()
    self.closeButton:OnClicked()
end

function ZO_MarketAnnouncement_Shared:OnMarketAnnouncementCloseKeybind()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_MarketAnnouncement_Shared:OnMarketAnnouncementViewCrownStoreKeybind()
    local targetData = self.carousel:GetSelectedData()
    local marketProductId = targetData.marketProduct:GetId()
    local openBehavior = GetMarketProductOpenMarketBehavior(marketProductId)

    local additionalData = GetMarketProductOpenMarketBehaviorReferenceData(marketProductId)
    if openBehavior == OPEN_MARKET_BEHAVIOR_NAVIGATE_TO_PRODUCT then
        additionalData = marketProductId
    end

    if openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_CHAPTER_UPGRADE then
        ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_ANNOUNCEMENT, additionalData)
    else
        SYSTEMS:GetObject(ZO_MARKET_NAME):RequestShowMarket(MARKET_OPEN_OPERATION_ANNOUNCEMENT, openBehavior, additionalData)
    end
end

function ZO_MarketAnnouncement_Shared:GetDailyRewardsTilesData(tileInfoList)
    --- Don't add tile if Daily Rewards is locked
    if GetNumRewardsInCurrentDailyLoginMonth() ~= 0 then
         local dailyRewardIndex = ZO_DAILYLOGINREWARDS_MANAGER:GetDailyLoginRewardIndex()

        local dailyRewardTileInfo = 
        {
            type = ZO_ACTION_TILE_TYPE.DAILY_REWARDS,
            layoutParams = { dailyRewardIndex }
        }
        table.insert(tileInfoList, dailyRewardTileInfo)
    end
end

do
    local TILE_TYPE_TO_GET_TILE_INFO_FUNCTION = 
    {
        [ZO_ACTION_TILE_TYPE.DAILY_REWARDS] = ZO_MarketAnnouncement_Shared.GetDailyRewardsTilesData
    }
    function ZO_MarketAnnouncement_Shared:LayoutActionTiles()
        -- Get list of available tile infos 
        local availableTileInfoList = {}
        for _, tileInfoFunction in pairs(TILE_TYPE_TO_GET_TILE_INFO_FUNCTION) do
            tileInfoFunction(self, availableTileInfoList)
        end

        -- Clear Data from previous show
        self.actionTileList = {}
        for _, objectPool in pairs(self.actionTileObjectPoolMap) do
            objectPool:ReleaseAllObjects()
        end

        -- Create display tiles from available tile infos (Limited at 3 as that's the most the display supports)
        local NUM_MAX_DISPLAY_TILES = 3
        for i, actionTileInfo in ipairs(availableTileInfoList) do
             if self.actionTileObjectPoolMap[actionTileInfo.type] then
                local actionTile = self.actionTileObjectPoolMap[actionTileInfo.type]:AcquireObject()
                actionTile:Layout(unpack(actionTileInfo.layoutParams))
                table.insert(self.actionTileList, actionTile)

                local actionTileControl = actionTile:GetControl()

                -- Set Anchors
                local ACTION_TILE_HORIZONTAL_PADDING = 34
                if i > 1 then
                    actionTileControl:SetAnchor(TOPLEFT, self.actionTileList[i-1].control, TOPRIGHT, ACTION_TILE_HORIZONTAL_PADDING)
                else 
                    actionTileControl:SetAnchor(TOPLEFT)
                end
                actionTileControl:SetHidden(false)

                if #self.actionTileList == NUM_MAX_DISPLAY_TILES then
                    break
                end
            else
                assert("ObjectPool was not defined for Action Tile " .. i) 
            end
        end
    end
end

function ZO_MarketAnnouncement_Shared:CreateMarketProduct(productId)
    -- To be overridden
end