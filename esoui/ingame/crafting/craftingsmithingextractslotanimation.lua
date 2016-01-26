ZO_CraftingSmithingExtractSlotAnimation = ZO_CraftingSlotAnimationBase:Subclass()

function ZO_CraftingSmithingExtractSlotAnimation:New(...)
    return ZO_CraftingSlotAnimationBase.New(self, ...)
end

function ZO_CraftingSmithingExtractSlotAnimation:Initialize(sceneName, visibilityPredicate)
    ZO_CraftingSlotAnimationBase.Initialize(self, sceneName, visibilityPredicate)

    self.burstToSlot = {}
    self.slotToBurst = {}
end

local AcquireSlotExtraction
do
    local g_extractPool
    function AcquireSlotExtraction()
        if not g_extractPool then
            local function Factory(objectPool)
                local extractionBurst = ZO_ObjectPool_CreateControl("ZO_CraftingSmithingExtractionBurst", objectPool, GuiRoot)
                extractionBurst.phase1Animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingSmithingExtractionBurstAnimationPhase1")
                extractionBurst.phase2Animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("CraftingSmithingExtractionBurstAnimationPhase2")

                extractionBurst.phase1Animation:GetAnimation(1):SetAnimatedControl(extractionBurst)
                extractionBurst.phase2Animation:GetAnimation(1):SetAnimatedControl(extractionBurst)

                extractionBurst.phase1Animation:GetAnimation(2):SetHandler("OnStop", function()
                    if not IsPerformingCraftProcess() and not extractionBurst.phase2Animation:IsPlaying() then
                        extractionBurst.phase2Animation:PlayFromStart()
                    end
                end)

                extractionBurst.phase2Animation:SetHandler("OnStop", function()
                    extractionBurst.owner.slotToBurst[extractionBurst.slot] = nil
                    extractionBurst.owner.burstToSlot[extractionBurst] = nil

                    extractionBurst.slot:RemoveAnimationRef()
                    extractionBurst.slot = nil
                    extractionBurst.owner = nil
                    g_extractPool:ReleaseObject(extractionBurst.key)
                end)

                return extractionBurst
            end

            g_extractPool = ZO_ObjectPool:New(Factory, ZO_ObjectPool_DefaultResetControl)
        end

        local extractionBurst, key = g_extractPool:AcquireObject()
        extractionBurst.key = key
        return extractionBurst
    end
end

function ZO_CraftingSmithingExtractSlotAnimation:Play(sceneName)
    ClearMenu()

    for i, slot in ipairs(self.slots) do
        local extractionBurst = nil

        local existingBurst = self.slotToBurst[slot]
        if existingBurst then
            if existingBurst.phase1Animation:IsPlaying() then
                --just stomp on this animation and keep using it
                extractionBurst = existingBurst
                slot:RemoveAnimationRef()
            elseif existingBurst.phase2Animation:IsPlaying() then
                -- this animation is too far along to stomp, stop it and let a new animation replace it
                existingBurst.phase2Animation:Stop()

                extractionBurst = AcquireSlotExtraction()
            end
        else
            extractionBurst = AcquireSlotExtraction()
        end
        
        extractionBurst.owner = self
        extractionBurst:SetHidden(false)
        extractionBurst:SetParent(slot:GetControl())
        extractionBurst:SetAnchor(CENTER, nil, CENTER)

        local icon = slot:GetControl():GetNamedChild("Icon")
        extractionBurst.phase1Animation:GetAnimation(2):SetAnimatedControl(icon)
        extractionBurst.phase1Animation:GetAnimation(3):SetAnimatedControl(icon)
        extractionBurst.phase1Animation:GetAnimation(4):SetAnimatedControl(icon)

        extractionBurst.phase2Animation:GetAnimation(2):SetAnimatedControl(icon)
        extractionBurst.phase2Animation:GetAnimation(3):SetAnimatedControl(icon)

        local name = slot:GetControl():GetNamedChild("Name")
        extractionBurst.phase1Animation:GetAnimation(5):SetAnimatedControl(name)

        extractionBurst.phase2Animation:GetAnimation(4):SetAnimatedControl(name)

        local stackCount = slot:GetControl():GetNamedChild("StackCount")
        extractionBurst.phase1Animation:GetAnimation(6):SetAnimatedControl(stackCount)

        extractionBurst.phase2Animation:GetAnimation(5):SetAnimatedControl(stackCount)

        extractionBurst.phase1Animation:PlayFromStart()

        extractionBurst.slot = slot

        self.burstToSlot[extractionBurst] = slot
        self.slotToBurst[slot] = extractionBurst

        slot:AddAnimationRef()
    end
end

function ZO_CraftingSmithingExtractSlotAnimation:Stop()
    for extractionBurst, slot in pairs(self.burstToSlot) do
        if extractionBurst.slot and not extractionBurst.phase2Animation:IsPlaying() then
            extractionBurst.phase2Animation:PlayFromStart()
        end
    end
end