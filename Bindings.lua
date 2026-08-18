-- Controller binding registry, presets and diagnostics.
-- WoW 1.12 has no XInput API, so the setup wizard binds the keyboard or mouse
-- signal that the handheld actually sends instead of guessing a device preset.

local bindingDefinitions = {
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
}

OctoPort.bindingDefinitions = bindingDefinitions

local extraPresetBindings = {
  { "TAB", "TARGETNEARESTENEMY" },
  { "SHIFT-TAB", "TARGETPREVIOUSENEMY" },
  { "CTRL-TAB", "TARGETNEARESTFRIEND" },
  { "F", "TURNORACTION" },
  { "R", "OCTOPORT_TOGGLEBAGS" },
  { "M", "TOGGLEWORLDMAP" },
  { "SPACE", "JUMP" },
  { "NUMLOCK", "TOGGLEAUTORUN" },
  { "ESCAPE", "TOGGLEGAMEMENU" },
}

local function CurrentBinding(key)
  if GetBindingAction then return GetBindingAction(key) or "" end
  return ""
end

local function IsCustomCommand(command)
  if not command then return false end
  return string.sub(command, 1, 9) == "OCTOPORT_"
end

local function FindDefinition(value)
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.id == value or definition.command == value then return definition, index end
  end
  return nil
end

function OctoPort:GetBindingDefinition(value)
  return FindDefinition(value)
end

function OctoPort:BackupBinding(key)
  if not key or key == "" then return end
  self.config.bindingBackup = self.config.bindingBackup or {}
  if self.config.bindingBackup[key] == nil then
    local oldAction = CurrentBinding(key)
    if IsCustomCommand(oldAction) then oldAction = "" end
    self.config.bindingBackup[key] = oldAction
  end
end

function OctoPort:ClearCommandBindings(command, restoreOriginal)
  local function ClearKey(key)
    if not key then return end
    local original = self.config and self.config.bindingBackup and self.config.bindingBackup[key]
    if restoreOriginal ~= false and original and original ~= "" then
      SetBinding(key, original)
    else
      SetBinding(key)
    end
  end
  local guard = 0
  while guard < 8 do
    local key1, key2 = GetBindingKey(command)
    if not key1 and not key2 then break end
    ClearKey(key1)
    ClearKey(key2)
    guard = guard + 1
  end
end

function OctoPort:GetControllerBindingKey(definition)
  if type(definition) ~= "table" then definition = FindDefinition(definition) end
  if not definition then return nil end

  local key1 = GetBindingKey(definition.command)
  if key1 then return key1 end

  if definition.layer and self.config and self.config.nativeModifiers then
    for modifier, layer in pairs(self.config.nativeModifiers) do
      if layer == definition.layer then return modifier .. " (native)" end
    end
  end

  return nil
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
  if complete then self.config.bindingVersion = 3 end
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
  return complete
end

function OctoPort:BindControllerKey(definition, key)
  if type(definition) ~= "table" then definition = FindDefinition(definition) end
  if not definition or not key or key == "" or key == "UNKNOWN" then return false end
  if not self.config then self:InitializeConfig() end

  if definition.layer and (key == "SHIFT" or key == "CTRL" or key == "ALT") then
    self:ClearCommandBindings(definition.command)
    for modifier, layer in pairs(self.config.nativeModifiers) do
      if layer == definition.layer then self.config.nativeModifiers[modifier] = nil end
    end
    self.config.nativeModifiers[key] = definition.layer
  else
    self:BackupBinding(key)
    self:ClearCommandBindings(definition.command)
    if definition.layer then
      for modifier, layer in pairs(self.config.nativeModifiers) do
        if layer == definition.layer then self.config.nativeModifiers[modifier] = nil end
      end
    end
    if not SetBinding(key, definition.command) then return false end
  end

  SaveBindings(GetCurrentBindingSet())
  self:RefreshSetupState()
  return true
end

function OctoPort:ApplyRecommendedBindings()
  if not self.config then self:InitializeConfig() end
  self.config.nativeModifiers = { SHIFT = "shift", CTRL = "ctrl" }

  local failed = 0
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    self:ClearCommandBindings(definition.command)
    if definition.defaultKey then
      self:BackupBinding(definition.defaultKey)
      if not SetBinding(definition.defaultKey, definition.command) then failed = failed + 1 end
    end
  end

  for index = 1, table.getn(extraPresetBindings) do
    local key = extraPresetBindings[index][1]
    self:BackupBinding(key)
    if not SetBinding(key, extraPresetBindings[index][2]) then failed = failed + 1 end
  end

  SaveBindings(GetCurrentBindingSet())
  self:RefreshSetupState()

  if failed == 0 then
    self:Print("ROG Ally legacy preset applied. Use Controller > Diagnostics to test every input.")
  else
    self:Print("Could not apply " .. failed .. " bindings. Try again outside combat.")
  end
end

function OctoPort:RestoreBindings()
  if not self.config or not self.config.bindingBackup then
    self:Print("No WOW Controller binding backup exists for this character.")
    return
  end

  for index = 1, table.getn(bindingDefinitions) do
    self:ClearCommandBindings(bindingDefinitions[index].command, false)
  end

  for key, command in pairs(self.config.bindingBackup) do
    if command and command ~= "" then SetBinding(key, command) else SetBinding(key) end
  end

  SaveBindings(GetCurrentBindingSet())
  self.config.bindingBackup = nil
  self.config.setupComplete = false
  self.config.bindingVersion = 0
  self.config.nativeModifiers = { SHIFT = "shift", CTRL = "ctrl" }
  self:Print("Original bindings restored.")
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
end

function OctoPort:SignalInput(id, state)
  self.lastControllerInput = id
  self.lastControllerInputState = state or "press"
  self.lastControllerInputAt = GetTime()
  if self.UpdateInputDiagnostics then self:UpdateInputDiagnostics() end
end

function OctoPort_ActionKey(slot, keystate)
  local ids = { "A", "B", "X", "Y" }
  if OctoPort then OctoPort:SignalInput(ids[slot], keystate) end
  if OctoPort and OctoPort.bindingCaptureActive then return end
  if OctoPort and OctoPort.HandleControllerAction then
    OctoPort:HandleControllerAction(slot, keystate)
  elseif keystate ~= "down" and ActionButtonUp then
    ActionButtonUp(slot)
  elseif keystate == "down" and ActionButtonDown then
    ActionButtonDown(slot)
  end
end

function OctoPort_RadialKey(keystate)
  if OctoPort then OctoPort:SignalInput("MENU", keystate) end
  if OctoPort and not OctoPort.bindingCaptureActive and OctoPort.HandleRadialKey then
    OctoPort:HandleRadialKey(keystate)
  end
end

function OctoPort_Target(direction)
  local ids = { up = "DUP", down = "DDOWN", left = "DLEFT", right = "DRIGHT" }
  if OctoPort then OctoPort:SignalInput(ids[direction]) end
  if not OctoPort or OctoPort.bindingCaptureActive then return end

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
  if not OctoPort then return end
  OctoPort.controllerLayerState = OctoPort.controllerLayerState or {}
  OctoPort.controllerLayerState[layer] = keystate == "down" and true or false
  OctoPort:SignalInput(layer == "shift" and "LB" or "LT", keystate)
  if OctoPort.UpdateLayer then OctoPort:UpdateLayer(true) end
end

function OctoPort_OpenConfig()
  if OctoPort and OctoPort.ToggleConfig then OctoPort:ToggleConfig(true) end
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
