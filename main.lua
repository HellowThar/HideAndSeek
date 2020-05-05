local HBD = LibStub("HereBeDragons-2.0")

--helper functions
local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function getDistance(other_x, other_y, other_instance)
    local player_x, player_y, player_instance = HBD:GetPlayerWorldPosition()
    other_x = tonumber(other_x)
    other_y = tonumber(other_y)
    other_instance = tonumber(other_instance)
    if player_instance == other_instance then
        local distance, delta_x, delta_y = HBD:GetWorldDistance(player_instance, player_x, player_y, other_x, other_y)
        return distance
    else
        return -1
    end
end

local function turnUIOff()    
    if GetCVar("UnitNameFriendlyPlayerName") == 1 then
        SetCVar("UnitNameFriendlyPlayerName", 0)
    end

    if (Minimap:IsShown()) then
        Minimap:Hide()
    end
end

local function turnUIOn()
    if GetCVar("UnitNameFriendlyPlayerName") == 0 then
        SetCVar("UnitNameFriendlyPlayerName", 1)
    end

    if (Minimap:IsShown()) == false then
        Minimap:Show()
    end
end

--main frame
C_ChatInfo.RegisterAddonMessagePrefix("hideandseek")

local HASF = CreateFrame("FRAME", "HideAndSeekFrame", UIParent)
local function SetDefaultUIState()
    HASF:SetSize(400,100)
    HASF:SetPoint("CENTER")
    HASF:SetMovable(true)
    HASF:EnableMouse(true)
    HASF:RegisterForDrag("LeftButton")
    HASF:SetScript("OnDragStart", HASF.StartMoving)
    HASF:SetScript("OnDragStop", HASF.StopMovingOrSizing)

    turnUIOn()
end

local HASLabel = HASF:CreateFontString("HideAndSeekLabel", "ARTWORK", "GameFontNormal")
HASLabel:SetText("Hide and Seek")
HASLabel:SetPoint("TOP", HASF, "TOP")

local function HasfHandler(arg)
    if arg == "help" then
        print("Type '/has enable' to turn the game on or '/has disable' to turn the game off")
        print("Press 'Start' and type in the Name-Realm of the player you wish to play with")
        print("Use the 'Hint' button to see how close you are. If you found them, get within 5 yards and push the button again to change turns.")
        print("*** Addon only works with players from the same realm or a connected realm ***")
        print("Have fun!")
    elseif arg == "enable" then
        HASF:Show()
    elseif arg == "disable" then
        HASF:Hide()
    end
end

local SLASH_HIDE_AND_SEEK1 = '/hideandseek'
local SLASH_HIDE_AND_SEEK2 = '/has'

SlashCmdList["HIDE_AND_SEEK"] = HasfHandler

local StartButton = CreateFrame("Button", "StartButton", HASF, "UIPanelButtonTemplate")
StartButton:SetSize(100,33)
StartButton:SetPoint("LEFT", HASF, "LEFT")
StartButton:SetText("Start")
StartButton:SetScript("OnClick", function(self, event, ...)
    StaticPopup_Show("INVITE_TO_HIDE_AND_SEEK")
end)

-- invite player box
StaticPopupDialogs["INVITE_TO_HIDE_AND_SEEK"] = {
    text = "Enter name-realm of player to invite",
    button1 = "Invite",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self, data, data2)
        local other_player = self.editBox:GetText()
        C_ChatInfo.SendAddonMessage("hideandseek", "invite", "WHISPER", other_player)
    end,
    enterClicksFirstButton = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

StaticPopupDialogs["HIDE_AND_SEEK_INVITATION"] = {
    text = "%s is inviting you to play hide and seek",
    button1 = "Accept",
    button2 = "Decline",
    OnAccept = function(self, data, data2)
        C_ChatInfo.SendAddonMessage("hideandseek", "accepted", "WHISPER", data)
        HASF.OtherPlayer = data
        StartButton:Hide()
        HintButton:SetText("Hide!")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

local HintButton = CreateFrame("Button", "HintButton", HASF, "UIPanelButtonTemplate")
HintButton:SetSize(100,33)
HintButton:SetPoint("CENTER", HASF, "CENTER")
HintButton:SetText("Hint")
HintButton:Disable()
HintButton:SetScript("OnClick", function()
    C_ChatInfo.SendAddonMessage("hideandseek", "marco", "WHISPER", HASF.OtherPlayer)
end)

local GiveUpButton = CreateFrame("Button", "GiveUpButton", HASF, "UIPanelButtonTemplate")
GiveUpButton:SetSize(100,33)
GiveUpButton:SetPoint("RIGHT", HASF, "RIGHT")
GiveUpButton:SetText("Give Up")
GiveUpButton:Hide()
GiveUpButton:SetScript("OnClick", function(self, event, ...)
    turnUIOn()
    HintButton:Disable()
    C_ChatInfo.SendAddonMessage("hideandseek", "gotcha", "WHISPER", HASF.OtherPlayer)
    self:Hide()
end)

-- event handler
HASF:RegisterEvent("CHAT_MSG_ADDON")

HASF:SetScript("OnEvent", function(self, event, ...)
    local prefix, text, channel, sender, target, zoneChannelID, localId, name, instanceID = ...
    if text == "gotcha" then
        turnUIOff()
        HintButton:SetText("Hint")
        HintButton:Enable()
        GiveUpButton:Show()

    elseif text == "invite" then
        local invitation = StaticPopup_Show("HIDE_AND_SEEK_INVITATION", sender)
        invitation.data = sender

    elseif text == "accepted" then
        HASF.OtherPlayer = sender
        StartButton:Hide()
        turnUIOff()
        HintButton:Enable()
        GiveUpButton:Show()

    elseif text == "marco" then
        local x, y, instance = HBD:GetPlayerWorldPosition()
        C_ChatInfo.SendAddonMessage("hideandseek", string.format("polo %s %s %s", x, y, instance), "WHISPER", HASF.OtherPlayer)

    elseif string.match(text, "polo") then
        local coordinates = split(text, " ")
        local x = coordinates[2]
        local y = coordinates[3]
        local instance = coordinates[4]

        local distance = getDistance(x, y, instance)
        if distance < 0 then
            HintButton:SetText("You are in the wrong zone!")
        elseif distance < 5 then
            print("You found them!")
            C_ChatInfo.SendAddonMessage("hideandseek", "gotcha", "WHISPER", HASF.OtherPlayer)
            turnUIOn()
            HintButton:SetText("Hide!")
            HintButton:Disable()
            GiveUpButton:Hide()
        elseif distance < 40 then
            HintButton:SetText("HOT")
        elseif distance < 100 then
            HintButton:SetText("WARM")
        else
            HintButton:SetText("COLD")
        end
    end
end)

--initialize

SetDefaultUIState()
print("Hide and Seek loaded! Type '/has help' for help")