local RetraitStationManager = ZO_CallbackObject:Subclass()

function RetraitStationManager:New(...)
    local obj = ZO_CallbackObject.New(self)
    obj:Initialize(...)
    return obj
end

function RetraitStationManager:Initialize()
    self:RegisterForEvents()
    self:InitializeTraitData()
end

function RetraitStationManager:RegisterForEvents()
    EVENT_MANAGER:RegisterForEvent("RetraitStationManager", EVENT_RETRAIT_STATION_INTERACT_START, function(eventCode) SYSTEMS:ShowScene("retrait") end)
    EVENT_MANAGER:RegisterForEvent("RetraitStationManager", EVENT_RETRAIT_RESPONSE, function(eventCode, result) SYSTEMS:GetObject("retrait"):OnRetraitResult(result) end)

    local function HandleDirtyEvent()
        self:FireCallbacks("OnRetraitDirtyEvent")
    end

    EVENT_MANAGER:RegisterForEvent("RetraitStationManager", EVENT_INVENTORY_FULL_UPDATE, HandleDirtyEvent)
    EVENT_MANAGER:RegisterForEvent("RetraitStationManager", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleDirtyEvent)

    EVENT_MANAGER:RegisterForEvent("RetraitStationManager", EVENT_SMITHING_TRAIT_RESEARCH_STARTED, HandleDirtyEvent)
    EVENT_MANAGER:RegisterForEvent("RetraitStationManager", EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED, HandleDirtyEvent)
end

function RetraitStationManager:InitializeTraitData()
    self.traitInfo = {
        [ITEM_TRAIT_TYPE_CATEGORY_WEAPON] = {},
        [ITEM_TRAIT_TYPE_CATEGORY_ARMOR] = {},
    }

    for traitIndex = 1, GetNumSmithingTraitItems() do
        local traitType, traitItemName, traitItemIcon, sellPrice, meetsUsageRequirement, itemStyle, quality = GetSmithingTraitItemInfo(traitIndex)
        if traitType then
            local traitCategory = GetItemTraitTypeCategory(traitType)
            local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
            if self.traitInfo[traitCategory] then
                table.insert(self.traitInfo[traitCategory], {traitType = traitType, traitItemIcon = traitItemIcon, traitName = zo_strformat(SI_SMITHING_RESEARCH_TRAIT_NAME_FORMAT, traitName)})
            end
        end
    end
end

function RetraitStationManager:GetTraitInfo()
    return self.traitInfo
end

function RetraitStationManager:GetTraitInfoForCategory(itemTraitTypeCategory)
    return self.traitInfo[itemTraitTypeCategory]
end

do
    local retraitScenes = {}
    function RetraitStationManager:RegisterRetraitScene(retraitSceneName)
        retraitScenes[retraitSceneName] = true
    end

    function RetraitStationManager:IsRetraitSceneShowing()
        local showingSceneName = SCENE_MANAGER:GetCurrentSceneName()
        if showingSceneName then
            return retraitScenes[showingSceneName] == true
        end

        return false
    end
end

ZO_RETRAIT_STATION_MANAGER = RetraitStationManager:New()
