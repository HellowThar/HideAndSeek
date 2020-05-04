local HBD = HereBeDragons

--helper functions
local function getDistance()
    local player_x, player_y, player_instance = HBD:GetPlayerWorldPosition()
    local target_x, target_y, target_instance = HBD:GetUnitWorldPosition("party1")
    if player_instance == target_instance then
        local distance, delta_x, delta_y = HBD:GetWorldDistance(player_instance, player_x, player_y, target_x, target_y)
        return distance
    else
        return -1
    end
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

local HASF = CreateFrame("FRAME", "HideAndSeekFrame", UIParent)

HASF:SetSize(400,100)
HASF:SetPoint("CENTER")
HASF:SetMovable(true)
HASF:EnableMouse(true)
HASF:RegisterForDrag("LeftButton")
HASF:SetScript("OnDragStart", HASF.StartMoving)
HASF:SetScript("OnDragStop", HASF.StopMovingOrSizing)
local tex = HASF:CreateTexture("ARTWORK")
tex:SetAllPoints()
tex:SetTexture(0.5, 0.5, 0)
tex:SetAlpha(0.5)

local function HasfHandler(arg)
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

SlashCmdList["HAS"] = HasfHandler

local StartButton = CreateFrame("Button", "StartButton", HASF, "UIPanelButtonTemplate")
StartButton:SetSize(100,33)
StartButton:SetPoint("LEFT", HASF, "LEFT")
StartButton:SetText("Start")
StartButton:SetScript("OnClick", function(self, event, ...)
    HASF.OtherPlayer = UnitName("party1")
    local distance = getDistance()

    if HASF.OtherPlayer == nil then
        print("Must be in a party with other player to start the game!")
    elseif distance < 0 then
        print("Must be in same zone to start the game!")
    else
        local success = C_ChatInfo.SendAddonMessage("hideandseek", "partner started game", "WHISPER", HASF.OtherPlayer)
        if success then
            HintButton:Enable()
            self:Hide()
        end
    end

end)

local HintButton = CreateFrame("Button", "HintButton", HASF, "UIPanelButtonTemplate")
HintButton:SetSize(100,33)
HintButton:SetPoint("CENTER", HASF, "CENTER")
HintButton:SetText("Hint")
HintButton:Disable()
HintButton:SetScript("OnClick", function()
    local distance = getDistance()
    
    if distance < 0 then
        HintButton:SetText("You are in the wrong zone!")
    elseif distance < 5 then
        print("You found them!")
        C_ChatInfo.SendAddonMessage("hideandseek", "you've been found", "WHISPER", HASF.OtherPlayer)
        turnUIOn()
        HintButton:SetText("Hide!")
        HintButton:Disable()
    elseif distance < 40 then
        HintButton:SetText("HOT")
    elseif distance < 100 then
        HintButton:SetText("WARM")
    else
        HintButton:SetText("COLD")
    end
end)

HASF:RegisterEvent("CHAT_MSG_ADDON")

-- event handler

HASF:SetScript("OnEvent", function(self, event, ...)
    local prefix, text, channel, sender, target, zoneChannelID, localId, name, instanceID = ...
    
    if text == "you've been found" then
        turnUIOff()
        HintButton:SetText("Hint")
        HintButton:Enable()
    elseif text == "partner started game" then
        HintButton:SetText("Hide!")
    end
end)

print("Hide and Seek loaded! Type '/has help' for help")