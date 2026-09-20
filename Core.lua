-- WOW Controller 0.9.1
-- Controller-first interface for OctoWoW / World of Warcraft 1.12.x.

OctoPort = OctoPort or {}
OctoPort.version = "0.9.1"

BINDING_HEADER_OCTOPORT = "WOW Controller"
BINDING_NAME_OCTOPORT_TOGGLEBAGS = "Open / close all bags"
BINDING_NAME_OCTOPORT_TOGGLEHELP = "Open OctoPort help"
BINDING_NAME_OCTOPORT_ACTION_A = "Controller A / action 1 (legacy)"
BINDING_NAME_OCTOPORT_ACTION_B = "Controller B / action 2 (legacy)"
BINDING_NAME_OCTOPORT_ACTION_X = "Controller X"
BINDING_NAME_OCTOPORT_ACTION_Y = "Controller Y"
BINDING_NAME_OCTOPORT_RADIAL = "Hold controller Menu / radial menu"
BINDING_NAME_OCTOPORT_TARGET_UP = "Previous friendly target"
BINDING_NAME_OCTOPORT_TARGET_DOWN = "Next friendly target"
BINDING_NAME_OCTOPORT_TARGET_LEFT = "Previous enemy target"
BINDING_NAME_OCTOPORT_TARGET_RIGHT = "Next enemy target"
BINDING_NAME_OCTOPORT_LAYER_LT = "Controller LT action layer"
BINDING_NAME_OCTOPORT_LAYER_RT = "Controller RT action layer"
BINDING_NAME_OCTOPORT_OPENCONFIG = "Open WOW Controller settings"
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
  -- Installation must be inert until the player explicitly enables it.
  enabled = false,
  safetyVersion = 1,
  scale = 1.00,
  x = 0,
  y = 122,
  editMode = false,
  moveMode = false,
  setupComplete = false,
  bindingVersion = 0,
  controlSchemaVersion = 0,
  firstRunSeen = false,
  bindingBackup = nil,
  controllerKeys = {},
  directionVerifiedKeys = {},
  movementBindingVersion = 0,
  arrowMovementFallback = false,
  menuOnlyMode = false,
  nativeFaceButtons = true,
  autoTarget = false,
  autoAcceptQuests = false,
  radialHold = 0.35,
  radialSlots = defaultRadialSlots,
  mountName = "",
  nativeModifiers = { SHIFT = "lt", CTRL = "rt" },
  selectedConfigTab = 1,
  reticleEnabled = false,
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
  local hadExistingConfig = type(OctoPortConfig) == "table"
  OctoPortConfig = OctoPortConfig or {}
  local previousSafetyVersion = tonumber(OctoPortConfig.safetyVersion) or 0
  CopyDefaults(OctoPortConfig, defaults)
  self.config = OctoPortConfig
  -- A /reload can discard Lua locals while WoW keeps the current temporary
  -- binding set. Recover the per-character baseline before migration, profile
  -- upgrades, UI creation or any new session activation.
  self.startupBindingRecoveryBlocked = nil
  if self.RecoverPersistedBindingSnapshot and self.config.bindingRecoverySnapshot then
    local recovered = self:RecoverPersistedBindingSnapshot()
    if recovered ~= true then
      self.config.enabled = false
      self.startupBindingRecoveryBlocked = true
    end
  end
  if self.EnsureMovementDefaults then self:EnsureMovementDefaults() end
  if self.EnsureDirectControlDefaults then self.controlsProfileUpgraded = self:EnsureDirectControlDefaults() end
  if self.RefreshSetupState then self:RefreshSetupState() end
  self.needsSafetyMigration = hadExistingConfig and previousSafetyVersion < defaults.safetyVersion
  if self.needsSafetyMigration then
    -- Versions through 0.4.0 saved custom commands permanently and modified
    -- Blizzard action buttons automatically. Stop all features before cleanup.
    self.config.enabled = false
    self.config.autoTarget = false
    self.config.autoAcceptQuests = false
    self.config.reticleEnabled = false
  end
end

function OctoPort:ShowCommands()
  self:Print("/octoport - open controller settings")
  self:Print("/octoport setup - start the controller binding wizard")
  self:Print("/octoport test - open the raw keyboard/mouse input test")
  self:Print("/octoport preset - apply safe session-only ROG Ally keys")
  self:Print("/octoport restore - disable addon and restore original bindings")
  self:Print("/octoport edit - show and edit all 20 action slots")
  self:Print("/octoport move - unlock or lock the controller HUD")
  self:Print("/octoport scale 0.7-1.6 - resize the HUD")
  self:Print("/octoport reset - reset HUD position and size")
  self:Print("/octoport wheel - edit the radial menu")
  self:Print("/octoport quest on | off - automatic quest acceptance")
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
  self.config.menuOnlyMode = false
  self.config.enabled = enabled and true or false
  local deferred = false
  if self.config.enabled then
    if self.ActivateSessionBindings then
      local activated, reason = self:ActivateSessionBindings()
      if activated == false then
        self.config.enabled = false
        if self.SetUIEnabled then self:SetUIEnabled(false) end
        self:Print("Controller stayed OFF because stick and D-pad calibration is incomplete or conflicting.")
        if self.ShowConfigTab then self:ShowConfigTab(1, true) end
        return false
      elseif activated == nil and (reason == "deferred" or self.bindingMutationDeferred) then
        deferred = true
      end
    end
  elseif self.DeactivateSessionBindings then
    local deactivated, reason = self:DeactivateSessionBindings()
    if deactivated == nil and (reason == "deferred" or self.bindingMutationDeferred) then deferred = true end
  end
  if self.SetUIEnabled then
    -- Never present a combat-ready HUD until the requested binding state has
    -- actually been installed. PLAYER_REGEN_ENABLED finishes it safely.
    self:SetUIEnabled(self.config.enabled and not deferred)
  elseif self.root then
    if self.config.enabled and not deferred then self.root:Show() else self.root:Hide() end
  end
  if self.configFrame and self.configFrame:IsVisible() and self.ActivateConfigNavigationBindings then
    self:ActivateConfigNavigationBindings()
  end
  if deferred then
    self:Print("Binding change queued until combat ends; no protected binding API was called.")
    return nil, "deferred"
  end
  self:Print(self.config.enabled and "Safe controller session enabled." or "Controller disabled; original bindings restored.")
  return true
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
  elseif message == "test" then
    if self.StartRawInputTest then self:StartRawInputTest() end
  elseif message == "preset" then
    self:ApplyRecommendedBindings()
  elseif message == "restore" then
    self:RestoreBindings()
  elseif message == "edit" then
    if self.SetActionEditMode then
      self:SetActionEditMode(not self.config.editMode)
    else
      self.config.editMode = not self.config.editMode
      if self.UpdateLayer then self:UpdateLayer(true) end
    end
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
    self.config.autoTarget = false
    self:Print("Automatic combat targeting is disabled for safety. Use D-pad Right for the next enemy.")
  elseif message == "target off" or message == "autotarget off" then
    self.config.autoTarget = false
    self:Print("Automatic combat targeting is already disabled.")
  elseif message == "quest on" then
    self.config.autoAcceptQuests = true
    self:Print("Automatic quest acceptance enabled. Hold LT while opening a quest to inspect it first.")
  elseif message == "quest off" then
    self.config.autoAcceptQuests = false
    self:Print("Automatic quest acceptance disabled.")
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
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and (arg1 == "Wow_Controller" or arg1 == "OctoPort") then
    OctoPort:InitializeConfig()
  elseif event == "PLAYER_LOGIN" then
    if not OctoPort.config then OctoPort:InitializeConfig() end
    local recoveryReady = true
    if OctoPort.RecoverPersistedBindingSnapshot and OctoPort.config.bindingRecoverySnapshot then
      recoveryReady = OctoPort:RecoverPersistedBindingSnapshot() == true
      if not recoveryReady then OctoPort.config.enabled = false end
    end
    local migrated = false
    if recoveryReady and OctoPort.RecoverLegacyBindings then migrated = OctoPort:RecoverLegacyBindings() end
    if OctoPort.InitializeUI then OctoPort:InitializeUI() end
    if recoveryReady and OctoPort.config.enabled then
      local activated = OctoPort.ActivateSessionBindings and OctoPort:ActivateSessionBindings()
      if not activated then
        -- Never leave a visible HUD claiming the controller is active after a
        -- failed migration, incomplete live calibration or rejected binding.
        OctoPort.config.enabled = false
        if OctoPort.SetUIEnabled then OctoPort:SetUIEnabled(false) end
        OctoPort:Print("Controller stayed OFF because its live input verification is incomplete or a binding was rejected.")
        if OctoPort.ShowConfigTab then OctoPort:ShowConfigTab(1, true) end
      else
        OctoPort:Print("v" .. OctoPort.version .. " loaded. Type /octoport for help.")
      end
    end
    if not recoveryReady and OctoPort.ShowConfigTab then
      OctoPort.config.firstRunSeen = true
      OctoPort:Print("Temporary bindings are waiting for exact recovery; the controller stays OFF until combat ends.")
      OctoPort:ShowConfigTab(1, true)
    elseif migrated and OctoPort.ShowConfigTab then
      OctoPort.config.firstRunSeen = true
      OctoPort:Print("Unsafe bindings from an older version were removed. The addon is OFF until you enable it again.")
      OctoPort:ShowConfigTab(1, true)
    elseif OctoPort.controlsProfileUpgraded and OctoPort.ShowConfigTab then
      OctoPort.config.firstRunSeen = true
      OctoPort:Print("Universal 20-action profile prepared. Calibrate all eight stick/D-pad directions before enabling it.")
      OctoPort:ShowConfigTab(1, true)
    elseif not OctoPort.config.setupComplete and OctoPort.ShowConfigTab then
      OctoPort.config.firstRunSeen = true
      OctoPort:ShowConfigTab(1, true)
    elseif not OctoPort.config.firstRunSeen and OctoPort.ToggleConfig then
      OctoPort.config.firstRunSeen = true
      OctoPort:ShowConfigTab(1, true)
    end
  elseif event == "PLAYER_TARGET_CHANGED" then
    -- Target selection stays on Blizzard's native TARGET* bindings. This
    -- event only mirrors the result in our HUD after the secure action ran.
    if OctoPort.TargetChanged then OctoPort:TargetChanged() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- PLAYER_REGEN_ENABLED fires after every combat. Only reconcile when a
    -- protected binding request was actually deferred, otherwise this event
    -- would spam a false "finished" message after each fight.
    if OctoPort.bindingMutationDeferred and OctoPort.RetryDeferredBindings then
      local restored, reason = OctoPort:RetryDeferredBindings()
      if restored == false then
        OctoPort:Print("Deferred controller bindings could not be restored. Open Setup before enabling the controller.")
      elseif restored and reason ~= "deferred" then
        if OctoPort.SetUIEnabled then OctoPort:SetUIEnabled(OctoPort.config and OctoPort.config.enabled and true or false) end
        OctoPort:Print("Deferred controller binding change finished safely after combat.")
      end
      if OctoPort.RefreshBindingMenu then OctoPort:RefreshBindingMenu() end
    end
  elseif event == "PLAYER_LOGOUT" then
    -- Prefer the durable baseline. If combat blocks the protected API, the
    -- snapshot remains in SavedVariables and is recovered first on next load.
    if OctoPort.config and OctoPort.config.bindingRecoverySnapshot and OctoPort.RecoverPersistedBindingSnapshot then
      OctoPort:RecoverPersistedBindingSnapshot()
    elseif OctoPort.DeactivateSessionBindings then
      OctoPort:DeactivateSessionBindings()
    end
  end
end)
