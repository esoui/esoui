------------------
-- Guild Finder --
------------------

ZO_GuildRecruitment_ActivityCheckboxTile = ZO_Tile:Subclass()

function ZO_GuildRecruitment_ActivityCheckboxTile:New(...)
    return ZO_Tile.New(self, ...)
end

function ZO_GuildRecruitment_ActivityCheckboxTile:Initialize(control)
    ZO_Tile.Initialize(self, control)
end

function ZO_GuildRecruitment_ActivityCheckboxTile:Layout(data)
    ZO_Tile.Layout(self, data)

    self.data = data
end