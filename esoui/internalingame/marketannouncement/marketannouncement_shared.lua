----
-- ZO_MarketAnnouncement_Shared
----

ZO_MARKET_ANNOUNCEMENT_TILE_DIMENSIONS_X = 315
ZO_MARKET_ANNOUNCEMENT_TILE_DIMENSIONS_Y = 210
ZO_MARKET_ANNOUNCEMENT_TILE_DIMENSIONS_ASPECT_RATIO = ZO_MARKET_ANNOUNCEMENT_TILE_DIMENSIONS_X / ZO_MARKET_ANNOUNCEMENT_TILE_DIMENSIONS_Y

ZO_ACTION_TILE_TYPE =
{
    EVENT_ANNOUNCEMENT = 1,
    DAILY_REWARDS = 2,
    ZONE_STORIES = 3,
    PROMOTIONAL_EVENT = 4,
}

ZO_ACTION_SORTED_TILE_TYPE =
{
    ZO_ACTION_TILE_TYPE.EVENT_ANNOUNCEMENT,
    ZO_ACTION_TILE_TYPE.DAILY_REWARDS,
    ZO_ACTION_TILE_TYPE.PROMOTIONAL_EVENT,
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
    self.crownStoreLockedTitleControl = self.crownStoreLockedControl:GetNamedChild("TitleText")
    self.crownStoreLockedDescriptionControl = self.crownStoreLockedControl:GetNamedChild("DescriptionText")
    self.crownStoreLockedTexture = self.crownStoreLockedControl:GetNamedChild("Background")

    self.controlContainer = container

    self.actionTileList = {}
    self.actionTileControlPoolMap = {}
    for _, tileType in pairs(ZO_ACTION_TILE_TYPE) do
        self:AddTileTypeObjectPoolToMap(tileType)
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
        self:OnDailyLoginRewardsUpdated()
    end

    ZO_MARKET_ANNOUNCEMENT_MANAGER:RegisterCallback("OnMarketAnnouncementDataUpdated", function() self:UpdateMarketCarousel() end)
    ZO_MARKET_ANNOUNCEMENT_MANAGER:RegisterCallback("EventAnnouncementExpired", function() self:LayoutActionTiles() end)
    PROMOTIONAL_EVENT_MANAGER:RegisterCallback("CampaignsUpdated", function() self:LayoutActionTiles() end)
    control:RegisterForEvent(EVENT_DAILY_LOGIN_REWARDS_UPDATED, OnDailyLoginRewardsUpdated)
end

function ZO_MarketAnnouncement_Shared:AddTileTypeObjectPoolToMap(tileType)
    self.actionTileControlPoolMap[tileType] = ZO_ControlPool:New(self.actionTileControlByType[tileType], self.actionTileListControl)

    local function ResetFunction(control)
        control.object:Reset()
    end
    self.actionTileControlPoolMap[tileType]:SetCustomResetBehavior(ResetFunction)
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

function ZO_MarketAnnouncement_Shared:OnDailyLoginRewardsUpdated()
    if self.fragment:IsShowing() then
        self:LayoutActionTiles()
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
    RequestEventAnnouncements()
    self:LayoutActionTiles()

    if not IsPromotionalEventSystemLocked() and PROMOTIONAL_EVENT_MANAGER:IsCampaignActive() then
        PlaySound(SOUNDS.PROMOTIONAL_EVENTS_ANNOUNCE)
    end

    if ZO_MARKET_ANNOUNCEMENT_MANAGER:ShouldHideMarketProductAnnouncements() then
        if GetMarketAnnouncementCrownStoreLocked() then
            self.crownStoreLockedTitleControl:SetText(GetString(SI_MARKET_ANNOUNCEMENT_LOCKED_CROWN_STORE_TITLE))
            self.crownStoreLockedDescriptionControl:SetHidden(false)
        else
            self.crownStoreLockedTitleControl:SetText(GetString(SI_MARKET_ANNOUNCEMENT_NO_FEATURED_PRODUCTS_TITLE))
            self.crownStoreLockedDescriptionControl:SetHidden(true)
        end
        self.carouselControl:SetHidden(true)
        self.crownStoreLockedControl:SetHidden(false)
        self.crownStoreLockedTexture:SetTexture(GetMarketAnnouncementCrownStoreLockedBackground())
    else
        UpdateMarketAnnouncement()
        self:UpdateMarketCarousel()
        self.carousel:Activate()
        self.carouselControl:SetHidden(false)
        self.crownStoreLockedControl:SetHidden(true)
    end
end

function ZO_MarketAnnouncement_Shared:OnShown()
    -- To be overridden
end

function ZO_MarketAnnouncement_Shared:OnHiding()
    PlaySound(SOUNDS.DEFAULT_WINDOW_CLOSE)
    self.carousel:Deactivate()
end

function ZO_MarketAnnouncement_Shared:OnHidden()
    -- To be overridden
end

function ZO_MarketAnnouncement_Shared:UpdateMarketCarousel()
    if self.fragment:IsShowing() then
        local productInfoTable = ZO_MARKET_ANNOUNCEMENT_MANAGER:GetProductInfoTable()

        self.carousel:Clear()
        for index, productInfo in ipairs(productInfoTable) do
            local marketProduct = self:CreateMarketProduct()
            marketProduct:SetMarketProductData(productInfo.productData)
            local data =
            {
                marketProduct = marketProduct,
                callback = self.marketProductSelectedCallback,
                index = index
            }
            self.carousel:AddEntry(data)
        end
        self.carousel:Commit()

        if #productInfoTable > 0 then
            self.carousel:UpdateSelection(1)
        end
    end
end

function ZO_MarketAnnouncement_Shared:OnSelectionClicked()
    -- To be overridden
end

function ZO_MarketAnnouncement_Shared:OnHelpClicked()
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

    internalassert(marketProductId ~= 0, string.format("Announcement Crown Store Keybind for %s has a market product id: 0", targetData.marketProduct:GetMarketProductDisplayName()))

    self:DoOpenMarketBehaviorForMarketProductId(marketProductId)
end

function ZO_MarketAnnouncement_Shared:DoOpenMarketBehaviorForMarketProductId(marketProductId)
    local openBehavior = GetMarketProductOpenMarketBehavior(marketProductId)

    local additionalData = GetMarketProductOpenMarketBehaviorReferenceData(marketProductId)
    if openBehavior == OPEN_MARKET_BEHAVIOR_NAVIGATE_TO_PRODUCT then
        additionalData = marketProductId
    end

    if openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_CHAPTER_UPGRADE then
        ZO_ShowChapterUpgradePlatformScreen(MARKET_OPEN_OPERATION_ANNOUNCEMENT, additionalData)
    elseif not IsInGamepadPreferredMode() and openBehavior == OPEN_MARKET_BEHAVIOR_SHOW_ESO_PLUS_CATEGORY then
        ESO_PLUS_OFFERS_KEYBOARD:RequestShowMarket(MARKET_OPEN_OPERATION_ANNOUNCEMENT, openBehavior, additionalData)
    else
        SYSTEMS:GetObject(ZO_MARKET_NAME):RequestShowMarket(MARKET_OPEN_OPERATION_ANNOUNCEMENT, openBehavior, additionalData)
    end
end

function ZO_MarketAnnouncement_Shared.GetEventAnnouncementTilesData(tileInfoList)
    --- Add tile if there is an active event
    if ZO_MARKET_ANNOUNCEMENT_MANAGER:GetNumEventAnnouncements() > 0 then
        local eventAnnouncementTileInfo =
        {
            type = ZO_ACTION_TILE_TYPE.EVENT_ANNOUNCEMENT,
            data =
            {
                eventAnnouncementIndex = 1 -- Always show first sorted announcement on the tile
            },
            visible = true,
        }
        table.insert(tileInfoList, eventAnnouncementTileInfo)
    end
end

function ZO_MarketAnnouncement_Shared.GetDailyRewardsTilesData(tileInfoList)
    --- Add tile if Daily Rewards is unlocked
    if not ZO_DAILYLOGINREWARDS_MANAGER:IsDailyRewardsLocked() then
         local dailyRewardIndex = ZO_DAILYLOGINREWARDS_MANAGER:GetDailyLoginRewardIndex()

        local dailyRewardTileInfo =
        {
            type = ZO_ACTION_TILE_TYPE.DAILY_REWARDS,
            data =
            {
                dailyRewardIndex = dailyRewardIndex
            },
            visible = true,
        }
        table.insert(tileInfoList, dailyRewardTileInfo)
    end
end

function ZO_MarketAnnouncement_Shared.GetZoneStoriesTilesData(tileInfoList)
    local zoneId
    if IsZoneStoryTracked() then
        zoneId = GetTrackedZoneStoryActivityInfo()
    else
        local zoneIndex = GetUnitZoneIndex("player")
        zoneId = ZO_ExplorationUtils_GetZoneStoryZoneIdByZoneIndex(zoneIndex)
    end

    if HasZoneStoriesData(zoneId) and not IsZoneStoryComplete(zoneId) then
        local zoneStoriesTileInfo =
        {
            type = ZO_ACTION_TILE_TYPE.ZONE_STORIES,
            data =
            {
                zoneId = zoneId,
            },
            visible = true,
        }
        table.insert(tileInfoList, zoneStoriesTileInfo)
    end
end

function ZO_MarketAnnouncement_Shared.GetPromotionalEventTilesData(tileInfoList)
    if not IsPromotionalEventSystemLocked() then
        local promotionalEventTileInfo =
        {
            type = ZO_ACTION_TILE_TYPE.PROMOTIONAL_EVENT,
            data =
            {
            },
            visible = function()
                return PROMOTIONAL_EVENT_MANAGER:IsCampaignActive()
            end,
        }
        table.insert(tileInfoList, promotionalEventTileInfo)
    end
end

do
    ZO_TILE_TYPE_TO_GET_TILE_INFO_FUNCTION =
    {
        [ZO_ACTION_TILE_TYPE.EVENT_ANNOUNCEMENT] = ZO_MarketAnnouncement_Shared.GetEventAnnouncementTilesData,
        [ZO_ACTION_TILE_TYPE.DAILY_REWARDS] = ZO_MarketAnnouncement_Shared.GetDailyRewardsTilesData,
        [ZO_ACTION_TILE_TYPE.PROMOTIONAL_EVENT] = ZO_MarketAnnouncement_Shared.GetPromotionalEventTilesData,
        [ZO_ACTION_TILE_TYPE.ZONE_STORIES] = ZO_MarketAnnouncement_Shared.GetZoneStoriesTilesData,
    }
    function ZO_MarketAnnouncement_Shared:LayoutActionTiles()
        -- Get list of available tile infos
        local availableTileInfoList = {}
        for _, data in ipairs(ZO_ACTION_SORTED_TILE_TYPE) do
            local tileInfoFunction = ZO_TILE_TYPE_TO_GET_TILE_INFO_FUNCTION[data]
            tileInfoFunction(availableTileInfoList)
        end

        -- Clear Data from previous show
        self.actionTileList = {}
        for _, controlPool in pairs(self.actionTileControlPoolMap) do
            controlPool:ReleaseAllObjects()
        end

        -- Create display tiles from available tile infos (Limited at 3 as that's the most the display supports)
        local NUM_MAX_DISPLAY_TILES = 3
        for i, actionTileInfo in ipairs(availableTileInfoList) do
            local visible
            if type(actionTileInfo.visible) == "function" then
                visible = actionTileInfo.visible()
            else
                visible = actionTileInfo.visible
            end

            if visible and self.actionTileControlPoolMap[actionTileInfo.type] then
                local actionTileControl = self.actionTileControlPoolMap[actionTileInfo.type]:AcquireObject()
                actionTileControl.object:Layout(actionTileInfo.data)
                table.insert(self.actionTileList, actionTileControl)

                -- Set Anchors
                local ACTION_TILE_HORIZONTAL_PADDING = 34
                if #self.actionTileList > 1 then
                    actionTileControl:SetAnchor(TOPLEFT, self.actionTileList[i-1], TOPRIGHT, ACTION_TILE_HORIZONTAL_PADDING)
                else 
                    actionTileControl:SetAnchor(TOPLEFT)
                end

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