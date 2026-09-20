-- Safe controller binding registry for WoW 1.12.
--
-- The addon stores selected physical keys in SavedVariables, but applies
-- OCTOPORT_* bindings only to the current UI session. It never calls
-- SaveBindings during normal setup or play. Original bindings are restored
-- when the controller is disabled and on PLAYER_LOGOUT.

local bindingDefinitions = {
  { id = "LSUP",   label = "L-Stick Up",    command = "OCTOPORT_MOVE_FORWARD",  defaultKey = "W", required = true, movement = "forward" },
  { id = "LSDOWN", label = "L-Stick Down",  command = "OCTOPORT_MOVE_BACKWARD", defaultKey = "S", required = true, movement = "backward" },
  { id = "LSLEFT", label = "L-Stick Left",  command = "OCTOPORT_MOVE_LEFT",     defaultKey = "A", required = true, movement = "left" },
  { id = "LSRIGHT", label = "L-Stick Right", command = "OCTOPORT_MOVE_RIGHT",   defaultKey = "D", required = true, movement = "right" },
  { id = "A",      label = "A",           command = "OCTOPORT_ACTION_A",     defaultKey = "F9",    required = true },
  { id = "B",      label = "B",           command = "OCTOPORT_ACTION_B",     defaultKey = "F10",   required = true },
  { id = "X",      label = "X",           command = "OCTOPORT_ACTION_X",     defaultKey = "F11",   required = true },
  { id = "Y",      label = "Y",           command = "OCTOPORT_ACTION_Y",     defaultKey = "F12",   required = true },
  { id = "DUP",    label = "D-Pad Up",    command = "OCTOPORT_TARGET_UP",    defaultKey = "UP",    required = true },
  { id = "DDOWN",  label = "D-Pad Down",  command = "OCTOPORT_TARGET_DOWN",  defaultKey = "DOWN",  required = true },
  { id = "DLEFT",  label = "D-Pad Left",  command = "OCTOPORT_TARGET_LEFT",  defaultKey = "LEFT",  required = true },
  { id = "DRIGHT", label = "D-Pad Right", command = "OCTOPORT_TARGET_RIGHT", defaultKey = "RIGHT", required = true },
  { id = "MENU",   label = "Menu",        command = "OCTOPORT_RADIAL",       defaultKey = "F8",    required = true },
  { id = "LB",     label = "LB layer",    command = "OCTOPORT_LAYER_LB",     nativeKey = "SHIFT", layer = "shift" },
  { id = "LT",     label = "LT layer",    command = "OCTOPORT_LAYER_LT",     nativeKey = "CTRL",  layer = "ctrl" },
  { id = "VIEW",   label = "View / Settings", command = "OCTOPORT_OPENCONFIG", defaultKey = "F7" },
  { id = "M1",     label = "Rear M1",     command = "OCTOPORT_REAR_M1",      defaultKey = "F6" },
  { id = "M2",     label = "Rear M2",     command = "OCTOPORT_REAR_M2",      defaultKey = "F5" },
}

-- Commands written by every public version through 0.4.0. Removed commands
-- remain here so migration can clean them from a saved WoW binding set.
local legacyCommands = {
  "OCTOPORT_MOVE_FORWARD",
  "OCTOPORT_MOVE_BACKWARD",
  "OCTOPORT_MOVE_LEFT",
  "OCTOPORT_MOVE_RIGHT",
  "OCTOPORT_ACTION_A",
  "OCTOPORT_ACTION_B",
  "OCTOPORT_ACTION_X",
  "OCTOPORT_ACTION_Y",
  "OCTOPORT_RADIAL",
  "OCTOPORT_TARGET_UP",
  "OCTOPORT_TARGET_DOWN",
  "OCTOPORT_TARGET_LEFT",
  "OCTOPORT_TARGET_RIGHT",
  "OCTOPORT_LAYER_LB",
  "OCTOPORT_LAYER_LT",
  "OCTOPORT_OPENCONFIG",
  "OCTOPORT_REAR_M1",
  "OCTOPORT_REAR_M2",
  "OCTOPORT_TOGGLEBAGS",
  "OCTOPORT_TOGGLEHELP",
}

OctoPort.bindingDefinitions = bindingDefinitions

local rearActionOrder = { "settings", "interact", "jump", "autorun", "bags", "map", "target", "reticle", "radial" }
local rearActionLabels = {
  settings = "Settings",
  interact = "Interact",
  jump = "Jump",
  autorun = "Auto run",
  bags = "Bags",
  map = "Map",
  target = "Next enemy",
  reticle = "Reticle",
  radial = "Radial wheel",
}

OctoPort.rearActionOrder = rearActionOrder
OctoPort.rearActionLabels = rearActionLabels

local function CurrentBinding(key)
  if GetBindingAction then return GetBindingAction(key) or "" end
  return ""
end

local function FindDefinition(value)
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.id == value or definition.command == value then return definition, index end
  end
  return nil
end

local function IsModifier(key)
  return key == "SHIFT" or key == "CTRL" or key == "ALT"
end

local function ClearCommand(command)
  local guard = 0
  while guard < 8 do
    local key1, key2 = GetBindingKey(command)
    if not key1 and not key2 then break end
    if key1 then SetBinding(key1) end
    if key2 then SetBinding(key2) end
    guard = guard + 1
  end
end

function OctoPort:GetBindingDefinition(value)
  return FindDefinition(value)
end

function OctoPort:EnsureMovementDefaults()
  if not self.config then return end
  self.config.controllerKeys = self.config.controllerKeys or {}
  if (tonumber(self.config.movementBindingVersion) or 0) >= 1 then return end

  local assigned = {}
  for id, key in pairs(self.config.controllerKeys) do
    if key and key ~= "" then assigned[key] = id end
  end

  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.movement and not self.config.controllerKeys[definition.id] and not assigned[definition.defaultKey] then
      self.config.controllerKeys[definition.id] = definition.defaultKey
      assigned[definition.defaultKey] = definition.id
    end
  end

  self.config.movementBindingVersion = 1
end

function OctoPort:GetControllerBindingKey(definition)
  if type(definition) ~= "table" then definition = FindDefinition(definition) end
  if not definition or not self.config then return nil end

  if definition.layer and self.config.nativeModifiers then
    for modifier, layer in pairs(self.config.nativeModifiers) do
      if layer == definition.layer then return modifier .. " (native)" end
    end
  end

  return self.config.controllerKeys and self.config.controllerKeys[definition.id]
end

function OctoPort:RefreshSetupState()
  local complete = true
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.required and not self:GetControllerBindingKey(definition) then
      complete = false
      break
    end
  end
  self.config.setupComplete = complete
  if complete then self.config.bindingVersion = 6 end
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
  return complete
end

function OctoPort:BindControllerKey(definition, key)
  if type(definition) ~= "table" then definition = FindDefinition(definition) end
  if not definition or not key or key == "" or key == "UNKNOWN" then return false end
  if not self.config then self:InitializeConfig() end

  self.config.controllerKeys = self.config.controllerKeys or {}
  self.config.nativeModifiers = self.config.nativeModifiers or {}

  -- One physical key may own only one controller action.
  for id, configuredKey in pairs(self.config.controllerKeys) do
    if configuredKey == key then self.config.controllerKeys[id] = nil end
  end

  if definition.layer and IsModifier(key) then
    for modifier, layer in pairs(self.config.nativeModifiers) do
      if layer == definition.layer or modifier == key then
        self.config.nativeModifiers[modifier] = nil
      end
    end
    self.config.nativeModifiers[key] = definition.layer
    self.config.controllerKeys[definition.id] = nil
  else
    if definition.layer then
      for modifier, layer in pairs(self.config.nativeModifiers) do
        if layer == definition.layer then self.config.nativeModifiers[modifier] = nil end
      end
    end
    self.config.controllerKeys[definition.id] = key
  end

  -- Refresh only the temporary session. Normal setup never writes WoW's
  -- account/character binding set to disk or server.
  if self.config.enabled then self:ActivateSessionBindings() end
  self:RefreshSetupState()
  return true
end

function OctoPort:ApplyRecommendedBindings()
  if not self.config then self:InitializeConfig() end
  self.config.controllerKeys = {}
  self.config.nativeModifiers = { SHIFT = "shift", CTRL = "ctrl" }

  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.defaultKey and not definition.layer then
      self.config.controllerKeys[definition.id] = definition.defaultKey
    end
  end

  self.config.movementBindingVersion = 1
  self.config.bindingVersion = 6
  self:RefreshSetupState()
  if self.config.enabled then self:ActivateSessionBindings() end
  self:Print("Safe ROG Ally profile selected. It is session-only and does not overwrite saved WoW bindings.")
end

function OctoPort:DeactivateSessionBindings()
  if not self.sessionBindingBackup then
    self.sessionBindingsActive = false
    return
  end

  for index = 1, table.getn(legacyCommands) do
    ClearCommand(legacyCommands[index])
  end
  for key, command in pairs(self.sessionBindingBackup) do
    if command and command ~= "" then SetBinding(key, command) else SetBinding(key) end
  end

  self.sessionBindingBackup = nil
  self.sessionBindingsActive = false
end

function OctoPort:ActivateSessionBindings()
  if not self.config or not self.config.enabled then return false end
  self:DeactivateSessionBindings()
  self.sessionBindingBackup = {}

  local applied = 0
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    local key = self.config.controllerKeys and self.config.controllerKeys[definition.id]
    if key and key ~= "" then
      if self.sessionBindingBackup[key] == nil then
        self.sessionBindingBackup[key] = CurrentBinding(key)
      end
      if SetBinding(key, definition.command) then applied = applied + 1 end
    end
  end

  self.sessionBindingsActive = applied > 0
  return self.sessionBindingsActive
end

local function CaptureLegacyControllerKeys(config)
  config.controllerKeys = config.controllerKeys or {}
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    local key = GetBindingKey(definition.command)
    if key and not config.controllerKeys[definition.id] and not IsModifier(key) then
      config.controllerKeys[definition.id] = key
    end
  end
end

function OctoPort:RecoverLegacyBindings(force)
  if not self.config then return false end
  if not force and not self.needsSafetyMigration then return false end

  CaptureLegacyControllerKeys(self.config)

  -- First remove every custom command, including movement commands deleted in
  -- 0.5.0. Then restore exact pre-addon actions captured by old releases.
  for index = 1, table.getn(legacyCommands) do
    ClearCommand(legacyCommands[index])
  end
  if self.config.bindingBackup then
    for key, command in pairs(self.config.bindingBackup) do
      if command and command ~= "" then SetBinding(key, command) else SetBinding(key) end
    end
  end

  -- This is the only persistent binding write: it repairs damage created by
  -- versions that used SaveBindings during setup.
  SaveBindings(GetCurrentBindingSet())
  self.config.bindingBackup = nil
  self.config.safetyVersion = 1
  self.config.bindingVersion = 0
  self.config.setupComplete = false
  self.config.enabled = false
  self.needsSafetyMigration = false
  return true
end

function OctoPort:RestoreBindings()
  self.config.enabled = false
  self:DeactivateSessionBindings()
  self:RecoverLegacyBindings(true)
  if self.SetUIEnabled then self:SetUIEnabled(false) end
  self:Print("Emergency cleanup complete. Saved OCTOPORT bindings were removed and the addon is OFF.")
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
end

function OctoPort:SignalInput(id, state)
  self.lastControllerInput = id
  self.lastControllerInputState = state or "press"
  self.lastControllerInputAt = GetTime()
  if self.UpdateInputDiagnostics then self:UpdateInputDiagnostics() end
end

function OctoPort_Move(direction, keystate)
  if not OctoPort or not OctoPort.config or not OctoPort.config.enabled then return end

  local ids = { forward = "LSUP", backward = "LSDOWN", left = "LSLEFT", right = "LSRIGHT" }
  OctoPort:SignalInput(ids[direction], keystate)
  if OctoPort.bindingCaptureActive then return end

  local stopFunctions = {
    forward = MoveForwardStop,
    backward = MoveBackwardStop,
    left = StrafeLeftStop,
    right = StrafeRightStop,
  }
  if keystate ~= "down" then
    if stopFunctions[direction] then stopFunctions[direction]() end
    return
  end

  local menuDirection = { forward = "up", backward = "down", left = "left", right = "right" }
  if OctoPort.HandleRadialDirection and OctoPort:HandleRadialDirection(menuDirection[direction]) then return end
  if OctoPort.HandleConfigDirection and OctoPort:HandleConfigDirection(menuDirection[direction]) then return end

  local startFunctions = {
    forward = MoveForwardStart,
    backward = MoveBackwardStart,
    left = StrafeLeftStart,
    right = StrafeRightStart,
  }
  if startFunctions[direction] then startFunctions[direction]() end
end

function OctoPort:GetRearActionLabel(button)
  local action = self.config and self.config.rearActions and self.config.rearActions[button] or "settings"
  return rearActionLabels[action] or action
end

function OctoPort:CycleRearAction(button)
  self.config.rearActions = self.config.rearActions or { M1 = "settings", M2 = "interact" }
  local current = self.config.rearActions[button]
  local position = 1
  for index = 1, table.getn(rearActionOrder) do
    if rearActionOrder[index] == current then position = index end
  end
  position = position + 1
  if position > table.getn(rearActionOrder) then position = 1 end
  self.config.rearActions[button] = rearActionOrder[position]
  if self.RefreshRearActionButtons then self:RefreshRearActionButtons() end
end

function OctoPort:HandleRearAction(button, keystate)
  if not self.config or not self.config.enabled then return end
  local action = self.config.rearActions and self.config.rearActions[button]
  if not action then action = button == "M1" and "settings" or "interact" end

  if action == "interact" then
    if keystate == "down" then TurnOrActionStart() else TurnOrActionStop() end
    return
  elseif action == "radial" then
    if self.HandleRadialKey then self:HandleRadialKey(keystate) end
    return
  elseif keystate ~= "down" then
    return
  end

  if action == "settings" then
    if self.ToggleConfig then self:ToggleConfig() end
  elseif action == "jump" then
    Jump()
  elseif action == "autorun" then
    ToggleAutoRun()
  elseif action == "bags" then
    OctoPort_ToggleBags()
  elseif action == "map" then
    ToggleWorldMap()
  elseif action == "target" then
    TargetNearestEnemy()
    if self.TargetChanged then self:TargetChanged("right") end
  elseif action == "reticle" then
    self.config.reticleEnabled = not self.config.reticleEnabled
    if self.UpdateReticle then self:UpdateReticle(true) end
  end
end

function OctoPort_RearKey(button, keystate)
  if not OctoPort then return end
  OctoPort:SignalInput(button, keystate)
  if OctoPort.bindingCaptureActive then return end
  OctoPort:HandleRearAction(button, keystate)
end

function OctoPort_ActionKey(slot, keystate)
  local ids = { "A", "B", "X", "Y" }
  if OctoPort then OctoPort:SignalInput(ids[slot], keystate) end
  if not OctoPort or not OctoPort.config or not OctoPort.config.enabled then return end
  if OctoPort.bindingCaptureActive then return end
  if OctoPort.HandleControllerAction then OctoPort:HandleControllerAction(slot, keystate) end
end

function OctoPort_RadialKey(keystate)
  if OctoPort then OctoPort:SignalInput("MENU", keystate) end
  if OctoPort and OctoPort.config and OctoPort.config.enabled and not OctoPort.bindingCaptureActive and OctoPort.HandleRadialKey then
    OctoPort:HandleRadialKey(keystate)
  end
end

function OctoPort_Target(direction)
  local ids = { up = "DUP", down = "DDOWN", left = "DLEFT", right = "DRIGHT" }
  if OctoPort then OctoPort:SignalInput(ids[direction]) end
  if not OctoPort or not OctoPort.config or not OctoPort.config.enabled or OctoPort.bindingCaptureActive then return end

  if OctoPort.HandleRadialDirection and OctoPort:HandleRadialDirection(direction) then return end
  if OctoPort.HandleConfigDirection and OctoPort:HandleConfigDirection(direction) then return end

  if direction == "up" then
    TargetNearestFriend(1)
  elseif direction == "down" then
    TargetNearestFriend()
  elseif direction == "left" then
    TargetNearestEnemy(1)
  elseif direction == "right" then
    TargetNearestEnemy()
  end

  if OctoPort.TargetChanged then OctoPort:TargetChanged(direction) end
end

function OctoPort_LayerKey(layer, keystate)
  if not OctoPort or not OctoPort.config or not OctoPort.config.enabled then return end
  OctoPort.controllerLayerState = OctoPort.controllerLayerState or {}
  OctoPort.controllerLayerState[layer] = keystate == "down" and true or false
  OctoPort:SignalInput(layer == "shift" and "LB" or "LT", keystate)
  if OctoPort.UpdateLayer then OctoPort:UpdateLayer(true) end
end

function OctoPort_OpenConfig()
  if not OctoPort then return end
  OctoPort:SignalInput("VIEW")
  if not OctoPort.bindingCaptureActive and OctoPort.ToggleConfig then OctoPort:ToggleConfig() end
end

function OctoPort_ToggleBags()
  local anyOpen = false
  for index = 1, 12 do
    local frame = getglobal("ContainerFrame" .. index)
    if frame and frame:IsVisible() then anyOpen = true break end
  end
  if anyOpen then CloseAllBags() else OpenAllBags() end
end

function OctoPort_ToggleHelp()
  if OctoPort and OctoPort.ToggleConfig then OctoPort:ToggleConfig(true) end
end
