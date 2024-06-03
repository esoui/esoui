ZO_Gamepad_ParametricList_BagsSearch_Screen = ZO_Object.MultiSubclass(ZO_Gamepad_ParametricList_Search_Screen, ZO_TextSearchObject)

function ZO_Gamepad_ParametricList_BagsSearch_Screen:Initialize(searchContext, ...)
    ZO_Gamepad_ParametricList_Search_Screen.Initialize(self, BACKGROUND_LIST_FILTER_TARGET_BAG_SLOT, searchContext, ...)
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:IsDataInSearchTextResults(bagId, slotIndex)
    if self.searchContext then
        return TEXT_SEARCH_MANAGER:IsDataInSearchTextResults(self.searchContext, self.searchFilterType, bagId, slotIndex)
    end
    -- Return true for every result if we don't have a context search
    return true
end

function ZO_Gamepad_ParametricList_BagsSearch_Screen:MarkDirtyByBagId(bagId, shouldSuppressSearchUpdate)
    TEXT_SEARCH_MANAGER:MarkDirtyByFilterTargetAndPrimaryKey(self.searchFilterType, bagId, shouldSuppressSearchUpdate)
end
