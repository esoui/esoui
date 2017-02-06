
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
ZO_SharedProvisioner = ZO_Object:Subclass()

function ZO_SharedProvisioner:New(...)
    local provisioner = ZO_Object.New(self)
    provisioner:Initialize(...)
    return provisioner
end

function ZO_SharedProvisioner:Initialize(control)
    ZO_Provisioner_AddSceneName(self.mainSceneName)
    
    self.control = control
    self.resultTooltip = self.control:GetNamedChild("Tooltip")

    self.control:RegisterForEvent(EVENT_CRAFTING_STATION_INTERACT, function(eventCode, craftingType)
        if craftingType == CRAFTING_TYPE_PROVISIONING and self:ShouldShowForControlScheme() then
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
    -- meant to be overriden
    return false
end

function ZO_SharedProvisioner:StartInteract()
    -- meant to be overriden
end

function ZO_SharedProvisioner:StartHide()
    -- meant to be overriden
end

function ZO_SharedProvisioner:SetDetailsEnabled(enabled)
    -- meant to be overriden
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

function ZO_SharedProvisioner:DoesRecipePassFilter(specialIngredientType, checkNumCreatable, numCreatable, checkSkills, tradeskillsLevelReqs, qualityReq, craftingInteractionType, requiredCraftingStationType)
    if craftingInteractionType ~= requiredCraftingStationType then
        return false
    end
    
    if self.filterType ~= specialIngredientType then
        return false
    end
    
    if checkNumCreatable then
        if numCreatable == 0 then
            return false
        end 
    end

    if checkSkills then
        if not self:PassesTradeskillLevelReqs(tradeskillsLevelReqs) or not self:PassesQualityLevelReq(qualityReq) then
            return false
        end
    end
   
    return true
end

function ZO_SharedProvisioner:CanPreviewRecipe(recipeData)
    return recipeData ~= nil and recipeData.specialIngredientType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FURNISHING
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

function ZO_Provisioning_IsSceneShowing()
    return SCENE_MANAGER:IsShowing("provisioner") or SCENE_MANAGER:IsShowing("gamepad_provisioner_root")
end