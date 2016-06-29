--[[ Character Creation Bucket]]--

ZO_CharacterCreateBucket_Base = ZO_Object:Subclass()

function ZO_CharacterCreateBucket_Base:New(...)
    local bucket = ZO_Object.New(self)
    bucket:Initialize(...)
    return bucket
end

function ZO_CharacterCreateBucket_Base:Initialize(parent, bucketCategory, manager)
    self.parent = parent
    self.category = bucketCategory
    self.manager = manager
    self.expanded = false
    self.controlData = {}
end

function ZO_CharacterCreateBucket_Base:GetContainer()
    return self.container
end

function ZO_CharacterCreateBucket_Base:GetScrollChild()
    return self.scrollChild
end

function ZO_CharacterCreateBucket_Base:UpdateControlsFromData()
    for control, data in pairs(self.controlData) do
        if data.updateFn then
            data.updateFn(control)
        end
    end
end

function ZO_CharacterCreateBucket_Base:RandomizeAppearance(randomizeType)
    for control, data in pairs(self.controlData) do
        if data.randomizeFn then
            data.randomizeFn(control, randomizeType)
        end
    end
end

--[[ Character Creation Bucket Manager ]]--
ZO_CharacterCreateBucketManager_Base = ZO_Object:Subclass()

function ZO_CharacterCreateBucketManager_Base:New(...)
    local manager = ZO_Object.New(self)
    manager:Initialize(...)
    return manager
end

function ZO_CharacterCreateBucketManager_Base:Initialize(container, bucketCategories)
    self.buckets = {}
    self.container = container
    self.currentBucket = nil

    for i, bucketCategory in ipairs(bucketCategories) do
        self:AddBucket(bucketCategory)
    end
end

function ZO_CharacterCreateBucketManager_Base:BucketForCategory(category)
    return self.buckets[category]
end

function ZO_CharacterCreateBucketManager_Base:BucketForChildControl(control)
    return control.bucket
end

function ZO_CharacterCreateBucketManager_Base:Reset()
    for _, bucket in pairs(self.buckets) do
        bucket:Reset()
    end
end

function ZO_CharacterCreateBucketManager_Base:AddControl(control, category, updateFn, randomizeFn, subCategoryId)
    local bucket = self:BucketForCategory(category)
    if bucket then
        bucket:AddControl(control, updateFn, randomizeFn, subCategoryId)
    end
end

function ZO_CharacterCreateBucketManager_Base:RemoveControl(control)
    local bucket = control.bucket
    if bucket then
        bucket:RemoveControl(control)
    end
end

function ZO_CharacterCreateBucketManager_Base:UpdateControlsFromData()
    for _, bucket in pairs(self.buckets) do
        bucket:UpdateControlsFromData()
    end
end

function ZO_CharacterCreateBucketManager_Base:RandomizeAppearance(randomizeType)
    for _, bucket in pairs(self.buckets) do
        bucket:RandomizeAppearance(randomizeType)
    end
end