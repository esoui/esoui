ZO_CraftingEnchantExtractSlotAnimation_Gamepad = ZO_CraftingSlotAnimationBase:Subclass()

function ZO_CraftingEnchantExtractSlotAnimation_Gamepad:New(...)
    return ZO_CraftingSlotAnimationBase.New(self, ...)
end

function ZO_CraftingEnchantExtractSlotAnimation_Gamepad:Initialize(sceneName, visibilityPredicate)
    ZO_CraftingSlotAnimationBase.Initialize(self, sceneName, visibilityPredicate)
end

local AcquireSlotExtraction
do
    local g_extractPool
    function AcquireSlotExtraction()
        if not g_extractPool then
            local function Factory(objectPool)
                local extractionBurst = ZO_ObjectPool_CreateNamedControl("ZO_CraftingEnchantExtractionBurst_Gamepad", "ZO_CraftingEnchantExtractionBurst", objectPool, GuiRoot)
                local burstAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingEnchantExtractionBurstAnimation_Gamepad")
                extractionBurst.animation = burstAnimation

                -- burst fade in
                burstAnimation:GetAnimation(1):SetAnimatedControl(extractionBurst.burst1)
                burstAnimation:GetAnimation(2):SetAnimatedControl(extractionBurst.burst2)
                burstAnimation:GetAnimation(3):SetAnimatedControl(extractionBurst.burst1)
                burstAnimation:GetAnimation(4):SetAnimatedControl(extractionBurst.burst2)

                -- burst fade out
                burstAnimation:GetAnimation(5):SetAnimatedControl(extractionBurst.burst1)
                burstAnimation:GetAnimation(6):SetAnimatedControl(extractionBurst.burst2)

                -- burst rotations
                burstAnimation:GetAnimationTimeline(1):GetAnimation(1):SetAnimatedControl(extractionBurst.burst1)
                burstAnimation:GetAnimationTimeline(1):GetAnimation(2):SetAnimatedControl(extractionBurst.burst2)

                burstAnimation:GetAnimation(8):SetHandler("OnStop", function() g_extractPool:ReleaseObject(extractionBurst.key) burstAnimation:Stop() end)

                return extractionBurst
            end

            g_extractPool = ZO_ObjectPool:New(Factory, ZO_ObjectPool_DefaultResetControl)
        end

        local extractionBurst, key = g_extractPool:AcquireObject()
        extractionBurst.key = key
        return extractionBurst
    end
end

function ZO_CraftingEnchantExtractSlotAnimation_Gamepad:Play(sceneName)
    ClearMenu()

    for i, slot in ipairs(self.slots) do
        local extractionBurst = AcquireSlotExtraction()

        extractionBurst:SetHidden(false)
        extractionBurst:SetParent(slot:GetControl())
        extractionBurst:SetAnchor(CENTER, nil, CENTER)

        local icon = slot:GetControl():GetNamedChild("Icon")
        extractionBurst.animation:GetAnimation(7):SetAnimatedControl(icon)
        extractionBurst.animation:GetAnimation(8):SetAnimatedControl(icon)

        local name = slot:GetControl():GetNamedChild("Name")
        extractionBurst.animation:GetAnimation(9):SetAnimatedControl(name)
        extractionBurst.animation:GetAnimation(10):SetAnimatedControl(name)

        extractionBurst.animation:PlayFromStart()
    end
end