-- Safe controller binding registry for WoW 1.12.
--
-- The addon stores selected physical keys in SavedVariables, but applies
-- OCTOPORT_* bindings only to the current UI session. It never calls
-- SaveBindings during normal setup or play. Original bindings are restored
-- when the controller is disabled and on PLAYER_LOGOUT.

local bindingDefinitions = {
  { id = "LSUP",   label = "L-Stick Up",    command = "MOVEFORWARD",  defaultKey = "W", required = true, movement = "forward" },
  { id = "LSDOWN", label = "L-Stick Down",  command = "MOVEBACKWARD", defaultKey = "S", required = true, movement = "backward" },
  { id = "LSLEFT", label = "L-Stick Left",  command = "STRAFELEFT",   defaultKey = "A", required = true, movement = "left" },
  { id = "LSRIGHT", label = "L-Stick Right", command = "STRAFERIGHT", defaultKey = "D", required = true, movement = "right" },
  { id = "A",      label = "A / Action 1", command = "OCTOPORT_ACTION_A",    defaultKey = "1",     required = true, nativeAction = true },
  { id = "B",      label = "B / Action 2", command = "OCTOPORT_ACTION_B",    defaultKey = "2",     required = true, nativeAction = true },
  { id = "X",      label = "X / Action 3", command = "OCTOPORT_ACTION_X",    defaultKey = "3",     required = true, nativeAction = true },
  { id = "Y",      label = "Y / Action 4", command = "OCTOPORT_ACTION_Y",    defaultKey = "4",     required = true, nativeAction = true },
  { id = "DUP",    label = "D-Pad Up",    command = "OCTOPORT_TARGET_UP",    nativeTarget = "TARGETPREVIOUSFRIEND", defaultKey = "UP",    required = true },
  { id = "DDOWN",  label = "D-Pad Down",  command = "OCTOPORT_TARGET_DOWN",  nativeTarget = "TARGETNEARESTFRIEND",  defaultKey = "DOWN",  required = true },
  { id = "DLEFT",  label = "D-Pad Left",  command = "OCTOPORT_TARGET_LEFT",  nativeTarget = "TARGETPREVIOUSENEMY",  defaultKey = "LEFT",  required = true },
  { id = "DRIGHT", label = "D-Pad Right", command = "OCTOPORT_TARGET_RIGHT", nativeTarget = "TARGETNEARESTENEMY",   defaultKey = "RIGHT", required = true },
  { id = "MENU",   label = "Menu",        command = "OCTOPORT_RADIAL",       defaultKey = "F8",    required = true },
  -- Vanilla has no gamepad API. LT and RT therefore have to emit real keyboard
  -- modifiers so Blizzard can execute every combat action as a native binding.
  { id = "LT",     label = "LT / Action layer", command = "OCTOPORT_LAYER_LT", nativeKey = "SHIFT", layer = "lt", required = true },
  { id = "RT",     label = "RT / Action layer", command = "OCTOPORT_LAYER_RT", nativeKey = "CTRL",  layer = "rt", required = true },
  -- Mouse clicks stay device-side. A WoW 1.12 addon cannot safely synthesize a
  -- secure UI click from an arbitrary key, but it can display and test the real
  -- mouse buttons emitted by Armoury Crate or Steam Input.
  { id = "LB",     label = "LB / Mouse Left",  defaultKey = "BUTTON1", passthrough = true },
  { id = "RB",     label = "RB / Mouse Right", defaultKey = "BUTTON2", passthrough = true },
  -- Stick clicks use Blizzard's own binding commands, just like movement.
  { id = "L3",     label = "L3 / Auto Run", command = "TOGGLEAUTORUN", defaultKey = "NUMLOCK", nativeAction = true },
  { id = "R3",     label = "R3 / Jump",     command = "JUMP",          defaultKey = "SPACE",   nativeAction = true },
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
  "OCTOPORT_LAYER_RT",
  "OCTOPORT_OPENCONFIG",
  "OCTOPORT_TOGGLEMODE",
  "OCTOPORT_REAR_M1",
  "OCTOPORT_REAR_M2",
  "OCTOPORT_TOGGLEBAGS",
  "OCTOPORT_TOGGLEHELP",
}

OctoPort.bindingDefinitions = bindingDefinitions

local rearActionOrder = { "settings", "interact", "jump", "autorun", "bags", "map", "target", "radial" }
local rearActionLabels = {
  settings = "Settings",
  interact = "Interact",
  jump = "Jump",
  autorun = "Auto run",
  bags = "Bags",
  map = "Map",
  target = "Next enemy",
  radial = "Radial wheel",
}

local rearNativeCommands = {
  interact = "TURNORACTION",
  jump = "JUMP",
  autorun = "TOGGLEAUTORUN",
  bags = "OPENALLBAGS",
  map = "TOGGLEWORLDMAP",
  target = "TARGETNEARESTENEMY",
}

OctoPort.rearActionOrder = rearActionOrder
OctoPort.rearActionLabels = rearActionLabels

local function CurrentBinding(key)
  if GetBindingAction then return GetBindingAction(key) or "" end
  return ""
end

-- SetBinding is protected by some 1.12-derived clients while the player is in
-- combat. InCombatLockdown is not present in every Vanilla client, so always
-- keep UnitAffectingCombat as the compatible fallback. Every binding mutation
-- in this file goes through SetBindingSafely; callers choose the desired final
-- state and RetryDeferredBindings reconciles it after PLAYER_REGEN_ENABLED.
function OctoPort:IsBindingMutationLocked()
  if InCombatLockdown and InCombatLockdown() then return true end
  if UnitAffectingCombat and UnitAffectingCombat("player") then return true end
  return false
end

function OctoPort:GetBindingOperationStatus()
  return self.bindingMutationDeferred and true or false,
    self.bindingMutationStatus,
    self.pendingBindingOperation
end

function OctoPort:DeferBindingOperation(operation, status)
  -- Startup recovery is the highest-priority request: a later menu show/hide
  -- or legacy cleanup must never overwrite it while combat is still active.
  -- Emergency restore likewise wins over ordinary desired-state reconciliation.
  local priorities = { reconcile = 1, restore = 2, recovery = 3 }
  local requested = operation or "reconcile"
  local pendingPriority = priorities[self.pendingBindingOperation] or 0
  local requestedPriority = priorities[requested] or 1
  if requestedPriority >= pendingPriority then self.pendingBindingOperation = requested end
  self.bindingMutationDeferred = true
  self.bindingMutationStatus = status or "Binding changes are waiting until combat ends."
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
  return nil, "deferred"
end

function OctoPort:ClearDeferredBindingOperation()
  self.pendingBindingOperation = nil
  self.bindingMutationDeferred = nil
  self.bindingMutationStatus = nil
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
end

function OctoPort:SetBindingSafely(key, command)
  if not key or key == "" then return false, "invalid" end
  if self:IsBindingMutationLocked() then
    self:DeferBindingOperation(self.bindingMutationOperation or "reconcile")
    return false, "deferred"
  end
  if not SetBinding then return false, "unavailable" end
  local ok, result = pcall(SetBinding, key, command)
  if not ok or not result then return false, "rejected" end
  return true
end

function OctoPort:SaveBindingsSafely(bindingSet)
  if self:IsBindingMutationLocked() then
    self:DeferBindingOperation("restore")
    return false, "deferred"
  end
  if not SaveBindings then return false, "unavailable" end
  local ok, result = pcall(SaveBindings, bindingSet)
  if not ok then return false, "rejected" end
  -- SaveBindings may return nil even when it succeeds on Vanilla clients.
  return true, result
end

function OctoPort:ReconcileBindingLayers()
  -- A modal capture owns the raw physical keys and therefore requires the
  -- untouched player baseline, regardless of the configured enabled state.
  if self.bindingCaptureActive or self.rawInputTestActive then
    if self.DeactivateSessionBindings then return self:DeactivateSessionBindings() end
    return true
  end

  local configVisible = self.configFrame and self.configFrame:IsVisible()
  local radialVisible = self.radialFrame and self.radialFrame:IsVisible()

  -- Always establish the requested gameplay state before adding the nested
  -- Settings navigation layer. Checking Settings first left an old gameplay
  -- layer active after a combat-time disable, or omitted gameplay after a
  -- combat-time enable.
  if self.config and self.config.enabled then
    if self.ActivateSessionBindings then
      local activated, reason = self:ActivateSessionBindings()
      if not activated then
        -- A definitive validation/API failure must not leave the requested
        -- state saying ON while no gameplay bindings or HUD are active. A
        -- new combat lock is only deferred and keeps the desired state.
        if activated == false then
          self.config.enabled = false
          if self.SetUIEnabled then self:SetUIEnabled(false) end
        end
        return activated, reason
      end
    end
  elseif self.DeactivateSessionBindings then
    local deactivated, reason = self:DeactivateSessionBindings()
    if not deactivated then return deactivated, reason end
  end

  if (configVisible or radialVisible) and self.ActivateConfigNavigationBindings then
    return self:ActivateConfigNavigationBindings()
  end
  return true
end

function OctoPort:RetryDeferredBindings()
  if not self.bindingMutationDeferred then return true end
  if self:IsBindingMutationLocked() then return nil, "deferred" end

  local operation = self.pendingBindingOperation or "reconcile"
  self.pendingBindingOperation = nil
  self.bindingMutationDeferred = nil
  self.bindingMutationStatus = nil

  if operation == "restore" then
    if not self.RestoreBindings then return false end
    local restored, reason = self:RestoreBindings()
    if not restored then return restored, reason end
    -- Emergency/legacy recovery deliberately leaves gameplay disabled, but a
    -- visible Settings window must remain navigable from the controller.
    return self:ReconcileBindingLayers()
  end
  if operation == "recovery" then
    if not self.RecoverPersistedBindingSnapshot then return false end
    local recovered, reason = self:RecoverPersistedBindingSnapshot()
    if not recovered then return recovered, reason end
  end

  return self:ReconcileBindingLayers()
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

local function IsModifiedChord(key)
  return type(key) == "string" and (
    string.find(key, "^SHIFT%-") or
    string.find(key, "^CTRL%-") or
    string.find(key, "^ALT%-")
  ) and true or false
end

local nativeFaceCommands = {
  A = "ACTIONBUTTON1",
  B = "ACTIONBUTTON2",
  X = "ACTIONBUTTON3",
  Y = "ACTIONBUTTON4",
}

local actionControlOrder = { "A", "B", "X", "Y", "DUP", "DRIGHT", "DDOWN", "DLEFT" }
local movementControlOrder = { "LSUP", "LSDOWN", "LSLEFT", "LSRIGHT" }
local directionControlOrder = { "LSUP", "LSDOWN", "LSLEFT", "LSRIGHT", "DUP", "DDOWN", "DLEFT", "DRIGHT" }
local directionControls = {}
for index = 1, table.getn(directionControlOrder) do
  directionControls[directionControlOrder[index]] = true
end

-- Keep the data-schema version separate from bindingVersion/setupComplete.
-- A partially completed live calibration must survive a reload instead of
-- being mistaken for an old profile and erased by migration again.
local controlSchemaVersion = 12
OctoPort.controlSchemaVersion = controlSchemaVersion

local layeredActionCommands = {
  lt = {
    A = "MULTIACTIONBAR1BUTTON1", B = "MULTIACTIONBAR1BUTTON2",
    X = "MULTIACTIONBAR1BUTTON3", Y = "MULTIACTIONBAR1BUTTON4",
    DUP = "MULTIACTIONBAR1BUTTON5", DRIGHT = "MULTIACTIONBAR1BUTTON6",
    DDOWN = "MULTIACTIONBAR1BUTTON7", DLEFT = "MULTIACTIONBAR1BUTTON8",
  },
  rt = {
    A = "MULTIACTIONBAR2BUTTON1", B = "MULTIACTIONBAR2BUTTON2",
    X = "MULTIACTIONBAR2BUTTON3", Y = "MULTIACTIONBAR2BUTTON4",
    DUP = "MULTIACTIONBAR2BUTTON5", DRIGHT = "MULTIACTIONBAR2BUTTON6",
    DDOWN = "MULTIACTIONBAR2BUTTON7", DLEFT = "MULTIACTIONBAR2BUTTON8",
  },
}

OctoPort.actionControlOrder = actionControlOrder
OctoPort.layeredActionCommands = layeredActionCommands

local function ClearCommand(command)
  local guard = 0
  while guard < 8 do
    local key1, key2 = GetBindingKey(command)
    if not key1 and not key2 then break end
    if key1 and not OctoPort:SetBindingSafely(key1) then return false end
    if key2 and not OctoPort:SetBindingSafely(key2) then return false end
    guard = guard + 1
  end
  local remaining1, remaining2 = GetBindingKey(command)
  return not remaining1 and not remaining2
end

-- SetBinding can evict a command's existing second key when a temporary
-- third key is assigned. Snapshot both commands touched by each mutation and
-- all of their original keys, not only the controller key being replaced.
local function NewBindingSnapshot()
  -- Plain tables only: this object is also stored directly in the per-character
  -- SavedVariables table so /reload can recover without a serializer.
  return { version = 1, keys = {}, commands = {} }
end

local function SnapshotCommand(snapshot, command)
  if not snapshot or not command or command == "" or snapshot.commands[command] then return end
  snapshot.commands[command] = true
  local key1, key2 = GetBindingKey(command)
  if key1 and snapshot.keys[key1] == nil then snapshot.keys[key1] = command end
  if key2 and snapshot.keys[key2] == nil then snapshot.keys[key2] = command end
end

local function SnapshotBindingMutation(snapshot, key, command)
  if not snapshot or not key or key == "" then return false end
  local previousCommand = CurrentBinding(key)
  SnapshotCommand(snapshot, previousCommand)
  if snapshot.keys[key] == nil then snapshot.keys[key] = previousCommand end
  SnapshotCommand(snapshot, command)
  return true
end

local function RestoreBindingSnapshot(snapshot)
  if not snapshot then return true end

  -- Clear current keys from every affected command, including temporary keys
  -- created after the snapshot, then rebuild the exact original key map. A
  -- failed/deferred restore leaves the snapshot with its caller for retry.
  for command in pairs(snapshot.commands) do
    if not ClearCommand(command) then return false end
  end
  for key in pairs(snapshot.keys) do
    if CurrentBinding(key) ~= "" and not OctoPort:SetBindingSafely(key) then return false end
  end
  for key, command in pairs(snapshot.keys) do
    if command ~= "" then
      if not OctoPort:SetBindingSafely(key, command) then return false end
      if CurrentBinding(key) ~= command then return false end
    end
  end
  for key, command in pairs(snapshot.keys) do
    if command == "" and CurrentBinding(key) ~= "" then return false end
  end
  return true
end

local function IsValidBindingSnapshot(snapshot)
  if type(snapshot) ~= "table" or snapshot.version ~= 1 or type(snapshot.keys) ~= "table" or type(snapshot.commands) ~= "table" then
    return false
  end
  for key, command in pairs(snapshot.keys) do
    if type(key) ~= "string" or key == "" or type(command) ~= "string" then return false end
    if command ~= "" and snapshot.commands[command] ~= true then return false end
  end
  for command, captured in pairs(snapshot.commands) do
    if type(command) ~= "string" or command == "" or captured ~= true then return false end
  end
  return true
end

-- Build one persisted baseline across every nested temporary layer. The
-- session and Settings layers still keep their own in-memory snapshots so
-- Settings can return to gameplay, while this table always points all the way
-- back to the player's pre-addon bindings after an interrupted /reload.
function OctoPort:EnsureBindingRecoverySnapshot()
  if not self.config then return nil end
  local snapshot = self.config.bindingRecoverySnapshot
  if snapshot == nil then
    snapshot = NewBindingSnapshot()
    self.config.bindingRecoverySnapshot = snapshot
  elseif not IsValidBindingSnapshot(snapshot) then
    self.config.lastBindingRecoveryError = "Saved binding recovery data is invalid; temporary bindings were not changed."
    return nil
  end
  return snapshot
end

function OctoPort:SnapshotTemporaryBinding(layerSnapshot, key, command)
  local recoverySnapshot = self:EnsureBindingRecoverySnapshot()
  if not recoverySnapshot then return false end
  -- Persist the baseline first. If the UI reloads after SetBinding below, WoW
  -- writes this already-populated table to SavedVariables on shutdown.
  SnapshotBindingMutation(recoverySnapshot, key, command)
  SnapshotBindingMutation(layerSnapshot, key, command)
  return true
end

function OctoPort:RecoverPersistedBindingSnapshot()
  if not self.config then return false end
  local snapshot = self.config.bindingRecoverySnapshot
  if snapshot == nil then
    self.bindingRecoveryPending = nil
    return true
  end
  if not IsValidBindingSnapshot(snapshot) then
    self.config.enabled = false
    self.bindingRecoveryPending = true
    self.config.lastBindingRecoveryError = "Saved binding recovery data is invalid."
    return false
  end
  if self:IsBindingMutationLocked() then
    self.config.enabled = false
    self.bindingRecoveryPending = true
    return self:DeferBindingOperation("recovery", "Temporary controller bindings will be recovered when combat ends.")
  end

  self.bindingMutationOperation = "recovery"
  local restored = RestoreBindingSnapshot(snapshot)
  self.bindingMutationOperation = nil
  if not restored then
    self.config.enabled = false
    self.bindingRecoveryPending = true
    self.config.lastBindingRecoveryError = "Temporary controller bindings could not be restored exactly."
    if self.bindingMutationDeferred then return nil, "deferred" end
    return false
  end

  -- Clear durable recovery data only after every affected key and command has
  -- been restored and verified by RestoreBindingSnapshot.
  self.config.bindingRecoverySnapshot = nil
  self.config.lastBindingRecoveryError = nil
  self.bindingRecoveryPending = nil
  self.sessionBindingBackup = nil
  self.configNavigationBindingBackup = nil
  self.sessionBindingsActive = false
  self.configNavigationBindingsActive = false
  return true
end

function OctoPort:GetBindingDefinition(value)
  return FindDefinition(value)
end

function OctoPort:EnsureMovementDefaults()
  if not self.config then return end
  self.config.controllerKeys = self.config.controllerKeys or {}
  local profileVersion = tonumber(self.config.movementBindingVersion) or 0
  if profileVersion >= 3 then return end

  local assigned = {}
  for id, key in pairs(self.config.controllerKeys) do
    if key and key ~= "" then assigned[key] = id end
  end

  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    local addDefault = profileVersion < 1 and definition.movement
    if profileVersion < 3 and (definition.id == "LB" or definition.id == "RB" or definition.id == "L3" or definition.id == "R3") then
      addDefault = true
    end
    if addDefault and not self.config.controllerKeys[definition.id] and not assigned[definition.defaultKey] then
      self.config.controllerKeys[definition.id] = definition.defaultKey
      assigned[definition.defaultKey] = definition.id
    end
  end

  self.config.movementBindingVersion = 3
end

function OctoPort:EnsureDirectControlDefaults()
  if not self.config then return false end
  if (tonumber(self.config.controlSchemaVersion) or 0) >= controlSchemaVersion then return false end

  self.config.controllerKeys = self.config.controllerKeys or {}
  local keys = self.config.controllerKeys
  local sharedArrows = self.config.arrowMovementFallback and true or false

  -- Versions 0.7.1/0.7.2 could put both physical controls behind the same
  -- arrow signals. Version 0.8 deliberately requires separate device output:
  -- W/A/S/D for the stick and arrows for the D-pad.
  local seenDirections = {}
  local directionsAreDistinct = true
  for index = 1, table.getn(directionControlOrder) do
    local id = directionControlOrder[index]
    local key = keys[id]
    if not key or seenDirections[key] then directionsAreDistinct = false end
    if key then seenDirections[key] = id end
  end
  if sharedArrows or not directionsAreDistinct then
    keys.LSUP, keys.LSDOWN = "W", "S"
    keys.LSLEFT, keys.LSRIGHT = "A", "D"
    keys.DUP, keys.DDOWN = "UP", "DOWN"
    keys.DLEFT, keys.DRIGHT = "LEFT", "RIGHT"
  end

  local oldFaceDefaults = { A = "F9", B = "F10", X = "F11", Y = "F12" }
  local directFaceDefaults = { A = "1", B = "2", X = "3", Y = "4" }
  for id, key in pairs(directFaceDefaults) do
    if not keys[id] or keys[id] == oldFaceDefaults[id] then keys[id] = key end
  end

  -- Migrate the old RB/RT mouse layout to the new two-trigger action model.
  -- The two real mouse clicks move to LB/RB; LT/RT become native modifiers.
  local oldLeftClick = keys.LB or keys.RB
  local oldRightClick = keys.RT
  keys.LB = oldLeftClick or "BUTTON1"
  keys.RB = oldRightClick or "BUTTON2"
  if keys.LB == keys.RB then keys.LB, keys.RB = "BUTTON1", "BUTTON2" end
  keys.LT = nil
  keys.RT = nil
  self.config.nativeModifiers = { SHIFT = "lt", CTRL = "rt" }

  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.defaultKey and not definition.layer and not keys[definition.id] then
      keys[definition.id] = definition.defaultKey
    end
  end

  self.config.arrowMovementFallback = false
  self.config.arrowInputMode = nil
  self.config.menuOnlyMode = false
  self.config.nativeFaceButtons = true
  self.config.reticleEnabled = false
  self.config.lastBindingCollision = nil
  self.config.directionVerifiedKeys = {}
  self.config.controlSchemaVersion = controlSchemaVersion
  self.config.setupComplete = false
  self.config.bindingVersion = 0
  return true
end

function OctoPort:IsDirectionControl(value)
  local definition = type(value) == "table" and value or FindDefinition(value)
  return definition and directionControls[definition.id] and true or false
end

function OctoPort:ResetDirectionVerification()
  if not self.config then return end
  self.config.directionVerifiedKeys = {}
  self.config.setupComplete = false
  self.config.bindingVersion = 0
end

function OctoPort:ClearDirectionVerification(value)
  if not self.config then return end
  local definition = type(value) == "table" and value or FindDefinition(value)
  if not definition or not directionControls[definition.id] then return end
  self.config.directionVerifiedKeys = self.config.directionVerifiedKeys or {}
  self.config.directionVerifiedKeys[definition.id] = nil
  self.config.setupComplete = false
  self.config.bindingVersion = 0
end

-- Only the capture layer should call this after seeing the physical input.
-- Storing the exact key makes changing a logical mapping automatically revoke
-- its previous live verification.
function OctoPort:MarkDirectionVerified(value, capturedKey)
  if not self.config then return false end
  local definition = type(value) == "table" and value or FindDefinition(value)
  if not definition or not directionControls[definition.id] then return false end
  local configuredKey = self.config.controllerKeys and self.config.controllerKeys[definition.id]
  if not configuredKey or configuredKey == "" or capturedKey ~= configuredKey then return false end
  self.config.directionVerifiedKeys = self.config.directionVerifiedKeys or {}
  self.config.directionVerifiedKeys[definition.id] = capturedKey
  if self.RefreshSetupState then self:RefreshSetupState() end
  return true
end

function OctoPort:IsDirectionVerified(value)
  if not self.config then return false end
  local definition = type(value) == "table" and value or FindDefinition(value)
  if not definition or not directionControls[definition.id] then return false end
  local configuredKey = self.config.controllerKeys and self.config.controllerKeys[definition.id]
  local verifiedKey = self.config.directionVerifiedKeys and self.config.directionVerifiedKeys[definition.id]
  return configuredKey and configuredKey ~= "" and verifiedKey == configuredKey and true or false
end

function OctoPort:ValidateDirectionalInputs()
  if not self.config or not self.config.controllerKeys then
    return false, "Controller keys are not configured."
  end

  local seen = {}
  for index = 1, table.getn(directionControlOrder) do
    local id = directionControlOrder[index]
    local definition = FindDefinition(id)
    local key = self.config.controllerKeys[id]
    if not key or key == "" then
      return false, (definition and definition.label or id) .. " is not configured."
    end
    if IsModifiedChord(key) then
      return false, (definition and definition.label or id) .. " must emit one unmodified key."
    end
    if seen[key] then
      local previous = FindDefinition(seen[key])
      return false, key .. " is shared by " .. (previous and previous.label or seen[key]) .. " and " .. (definition and definition.label or id) .. "."
    end
    seen[key] = id
  end

  for index = 1, table.getn(directionControlOrder) do
    local id = directionControlOrder[index]
    local definition = FindDefinition(id)
    if not self:IsDirectionVerified(id) then
      return false, (definition and definition.label or id) .. " has not been verified by live capture."
    end
  end
  return true
end

function OctoPort:ValidateRequiredInputs()
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.required and not self:GetControllerBindingKey(definition) then
      return false, definition.label .. " is not configured."
    end
    local key = self.config.controllerKeys and self.config.controllerKeys[definition.id]
    if nativeFaceCommands[definition.id] and IsModifiedChord(key) then
      return false, definition.label .. " must emit one unmodified key so LT/RT layers remain distinct."
    end
  end
  return self:ValidateDirectionalInputs()
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
  local complete, setupError = self:ValidateRequiredInputs()
  local directionsValid, directionError = self:ValidateDirectionalInputs()
  self.config.lastDirectionalError = directionsValid and nil or directionError
  self.config.lastSetupError = complete and nil or setupError
  self.config.setupComplete = complete
  self.config.bindingVersion = complete and controlSchemaVersion or 0
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
  return complete
end

function OctoPort:BindControllerKey(definition, key)
  if type(definition) ~= "table" then definition = FindDefinition(definition) end
  if not definition or not key or key == "" or key == "UNKNOWN" then return false end
  if not self.config then self:InitializeConfig() end

  self.config.controllerKeys = self.config.controllerKeys or {}
  self.config.nativeModifiers = self.config.nativeModifiers or {}
  self.config.directionVerifiedKeys = self.config.directionVerifiedKeys or {}
  if not definition.layer and (directionControls[definition.id] or nativeFaceCommands[definition.id]) and IsModifiedChord(key) then
    self:Print(definition.label .. " must emit one unmodified key so movement and LT/RT layers stay separate.")
    return false
  end
  if definition.layer and not IsModifier(key) then
    self:Print(definition.label .. " must emit SHIFT, CTRL or ALT. This keeps all 20 combat actions native and safe.")
    return false
  end
  if not definition.layer and IsModifier(key) and self.config.nativeModifiers[key] then
    self:Print(key .. " is already used by an action layer. Choose a different signal for " .. definition.label .. ".")
    return false
  end
  -- One physical key may own only one controller action. Keep a visible
  -- record when a new capture displaced an older control; this is the most
  -- common sign that Armoury Crate sends arrows for both the stick and D-pad.
  local displaced = nil
  for id, configuredKey in pairs(self.config.controllerKeys) do
    if configuredKey == key and id ~= definition.id then
      self.config.controllerKeys[id] = nil
      if directionControls[id] then self.config.directionVerifiedKeys[id] = nil end
      displaced = id
    end
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
    local previousKey = self.config.controllerKeys[definition.id]
    self.config.controllerKeys[definition.id] = key
    if directionControls[definition.id] and previousKey ~= key then
      self.config.directionVerifiedKeys[definition.id] = nil
    end
  end

  if displaced then
    self.config.lastBindingCollision = {
      key = key,
      previous = displaced,
      current = definition.id,
    }
    local previousDefinition = FindDefinition(displaced)
    self:Print("Input collision: " .. key .. " was used by " .. (previousDefinition and previousDefinition.label or displaced) .. ". Give the stick and D-pad different keys in Armoury Crate.")
  elseif self.config.lastBindingCollision then
    local collision = self.config.lastBindingCollision
    local previousKey = self.config.controllerKeys[collision.previous]
    local currentKey = self.config.controllerKeys[collision.current]
    if previousKey and currentKey and previousKey ~= currentKey then
      self.config.lastBindingCollision = nil
    end
  end

  self:RefreshSetupState()
  -- Never reinstall gameplay bindings while the capture overlay is listening.
  -- Doing so after the first wizard step made later buttons execute actions
  -- instead of being captured. StopBindingCapture owns the eventual restore.
  if self.config.enabled and not self.bindingCaptureActive then
    self:ActivateSessionBindings()
  end
  return true
end

function OctoPort:ApplyRecommendedBindings()
  if not self.config then self:InitializeConfig() end
  if self:IsBindingMutationLocked() then
    return self:DeferBindingOperation("reconcile", "Vychozi profil lze pouzit po boji; aktivni bindy zustaly beze zmeny.")
  end
  if self.sessionBindingsActive or self.configNavigationBindingsActive then
    if not self:DeactivateSessionBindings() then return false end
  end
  -- A newly selected preset is intentionally OFF until all eight physical
  -- directions have been observed by the capture overlay.
  self.config.enabled = false
  self.config.controllerKeys = {}
  self.config.nativeModifiers = { SHIFT = "lt", CTRL = "rt" }

  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.defaultKey and not definition.layer then
      self.config.controllerKeys[definition.id] = definition.defaultKey
    end
  end

  self.config.movementBindingVersion = 3
  self.config.controlSchemaVersion = controlSchemaVersion
  self.config.bindingVersion = 0
  self.config.lastBindingCollision = nil
  self.config.arrowMovementFallback = false
  self.config.menuOnlyMode = false
  self.config.nativeFaceButtons = true
  self.config.reticleEnabled = false
  -- A preset describes the expected Armoury Crate output; it is not proof of
  -- what this device actually emitted. The eight directions must be captured.
  self:ResetDirectionVerification()
  self:RefreshSetupState()
  if self.configFrame and self.configFrame:IsVisible() then self:ActivateConfigNavigationBindings() end
  if self.SetUIEnabled then self:SetUIEnabled(false) end
  self:Print("Universal profile selected. Calibrate all eight stick/D-pad directions before enabling it; bindings stay session-only.")
end

function OctoPort:ApplyNativeFaceButtons()
  if not self.config then self:InitializeConfig() end
  if self:IsBindingMutationLocked() then
    return self:DeferBindingOperation("reconcile", "Mapovani ABXY lze zmenit po boji; aktivni bindy zustaly beze zmeny.")
  end
  local wasEnabled = self.config.enabled and true or false
  if self.sessionBindingsActive and not self:DeactivateSessionBindings() then return false end
  self.config.enabled = false
  self.config.controllerKeys = self.config.controllerKeys or {}
  self.config.controllerKeys.A = self.config.controllerKeys.A or "1"
  self.config.controllerKeys.B = self.config.controllerKeys.B or "2"
  self.config.controllerKeys.X = self.config.controllerKeys.X or "3"
  self.config.controllerKeys.Y = self.config.controllerKeys.Y or "4"
  self.config.nativeFaceButtons = true
  self.config.enabled = wasEnabled
  self:RefreshSetupState()
  if wasEnabled then self:ActivateSessionBindings() end
  self:Print("ABXY now use native Blizzard action slots 1-4 through the captured physical buttons.")
end

function OctoPort:SetQuickMenuKey(key)
  if not key or key == "" or key == "UNKNOWN" then return false end
  if not self.config then self:InitializeConfig() end
  if self:IsBindingMutationLocked() then
    return self:DeferBindingOperation("reconcile", "Tlacitko menu lze zmenit po boji; aktivni bindy zustaly beze zmeny.")
  end

  local wasEnabled = self.config.enabled and true or false
  local wasMenuOnly = self.config.menuOnlyMode and true or false
  if self.sessionBindingsActive and not self:DeactivateSessionBindings() then return false end
  self.config.enabled = false
  self:BindControllerKey("VIEW", key)
  self.config.lastBindingCollision = nil
  self.config.menuOnlyMode = (not wasEnabled) or wasMenuOnly
  self.config.enabled = true
  if not self:ActivateSessionBindings() then
    self.config.enabled = false
    if self.SetUIEnabled then self:SetUIEnabled(false) end
    return false
  end
  if self.SetUIEnabled then self:SetUIEnabled(true) end
  self:Print(key .. " now opens WOW Controller. The binding is session-only and will be restored on logout or disable.")
  return true
end

function OctoPort:DeactivateSessionBindings()
  if self:IsBindingMutationLocked() then return self:DeferBindingOperation("reconcile") end
  -- Navigation is a nested temporary layer. Restore it first so the session
  -- backup below sees and restores the actual gameplay bindings.
  if self.DeactivateConfigNavigationBindings then
    if not self:DeactivateConfigNavigationBindings() then return false end
  end
  if not self.sessionBindingBackup then
    self.sessionBindingsActive = false
    -- A previous UI instance may have been interrupted by /reload before its
    -- in-memory layer snapshots could be restored.
    if self.config and self.config.bindingRecoverySnapshot then
      return self:RecoverPersistedBindingSnapshot()
    end
    return true
  end

  if self.config and self.config.bindingRecoverySnapshot then
    local recovered, reason = self:RecoverPersistedBindingSnapshot()
    if not recovered then return recovered, reason end
  elseif not RestoreBindingSnapshot(self.sessionBindingBackup) then
    return false
  end

  self.sessionBindingBackup = nil
  self.sessionBindingsActive = false
  return true
end

function OctoPort:ApplyTemporaryBinding(key, command)
  if not key or key == "" then return false end
  if not self:SnapshotTemporaryBinding(self.sessionBindingBackup, key, command) then return false end
  if not self:SetBindingSafely(key, command) then return false end
  return CurrentBinding(key) == (command or "")
end

function OctoPort:GetLayerModifier(layerName)
  for modifier, layer in pairs(self.config.nativeModifiers or {}) do
    if layer == layerName then return modifier end
  end
  return nil
end

function OctoPort:ActivateSessionBindings()
  if not self.config or not self.config.enabled then return false end
  if self:IsBindingMutationLocked() then return self:DeferBindingOperation("reconcile") end
  if not self:DeactivateSessionBindings() then return false end
  self.sessionBindingBackup = NewBindingSnapshot()

  if not self.config.menuOnlyMode then
    local setupValid, setupError = self:ValidateRequiredInputs()
    if not setupValid then
      local directionsValid, directionError = self:ValidateDirectionalInputs()
      self.config.lastDirectionalError = directionsValid and nil or directionError
      self.config.lastSetupError = setupError
      self:Print("Controller not enabled: " .. setupError .. " Calibrate the physical inputs in Setup.")
      self.sessionBindingBackup = nil
      return false
    end
    self.config.lastDirectionalError = nil
    self.config.lastSetupError = nil
  end

  local applied = 0
  local failedBinding = nil
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    local key = self.config.controllerKeys and self.config.controllerKeys[definition.id]
    local command = definition.command
    local allowedByMode = not self.config.menuOnlyMode or definition.id == "VIEW"
    if definition.nativeTarget then command = definition.nativeTarget end
    if definition.id == "M1" or definition.id == "M2" then
      local rearAction = self.config.rearActions and self.config.rearActions[definition.id]
      command = rearNativeCommands[rearAction] or command
    end
    if self.config.nativeFaceButtons and nativeFaceCommands[definition.id] then
      command = nativeFaceCommands[definition.id]
    end
    if allowedByMode and key and key ~= "" and command and not definition.passthrough then
      if self:ApplyTemporaryBinding(key, command) then
        applied = applied + 1
      elseif definition.required or self.config.menuOnlyMode then
        failedBinding = key .. " -> " .. command
        break
      end
    end
  end

  -- LT/RT action layers use Blizzard's native multi-action-bar commands. No
  -- UseAction call is involved, so combat cannot taint or block the action.
  if not self.config.menuOnlyMode and not failedBinding then
    for layerName, commands in pairs(layeredActionCommands) do
      local modifier = self:GetLayerModifier(layerName)
      if modifier then
        for index = 1, table.getn(actionControlOrder) do
          local id = actionControlOrder[index]
          local key = self.config.controllerKeys[id]
          if key then
            local chord = modifier .. "-" .. key
            if self:ApplyTemporaryBinding(chord, commands[id]) then
              applied = applied + 1
            else
              failedBinding = chord .. " -> " .. commands[id]
              break
            end
          end
        end
        if failedBinding then break end
        -- Clear modifier+movement chords so they fall through to the native
        -- W/A/S/D binding while LT/RT is held. Never bind all three variants
        -- to MOVEFORWARD/etc: Vanilla keeps at most two keys per command and
        -- the third assignment can evict the base movement key. The original
        -- modified chords are included in the exact session snapshot.
        for index = 1, table.getn(movementControlOrder) do
          local id = movementControlOrder[index]
          local key = self.config.controllerKeys[id]
          if key then
            local chord = modifier .. "-" .. key
            if self:ApplyTemporaryBinding(chord, nil) then
              applied = applied + 1
            else
              failedBinding = chord .. " -> UNBOUND"
              break
            end
          end
        end
        if failedBinding then break end
      end
    end
  end

  if failedBinding then
    self.config.lastSetupError = "WoW rejected binding " .. failedBinding .. "."
    self:Print(self.config.lastSetupError)
    self:DeactivateSessionBindings()
    return false
  end

  self.sessionBindingsActive = applied > 0
  if not self.sessionBindingsActive then
    self:DeactivateSessionBindings()
    return false
  end
  return true
end

function OctoPort:ActivateConfigNavigationBindings()
  if not self.config then return false end
  if self:IsBindingMutationLocked() then return self:DeferBindingOperation("reconcile") end
  if not self:DeactivateConfigNavigationBindings() then return false end
  self.configNavigationBindingBackup = NewBindingSnapshot()
  self.config.lastConfigBindingError = nil
  local commands = {
    A = "OCTOPORT_ACTION_A",
    B = "OCTOPORT_ACTION_B",
    X = "OCTOPORT_ACTION_X",
    Y = "OCTOPORT_ACTION_Y",
    DUP = "OCTOPORT_TARGET_UP",
    DDOWN = "OCTOPORT_TARGET_DOWN",
    DLEFT = "OCTOPORT_TARGET_LEFT",
    DRIGHT = "OCTOPORT_TARGET_RIGHT",
  }
  local applied = 0
  local function ApplyNavigationKey(key, command)
    if not key or key == "" then return false end
    if not self:SnapshotTemporaryBinding(self.configNavigationBindingBackup, key, command) then
      self.config.lastConfigBindingError = "Binding recovery snapshot could not be prepared."
      return false
    end
    local setOK = self:SetBindingSafely(key, command)
    local expected = command or ""
    if setOK and CurrentBinding(key) == expected then
      applied = applied + 1
      return true
    else
      self.config.lastConfigBindingError = key .. " -> " .. (command or "UNBOUND")
      return false
    end
  end
  local order = { "A", "B", "X", "Y", "DUP", "DDOWN", "DLEFT", "DRIGHT" }
  for index = 1, table.getn(order) do
    local id = order[index]
    local command = commands[id]
    local key = self.config.controllerKeys and self.config.controllerKeys[id]
    if key and key ~= "" then
      if not ApplyNavigationKey(key, command) then break end
      -- A held LT/RT must not leak a combat action through the gameplay chord
      -- while Settings or the radial editor owns controller navigation. Clear
      -- the chords instead of adding a third key to one Vanilla command.
      for modifier in pairs(self.config.nativeModifiers or {}) do
        if not ApplyNavigationKey(modifier .. "-" .. key, nil) then break end
      end
      if self.config.lastConfigBindingError then break end
    end
  end
  if self.config.lastConfigBindingError then
    self:DeactivateConfigNavigationBindings()
    return false
  end
  self.configNavigationBindingsActive = applied > 0
  if not self.configNavigationBindingsActive then
    self:DeactivateConfigNavigationBindings()
  end
  return self.configNavigationBindingsActive
end

function OctoPort:DeactivateConfigNavigationBindings()
  if self:IsBindingMutationLocked() then return self:DeferBindingOperation("reconcile") end
  local backup = self.configNavigationBindingBackup
  if not backup then
    self.configNavigationBindingsActive = false
    if not self.sessionBindingBackup and self.config and self.config.bindingRecoverySnapshot then
      return self:RecoverPersistedBindingSnapshot()
    end
    return true
  end
  if not RestoreBindingSnapshot(backup) then return false end
  self.configNavigationBindingBackup = nil
  self.configNavigationBindingsActive = false
  -- Without a gameplay session this was the outermost temporary layer, so its
  -- successful close must also retire the durable crash-recovery baseline.
  if not self.sessionBindingBackup and self.config and self.config.bindingRecoverySnapshot then
    local recovered, reason = self:RecoverPersistedBindingSnapshot()
    if not recovered then return recovered, reason end
  end
  return true
end

local function CaptureLegacyControllerKeys(config)
  config.controllerKeys = config.controllerKeys or {}
  for index = 1, table.getn(bindingDefinitions) do
    local definition = bindingDefinitions[index]
    if definition.command then
      local key = GetBindingKey(definition.command)
      if key and not config.controllerKeys[definition.id] and not IsModifier(key) then
        config.controllerKeys[definition.id] = key
      end
    end
  end
end

function OctoPort:RecoverLegacyBindings(force)
  if not self.config then return false end
  if not force and not self.needsSafetyMigration then return false end
  if self:IsBindingMutationLocked() then
    return self:DeferBindingOperation("restore", "Nouzova obnova bindu probehne automaticky po boji.")
  end

  CaptureLegacyControllerKeys(self.config)

  -- Migration is the only persistent binding write. Snapshot every affected
  -- command/key before touching the live set so a rejected write can be rolled
  -- back instead of leaving a half-migrated profile in memory.
  local migrationSnapshot = NewBindingSnapshot()
  for index = 1, table.getn(legacyCommands) do
    SnapshotCommand(migrationSnapshot, legacyCommands[index])
  end
  if self.config.bindingBackup then
    for key, command in pairs(self.config.bindingBackup) do
      SnapshotBindingMutation(migrationSnapshot, key, command)
    end
  end

  local function AbortMigration()
    RestoreBindingSnapshot(migrationSnapshot)
    return false
  end

  -- First remove every custom command, including movement commands deleted in
  -- 0.5.0. Then restore exact pre-addon actions captured by old releases.
  for index = 1, table.getn(legacyCommands) do
    if not ClearCommand(legacyCommands[index]) then return AbortMigration() end
  end
  if self.config.bindingBackup then
    for key, command in pairs(self.config.bindingBackup) do
      if not self:SetBindingSafely(key, command ~= "" and command or nil) then return AbortMigration() end
    end
  end

  -- This is the only persistent binding write: it repairs damage created by
  -- versions that used SaveBindings during setup.
  if not self:SaveBindingsSafely(GetCurrentBindingSet()) then return AbortMigration() end
  self.config.bindingBackup = nil
  self.config.safetyVersion = 1
  self.config.bindingVersion = 0
  self.config.controlSchemaVersion = 0
  self.config.directionVerifiedKeys = {}
  self.config.setupComplete = false
  self.config.enabled = false
  self.needsSafetyMigration = false
  return true
end

function OctoPort:RestoreBindings()
  if self:IsBindingMutationLocked() then
    self.config.enabled = false
    if self.SetUIEnabled then self:SetUIEnabled(false) end
    return self:DeferBindingOperation("restore", "Nouzova obnova bindu probehne automaticky po boji.")
  end
  self.config.enabled = false
  self.config.menuOnlyMode = false
  self.config.arrowMovementFallback = false
  self.config.nativeFaceButtons = true
  if not self:DeactivateSessionBindings() then return false end
  if not self:RecoverLegacyBindings(true) then return false end
  if self.SetUIEnabled then self:SetUIEnabled(false) end
  self:Print("Emergency cleanup complete. Saved OCTOPORT bindings were removed and the addon is OFF.")
  if self.RefreshBindingMenu then self:RefreshBindingMenu() end
  return true
end

function OctoPort:SignalInput(id, state)
  self.lastControllerInput = id
  self.lastControllerInputState = state or "press"
  self.lastControllerInputAt = GetTime()
  if self.UpdateInputDiagnostics then self:UpdateInputDiagnostics() end
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
  if self.config.enabled and self.ActivateSessionBindings then self:ActivateSessionBindings() end
  if self.configFrame and self.configFrame:IsVisible() then self:ActivateConfigNavigationBindings() end
end

function OctoPort:HandleRearAction(button, keystate)
  if not self.config or not self.config.enabled then return end
  local action = self.config.rearActions and self.config.rearActions[button]
  if not action then action = button == "M1" and "settings" or "interact" end

  if rearNativeCommands[action] then
    -- Native rear actions are bound directly in ActivateSessionBindings and
    -- never reach this Lua handler. Keep this guard for old cached bindings.
    return
  elseif action == "radial" then
    if self.HandleRadialKey then self:HandleRadialKey(keystate) end
    return
  elseif keystate ~= "down" then
    return
  end

  if action == "settings" then
    if self.ToggleConfig then self:ToggleConfig() end
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
  if not OctoPort or not OctoPort.config then return end
  if OctoPort.bindingCaptureActive then return end
  -- Setup is a recovery surface and must remain controllable even when the
  -- gameplay profile is OFF or invalid.
  if OctoPort.HandleConfigAction and OctoPort:HandleConfigAction(slot, keystate) then return end
  -- The radial editor uses the same temporary ABXY navigation layer as Setup.
  -- It must remain operable while gameplay bindings are deliberately OFF.
  local radialVisible = OctoPort.radialFrame and OctoPort.radialFrame:IsVisible()
  if radialVisible then
    if OctoPort.HandleControllerAction then OctoPort:HandleControllerAction(slot, keystate) end
    return
  end
  if not OctoPort.config.enabled then return end
  if OctoPort.HandleControllerAction then OctoPort:HandleControllerAction(slot, keystate) end
end

function OctoPort_RadialKey(keystate)
  if OctoPort then OctoPort:SignalInput("MENU", keystate) end
  if OctoPort and OctoPort.config and OctoPort.config.enabled and not OctoPort.bindingCaptureActive and OctoPort.HandleRadialKey then
    OctoPort:HandleRadialKey(keystate)
  end
end

function OctoPort_Target(direction, keystate)
  -- These addon commands exist only while Settings or the radial owns a
  -- temporary navigation layer. Gameplay targeting is bound directly to
  -- Blizzard's native TARGET* commands, never invoked from Lua.
  if keystate and keystate ~= "down" then return end
  local ids = { up = "DUP", down = "DDOWN", left = "DLEFT", right = "DRIGHT" }
  if OctoPort then OctoPort:SignalInput(ids[direction]) end
  if not OctoPort or not OctoPort.config or OctoPort.bindingCaptureActive then return end

  if OctoPort.HandleConfigDirection and OctoPort:HandleConfigDirection(direction) then return end
  -- Like Setup, a visible radial is a recovery surface and stays navigable
  -- while the gameplay profile is disabled or still invalid.
  if OctoPort.HandleRadialDirection and OctoPort:HandleRadialDirection(direction) then return end
end

function OctoPort_LayerKey(layer, keystate)
  if not OctoPort or not OctoPort.config or not OctoPort.config.enabled then return end
  OctoPort.controllerLayerState = OctoPort.controllerLayerState or {}
  OctoPort.controllerLayerState[layer] = keystate == "down" and true or false
  OctoPort:SignalInput(layer == "lt" and "LT" or "RT", keystate)
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
