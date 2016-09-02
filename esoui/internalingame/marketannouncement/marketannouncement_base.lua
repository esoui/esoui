----
-- ZO_MarketAnnouncementMarketProduct_Base
----

ZO_MarketAnnouncementMarketProduct_Base = ZO_LargeSingleMarketProduct_Base:Subclass()

function ZO_MarketAnnouncementMarketProduct_Base:New(...)
    return ZO_LargeSingleMarketProduct_Base.New(self, ...)
end

function ZO_MarketAnnouncementMarketProduct_Base:Initialize(...)
    ZO_LargeSingleMarketProduct_Base.Initialize(self, ...)
end

-- Market Announcements only show tiles in an available state, never as purchased or a "fail" condition
function ZO_MarketAnnouncementMarketProduct_Base:IsPurchaseLocked()
    return false
end

function ZO_MarketAnnouncementMarketProduct_Base:GetPurchaseState()
    return MARKET_PRODUCT_PURCHASE_STATE_NOT_PURCHASED
end

--
-- ZO_MarketProductCarousel
--

ZO_MarketProductCarousel = ZO_HorizontalScrollList_Gamepad:Subclass()

function ZO_MarketProductCarousel:New(...)
    return ZO_HorizontalScrollList_Gamepad.New(self, ...)
end

function ZO_MarketProductCarousel:Initialize(...)
    ZO_HorizontalScrollList_Gamepad.Initialize(self, ...)
end

do
    local function EntrySetup(control, data, selected, reselectingDuringRebuild, enabled, activated)
        if data.canSelect == nil then
            data.canSelect = true
        end

        data.marketProduct:InitializeControls(control)
        data.marketProduct:Show()
        data.marketProduct:SetIsFocused(selected)
    end

    local function OnSelectionChanged(newData)
        if newData.callback then
            newData.callback(newData)
        end
    end

    local NUM_VISIBLE_CATEGORIES = 1

    function ZO_MarketProductCarousel:Initialize(control, template)
        ZO_HorizontalScrollList_Gamepad.Initialize(self, control, template, NUM_VISIBLE_CATEGORIES, EntrySetup, MenuEntryTemplateEquality)
        self:SetOnTargetDataChangedCallback(OnSelectionChanged)
        self:SetAllowWrapping(false)
        self:SetDisplayEntryType(ZO_HORIZONTAL_SCROLL_LIST_ANCHOR_ENTRIES_AT_FIXED_DISTANCE)
        self:SetOffsetBetweenEntries(10)
        self:SetEntryWidth(ZO_LARGE_SINGLE_MARKET_PRODUCT_WIDTH)
    end
end

----
-- ZO_MarketAnnouncement_Base
----

ZO_MarketAnnouncement_Base = ZO_Object:Subclass()

function ZO_MarketAnnouncement_Base:New(...)
    local announcement = ZO_Object.New(self)
    announcement:Initialize(...)
    return announcement
end

function ZO_MarketAnnouncement_Base:InitializeKeybindButtons()
    local bindsContainer = self.controlContainer:GetNamedChild("Keybinds")

    self.closeButton = bindsContainer:GetNamedChild("Close")
    self.closeButton:SetKeybind("MARKET_ANNOUNCEMENT_CLOSE")
    self.closeButton:SetClickSound(SOUNDS.DIALOG_DECLINE)
    self.closeButton:SetCallback(function()
        self:OnMarketAnnouncementCloseKeybind()
    end)

    self.crownStoreButton = bindsContainer:GetNamedChild("CrownStore")
    self.crownStoreButton:SetKeybind("MARKET_ANNOUNCEMENT_VIEW_CROWN_STORE")
    self.crownStoreButton:SetClickSound(SOUNDS.DIALOG_ACCEPT)
    self.crownStoreButton:SetCallback(function()
        self:OnMarketAnnouncementViewCrownStoreKeybind()
    end)
end

function ZO_MarketAnnouncement_Base:Initialize(control, fragmentConditionFunction)
    self.control = control

    local container = control:GetNamedChild("Container")
    self.titleLabel = container:GetNamedChild("Title")
    self.positionLabel = container:GetNamedChild("PositionTracker")
    self.keybindsControl = container:GetNamedChild("Keybinds")
    self.carouselControl = container:GetNamedChild("Carousel")
    self.scrollContainer = container:GetNamedChild("ScrollContainer")
    self.productDescriptionLabel = self.scrollContainer:GetNamedChild("ScrollChildProductDescription")

    self.controlContainer = container

    self:InitializeKeybindButtons()
    local fragment = ZO_FadeSceneFragment:New(control)
    fragment:RegisterCallback("StateChange", function(...) self:OnStateChanged(...) end)
    if fragmentConditionFunction then
        fragment:SetConditional(fragmentConditionFunction)
    end
    self.fragment = fragment

    self.marketProductSelectedCallback = function(...) self:UpdateLabels(...) end
end

function ZO_MarketAnnouncement_Base:OnStateChanged(oldState, newState)
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

function ZO_MarketAnnouncement_Base:UpdateLabels(productData)
    local marketProduct = productData.marketProduct
    if marketProduct then
        local description = marketProduct:GetMarketProductDescription()
        local formattedDescription = zo_strformat(SI_MARKET_TEXT_FORMATTER, description)
        self:SetProductDescription(formattedDescription)
        self:UpdatePositionLabel(productData.index)
    end
end

function ZO_MarketAnnouncement_Base:SetProductDescription(description)
    self.productDescriptionLabel:SetText(description)
end

function ZO_MarketAnnouncement_Base:UpdatePositionLabel(index)
    self.positionLabel:SetText(zo_strformat(SI_MARKET_ANNOUNCEMENT_INDEX_FORMATTER, index, self.numAnnouncementProducts))
end

function ZO_MarketAnnouncement_Base:GetFragment()
    return self.fragment
end

do
    local MARKET_PRODUCT_SORT_KEYS =
        {
            isLimitedTime = {tiebreaker = "timeLeft", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            timeLeft = {isNumeric = true, tiebreaker = "containsDLC", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            containsDLC = { tiebreaker = "isNew", tieBreakerSortOrder = ZO_SORT_ORDER_DOWN },
            isNew = { tiebreaker = "name", tieBreakerSortOrder = ZO_SORT_ORDER_UP },
            name = {},
        }

    function CompareMarketProducts(entry1, entry2)
        return ZO_TableOrderingFunction(entry1, entry2, "isLimitedTime", MARKET_PRODUCT_SORT_KEYS, ZO_SORT_ORDER_DOWN)
    end

    function ZO_MarketAnnouncement_Base:OnShowing()
        if HasMarketAnnouncement() then
            local numAnnouncementProducts = GetNumMarketAnnouncementProducts()
            self.numAnnouncementProducts = numAnnouncementProducts

            self.carousel:Clear()
            if numAnnouncementProducts > 0 then --future proofing for likely addition of text-only announcements
                local productInfoTable = {}
                for i = 1, numAnnouncementProducts do
                    local productId = GetMarketAnnouncementProductDefId(i)
                    local marketProduct = self:CreateMarketProduct(productId)

                    local name, description, icon, isNew, isFeatured = marketProduct:GetMarketProductInfo()
                    local timeLeft = marketProduct:GetTimeLeftInSeconds()
                    local containsDLC = DoesMarketProductContainDLC(productId)
                    -- durations longer than 1 month aren't represented to the user, so it's effectively not limited time
                    local isLimitedTime = timeLeft > 0 and timeLeft <= ZO_ONE_MONTH_IN_SECONDS
                    local productInfo = {
                                            marketProduct = marketProduct,
                                            isLimitedTime = isLimitedTime,
                                            timeLeft = isLimitedTime and timeLeft or 0,
                                            isNew = isNew,
                                            name = name,
                                            containsDLC = containsDLC,
                                        }

                    table.insert(productInfoTable, productInfo)
                end

                table.sort(productInfoTable, CompareMarketProducts)

                for i = 1, numAnnouncementProducts do
                    local marketProduct = productInfoTable[i].marketProduct
                    self.carousel:AddEntry({marketProduct = marketProduct, callback = self.marketProductSelectedCallback, index = i})
                end
                self.carousel:Activate()
            end
            self.carousel:Commit()
        end
    end
end

function ZO_MarketAnnouncement_Base:OnShown()
end

function ZO_MarketAnnouncement_Base:OnHiding()
    self.carousel:Deactivate()
end

function ZO_MarketAnnouncement_Base:OnHidden()
end

function ZO_MarketAnnouncement_Base:OnMarketAnnouncementCloseKeybind()
    SCENE_MANAGER:HideCurrentScene()
end

function ZO_MarketAnnouncement_Base:OnMarketAnnouncementViewCrownStoreKeybind()
    local targetData = self.carousel:GetSelectedData()
    local marketProductId = targetData.marketProduct:GetId()
    SetOpenMarketSource(MARKET_OPEN_OPERATION_ANNOUNCEMENT)
    SYSTEMS:GetObject(ZO_MARKET_NAME):OnShowMarketProduct(marketProductId)
end

-- Functions to be overridden

function ZO_MarketAnnouncement_Base:CreateMarketProduct(productId)
end