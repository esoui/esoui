ZO_ItemPreviewListHelper_Shared = ZO_CallbackObject:Subclass()

function ZO_ItemPreviewListHelper_Shared:New(...)
    local object = ZO_CallbackObject.New(self)
    object:Initialize(...)
    return object
end

function ZO_ItemPreviewListHelper_Shared:Initialize(control)
    self.control = control
    self.dontWrap = false
    self.previewListEntries = {}

    self:ClearPreviewData()

    self.fragment = ZO_SimpleSceneFragment:New(control)
    self.fragment:SetHideOnSceneHidden(true)
    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            self:OnShowing()
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            self:OnHidden()
        end
    end)

    self.RefreshActionsCallback = function()
        self:RefreshActions()
    end

    self.CanChangePreviewChangedCallback = function(...)
        self:FireCallbacks("CanChangePreviewChanged", ...)
    end

    self.EndCurrentPreviewCallback = function()
        self:ClearPreviewData()
        self:RefreshActions()
    end
end

function ZO_ItemPreviewListHelper_Shared:ClearPreviewData()
    ZO_ClearNumericallyIndexedTable(self.previewListEntries)
    self.previewType = nil
    self.previewIndex = nil
    self.previewData = nil
end

function ZO_ItemPreviewListHelper_Shared:PreviewList(previewType, previewListEntries, startingIndex, dontWrap)
    assert(previewListEntries and #previewListEntries > 0)

    self:ClearPreviewData()
    for previewIndex, previewData in ipairs(previewListEntries) do
        self.previewListEntries[previewIndex] = previewData
    end
    self.previewType = previewType
    self:SetPreviewIndex(startingIndex or 1)
    self.dontWrap = dontWrap == true -- coerce to bool
end

function ZO_ItemPreviewListHelper_Shared:UpdatePreviewList(newPreviewList, dontReselectCurrentEntry)
    local currentEntryIndex = nil
    -- Copy new previews over old list
    ZO_ClearNumericallyIndexedTable(self.previewListEntries)
    for newPreviewIndex, newPreviewData in ipairs(newPreviewList) do
        self.previewListEntries[newPreviewIndex] = newPreviewData

        if newPreviewData == self.previewData then
            currentEntryIndex = newPreviewIndex
        end
    end

    -- Select a new entry
    if dontReselectCurrentEntry then
        currentEntryIndex = 1
    end

    if currentEntryIndex == nil then
        -- try to pick the element in the list closest to the old index.
        -- If the old entry wasn't at the end of the list or further, that means we pick the next item index-wise. If it is at the end, that means we pick the last item in that list
        currentEntryIndex = math.min(#self.previewListEntries, self.previewIndex)
    end
    
    self:SetPreviewIndex(currentEntryIndex)
end

function ZO_ItemPreviewListHelper_Shared:CanPreviewNext()
    if not self:HasMultiplePreviewDatas() then
        return false
    end

    if self.dontWrap then
        return self.previewIndex < #self.previewListEntries
    end

    return true
end

function ZO_ItemPreviewListHelper_Shared:PreviewNext()
    if self:CanPreviewNext() then
        local previewIndex = self.previewIndex + 1

        if previewIndex > #self.previewListEntries then
            previewIndex = previewIndex - #self.previewListEntries
        end

        self:SetPreviewIndex(previewIndex)
    end
end

function ZO_ItemPreviewListHelper_Shared:CanPreviewPrevious()
    if not self:HasMultiplePreviewDatas() then
        return false
    end

    if self.dontWrap then
        return self.previewIndex > 1
    end

    return true
end

function ZO_ItemPreviewListHelper_Shared:PreviewPrevious()
    if self:CanPreviewPrevious() then
        local previewIndex = self.previewIndex - 1

        if previewIndex < 1 then
            previewIndex = #self.previewListEntries - previewIndex
        end

        self:SetPreviewIndex(previewIndex)
    end
end

function ZO_ItemPreviewListHelper_Shared:SetPreviewIndex(previewIndex)
    local previewData = self.previewListEntries[previewIndex]
    if self:IsValidPreviewIndex(previewIndex) and self.previewData ~= previewData then
        self.previewIndex = previewIndex
        self.previewData = previewData
        local previewObject = self:GetPreviewObject()

        previewObject:ClearPreviewCollection()
        if type(previewData) == "table" then
            previewObject:SharedPreviewSetup(self.previewType, unpack(previewData))
        else
            previewObject:SharedPreviewSetup(self.previewType, previewData)
        end

        self:FireCallbacks("OnPreviewChanged", previewData)
    end
end

function ZO_ItemPreviewListHelper_Shared:EndCurrentPreview()
    self:GetPreviewObject():EndCurrentPreview()
end

function ZO_ItemPreviewListHelper_Shared:GetPreviewIndex()
    return self.previewIndex
end

function ZO_ItemPreviewListHelper_Shared:GetPreviewData(previewIndex)
    if self:IsValidPreviewIndex(previewIndex) then
        return self.previewListEntries[previewIndex]
    end
end

function ZO_ItemPreviewListHelper_Shared:GetCurrentPreviewData()
    return self:GetPreviewData(self.previewIndex)
end

function ZO_ItemPreviewListHelper_Shared:GetCurrentPreviewTypeAndData()
    local data = self:GetCurrentPreviewData()
    local previewType = self.previewType
    local previewData = nil

    -- A previewType of nil indicates that the previewType is specified
    -- per list entry as the first element in the data array.
    if previewType == nil and type(data) == "table" then
        previewType = data[1]
        previewData = {select(2, unpack(data))}
    else
        previewData = data
    end

    if type(previewData) == "table" then
        return previewType, unpack(previewData)
    end
    return previewType, previewData
end

function ZO_ItemPreviewListHelper_Shared:IsValidPreviewIndex(previewIndex)
    if previewIndex >= 1 and previewIndex <= #self.previewListEntries then
        return true
    end
    return false
end

function ZO_ItemPreviewListHelper_Shared:GetPreviewObject()
    assert(false) -- Must be overriden
end

function ZO_ItemPreviewListHelper_Shared:GetFragment()
    return self.fragment
end

function ZO_ItemPreviewListHelper_Shared:HasMultiplePreviewDatas()
    return self.previewListEntries and #self.previewListEntries > 1
end

function ZO_ItemPreviewListHelper_Shared:HasVariations()
    return self:GetPreviewObject():HasVariations()
end

function ZO_ItemPreviewListHelper_Shared:RefreshActions()
    self:FireCallbacks("RefreshActions")
end

function ZO_ItemPreviewListHelper_Shared:OnShowing()
    self:GetPreviewObject():RegisterCallback("RefreshActions", self.RefreshActionsCallback)
    self:GetPreviewObject():RegisterCallback("CanChangePreviewChanged", self.CanChangePreviewChangedCallback)
    self:GetPreviewObject():RegisterCallback("EndCurrentPreview", self.EndCurrentPreviewCallback)
end

function ZO_ItemPreviewListHelper_Shared:OnHidden()
    self:ClearPreviewData()

    self:GetPreviewObject():UnregisterCallback("RefreshActions", self.RefreshActionsCallback)
    self:GetPreviewObject():UnregisterCallback("CanChangePreviewChanged", self.CanChangePreviewChangedCallback)
    self:GetPreviewObject():UnregisterCallback("EndCurrentPreview", self.EndCurrentPreviewCallback)
end

function ZO_ItemPreviewListHelper_Shared:PreviewMarketProduct(marketProductId)
    if marketProductId ~= 0 then
        local previewList
        if GetMarketProductType(marketProductId) == MARKET_PRODUCT_TYPE_BUNDLE then
            previewList = {}
            for i = 1, GetMarketProductNumChildren(marketProductId) do
                local childMarketProductId = GetMarketProductChildId(marketProductId, i)
                -- Only preview the parts of the bundle that actually can be previewed
                if CanPreviewMarketProduct(childMarketProductId) then
                    table.insert(previewList, childMarketProductId)
                end
            end
        else
            -- If we got here, we already validated that it can be previewed
            previewList = { marketProductId }
        end

        if #previewList > 0 then
            self:PreviewList(ZO_ITEM_PREVIEW_MARKET_PRODUCT, previewList)
        end
    end
end

function ZO_ItemPreviewListHelper_Shared:CanPreviewMarketProduct(marketProductId)
    if marketProductId ~= 0 then
        if GetMarketProductType(marketProductId) == MARKET_PRODUCT_TYPE_BUNDLE then
            for i = 1, GetMarketProductNumChildren(marketProductId) do
                local childMarketProductId = GetMarketProductChildId(marketProductId, i)
                if CanPreviewMarketProduct(childMarketProductId) then
                    -- If we can preview anything in this bundle it's enough to start a preview.  We'll figure out which ones to include when we actually decide to preview.
                    return true
                end
            end
        else
            return CanPreviewMarketProduct(marketProductId)
        end
    end
    return false
end