-- OctoPort 0.1.0
-- Controller-first interface for OctoWoW / World of Warcraft 1.12.x.

OctoPort = OctoPort or {}
OctoPort.version = "0.1.0"

BINDING_HEADER_OCTOPORT = "WOW Controller"
BINDING_NAME_OCTOPORT_TOGGLEBAGS = "Open / close all bags"
BINDING_NAME_OCTOPORT_TOGGLEHELP = "Open OctoPort help"

local defaults = {
  enabled = true,
  scale = 1.00,
  x = 0,
  y = 122,
  editMode = false,
  moveMode = false,
  setupComplete = false,
  firstRunSeen = false,
  bindingBackup = nil,
}

local function CopyDefaults(target, source)
  for key, value in pairs(source) do
    if target[key] == nil then
      target[key] = value
    end
  end
end

function OctoPort:Print(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff3dd6d0WOW Controller:|r " .. tostring(message))
  end
end

function OctoPort:InitializeConfig()
  OctoPortConfig = OctoPortConfig or {}
  CopyDefaults(OctoPortConfig, defaults)
  self.config = OctoPortConfig
end

function OctoPort:ShowCommands()
  self:Print("/octoport setup - apply the recommended keyboard bindings")
  self:Print("/octoport restore - restore bindings saved before setup")
  self:Print("/octoport edit - show all three action layers")
  self:Print("/octoport move - unlock or lock the controller HUD")
  self:Print("/octoport scale 0.7-1.6 - resize the HUD")
  self:Print("/octoport reset - reset HUD position and size")
  self:Print("/octoport on | off - enable or hide the HUD")
end

function OctoPort:ResetLayout()
  self.config.scale = defaults.scale
  self.config.x = defaults.x
  self.config.y = defaults.y
  self.config.editMode = false
  self.config.moveMode = false
  if self.ApplyLayout then self:ApplyLayout() end
  self:Print("HUD position and size reset.")
end

function OctoPort:SetEnabled(enabled)
  self.config.enabled = enabled and true or false
  if self.SetUIEnabled then
    self:SetUIEnabled(self.config.enabled)
  elseif self.root then
    if self.config.enabled then self.root:Show() else self.root:Hide() end
  end
  self:Print(self.config.enabled and "HUD enabled." or "HUD hidden.")
end

local function Trim(text)
  text = text or ""
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

function OctoPort:HandleSlash(message)
  message = Trim(string.lower(message or ""))

  if message == "" or message == "help" then
    if self.ToggleHelp then self:ToggleHelp(true) end
    self:ShowCommands()
    return
  end

  if message == "setup" then
    self:ApplyRecommendedBindings()
  elseif message == "restore" then
    self:RestoreBindings()
  elseif message == "edit" then
    self.config.editMode = not self.config.editMode
    if self.UpdateLayer then self:UpdateLayer(true) end
    self:Print(self.config.editMode and "Edit mode: all layers visible." or "Play mode: only the active layer is visible.")
  elseif message == "move" then
    self.config.moveMode = not self.config.moveMode
    if self.SetMoveMode then self:SetMoveMode(self.config.moveMode) end
  elseif string.sub(message, 1, 5) == "scale" then
    local value = tonumber(string.sub(message, 6))
    if not value or value < 0.7 or value > 1.6 then
      self:Print("Use /octoport scale 0.7-1.6")
      return
    end
    self.config.scale = value
    if self.ApplyLayout then self:ApplyLayout() end
    self:Print("HUD scale: " .. value)
  elseif message == "reset" then
    self:ResetLayout()
  elseif message == "on" then
    self:SetEnabled(true)
  elseif message == "off" then
    self:SetEnabled(false)
  else
    self:Print("Unknown command: " .. message)
    self:ShowCommands()
  end
end

SLASH_OCTOPORT1 = "/octoport"
SLASH_OCTOPORT2 = "/op"
SLASH_OCTOPORT3 = "/wowcontroller"
SLASH_OCTOPORT4 = "/wc"
SlashCmdList["OCTOPORT"] = function(message)
  OctoPort:HandleSlash(message)
end

local events = CreateFrame("Frame", "OctoPortEvents")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "OctoPort" then
    OctoPort:InitializeConfig()
  elseif event == "PLAYER_LOGIN" then
    if not OctoPort.config then OctoPort:InitializeConfig() end
    if OctoPort.InitializeUI then OctoPort:InitializeUI() end
    if OctoPort.config.enabled then
      OctoPort:Print("v" .. OctoPort.version .. " loaded. Type /octoport for help.")
    end
    if not OctoPort.config.firstRunSeen and OctoPort.ToggleHelp then
      OctoPort.config.firstRunSeen = true
      OctoPort:ToggleHelp(true)
    end
  end
end)
