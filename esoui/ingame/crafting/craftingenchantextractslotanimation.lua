ZO_CraftingEnchantExtractSlotAnimation = ZO_CraftingSlotAnimationBase:Subclass()

function ZO_CraftingEnchantExtractSlotAnimation:New(...)
    return ZO_CraftingSlotAnimationBase.New(self, ...)
end

function ZO_CraftingEnchantExtractSlotAnimation:Initialize(sceneName, visibilityPredicate)
    ZO_CraftingSlotAnimationBase.Initialize(self, sceneName, visibilityPredicate)
end

local AcquireSlotExtraction
do
    local g_extractPool
    function AcquireSlotExtraction()
        if not g_extractPool then
            local function Factory(objectPool)
                local extractionBurst = ZO_ObjectPool_CreateControl("ZO_CraftingEnchantExtractionBurst", objectPool, GuiRoot)
                extractionBurst.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingEnchantExtractionBurstAnimation")

                extractionBurst.animation:GetAnimation(1):SetAnimatedControl(extractionBurst.burst1)
                extractionBurst.animation:GetAnimation(2):SetAnimatedControl(extractionBurst.burst2)

                extractionBurst.animation:GetAnimation(3):SetAnimatedControl(extractionBurst.burst1)
                extractionBurst.animation:GetAnimation(4):SetAnimatedControl(extractionBurst.burst2)

                extractionBurst.animation:GetAnimation(5):SetAnimatedControl(extractionBurst.burst1)
                extractionBurst.animation:GetAnimation(6):SetAnimatedControl(extractionBurst.burst2)

                extractionBurst.animation:GetAnimation(7):SetAnimatedControl(extractionBurst.underlay)
                extractionBurst.animation:GetAnimation(8):SetAnimatedControl(extractionBurst.underlay)
                extractionBurst.animation:GetAnimation(9):SetAnimatedControl(extractionBurst.underlay)

                extractionBurst.animation:GetAnimationTimeline(1):GetAnimation(1):SetAnimatedControl(extractionBurst.burst1)
                extractionBurst.animation:GetAnimationTimeline(1):GetAnimation(2):SetAnimatedControl(extractionBurst.burst2)

                extractionBurst.animation:GetAnimation(9):SetHandler("OnStop", function() g_extractPool:ReleaseObject(extractionBurst.key) extractionBurst.animation:Stop() end)

                return extractionBurst
            end

            g_extractPool = ZO_ObjectPool:New(Factory, ZO_ObjectPool_DefaultResetControl)
        end

        local extractionBurst, key = g_extractPool:AcquireObject()
        extractionBurst.key = key
        return extractionBurst
    end
end

function ZO_CraftingEnchantExtractSlotAnimation:Play(sceneName)
    ClearMenu()

    for i, slot in ipairs(self.slots) do
        local extractionBurst = AcquireSlotExtraction()

        extractionBurst:SetHidden(false)
        extractionBurst:SetParent(slot:GetControl())
        extractionBurst:SetAnchor(CENTER, nil, CENTER)

        local icon = slot:GetControl():GetNamedChild("Icon")
        extractionBurst.animation:GetAnimation(10):SetAnimatedControl(icon)
        extractionBurst.animation:GetAnimation(11):SetAnimatedControl(icon)

        extractionBurst.animation:PlayFromStart()
    end
end