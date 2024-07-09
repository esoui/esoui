ZO_HouseTours_Keyboard = ZO_InitializingObject:Subclass()

function ZO_HouseTours_Keyboard:Initialize()
    --TODO House Tours: Implement any additional setup
    self:InitializeActivityFinderCategory()
end

function ZO_HouseTours_Keyboard:InitializeActivityFinderCategory()
    local houseToursCategoryData =
    {
        priority = ZO_ACTIVITY_FINDER_SORT_PRIORITY.HOUSE_TOURS,
        name = GetString(SI_ACTIVITY_FINDER_CATEGORY_HOUSE_TOURS),
        onTreeEntrySelected = function() HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:OnCategorySelected(HOUSE_TOURS_LISTING_TYPE_RECOMMENDED) end,
        normalIcon = "EsoUI/Art/LFG/LFG_indexIcon_houseTours_up.dds",
        pressedIcon = "EsoUI/Art/LFG/LFG_indexIcon_houseTours_down.dds",
        mouseoverIcon = "EsoUI/Art/LFG/LFG_indexIcon_houseTours_over.dds",
        disabledIcon = "EsoUI/Art/LFG/LFG_indexIcon_houseTours_disabled.dds",
        children =
        {
            HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:GetActivityFinderCategoryData(HOUSE_TOURS_LISTING_TYPE_RECOMMENDED),
            HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:GetActivityFinderCategoryData(HOUSE_TOURS_LISTING_TYPE_BROWSE),
            HOUSE_TOURS_SEARCH_RESULTS_KEYBOARD:GetActivityFinderCategoryData(HOUSE_TOURS_LISTING_TYPE_FAVORITE),
            HOUSE_TOURS_MANAGE_LISTINGS_KEYBOARD:GetActivityFinderCategoryData(),
        },
        isHouseTours = true,
    }
    GROUP_MENU_KEYBOARD:AddCategory(houseToursCategoryData)
end

HOUSE_TOURS_KEYBOARD = ZO_HouseTours_Keyboard:New()