function ZO_FurnishingsFilter_ApplyToSearch(search, categoryData, subcategoryData, specializedItemTypeData)
    if categoryData then
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_FURNITURE_CATEGORY, categoryData.minValue)
    else
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_FURNITURE_CATEGORY, nil)
    end

    if subcategoryData then
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_FURNITURE_SUBCATEGORY, subcategoryData.minValue)
    else
        search:SetFilter(TRADING_HOUSE_FILTER_TYPE_FURNITURE_SUBCATEGORY, nil)
    end

    search:SetFilter(TRADING_HOUSE_FILTER_TYPE_SPECIALIZED_ITEM, specializedItemTypeData.minValue)
end