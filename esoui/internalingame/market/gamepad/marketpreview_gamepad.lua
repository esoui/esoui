ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME = "gamepad_market_preview"

ZO_MarketPreview_Gamepad = ZO_Object:Subclass()

function ZO_MarketPreview_Gamepad:New(...)
    local marketPreview = ZO_Object.New(self)
    marketPreview:Initialize(...)
    return marketPreview
end

function ZO_MarketPreview_Gamepad:Initialize()
    self.previewKeybindStripDesciptor =
    {
        -- ITEM_PREVIEW_LIST_HELPER_GAMEPAD will handle the prev/next keybinds
        KEYBIND_STRIP:GetDefaultGamepadBackButtonDescriptor()
    }

    self:InitializePreviewScene()
    self:InitializeNarrationInfo()
end

function ZO_MarketPreview_Gamepad:InitializePreviewScene()
    GAMEPAD_MARKET_PREVIEW_SCENE = ZO_RemoteScene:New(ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME, SCENE_MANAGER)

    local OnPreviewChangedFunction = function(...) self:OnPreviewChanged(...) end
    local OnRefreshActionsFunction = function(...) self:OnRefreshActions(...) end
    local OnCanChangePreviewChangedFunction = function(...) self:OnCanChangePreviewChanged(...) end

    local function OnPreviewSceneStateChange(oldState, newState)
        if newState == SCENE_SHOWING then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.previewKeybindStripDesciptor)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:RegisterCallback("OnPreviewChanged", OnPreviewChangedFunction)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:RegisterCallback("RefreshActions", OnRefreshActionsFunction)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:RegisterCallback("CanChangePreviewChanged", OnCanChangePreviewChangedFunction)
        elseif newState == SCENE_SHOWN then
            --Preventing an out of order issue with the begin preview mode
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:PreviewList(ZO_ITEM_PREVIEW_MARKET_PRODUCT, self.previewListEntries, self.startingIndex)
        elseif newState == SCENE_HIDDEN then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.previewKeybindStripDesciptor)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:UnregisterCallback("OnPreviewChanged", OnPreviewChangedFunction)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:UnregisterCallback("RefreshActions", OnRefreshActionsFunction)
            ITEM_PREVIEW_LIST_HELPER_GAMEPAD:UnregisterCallback("CanChangePreviewChanged", OnCanChangePreviewChangedFunction)
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
    end

    GAMEPAD_MARKET_PREVIEW_SCENE:RegisterCallback("StateChange", OnPreviewSceneStateChange)
end

function ZO_MarketPreview_Gamepad:InitializeNarrationInfo()
    local narrationInfo =
    {
        canNarrate = function()
            return GAMEPAD_MARKET_PREVIEW_SCENE:IsShowing()
        end,
        headerNarrationFunction = function()
            local marketProductId = self:GetCurrentPreviewData()
            if marketProductId and ITEM_PREVIEW_LIST_HELPER_GAMEPAD:HasVariations() then
                local name = GetMarketProductInfo(marketProductId)
                return SCREEN_NARRATION_MANAGER:CreateNarratableObject(zo_strformat(SI_MARKET_PRODUCT_NAME_FORMATTER, name))
            end
        end,
        selectedNarrationFunction = function()
            return ITEM_PREVIEW_LIST_HELPER_GAMEPAD:GetPreviewNarrationText()
        end,
        additionalInputNarrationFunction = function()
            local narrationFunction = ITEM_PREVIEW_LIST_HELPER_GAMEPAD:GetAdditionalInputNarrationFunction()
            if narrationFunction then
                return narrationFunction()
            end
        end,
    }
    SCREEN_NARRATION_MANAGER:RegisterCustomObject("MarketPreviewGamepad", narrationInfo)
end

function ZO_MarketPreview_Gamepad:OnPreviewChanged(previewData)
    self:RefreshTooltip()
    if self.onPreviewChangedCallback then
        self.onPreviewChangedCallback(previewData)
    end
end

function ZO_MarketPreview_Gamepad:OnRefreshActions()
    SCREEN_NARRATION_MANAGER:QueueCustomEntry("MarketPreviewGamepad")
end

function ZO_MarketPreview_Gamepad:OnCanChangePreviewChanged(canChangePreview)
    if canChangePreview then
        local NARRATE_HEADER = true
        SCREEN_NARRATION_MANAGER:QueueCustomEntry("MarketPreviewGamepad", NARRATE_HEADER)
    end
end

function ZO_MarketPreview_Gamepad:RefreshTooltip()
    local marketProductId = self:GetCurrentPreviewData()
    if marketProductId then
        GAMEPAD_TOOLTIPS:LayoutMarketProduct(GAMEPAD_RIGHT_TOOLTIP, marketProductId)
    end
end

function ZO_MarketPreview_Gamepad:GetCurrentPreviewData()
    return ITEM_PREVIEW_LIST_HELPER_GAMEPAD:GetCurrentPreviewData()
end

function ZO_MarketPreview_Gamepad:BeginPreview(previewListEntries, startingIndex, onPreviewChangedCallback)
    self.previewListEntries = previewListEntries
    self.startingIndex = startingIndex
    self.onPreviewChangedCallback = onPreviewChangedCallback
    SCENE_MANAGER:Push(ZO_GAMEPAD_MARKET_PREVIEW_SCENE_NAME)
end

ZO_MARKET_PREVIEW_GAMEPAD = ZO_MarketPreview_Gamepad:New()
