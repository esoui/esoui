ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY = "root"

local Achievements_Manager = ZO_CallbackObject:Subclass()

function Achievements_Manager:New(...)
    local manager = ZO_CallbackObject.New(self)
    manager:Initialize(...)
    return manager
end

function Achievements_Manager:Initialize()
    self.searchString = ""
    self.searchResults = {}

    -- ESO-747009: Ensure that the last search string stored in C++ is reset when we reinitialize UI
    StartAchievementSearch("")

    local function OnAchievementsUpdated()
        -- When the data is getting rebuilt, the indicies can change so our old search results are no longer any good
        if self:GetSearchResults() then
            local currentSearch = self.searchString
            ZO_ClearTable(self.searchResults)
            local FORCE_REFRESH = true
            self:SetSearchString(currentSearch, FORCE_REFRESH)
        end
    end

    EVENT_MANAGER:RegisterForEvent("Achievements_Manager", EVENT_ACHIEVEMENTS_UPDATED, OnAchievementsUpdated)
    EVENT_MANAGER:RegisterForEvent("Achievements_Manager", EVENT_ACHIEVEMENT_AWARDED, OnAchievementsUpdated)
    EVENT_MANAGER:RegisterForEvent("Achievements_Manager", EVENT_ACHIEVEMENTS_SEARCH_RESULTS_READY, function() self:UpdateSearchResults() end)
end

function Achievements_Manager:ClearSearch(requiresImmediateRefresh)
    if self.searchString ~= "" then
        self:SetSearchString("")
    end

    if requiresImmediateRefresh then
        -- If we're relying on results being cleared this frame, do this now so any checks will work, and let the "search" run in the background
        -- so that C stays in sync.  This will result in a double update, but sometimes it can't be avoided
        ZO_ClearTable(self.searchResults)
        self:FireCallbacks("UpdateSearchResults")
    end
end

function Achievements_Manager:SetSearchString(searchString, forceRefresh)
    if forceRefresh or (self.searchString ~= (searchString or "")) then
        self.requestingSearchResults = true
        self.searchString = searchString or ""
        StartAchievementSearch(self.searchString, forceRefresh)
    end
end

function Achievements_Manager:IsRequestingSearchResults()
    return self.requestingSearchResults
end

function Achievements_Manager:UpdateSearchResults()
    self.requestingSearchResults = false

    ZO_ClearTable(self.searchResults)

    local searchResults = self.searchResults
    for i = 1, GetNumAchievementsSearchResults() do
        local categoryIndex, subcategoryIndex, achievementIndex = GetAchievementsSearchResult(i)

        local categoryData = searchResults[categoryIndex]
        if not categoryData then
            categoryData = {}
            searchResults[categoryIndex] = categoryData
        end

        local effectiveSubcategoryIndex = subcategoryIndex or ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY
        local effectiveSubcategoryData = categoryData[effectiveSubcategoryIndex]
        if not effectiveSubcategoryData then
            effectiveSubcategoryData = {}
            categoryData[effectiveSubcategoryIndex] = effectiveSubcategoryData
        end

        effectiveSubcategoryData[achievementIndex] = true
    end

    self:FireCallbacks("UpdateSearchResults")
end

function Achievements_Manager:GetSearchResults()
    if zo_strlen(self.searchString) > 1 then
        return self.searchResults
    end
    return nil
end

function Achievements_Manager:IsInSearchResults(categoryIndex, subcategoryIndex, achievementIndex)
    local searchResults = self:GetSearchResults()

    if searchResults then
        local effectiveSubcategoryIndex = subcategoryIndex or ZO_ACHIEVEMENTS_ROOT_SUBCATEGORY
        return searchResults[categoryIndex] and searchResults[categoryIndex][effectiveSubcategoryIndex] and searchResults[categoryIndex][effectiveSubcategoryIndex][achievementIndex]
    else
        return true
    end
end

ACHIEVEMENTS_MANAGER = Achievements_Manager:New()