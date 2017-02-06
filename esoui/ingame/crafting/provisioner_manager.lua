ZO_ProvisionerManager = ZO_CallbackObject:Subclass()

local DIRTY =
{
    ALL = 1,
    NUM_CREATABLE = 2,
    MEETS_REQUIREMENTS = 3,
}

function ZO_ProvisionerManager:New(...)
    local obj = ZO_CallbackObject.New(self)
    obj:Initialize(...)
    return obj
end

function ZO_ProvisionerManager:Initialize()
    self.dirtyFlags = {}
    self:ClearDirtyFlags()
    self.dirtyFlags[DIRTY.ALL] = true

    EVENT_MANAGER:RegisterForEvent("ZO_ProvisionerManager", EVENT_RECIPE_LEARNED, function()
        self:MarkDirtyFlag(DIRTY.ALL)
    end)

    EVENT_MANAGER:RegisterForEvent("ZO_ProvisionerManager", EVENT_INVENTORY_FULL_UPDATE, function()
        self:MarkDirtyFlag(DIRTY.NUM_CREATABLE)
    end)
    EVENT_MANAGER:RegisterForEvent("ZO_ProvisionerManager", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, function()
        self:MarkDirtyFlag(DIRTY.NUM_CREATABLE)
    end)

    EVENT_MANAGER:RegisterForEvent("ZO_ProvisionerManager", EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if GetTradeskillTypeForNonCombatBonusLevelType(nonCombatBonusType) ~= CRAFTING_TYPE_INVALID or nonCombatBonusType == NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL then
            self:MarkDirtyFlag(DIRTY.MEETS_REQUIREMENTS)
        end
    end)
end

function ZO_ProvisionerManager:MarkDirtyFlag(flagValue)
    self.dirtyFlags[flagValue] = true
    self:FireCallbacks("RecipeDataUpdated")
end

function ZO_ProvisionerManager:ClearDirtyFlags()
    for flag, flagValue in pairs(DIRTY) do
        self.dirtyFlags[flagValue] = false
    end
end

function ZO_ProvisionerManager:GetRecipeData()
    if self.dirtyFlags[DIRTY.ALL] then
        self:BuildRecipeData()
    else
        if self.dirtyFlags[DIRTY.NUM_CREATABLE] then
            for _, recipeList in pairs(self.recipeData) do
                for _, recipe in ipairs(recipeList.recipes) do
                    recipe.numCreatable = self:CalculateHowManyCouldBeCreated(recipe.recipeListIndex, recipe.recipeIndex, recipe.numIngredients)
                end
            end
        end
        if self.dirtyFlags[DIRTY.MEETS_REQUIREMENTS] then
            for _, recipeList in pairs(self.recipeData) do
                for _, recipe in ipairs(recipeList.recipes) do
                    recipe.passesTradeskillLevelReqs = self:PassesTradeskillLevelReqs(recipe.tradeskillsLevelReqs)
                    recipe.passesQualityLevelReq = self:PassesQualityLevelReq(recipe.qualityReq)
                end
            end
        end
    end
    self:ClearDirtyFlags()

    return self.recipeData
end

function ZO_ProvisionerManager:CalculateHowManyCouldBeCreated(recipeListIndex, recipeIndex, numIngredients)
    local minCount

    for ingredientIndex = 1, numIngredients do
        local _, _, requiredQuantity = GetRecipeIngredientItemInfo(recipeListIndex, recipeIndex, ingredientIndex)
        local ingredientCount = GetCurrentRecipeIngredientCount(recipeListIndex, recipeIndex, ingredientIndex)

        minCount = zo_min(zo_floor(ingredientCount / requiredQuantity), minCount or math.huge)
        if minCount == 0 then
            return 0
        end
    end

    return minCount or 0
end

function ZO_ProvisionerManager:PassesTradeskillLevelReqs(tradeskillsReqs)
    for tradeskill, levelReq in pairs(tradeskillsReqs) do
        local level = GetNonCombatBonus(GetNonCombatBonusLevelTypeForTradeskillType(tradeskill))
        if level < levelReq then
            return false
        end
    end
    return true
end

function ZO_ProvisionerManager:PassesQualityLevelReq(qualityReq)
    if qualityReq == 0 then
        return true
    else
        --Only exclusively provisioning system recipes have a quality requirement
        return GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL) >= qualityReq
    end
end

local DEFAULT_RECIPE_CREATE_SOUND = SOUNDS.DEFAULT_RECIPE_CRAFTED
function ZO_ProvisionerManager:BuildRecipeData()
    self.recipeData = {}

    for recipeListIndex = 1, GetNumRecipeLists() do
        local recipeListName, numRecipes, upIcon, downIcon, overIcon, disabledIcon, recipeListCreateSound = GetRecipeListInfo(recipeListIndex)
        for recipeIndex = 1, numRecipes do
            local known, recipeName, numIngredients, _, qualityReq, specialIngredientType, requiredCraftingStationType = GetRecipeInfo(recipeListIndex, recipeIndex)
            local _, resultIcon = GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
            if known then
                local numCreatable = self:CalculateHowManyCouldBeCreated(recipeListIndex, recipeIndex, numIngredients)
                local tradeskillsLevelReqs = {}
                for tradeskillIndex = 1, GetNumRecipeTradeskillRequirements(recipeListIndex, recipeIndex) do
                    local tradeskill, levelReq = GetRecipeTradeskillRequirement(recipeListIndex, recipeIndex, tradeskillIndex)
                    tradeskillsLevelReqs[tradeskill] = levelReq
                end

                local itemLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)
                local quality = GetItemLinkQuality(itemLink)
                local createSound = recipeListCreateSound
                if createSound == "" then
                    createSound = DEFAULT_RECIPE_CREATE_SOUND
                end
                local recipe = {
                    recipeListName = recipeListName,
                    recipeListIndex = recipeListIndex,
                    recipeIndex = recipeIndex,
                    qualityReq = qualityReq,
                    passesTradeskillLevelReqs = self:PassesTradeskillLevelReqs(tradeskillsLevelReqs),
                    passesQualityLevelReq = self:PassesQualityLevelReq(qualityReq),
                    specialIngredientType = specialIngredientType,
                    numIngredients = numIngredients,
                    numCreatable = numCreatable,
                    createSound = createSound,
                    iconFile = resultIcon,
                    quality = quality,
                    tradeskillsLevelReqs = tradeskillsLevelReqs,
                    name = recipeName,
                    requiredCraftingStationType = requiredCraftingStationType,
                }

                local recipeList = self.recipeData[recipeListIndex]
                if not recipeList then
                    recipeList =
                    {
                        recipeListName = recipeListName,
                        recipeListIndex = recipeListIndex,
                        upIcon = upIcon,
                        downIcon = downIcon,
                        overIcon = overIcon,
                        disabledIcon = disabledIcon,
                        recipes = {}
                    }
                    self.recipeData[recipeListIndex] = recipeList
                end

                table.insert(recipeList.recipes, recipe)
            end
        end
    end
end

PROVISIONER_MANAGER = ZO_ProvisionerManager:New()