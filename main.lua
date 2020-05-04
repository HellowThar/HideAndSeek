local HBD = HereBeDragons

--helper functions
local function getDistance()
    local player_x, player_y, player_instance = HBD:GetPlayerWorldPosition()
    local tar_x, tar_y, tar_instance = HBD:GetUnitWorldPosition("party1")
    local distance, delta_x, delta_y = HBD:GetWorldDistance(player_instance, player_x, player_y, tar_x, tar_y)
    return distance
end

local function turnUIOff()
    local UnitNameFriendlyPlayerName = GetCVar("UnitNameFriendlyPlayerName")
    
    if UnitNameFriendlyPlayerName == 1 then
        SetCVar("UnitNameFriendlyPlayerName", 0)
    end

    if (Minimap:IsShown()) then
        Minimap:Hide()
    end
end

local function turnUIOn()
    if UnitNameFriendlyPlayerName == 0 then
        SetCVar("UnitNameFriendlyPlayerName", 1)
    end

    if (Minimap:IsShown()) == false then
        Minimap:Show()
    end
end

--main frame
C_ChatInfo.RegisterAddonMessagePrefix("hideandseek")

local HideAndSeekFrame = CreateFrame("Button", "HideAndSeekFrame", UIParent, "UIPanelButtonTemplate")
local HASF = HideAndSeekFrame
HASF:SetSize(100,33)
HASF:SetPoint("CENTER")
HASF:SetMovable(true)

HASF:SetText("Hint")
HASF:SetScript("OnClick", function()
    local distance = getDistance()
    if distance < 5 then
        print("You found them!")
        C_ChatInfo.SendAddonMessage("hideandseek", "you've been found", "PARTY")
        turnUIOn()
        HASF:SetText("Hide!")
        HASF:Disable()
    elseif distance < 40 then
        HASF:SetText("HOT")
    elseif distance < 100 then
        HASF:SetText("WARM")
    else
        HASF:SetText("COLD")
    end
end)

HASF:RegisterEvent("CHAT_MSG_ADDON")

HASF:SetScript("OnEvent", function(self, event, ...)
    local prefix, text, channel, sender, target, zoneChannelID, localId, name, instanceID = ...

    if text == "you've been found" then
        turnUIOff()
        HASF:SetText("Hint")
        HASF:Enable()
    end
end)


local function HasHandler(arg)
    if arg == "help" then
        print("type '/has enable' to turn the game on or '/has disable' to turn the game off")
    elseif arg == "enable" then
        HASF:Show()
    elseif arg == "disable" then
        HASF:Hide()
    end
end

SLASH_HAS1 = '/hideandseek'
SLASH_HAS2 = '/has'

SlashCmdList["HAS"] = HasHandler

print("Hide and Seek loaded! Type '/has help' for help")