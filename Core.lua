-- OctoPort 0.4.0
-- Controller-first interface for OctoWoW / World of Warcraft 1.12.x.

OctoPort = OctoPort or {}
OctoPort.version = "0.4.0"

BINDING_HEADER_OCTOPORT = "WOW Controller"
BINDING_NAME_OCTOPORT_TOGGLEBAGS = "Open / close all bags"
BINDING_NAME_OCTOPORT_TOGGLEHELP = "Open OctoPort help"
BINDING_NAME_OCTOPORT_ACTION_A = "Controller A / confirm"
BINDING_NAME_OCTOPORT_ACTION_B = "Controller B / back"
BINDING_NAME_OCTOPORT_ACTION_X = "Controller X"
BINDING_NAME_OCTOPORT_ACTION_Y = "Controller Y"
BINDING_NAME_OCTOPORT_RADIAL = "Hold controller Menu / radial menu"
BINDING_NAME_OCTOPORT_TARGET_UP = "Previous friendly target"
BINDING_NAME_OCTOPORT_TARGET_DOWN = "Next friendly target"
BINDING_NAME_OCTOPORT_TARGET_LEFT = "Previous enemy target"
BINDING_NAME_OCTOPORT_TARGET_RIGHT = "Next enemy target"
BINDING_NAME_OCTOPORT_LAYER_LB = "Controller LB action layer"
BINDING_NAME_OCTOPORT_LAYER_LT = "Controller LT action layer"
BINDING_NAME_OCTOPORT_OPENCONFIG = "Open WOW Controller settings"
BINDING_NAME_OCTOPORT_MOVE_FORWARD = "Left stick forward"
BINDING_NAME_OCTOPORT_MOVE_BACKWARD = "Left stick backward"
BINDING_NAME_OCTOPORT_MOVE_LEFT = "Left stick strafe left"
BINDING_NAME_OCTOPORT_MOVE_RIGHT = "Left stick strafe right"
BINDING_NAME_OCTOPORT_REAR_M1 = "ROG Ally rear paddle M1"
BINDING_NAME_OCTOPORT_REAR_M2 = "ROG Ally rear paddle M2"

local defaultRadialSlots = {
  "map",
  "quests",
  "bags",
  "character",
  "mount",
  "chat",
  "combatlog",
  "spellbook",
}

local defaults = {
  enabled = true,
  scale = 1.00,
  x = 0,
  y = 122,
  editMode = false,
  moveMode = false,
  setupComplete = false,
  bindingVersion = 0,
  firstRunSeen = false,
  bindingBackup = nil,
  autoTarget = true,
  autoAcceptQuests = true,
  radialHold = 0.35,
  radialSlots = defaultRadialSlots,
  mountName = "",
  nativeModifiers = { SHIFT = "shift", CTRL = "ctrl" },
  selectedConfigTab = 1,
  reticleEnabled = true,
  reticleScale = 1.00,
  rearActions = { M1 = "settings", M2 = "interact" },
}

local function CopyValue(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, nested in pairs(value) do
    result[key] = CopyValue(nested)
  end
  return result
end

local function CopyDefaults(target, source)
  for key, value in pairs(source) do
    if target[key] == nil then
      target[key] = CopyValue(value)
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
  self:Print("/octoport - open controller settings")
  self:Print("/octoport setup - start the controller binding wizard")
  self:Print("/octoport preset - apply the legacy ROG Ally F-key preset")
  self:Print("/octoport restore - restore bindings saved before setup")
  self:Print("/octoport edit - show all three action layers")
  self:Print("/octoport move - unlock or lock the controller HUD")
  self:Print("/octoport scale 0.7-1.6 - resize the HUD")
  self:Print("/octoport reset - reset HUD position and size")
  self:Print("/octoport wheel - edit the radial menu")
  self:Print("/octoport target on | off - automatic enemy target for empty target")
  self:Print("/octoport quest on | off - automatic quest acceptance")
  self:Print("/octoport reticle on | off - center target reticle")
  self:Print("/octoport mount NAME - preferred mount item or spell")
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
  local originalMessage = Trim(message or "")
  message = string.lower(originalMessage)

  if message == "" or message == "help" then
    if self.ToggleConfig then self:ToggleConfig(true) end
    return
  end

  if message == "setup" then
    if self.StartBindingWizard then self:StartBindingWizard() end
  elseif message == "preset" then
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
  elseif message == "wheel" then
    if self.ToggleRadialEditor then self:ToggleRadialEditor() end
  elseif message == "wheel reset" then
    self.config.radialSlots = CopyValue(defaultRadialSlots)
    if self.RefreshRadial then self:RefreshRadial() end
    self:Print("Radial menu reset to defaults.")
  elseif message == "target on" or message == "autotarget on" then
    self.config.autoTarget = true
    self:Print("Automatic enemy targeting enabled.")
  elseif message == "target off" or message == "autotarget off" then
    self.config.autoTarget = false
    self:Print("Automatic enemy targeting disabled.")
  elseif message == "quest on" then
    self.config.autoAcceptQuests = true
    self:Print("Automatic quest acceptance enabled. Hold LB while opening a quest to inspect it first.")
  elseif message == "quest off" then
    self.config.autoAcceptQuests = false
    self:Print("Automatic quest acceptance disabled.")
  elseif message == "reticle on" then
    self.config.reticleEnabled = true
    if self.UpdateReticle then self:UpdateReticle(true) end
    self:Print("Target reticle enabled.")
  elseif message == "reticle off" then
    self.config.reticleEnabled = false
    if self.UpdateReticle then self:UpdateReticle(true) end
    self:Print("Target reticle disabled.")
  elseif string.sub(message, 1, 5) == "mount" then
    local name = Trim(string.sub(originalMessage, 6))
    self.config.mountName = name
    if name == "" then
      self:Print("Preferred mount cleared. Use /octoport mount NAME")
    else
      self:Print("Preferred mount: " .. name)
    end
  elseif message == "on" then
    self:SetEnabled(true)
  elseif message == "off" then
    self:SetEnabled(false)
  elseif message == "diagnostics" or message == "debug" then
    if self.ShowConfigTab then self:ShowConfigTab(4, true) end
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
  if event == "ADDON_LOADED" and (arg1 == "Wow_Controller" or arg1 == "OctoPort") then
    OctoPort:InitializeConfig()
  elseif event == "PLAYER_LOGIN" then
    if not OctoPort.config then OctoPort:InitializeConfig() end
    if OctoPort.InitializeUI then OctoPort:InitializeUI() end
    if OctoPort.config.enabled then
      OctoPort:Print("v" .. OctoPort.version .. " loaded. Type /octoport for help.")
    end
    if (OctoPort.config.bindingVersion or 0) < 4 and OctoPort.ShowConfigTab then
      OctoPort.config.firstRunSeen = true
      OctoPort:ShowConfigTab(1, true)
    elseif not OctoPort.config.firstRunSeen and OctoPort.ToggleConfig then
      OctoPort.config.firstRunSeen = true
      OctoPort:ShowConfigTab(1, true)
    end
  end
end)
