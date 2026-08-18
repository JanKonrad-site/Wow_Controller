-- Recommended keyboard layer used by the ROG Ally X Desktop Mode profile.
-- The addon never applies it silently. The player must use /octoport setup.

local bindings = {}

local function AddBinding(key, command)
  table.insert(bindings, { key, command })
end

-- F9-F12 are deliberately used for ABXY so the controller does not inherit
-- desktop Enter/Escape bindings. The same command is registered with both
-- action-layer modifiers; the handler chooses the visible layer at runtime.
local modifiers = { "", "SHIFT-", "CTRL-" }
local faceKeys = { "F9", "F10", "F11", "F12" }
local faceCommands = {
  "OCTOPORT_ACTION_A",
  "OCTOPORT_ACTION_B",
  "OCTOPORT_ACTION_X",
  "OCTOPORT_ACTION_Y",
}

for _, modifier in pairs(modifiers) do
  for slot = 1, 4 do
    AddBinding(modifier .. faceKeys[slot], faceCommands[slot])
  end

  AddBinding(modifier .. "F8", "OCTOPORT_RADIAL")
  AddBinding(modifier .. "UP", "OCTOPORT_TARGET_UP")
  AddBinding(modifier .. "DOWN", "OCTOPORT_TARGET_DOWN")
  AddBinding(modifier .. "LEFT", "OCTOPORT_TARGET_LEFT")
  AddBinding(modifier .. "RIGHT", "OCTOPORT_TARGET_RIGHT")
end

-- Useful fallbacks for controls that are not part of the face/D-pad cluster.
AddBinding("TAB", "TARGETNEARESTENEMY")
AddBinding("SHIFT-TAB", "TARGETPREVIOUSENEMY")
AddBinding("CTRL-TAB", "TARGETNEARESTFRIEND")
AddBinding("F", "TURNORACTION")
AddBinding("R", "OCTOPORT_TOGGLEBAGS")
AddBinding("M", "TOGGLEWORLDMAP")
AddBinding("SPACE", "JUMP")
AddBinding("NUMLOCK", "TOGGLEAUTORUN")
AddBinding("ESCAPE", "TOGGLEGAMEMENU")

OctoPort.recommendedBindings = bindings

local function CurrentBinding(key)
  if GetBindingAction then
    return GetBindingAction(key) or ""
  end
  return ""
end

function OctoPort:ApplyRecommendedBindings()
  if not self.config then self:InitializeConfig() end

  self.config.bindingBackup = self.config.bindingBackup or {}

  -- Back up newly managed keys as they are introduced by addon updates. This
  -- keeps old 0.1 profiles restorable without discarding their first backup.
  for i = 1, table.getn(bindings) do
    local key = bindings[i][1]
    if self.config.bindingBackup[key] == nil then
      self.config.bindingBackup[key] = CurrentBinding(key)
    end
  end

  local failed = 0
  for i = 1, table.getn(bindings) do
    local key = bindings[i][1]
    local command = bindings[i][2]
    if not SetBinding(key, command) then failed = failed + 1 end
  end

  SaveBindings(GetCurrentBindingSet())
  self.config.setupComplete = failed == 0

  if failed == 0 then
    self:Print("Controller profile 0.2 applied and saved.")
    self:Print("Armoury Crate: ABXY = F9-F12, D-pad = arrows, Menu = F8.")
  else
    self:Print("Could not apply " .. failed .. " bindings. Try again outside combat.")
  end

  if self.RefreshButtonLabels then self:RefreshButtonLabels() end
end

function OctoPort:RestoreBindings()
  if not self.config or not self.config.bindingBackup then
    self:Print("No WOW Controller binding backup exists for this character.")
    return
  end

  for key, command in pairs(self.config.bindingBackup) do
    if command and command ~= "" then
      SetBinding(key, command)
    else
      SetBinding(key)
    end
  end

  SaveBindings(GetCurrentBindingSet())
  self.config.bindingBackup = nil
  self.config.setupComplete = false
  self:Print("Original bindings restored.")
end

function OctoPort_ActionKey(slot, keystate)
  if OctoPort and OctoPort.HandleControllerAction then
    OctoPort:HandleControllerAction(slot, keystate)
  elseif keystate ~= "down" and ActionButtonUp then
    ActionButtonUp(slot)
  elseif keystate == "down" and ActionButtonDown then
    ActionButtonDown(slot)
  end
end

function OctoPort_RadialKey(keystate)
  if OctoPort and OctoPort.HandleRadialKey then
    OctoPort:HandleRadialKey(keystate)
  end
end

function OctoPort_Target(direction)
  if direction == "up" then
    TargetNearestFriend(1)
  elseif direction == "down" then
    TargetNearestFriend()
  elseif direction == "left" then
    TargetNearestEnemy(1)
  elseif direction == "right" then
    TargetNearestEnemy()
  end

  if OctoPort and OctoPort.TargetChanged then
    OctoPort:TargetChanged(direction)
  end
end

function OctoPort_ToggleBags()
  local anyOpen = false
  for i = 1, 12 do
    local frame = getglobal("ContainerFrame" .. i)
    if frame and frame:IsVisible() then
      anyOpen = true
      break
    end
  end

  if anyOpen then
    CloseAllBags()
  else
    OpenAllBags()
  end
end

function OctoPort_ToggleHelp()
  if OctoPort and OctoPort.ToggleHelp then OctoPort:ToggleHelp() end
end
