ZO_BulletList = ZO_Object:Subclass()

function ZO_BulletList:New(control, labelTemplate, bulletTemplate, secondaryBulletTemplate)
    local list = ZO_Object.New(self)
    list.control = control
    
    labelTemplate = labelTemplate or "ZO_BulletLabel"
    bulletTemplate = bulletTemplate or "ZO_Bullet"

    list.labelPool = ZO_ControlPool:New(labelTemplate, control, "Label")
    list.bulletPool = ZO_ControlPool:New(bulletTemplate, control, "Bullet")

    if secondaryBulletTemplate then
        list.secondaryBulletPool = ZO_ControlPool:New(secondaryBulletTemplate, control, "SecondaryBullet")
    end
    
    list.linePaddingY = 2
    list.bulletPaddingX = 4
    list.height = 0

    return list
end

function ZO_BulletList:SetLinePaddingY(padding)
    self.linePaddingY = padding
end

function ZO_BulletList:SetBulletPaddingX(padding)
    self.bulletPaddingX = padding
end

function ZO_BulletList:AddLine(text, useSecondaryBullet)
    local bullet = useSecondaryBullet and self.secondaryBulletPool:AcquireObject() or self.bulletPool:AcquireObject()
    local label = self.labelPool:AcquireObject()

    local labelLineHeight = label:GetFontHeight()
    local bulletHeight = bullet:GetHeight()
    local bulletOffsetY = (labelLineHeight - bulletHeight) * 0.5

    label:SetText(text)

    if self.lastLabel then
        label:SetAnchor(TOPLEFT, self.lastLabel, BOTTOMLEFT, 0, self.linePaddingY)
        label:SetAnchor(TOPRIGHT, self.lastLabel, BOTTOMRIGHT, 0, self.linePaddingY)
        bullet:SetAnchor(TOPRIGHT, label, TOPLEFT, -self.bulletPaddingX, bulletOffsetY)
        local textWidth, textHeight = label:GetTextDimensions()
        self.height = self.height + textHeight + self.linePaddingY
    else
        self.entryText = {}
        bullet:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, bulletOffsetY)
        label:SetAnchor(TOPLEFT, bullet, TOPRIGHT, self.bulletPaddingX, -bulletOffsetY)
        label:SetAnchor(TOPRIGHT, nil, TOPRIGHT, 0, 0)
        local textWidth, textHeight = label:GetTextDimensions()
        self.height = textHeight
    end

    table.insert(self.entryText, text)
    self.control:SetHeight(self.height)
    self.lastLabel = label
    self.lastBullet = bullet
end

function ZO_BulletList:Clear()
    self.lastLabel = nil
    self.height = 0
    self.control:SetHeight(self.height)
    self.labelPool:ReleaseAllObjects()
    self.bulletPool:ReleaseAllObjects()

    if self.secondaryBulletPool then
        self.secondaryBulletPool:ReleaseAllObjects()
    end
    self.entryText = nil
end

function ZO_BulletList:HasEntries()
    return self.entryText and #self.entryText > 0
end

function ZO_BulletList:GetNarrationText()
    local narrations = {}
    if self.entryText then
        for _, text in ipairs(self.entryText) do
            table.insert(narrations, SCREEN_NARRATION_MANAGER:CreateNarratableObject(text))
        end
    end
    return narrations
end
