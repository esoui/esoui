
-- Returns an array of all versions of this screen
local PROVISIONER_SCENE_NAMES = {}

function ZO_Provisioner_AddSceneName(sceneName)
    table.insert(PROVISIONER_SCENE_NAMES, sceneName)
end

-- Returns the currently visible alchemy screen, or nil if none are visible
function ZO_Provisioner_GetVisibleSceneName()
    for _, sceneName in ipairs(PROVISIONER_SCENE_NAMES) do
        if SCENE_MANAGER:IsShowing(sceneName) then
            return sceneName
        end
    end

    return nil
end

-- Checks whether any version of the provisioner scene (mouse+keyboard or gamepad) is showing
function ZO_Provisioner_IsSceneShowing()
    return ZO_Provisioner_GetVisibleSceneName() ~= nil
end

-- ZO_SharedProvisioner class
ZO_SharedProvisioner = ZO_CraftingCreateScreenBase:Subclass()

function ZO_SharedProvisioner:New(...)
    local provisioner = ZO_CraftingCreateScreenBase.New(self)
    provisioner:Initialize(...)
    return provisioner
end

function ZO_SharedProvisioner:Initialize(control)
    ZO_Provisioner_AddSceneName(self.mainSceneName)

    self.control = control
    self.resultTooltip = self.control:GetNamedChild("Tooltip")

    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType, isCraftingSameAsPrevious)
        if craftingType == CRAFTING_TYPE_PROVISIONING and self:ShouldShowForControlScheme() then
            if not isCraftingSameAsPrevious then
                self:ResetSelectedTab()
            end
            self:StartInteract()
            SCENE_MANAGER:Show(self.mainSceneName)
        end
    end)

    self.control:RegisterForEvent(EVENT_END_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
        if craftingType == CRAFTING_TYPE_PROVISIONING and self:ShouldShowForControlScheme() then
            self:StartHide()
            SCENE_MANAGER:Hide(self.mainSceneName)
        end
    end)

    local function OnCraftStarted()
        if SCENE_MANAGER:IsShowing(self.mainSceneName) then
            self:SetDetailsEnabled(false)
        end
    end
    
    local function OnCraftCompleted()
        if SCENE_MANAGER:IsShowing(self.mainSceneName) then
            self:SetDetailsEnabled(true)
        end
    end
    
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStarted", OnCraftStarted)
    CALLBACK_MANAGER:RegisterCallback("CraftingAnimationsStopped", OnCraftCompleted)
    
    PROVISIONER_MANAGER:RegisterCallback("RecipeDataUpdated", function()
        self:DirtyRecipeList()
    end)

    self.control:SetHandler("OnUpdate", function()
        if self.dirty then
            self:RefreshRecipeList()
            self.dirty = false
        end
    end)

    self.provisionerStationInteraction =
    {
        type = "Provisioner Station",
        End = function()
            SCENE_MANAGER:Hide(self.mainSceneName)
        end,
        interactTypes = { INTERACTION_CRAFT },
    }
end

function ZO_SharedProvisioner:CreateInteractScene(sceneName)
    return ZO_InteractScene:New(sceneName, SCENE_MANAGER, self.provisionerStationInteraction)
end

function ZO_SharedProvisioner:DirtyRecipeList()
    self.dirty = true
end

function ZO_SharedProvisioner:ShouldShowForControlScheme()
    -- meant to be overridden
    return false
end

function ZO_SharedProvisioner:ResetSelectedTab()
    -- meant to be overridden
end

function ZO_SharedProvisioner:StartInteract()
    -- meant to be overridden
end

function ZO_SharedProvisioner:StartHide()
    -- meant to be overridden
end

function ZO_SharedProvisioner:SetDetailsEnabled(enabled)
    -- meant to be overridden
end

function ZO_SharedProvisioner:GetRecipeData()
    -- meant to be overridden
end

function ZO_SharedProvisioner:GetRecipeIndices()
    local recipeData = self:GetRecipeData()
    if recipeData then
        return recipeData.recipeListIndex, recipeData.recipeIndex
    end
    return 0, 0
end

function ZO_SharedProvisioner:PassesTradeskillLevelReqs(tradeskillsReqs)
    for tradeskill, levelReq in pairs(tradeskillsReqs) do
        local level = GetNonCombatBonus(GetNonCombatBonusLevelTypeForTradeskillType(tradeskill))
        if level < levelReq then
            return false
        end
    end
    return true
end

function ZO_SharedProvisioner:PassesQualityLevelReq(qualityReq)
    if qualityReq == 0 then
        return true
    else
        --Only exclusively provisioning system recipes have a quality requirement
        return GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL) >= qualityReq
    end
end

function ZO_SharedProvisioner:DoesRecipePassFilter(specialIngredientType, shouldRequireIngredients, maxIterationsForIngredients, shouldRequireSkills, tradeskillsLevelReqs, qualityReq, craftingInteractionType, requiredCraftingStationType)
    if craftingInteractionType ~= requiredCraftingStationType then
        return false
    end
    
    if self.filterType ~= specialIngredientType then
        return false
    end
    
    if shouldRequireIngredients then
        if maxIterationsForIngredients == 0 then
            return false
        end 
    end

    if shouldRequireSkills then
        if not self:PassesTradeskillLevelReqs(tradeskillsLevelReqs) or not self:PassesQualityLevelReq(qualityReq) then
            return false
        end
    end
   
    return true
end

function ZO_SharedProvisioner:PreviewRecipe(recipeData)
    if self:CanPreviewRecipe(recipeData) then
        SYSTEMS:GetObject("itemPreview"):PreviewProvisionerItemAsFurniture(recipeData.recipeListIndex, recipeData.recipeIndex)
    end
end

function ZO_SharedProvisioner:EndRecipePreview()
    SYSTEMS:GetObject("itemPreview"):EndCurrentPreview()
end

function ZO_SharedProvisioner:CanPreviewRecipe(recipeData)
    if recipeData then
        return recipeData.specialIngredientType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING
    end
    return false
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedProvisioner:IsCraftable()
    local recipeData = self:GetRecipeData()
    if recipeData then
        return recipeData.maxIterationsForIngredients > 0 
           and self:PassesTradeskillLevelReqs(recipeData.tradeskillsLevelReqs) 
           and self:PassesQualityLevelReq(recipeData.qualityReq)
    end
    return false
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedProvisioner:GetAllCraftingParameters(numIterations)
    local recipeData = self:GetRecipeData()
    if recipeData then
        return recipeData.recipeListIndex, recipeData.recipeIndex, numIterations
    end
    return 0, 0, numIterations
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedProvisioner:ShouldCraftButtonBeEnabled()
    if ZO_CraftingUtils_IsPerformingCraftProcess() then
        return false
    end

    local recipeData = self:GetRecipeData()
    if not recipeData then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_NO_RECIPE)
    elseif not recipeData.passesTradeskillLevelReqs then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_NEED_RECIPE_RANK)
    elseif not recipeData.passesQualityLevelReq then
        return false, GetString("SI_TRADESKILLRESULT", CRAFTING_RESULT_NEED_RECIPE_QUALITY_RANK)
    end

    local maxIterations, craftingResult = GetMaxIterationsPossibleForRecipe(self:GetRecipeIndices())
    return maxIterations ~= 0, GetString("SI_TRADESKILLRESULT", craftingResult)
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedProvisioner:GetMultiCraftMaxIterations()
    if not self:IsCraftable() then
        return 0
    end

    -- throw away second argument
    local numIterations = GetMaxIterationsPossibleForRecipe(self:GetRecipeIndices())
    return numIterations
end

function ZO_SharedProvisioner:GetResultItemLink()
    return GetRecipeResultItemLink(self:GetRecipeIndices())
end

function ZO_SharedProvisioner:GetMultiCraftNumResults(numIterations)
    local recipeListIndex, recipeIndex = self:GetRecipeIndices()
    return GetRecipeResultQuantity(recipeListIndex, recipeIndex, numIterations)
end

-- Overrides ZO_CraftingCreateScreenBase
function ZO_SharedProvisioner:Create(numIterations)
    CraftProvisionerItem(self:GetAllCraftingParameters(numIterations))
end
