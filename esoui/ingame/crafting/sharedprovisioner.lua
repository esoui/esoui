
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
    ZO_Skills_TieSkillInfoHeaderToCraftingSkill(self.control:GetNamedChild("SkillInfo"), CRAFTING_TYPE_PROVISIONING)

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

    self.control:RegisterForEvent(EVENT_RECIPE_LEARNED, function()  
        if self:ShouldShowForControlScheme() then
            self:DirtyRecipeList()
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
    
    local function HandleInventoryChanged()
        if self:ShouldShowForControlScheme() then
            self:DirtyRecipeList()
        end
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, HandleInventoryChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, HandleInventoryChanged)

    self.control:RegisterForEvent(EVENT_NON_COMBAT_BONUS_CHANGED, function(eventCode, nonCombatBonusType)
        if self:ShouldShowForControlScheme() then
            if nonCombatBonusType == NON_COMBAT_BONUS_PROVISIONING_LEVEL or nonCombatBonusType == NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL then
                self:DirtyRecipeList()
            end
        end
    end)
    
    self.control:SetHandler("OnUpdate", function()
        if self.dirty then
            self:RefreshRecipeList()
            self.dirty = false
        end
    end)
end

function ZO_SharedProvisioner:CreateInteractScene(sceneName)
    local PROVISIONER_STATION_INTERACTION =
    {
        type = "Provisioner Station",
        End = function()
            SCENE_MANAGER:Hide(self.mainSceneName)
        end,
        interactTypes = { INTERACTION_CRAFT },
    }

    return ZO_InteractScene:New(sceneName, SCENE_MANAGER, PROVISIONER_STATION_INTERACTION)
end

function ZO_SharedProvisioner:SetupMainInteractScene(mainInteractScene)
    mainInteractScene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            if not self.deferredInitializationComplete then
                self.deferredInitializationComplete = true
                self:PerformDeferredInitialization()
            end

            TriggerTutorial(TUTORIAL_TRIGGER_PROVISIONING_OPENED)

            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(self.resultTooltip)

            self:OnSceneShowing()
        elseif newState == SCENE_HIDDEN then
            SYSTEMS:GetObject("craftingResults"):SetCraftingTooltip(nil)

            self:OnSceneHidden()
        end
    end)
end

function ZO_SharedProvisioner:PerformDeferredInitialization()
    -- meant to be overriden
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

function ZO_SharedProvisioner:PassesProvisionerLevelReq(provisionerLevelReq)
    return provisionerLevelReq <= GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_LEVEL)
end

function ZO_SharedProvisioner:PassesQualityLevelReq(qualityReq)
    return qualityReq <= GetNonCombatBonus(NON_COMBAT_BONUS_PROVISIONING_RARITY_LEVEL)
end

function ZO_SharedProvisioner:CalculateHowManyCouldBeCreated(recipeListIndex, recipeIndex, numIngredients)
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

function ZO_SharedProvisioner:DoesRecipePassFilter(specialIngredientType, checkNumCreatable, numCreatable, checkSkills, provisionerLevelReq, qualityReq)
    if self.filterType ~= specialIngredientType then
        return false
    end
    
    if checkNumCreatable then
        if numCreatable == 0 then
            return false
        end 
    end

    if checkSkills then
        if not self:PassesProvisionerLevelReq(provisionerLevelReq) or not self:PassesQualityLevelReq(qualityReq) then
            return false
        end
    end

    return true
end
