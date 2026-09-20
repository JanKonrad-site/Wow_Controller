-- Console-style controller setup, bindings, options and live diagnostics.

local tabNames = { "SETUP", "OVLADANI", "HRANI", "DIAGNOSTIKA" }

local function MakeLabel(parent, template, text, width)
  local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  label:SetText(text or "")
  if width then label:SetWidth(width) end
  return label
end

local function MakeButton(parent, text, width, handler)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetWidth(width or 140)
  button:SetHeight(24)
  button:SetText(text)
  if handler then button:SetScript("OnClick", handler) end
  return button
end

local function MakePanel(parent)
  local panel = CreateFrame("Frame", nil, parent)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 158, -66)
  panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -24, 48)
  panel:Hide()
  panel.focusables = {}
  return panel
end

local function AddFocusable(panel, button)
  table.insert(panel.focusables, button)
  button.octoFocusPanel = panel
  return button
end

local function SetToggleText(button, label, enabled)
  button:SetText(label .. ": " .. (enabled and "ON" or "OFF"))
end

local function NormalizeMouseButton(button)
  if button == "LeftButton" then return "BUTTON1" end
  if button == "RightButton" then return "BUTTON2" end
  if button == "MiddleButton" then return "BUTTON3" end
  if button == "Button4" then return "BUTTON4" end
  if button == "Button5" then return "BUTTON5" end
  return button
end

local function ComposeKey(raw)
  if not raw or raw == "" then return nil end
  raw = NormalizeMouseButton(raw)
  if raw == "LSHIFT" or raw == "RSHIFT" then raw = "SHIFT" end
  if raw == "LCTRL" or raw == "RCTRL" then raw = "CTRL" end
  if raw == "LALT" or raw == "RALT" then raw = "ALT" end
  if raw == "SHIFT" or raw == "CTRL" or raw == "ALT" then return raw end

  local key = raw
  if IsShiftKeyDown and IsShiftKeyDown() then key = "SHIFT-" .. key end
  if IsControlKeyDown and IsControlKeyDown() then key = "CTRL-" .. key end
  if IsAltKeyDown and IsAltKeyDown() then key = "ALT-" .. key end
  return key
end

local directionCaptureIds = {
  LSUP = true, LSDOWN = true, LSLEFT = true, LSRIGHT = true,
  DUP = true, DDOWN = true, DLEFT = true, DRIGHT = true,
}

local function CopyMap(source)
  local result = {}
  for key, value in pairs(source or {}) do result[key] = value end
  return result
end

local function IsModifierKey(key)
  return key == "SHIFT" or key == "CTRL" or key == "ALT"
end

local function NormalizeReleasedKey(raw)
  if not raw or raw == "" then return nil end
  raw = NormalizeMouseButton(raw)
  if raw == "LSHIFT" or raw == "RSHIFT" then return "SHIFT" end
  if raw == "LCTRL" or raw == "RCTRL" then return "CTRL" end
  if raw == "LALT" or raw == "RALT" then return "ALT" end
  return raw
end

function OctoPort:RestoreGameplayAfterModal()
  if not self.config or not self.config.enabled or not self.ActivateSessionBindings then return true end
  local activated, reason = self:ActivateSessionBindings()
  if activated then return true end
  if reason == "deferred" or self.bindingMutationDeferred then return nil, "deferred" end
  self.config.enabled = false
  if self.SetUIEnabled then self:SetUIEnabled(false) end
  self:Print("Controller zustal vypnuty: dokoncete zivou kalibraci vstupu v Setupu.")
  return false
end

function OctoPort:SetConfigFocus(index)
  if not self.configPanel then return end
  local focusables = self.configPanel.focusables or {}
  local count = table.getn(focusables)
  if count == 0 then return end

  if index < 1 then index = count end
  if index > count then index = 1 end
  if self.configFocusButton then self.configFocusButton:UnlockHighlight() end
  self.configFocusIndex = index
  self.configFocusButton = focusables[index]
  self.configFocusButton:LockHighlight()
end

function OctoPort:ShowConfigTab(index, forceOpen)
  self:CreateConfigMenu()
  if index < 1 then index = table.getn(tabNames) end
  if index > table.getn(tabNames) then index = 1 end

  for tabIndex = 1, table.getn(self.configPanels) do
    if tabIndex == index then
      self.configPanels[tabIndex]:Show()
      self.configTabs[tabIndex]:LockHighlight()
    else
      self.configPanels[tabIndex]:Hide()
      self.configTabs[tabIndex]:UnlockHighlight()
    end
  end

  self.config.selectedConfigTab = index
  self.configPanel = self.configPanels[index]
  self.configFocusButton = nil
  self.configFocusIndex = 1
  self:SetConfigFocus(1)
  self:RefreshBindingMenu()
  self:UpdateInputDiagnostics()
  if forceOpen then self.configFrame:Show() end
  if self.configFrame:IsVisible() and self.ActivateConfigNavigationBindings then
    self:ActivateConfigNavigationBindings()
  end
end

function OctoPort:ToggleConfig(forceOpen)
  self:CreateConfigMenu()
  if forceOpen or not self.configFrame:IsVisible() then
    self:ShowConfigTab(self.config.selectedConfigTab or 1, true)
  else
    self.configFrame:Hide()
  end
end

function OctoPort:ToggleHelp(forceOpen)
  self:ToggleConfig(forceOpen)
end

function OctoPort:HandleConfigDirection(direction)
  if not self.configFrame or not self.configFrame:IsVisible() then return false end
  if direction == "left" then
    self:ShowConfigTab((self.config.selectedConfigTab or 1) - 1, true)
  elseif direction == "right" then
    self:ShowConfigTab((self.config.selectedConfigTab or 1) + 1, true)
  elseif direction == "up" then
    self:SetConfigFocus((self.configFocusIndex or 1) - 1)
  elseif direction == "down" then
    self:SetConfigFocus((self.configFocusIndex or 1) + 1)
  end
  return true
end

function OctoPort:HandleConfigAction(slot, keystate)
  if not self.configFrame or not self.configFrame:IsVisible() then return false end
  if keystate == "down" then return true end

  if slot == 1 and self.configFocusButton and self.configFocusButton:IsVisible() then
    self.configFocusButton:Click()
  elseif slot == 2 then
    self.configFrame:Hide()
  end
  return true
end

function OctoPort:CreateCaptureOverlay()
  if self.captureFrame then return end
  local frame = CreateFrame("Frame", "OctoPortBindingCapture", UIParent)
  frame:SetWidth(620)
  frame:SetHeight(300)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 },
  })
  frame:EnableKeyboard(true)
  frame:EnableMouse(true)
  frame:Hide()

  local title = MakeLabel(frame, "GameFontNormalLarge", "STISKNI TLACITKO")
  title:SetPoint("TOP", frame, "TOP", 0, -32)
  title:SetTextColor(0.24, 0.84, 0.81)

  local instruction = MakeLabel(frame, "GameFontHighlight", "", 430)
  instruction:SetPoint("TOP", title, "BOTTOM", 0, -20)
  instruction:SetJustifyH("CENTER")

  local progress = MakeLabel(frame, "GameFontDisableSmall", "", 430)
  progress:SetPoint("TOP", instruction, "BOTTOM", 0, -14)
  progress:SetJustifyH("CENTER")

  local stickStatus = MakeLabel(frame, "GameFontHighlightSmall", "", 500)
  stickStatus:SetPoint("TOP", progress, "BOTTOM", 0, -22)
  stickStatus:SetJustifyH("CENTER")

  local dpadStatus = MakeLabel(frame, "GameFontHighlightSmall", "", 500)
  dpadStatus:SetPoint("TOP", stickStatus, "BOTTOM", 0, -12)
  dpadStatus:SetJustifyH("CENTER")

  local cancel = MakeButton(frame, "ZAVRIT PRUVODCE", 150, function()
    OctoPort:StopBindingCapture(false)
  end)
  cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -96, 30)

  local skip = MakeButton(frame, "PRESKOCIT", 120, function()
    OctoPort:SkipCaptureStep()
  end)
  skip:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 96, 30)

  frame:SetScript("OnKeyDown", function()
    OctoPort:CaptureControllerKey(arg1)
  end)
  frame:SetScript("OnKeyUp", function()
    OctoPort:ReleaseCapturedKey(arg1)
  end)
  frame:SetScript("OnMouseDown", function()
    OctoPort:CaptureControllerKey(arg1)
  end)
  frame:SetScript("OnMouseUp", function()
    OctoPort:ReleaseCapturedKey(arg1)
  end)

  frame.title = title
  frame.instruction = instruction
  frame.progress = progress
  frame.stickStatus = stickStatus
  frame.dpadStatus = dpadStatus
  frame.skip = skip
  self.captureFrame = frame
end

local function CapturedKeyText(owner, id)
  local key = owner.captureWorkingKeys and owner.captureWorkingKeys[id]
  if not key then return "--" end
  if owner.captureObservedIds and owner.captureObservedIds[id] then
    return "|cff4df273" .. key .. "|r"
  end
  return "|cff808890" .. key .. "|r"
end

function OctoPort:UpdateDirectionCaptureStatus()
  if not self.captureFrame then return end
  if not self.captureIncludesDirections then
    self.captureFrame.stickStatus:Hide()
    self.captureFrame.dpadStatus:Hide()
    return
  end

  self.captureFrame.stickStatus:SetText(
    "L-STICK   ^ " .. CapturedKeyText(self, "LSUP") ..
    "   v " .. CapturedKeyText(self, "LSDOWN") ..
    "   < " .. CapturedKeyText(self, "LSLEFT") ..
    "   > " .. CapturedKeyText(self, "LSRIGHT"))
  self.captureFrame.dpadStatus:SetText(
    "D-PAD     ^ " .. CapturedKeyText(self, "DUP") ..
    "   v " .. CapturedKeyText(self, "DDOWN") ..
    "   < " .. CapturedKeyText(self, "DLEFT") ..
    "   > " .. CapturedKeyText(self, "DRIGHT"))
  self.captureFrame.stickStatus:Show()
  self.captureFrame.dpadStatus:Show()
end

function OctoPort:UpdateCapturePrompt()
  if not self.captureFrame or not self.captureDefinition then return end
  self.captureFrame.instruction:SetText("Ted stiskni na ovladaci:  |cffffffff" .. self.captureDefinition.label .. "|r")
  if self.captureSingle then
    self.captureFrame.progress:SetText("Stavajici vazba se nahradi. Funguje i Enter, Escape a tlacitka mysi.")
  else
    local optional = self.captureDefinition.required and "" or "  |  VOLITELNE"
    local count = self.captureSequence and table.getn(self.captureSequence) or table.getn(self.bindingDefinitions)
    self.captureFrame.progress:SetText("Krok " .. self.captureIndex .. " / " .. count .. optional)
  end
  if self.captureDefinition.required then self.captureFrame.skip:Hide() else self.captureFrame.skip:Show() end
  self:UpdateDirectionCaptureStatus()
end

function OctoPort:BeginBindingCapture(definition, sequence, options)
  self:CreateConfigMenu()
  if self.IsBindingMutationLocked and self:IsBindingMutationLocked() then
    if self.DeferBindingOperation then
      self:DeferBindingOperation("reconcile", "Kalibrace pocka na konec boje; aktivni bindy se v boji nemeni.")
    end
    self:Print("Kalibraci lze spustit po boji. Zadny aktivni bind nebyl zmenen.")
    return false
  end
  self:CreateCaptureOverlay()
  options = options or {}

  self.captureSingle = options.single and true or false
  self.captureSequence = sequence
  self.captureFaceActions = options.faces and true or false
  self.captureDirections = options.directions and true or false
  self.captureIncludesDirections = options.includesDirections and true or false
  self.captureIndex = self.captureSingle and nil or 1
  self.captureDefinition = definition
  self.captureWorkingKeys = CopyMap(self.config.controllerKeys)
  self.captureWorkingModifiers = CopyMap(self.config.nativeModifiers)
  self.captureObservedIds = {}
  self.captureObservedKeys = {}
  self.captureDisplacedIds = {}
  self.captureAwaitRelease = nil
  self.captureAwaitReleaseRaw = nil
  self.bindingCaptureActive = true

  -- CONFIG and PLAY each own temporary bindings. Capture owns neither, so a
  -- key being calibrated cannot also move the character or activate a button.
  if self.DeactivateConfigNavigationBindings then self:DeactivateConfigNavigationBindings() end
  if self.sessionBindingsActive and self.DeactivateSessionBindings then self:DeactivateSessionBindings() end
  self.configFrame:Hide()
  self:UpdateCapturePrompt()
  self.captureFrame:Show()
  return true
end

function OctoPort:StartBindingWizard()
  return self:BeginBindingCapture(self.bindingDefinitions[1], nil, { includesDirections = true })
end

function OctoPort:StartFaceBindingWizard()
  local sequence = { "A", "B", "X", "Y" }
  return self:BeginBindingCapture(self:GetBindingDefinition(sequence[1]), sequence, { faces = true })
end

function OctoPort:StartDirectionalBindingWizard()
  local sequence = { "LSUP", "LSDOWN", "LSLEFT", "LSRIGHT", "DUP", "DDOWN", "DLEFT", "DRIGHT" }
  return self:BeginBindingCapture(self:GetBindingDefinition(sequence[1]), sequence, {
    directions = true,
    includesDirections = true,
  })
end

function OctoPort:StartSingleBinding(definition)
  return self:BeginBindingCapture(definition, nil, {
    single = true,
    includesDirections = definition and directionCaptureIds[definition.id],
  })
end

function OctoPort:StageCapturedKey(definition, key)
  if not definition or not key then return false, "Neznamy vstup." end
  local keys = self.captureWorkingKeys
  local modifiers = self.captureWorkingModifiers
  local displaced = nil
  local faceAction = definition.id == "A" or definition.id == "B" or definition.id == "X" or definition.id == "Y"

  if not definition.layer and (directionCaptureIds[definition.id] or faceAction) and string.find(key, "-", 1, true) then
    return false, definition.label .. " musi vysilat jednu klavesu bez SHIFT/CTRL/ALT."
  end

  if definition.layer then
    if not IsModifierKey(key) then
      return false, definition.label .. " musi vysilat SHIFT, CTRL nebo ALT."
    end
    local previousLayer = modifiers[key]
    if previousLayer and previousLayer ~= definition.layer then
      local previousId = previousLayer == "lt" and "LT" or "RT"
      if self.captureObservedIds[previousId] then
        return false, key .. " uz byl zachycen pro druhou akcni vrstvu."
      end
      modifiers[key] = nil
      displaced = previousId
      self.captureDisplacedIds[previousId] = true
    end
    for modifier, layer in pairs(modifiers) do
      if layer == definition.layer then modifiers[modifier] = nil end
    end
    for id, configuredKey in pairs(keys) do
      if configuredKey == key then
        if self.captureObservedIds[id] then
          return false, key .. " uz byl zachycen pro " .. id .. "."
        end
        keys[id] = nil
        displaced = id
        self.captureDisplacedIds[id] = true
      end
    end
    modifiers[key] = definition.layer
  else
    if IsModifierKey(key) and modifiers[key] then
      return false, key .. " uz ovlada akcni vrstvu."
    end
    local capturedOwner = self.captureObservedKeys[key]
    if capturedOwner and capturedOwner ~= definition.id then
      local previous = self:GetBindingDefinition(capturedOwner)
      return false, key .. " uz byl zachycen pro " .. (previous and previous.label or capturedOwner) .. "."
    end
    for id, configuredKey in pairs(keys) do
      if configuredKey == key and id ~= definition.id then
        if self.captureObservedIds[id] then
          local previous = self:GetBindingDefinition(id)
          return false, key .. " uz byl zachycen pro " .. (previous and previous.label or id) .. "."
        end
        keys[id] = nil
        displaced = id
        self.captureDisplacedIds[id] = true
      end
    end
    keys[definition.id] = key
  end

  if displaced then self.captureDisplacedIds[displaced] = true end
  self.captureObservedIds[definition.id] = true
  self.captureObservedKeys[key] = definition.id
  return true, displaced
end

function OctoPort:CommitBindingCapture()
  if not self.captureWorkingKeys or not self.captureWorkingModifiers then return false end
  self.config.controllerKeys = self.captureWorkingKeys
  self.config.nativeModifiers = self.captureWorkingModifiers
  if self.controlSchemaVersion then self.config.controlSchemaVersion = self.controlSchemaVersion end
  self.config.directionVerifiedKeys = self.config.directionVerifiedKeys or {}

  for id in pairs(self.captureDisplacedIds or {}) do
    if directionCaptureIds[id] then self.config.directionVerifiedKeys[id] = nil end
  end
  for id in pairs(self.captureObservedIds or {}) do
    if directionCaptureIds[id] then
      self.config.directionVerifiedKeys[id] = self.config.controllerKeys[id]
    end
  end

  self.config.lastBindingCollision = nil
  if self.RefreshSetupState then self:RefreshSetupState() end
  return true
end

function OctoPort:StopBindingCapture(completed)
  local capturedSingle = completed and self.captureSingle
  local capturedDefinition = self.captureDefinition
  if completed then self:CommitBindingCapture() end
  if not completed and self.config then
    self.config.lastBindingCollision = nil
    if self.RefreshSetupState then self:RefreshSetupState() end
  end
  if completed then
    self.config.arrowMovementFallback = false
    self.config.menuOnlyMode = false
    self.config.nativeFaceButtons = true
    self.config.reticleEnabled = false
  end
  local capturedFaces = completed and self.captureFaceActions
  local capturedDirections = completed and self.captureDirections
  self.bindingCaptureActive = false
  self.captureDefinition = nil
  self.captureIndex = nil
  self.captureSingle = nil
  self.captureSequence = nil
  self.captureFaceActions = nil
  self.captureDirections = nil
  self.captureIncludesDirections = nil
  self.captureWorkingKeys = nil
  self.captureWorkingModifiers = nil
  self.captureObservedIds = nil
  self.captureObservedKeys = nil
  self.captureDisplacedIds = nil
  self.captureAwaitRelease = nil
  self.captureAwaitReleaseRaw = nil
  if self.captureFrame then self.captureFrame:Hide() end
  self:RestoreGameplayAfterModal()
  local returnTab = 2
  if capturedDirections then returnTab = 1 elseif completed and not capturedSingle then returnTab = 4 end
  self:ShowConfigTab(returnTab, true)
  if completed then
    if capturedFaces then
      self:Print("ABXY captured: physical A/B/X/Y now activate native action slots 1/2/3/4.")
    elseif capturedDirections then
      self:Print("Stick and D-pad calibrated as eight separate inputs. Base D-pad now targets; LT/RT + D-pad use action slots.")
    elseif capturedSingle then
      self:Print((capturedDefinition and capturedDefinition.label or "Input") .. " saved. The previous action will be restored when Controller is disabled.")
    else
      self:Print("Controller wizard complete. Press every control once in Diagnostics.")
    end
  end
end

function OctoPort:AdvanceCaptureStep()
  if self.captureSingle then
    self:StopBindingCapture(true)
    return
  end

  self.captureIndex = self.captureIndex + 1
  local count = self.captureSequence and table.getn(self.captureSequence) or table.getn(self.bindingDefinitions)
  if self.captureIndex > count then
    self:StopBindingCapture(true)
    return
  end
  if self.captureSequence then
    self.captureDefinition = self:GetBindingDefinition(self.captureSequence[self.captureIndex])
  else
    self.captureDefinition = self.bindingDefinitions[self.captureIndex]
  end
  self:UpdateCapturePrompt()
end

function OctoPort:SkipCaptureStep()
  if not self.captureDefinition or self.captureDefinition.required then return end
  self:AdvanceCaptureStep()
end

function OctoPort:CaptureControllerKey(raw)
  if not self.bindingCaptureActive or not self.captureDefinition then return end
  if self.captureAwaitRelease then return end
  local key = ComposeKey(raw)
  if not key or key == "UNKNOWN" then return end

  local accepted, detail = self:StageCapturedKey(self.captureDefinition, key)
  if not accepted then
    self.config.lastBindingCollision = {
      key = key,
      previous = (self.captureObservedKeys and self.captureObservedKeys[key]) or "DEVICE",
      current = self.captureDefinition.id,
    }
    self.captureFrame.progress:SetText("|cffff5555KOLIZE: " .. detail .. " Vysli z ovladace jiny signal.|r")
    return
  end

  self:SignalInput(self.captureDefinition.id, "captured")
  self.captureAwaitRelease = key
  self.captureAwaitReleaseRaw = NormalizeReleasedKey(raw)
  self.captureFrame.progress:SetText("|cff4df273ZACHYCENO: " .. key .. "|r  -  uvolni ovladac pro dalsi krok")
  self:UpdateDirectionCaptureStatus()
end

function OctoPort:ReleaseCapturedKey(raw)
  if not self.bindingCaptureActive or not self.captureAwaitRelease then return end
  local released = NormalizeReleasedKey(raw)
  if released ~= self.captureAwaitReleaseRaw then return end
  self.captureAwaitRelease = nil
  self.captureAwaitReleaseRaw = nil
  self:AdvanceCaptureStep()
end

function OctoPort:RefreshBindingMenu()
  if not self.bindingRows or not self.config then return end
  if self.enableControllerButton then
    self.enableControllerButton:SetText(self.config.enabled and "VYPNOUT A OBNOVIT BINDY" or "ZAPNOUT BEZPECNE")
  end
  local complete = true
  for index = 1, table.getn(self.bindingDefinitions) do
    local definition = self.bindingDefinitions[index]
    local key = self:GetControllerBindingKey(definition)
    local row = self.bindingRows[index]
    if row then
      row.keyButton:SetText(key or "NASTAVIT")
      if key then
        local isDirection = self.IsDirectionControl and self:IsDirectionControl(definition)
        local isVerified = not isDirection or (self.IsDirectionVerified and self:IsDirectionVerified(definition))
        if isVerified then
          row.status:SetText(isDirection and "LIVE" or "OK")
          row.status:SetTextColor(0.30, 0.95, 0.45)
        else
          row.status:SetText("TEST")
          row.status:SetTextColor(1.00, 0.72, 0.22)
        end
      else
        row.status:SetText("--")
        row.status:SetTextColor(1.0, 0.35, 0.25)
      end
    end
    if definition.required and not key then complete = false end
  end

  if self.setupStatus then
    local collision = self.config.lastBindingCollision
    local deferred, deferredStatus = false, nil
    if self.GetBindingOperationStatus then
      deferred, deferredStatus = self:GetBindingOperationStatus()
    end
    if deferred then
      self.setupStatus:SetText("|cffffb83dCEKA NA KONEC BOJE: " .. (deferredStatus or "bindy se potom bezpecne obnovi") .. "|r")
    elseif collision then
      local previous = self:GetBindingDefinition(collision.previous)
      local current = self:GetBindingDefinition(collision.current)
      self.setupStatus:SetText("|cffff6655KOLIZE " .. collision.key .. ": " .. (previous and previous.label or collision.previous) .. " / " .. (current and current.label or collision.current) .. "|r")
    elseif self.config.lastDirectionalError then
      self.setupStatus:SetText("|cffff6655SMERY NEJSOU ODDELENE: " .. self.config.lastDirectionalError .. "|r")
    elseif self.config.menuOnlyMode then
      self.setupStatus:SetText("|cffffb83dAKTIVNI JE JEN TLACITKO PRO MENU|r")
    else
      self.setupStatus:SetText(complete and "|cff4df273OVLADAC JE PRIPRAVEN|r" or "|cffff6655DOKONCI PRUVODCE VSTUPU|r")
    end
  end
end

local function RawInputMatch(key)
  local matches = {}
  local keys = OctoPort.config and OctoPort.config.controllerKeys or {}
  local native = OctoPort.config and OctoPort.config.nativeModifiers or {}

  for index = 1, table.getn(OctoPort.bindingDefinitions) do
    local definition = OctoPort.bindingDefinitions[index]
    local matched = keys[definition.id] == key
    if definition.layer and native[key] == definition.layer then matched = true end
    if matched then table.insert(matches, definition) end
  end

  -- Show modified input as the actual controller combination. This makes the
  -- raw tester useful for verifying all 16 LT/RT layer actions, not just the
  -- unmodified physical buttons.
  -- WoW 1.12 embeds Lua 5.0, where string.match does not exist. string.find
  -- returns the same captures here and keeps RAW TEST usable on the real client.
  local _, _, modifier, baseKey = string.find(key, "^(%u+)%-(.+)$")
  local layer = modifier and native[modifier]
  if layer and baseKey then
    for index = 1, table.getn(OctoPort.bindingDefinitions) do
      local definition = OctoPort.bindingDefinitions[index]
      if keys[definition.id] == baseKey and OctoPort.layeredActionCommands and OctoPort.layeredActionCommands[layer] and OctoPort.layeredActionCommands[layer][definition.id] then
        table.insert(matches, { id = definition.id, label = string.upper(layer) .. " + " .. definition.label })
      elseif keys[definition.id] == baseKey and definition.movement then
        table.insert(matches, { id = definition.id, label = string.upper(layer) .. " + " .. definition.label .. " (movement)" })
      end
    end
  end
  return matches
end

function OctoPort:RecordRawInput(raw)
  if not self.rawTestFrame or not self.rawTestFrame:IsVisible() then return end
  local key = ComposeKey(raw)
  if not key or key == "UNKNOWN" then return end
  self.lastRawInputKey = key

  local matches = RawInputMatch(key)
  local labels = "NEPRIRAZENO"
  if table.getn(matches) > 0 then
    local names = {}
    for index = 1, table.getn(matches) do
      table.insert(names, matches[index].label)
      self:SignalInput(matches[index].id, "raw " .. key)
    end
    labels = table.concat(names, " + ")
  end

  local warning = ""
  if key == "UP" or key == "DOWN" or key == "LEFT" or key == "RIGHT" then
    warning = "Pokud jsi pohnul LEVOU PACKOU, je profil spatne: packa musi vysilat W/S/A/D, ne sipky D-padu."
  elseif key == "W" or key == "S" or key == "A" or key == "D" then
    warning = "W/S/A/D je spravny signal pro levou packu a nativni pohyb."
  elseif table.getn(matches) == 0 then
    warning = "Signal do WoW dorazil. Prirad ho v RUCNIM MAPOVANI nebo pruvodci."
  end

  self.rawTestFrame.last:SetText("RAW: |cffffffff" .. key .. "|r  ->  |cff4df273" .. labels .. "|r")
  self.rawTestFrame.warning:SetText(warning)
  self.rawInputHistory = self.rawInputHistory or {}
  table.insert(self.rawInputHistory, 1, key .. "  ->  " .. labels)
  while table.getn(self.rawInputHistory) > 7 do table.remove(self.rawInputHistory) end
  self.rawTestFrame.history:SetText(table.concat(self.rawInputHistory, "\n"))
end

function OctoPort:CreateRawInputTest()
  if self.rawTestFrame then return end

  local frame = CreateFrame("Frame", "OctoPortRawInputTest", UIParent)
  frame:SetWidth(600)
  frame:SetHeight(460)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 25)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 },
  })
  frame:EnableKeyboard(true)
  frame:EnableMouse(true)
  frame:Hide()

  local title = MakeLabel(frame, "GameFontNormalLarge", "RAW TEST ROG ALLY")
  title:SetPoint("TOP", frame, "TOP", 0, -30)
  title:SetTextColor(0.24, 0.84, 0.81)

  local body = MakeLabel(frame, "GameFontHighlightSmall",
    "Postupne pohni levou packou a stiskni ABXY, D-pad, Menu, View, LT/RT vrstvy, LB/RB kliky, L3/R3 a M1/M2. Escape se take zobrazi. Kdyz se nic nezmeni, tlacitko posila jen XInput a musi se premapovat v Armoury Crate.", 520)
  body:SetPoint("TOP", title, "BOTTOM", 0, -16)
  body:SetJustifyH("LEFT")

  local last = MakeLabel(frame, "GameFontNormal", "RAW: cekam na vstup", 520)
  last:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -24)
  last:SetJustifyH("LEFT")

  local warning = MakeLabel(frame, "GameFontHighlightSmall", "Leva packa musi ukazat W/S/A/D. D-pad musi ukazat sipky nebo ctyri jine samostatne klavesy.", 520)
  warning:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -16)
  warning:SetJustifyH("LEFT")
  warning:SetTextColor(1.0, 0.72, 0.22)

  local historyTitle = MakeLabel(frame, "GameFontNormalSmall", "POSLEDNI VSTUPY")
  historyTitle:SetPoint("TOPLEFT", warning, "BOTTOMLEFT", 0, -24)
  local history = MakeLabel(frame, "GameFontDisableSmall", "", 520)
  history:SetPoint("TOPLEFT", historyTitle, "BOTTOMLEFT", 0, -8)
  history:SetJustifyH("LEFT")

  local useForMenu = MakeButton(frame, "VSTUP = MENU", 190, function()
    if not OctoPort.lastRawInputKey then
      OctoPort.rawTestFrame.warning:SetText("Nejprve stiskni jedno funkcni fyzicke tlacitko.")
      return
    end
    if OctoPort:SetQuickMenuKey(OctoPort.lastRawInputKey) then
      OctoPort.rawTestFrame:Hide()
    end
  end)
  useForMenu:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 92, 28)

  local close = MakeButton(frame, "ZAVRIT TEST", 150, function() OctoPort.rawTestFrame:Hide() end)
  close:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -92, 28)

  frame:SetScript("OnKeyDown", function()
    OctoPort:RecordRawInput(arg1)
  end)
  frame:SetScript("OnMouseDown", function() OctoPort:RecordRawInput(arg1) end)
  frame:SetScript("OnUpdate", function()
    OctoPort.rawCursorElapsed = (OctoPort.rawCursorElapsed or 0) + arg1
    if OctoPort.rawCursorElapsed < 0.12 then return end
    OctoPort.rawCursorElapsed = 0
    local x, y = GetCursorPosition()
    if OctoPort.rawCursorX and (math.abs(x - OctoPort.rawCursorX) > 4 or math.abs(y - OctoPort.rawCursorY) > 4) then
      last:SetText("RAW: |cffffffffMOUSE MOVE|r  ->  |cff4df273R-Stick / Mouse|r")
      warning:SetText("Prava packa posila mys spravne.")
      OctoPort:SignalInput("RSTICK", "raw mouse move")
    end
    OctoPort.rawCursorX = x
    OctoPort.rawCursorY = y
  end)
  frame:SetScript("OnHide", function()
    OctoPort.rawInputTestActive = false
    OctoPort:RestoreGameplayAfterModal()
  end)

  frame.last = last
  frame.warning = warning
  frame.history = history
  frame.menuButton = useForMenu
  self.rawTestFrame = frame
end

function OctoPort:StartRawInputTest()
  if self.IsBindingMutationLocked and self:IsBindingMutationLocked() then
    if self.DeferBindingOperation then
      self:DeferBindingOperation("reconcile", "RAW test pocka na konec boje; aktivni bindy se v boji nemeni.")
    end
    self:Print("RAW test lze spustit po boji. Zadny aktivni bind nebyl zmenen.")
    return false
  end
  self:CreateRawInputTest()
  self.rawInputTestActive = true
  if self.DeactivateConfigNavigationBindings then self:DeactivateConfigNavigationBindings() end
  if self.sessionBindingsActive and self.DeactivateSessionBindings then self:DeactivateSessionBindings() end
  if self.configFrame then self.configFrame:Hide() end
  self.rawInputHistory = {}
  self.lastRawInputKey = nil
  self.rawTestFrame.history:SetText("")
  self.rawTestFrame.last:SetText("RAW: cekam na vstup")
  self.rawTestFrame.warning:SetText("Leva packa musi ukazat W/S/A/D. D-pad musi ukazat sipky nebo ctyri jine samostatne klavesy.")
  self.rawCursorX, self.rawCursorY = GetCursorPosition()
  self.rawTestFrame:Show()
  return true
end

function OctoPort:UpdateInputDiagnostics()
  if not self.diagnosticRows then return end
  local now = GetTime()
  local cursorX, cursorY = GetCursorPosition()
  if self.lastDiagnosticCursorX and (math.abs(cursorX - self.lastDiagnosticCursorX) > 2 or math.abs(cursorY - self.lastDiagnosticCursorY) > 2) then
    self.lastRightStickAt = now
    self.lastControllerInput = "RSTICK"
    self.lastControllerInputState = "mouse"
    self.lastControllerInputAt = now
  end
  self.lastDiagnosticCursorX = cursorX
  self.lastDiagnosticCursorY = cursorY

  for index = 1, table.getn(self.diagnosticRows) do
    local row = self.diagnosticRows[index]
    local active = self.lastControllerInput == row.id and self.lastControllerInputAt and now - self.lastControllerInputAt < 0.65
    local native = self.config and self.config.nativeModifiers or {}
    if row.id == "LT" and ((native.SHIFT == "lt" and IsShiftKeyDown and IsShiftKeyDown()) or (native.CTRL == "lt" and IsControlKeyDown and IsControlKeyDown()) or (native.ALT == "lt" and IsAltKeyDown and IsAltKeyDown())) then
      active = true
    elseif row.id == "RT" and ((native.SHIFT == "rt" and IsShiftKeyDown and IsShiftKeyDown()) or (native.CTRL == "rt" and IsControlKeyDown and IsControlKeyDown()) or (native.ALT == "rt" and IsAltKeyDown and IsAltKeyDown())) then
      active = true
    elseif row.id == "RSTICK" and self.lastRightStickAt and now - self.lastRightStickAt < 0.65 then
      active = true
    end
    if row.systemOnly then
      row:SetBackdropColor(0.16, 0.10, 0.03, 0.94)
      row:SetBackdropBorderColor(0.78, 0.52, 0.18, 0.90)
      row.state:SetText("SYSTEM")
      row.state:SetTextColor(1.00, 0.68, 0.25)
    elseif active then
      row:SetBackdropColor(0.04, 0.38, 0.28, 0.98)
      row:SetBackdropBorderColor(0.30, 1.00, 0.62, 1)
      row.state:SetText("SIGNAL")
      row.state:SetTextColor(0.30, 1.00, 0.62)
    elseif (row.nativeMovement or row.nativeAction or (self.config.nativeFaceButtons and (row.id == "A" or row.id == "B" or row.id == "X" or row.id == "Y"))) and self:GetControllerBindingKey(row.id) then
      row:SetBackdropColor(0.04, 0.18, 0.34, 0.98)
      row:SetBackdropBorderColor(0.28, 0.62, 1.00, 1)
      row.state:SetText("NATIVE")
      row.state:SetTextColor(0.38, 0.72, 1.00)
    elseif row.passthrough and self:GetControllerBindingKey(row.id) then
      row:SetBackdropColor(0.04, 0.18, 0.34, 0.98)
      row:SetBackdropBorderColor(0.28, 0.62, 1.00, 1)
      row.state:SetText("PASS")
      row.state:SetTextColor(0.38, 0.72, 1.00)
    else
      row:SetBackdropColor(0.025, 0.04, 0.055, 0.94)
      row:SetBackdropBorderColor(0.40, 0.48, 0.52, 0.85)
      row.state:SetText("CEKA")
      row.state:SetTextColor(0.62, 0.66, 0.70)
    end
  end

  if self.lastInputText then
    local key = self.lastControllerInput or "zadny"
    local state = self.lastControllerInputState or ""
    self.lastInputText:SetText("Posledni vstup: |cffffffff" .. key .. "  " .. state .. "|r")
  end
end

function OctoPort:RefreshRearActionButtons()
  if self.rearM1Button then
    self.rearM1Button:SetText("M1: " .. string.upper(self:GetRearActionLabel("M1")))
  end
  if self.rearM2Button then
    self.rearM2Button:SetText("M2: " .. string.upper(self:GetRearActionLabel("M2")))
  end
end

local function BuildSetupPanel(panel)
  local title = MakeLabel(panel, "GameFontNormalLarge", "PRIPOJENI OVLADACE")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -2)
  title:SetTextColor(0.24, 0.84, 0.81)

  local body = MakeLabel(panel, "GameFontHighlightSmall",
    "BEZPECNY REZIM: leva packa a D-pad jsou dve striktne oddelene skupiny. Zakladni ABXY dava 4 akce; LT a RT pridaji vzdy ABXY + D-pad, celkem 20. Bojove akce i pohyb pouzivaji nativni Blizzard bindingy, ne chranena Lua volani.", 470)
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")

  local status = MakeLabel(panel, "GameFontNormal", "")
  status:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -24)
  status:SetWidth(470)
  status:SetJustifyH("LEFT")
  OctoPort.setupStatus = status

  local wizard = AddFocusable(panel, MakeButton(panel, "SPUSTIT PRUVODCE", 180, function()
    OctoPort:StartBindingWizard()
  end))
  wizard:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -18)

  local controls = AddFocusable(panel, MakeButton(panel, "RUCNI MAPOVANI", 150, function()
    OctoPort:ShowConfigTab(2, true)
  end))
  controls:SetPoint("LEFT", wizard, "RIGHT", 10, 0)

  local rawTest = AddFocusable(panel, MakeButton(panel, "RYCHLY TEST", 130, function()
    OctoPort:StartRawInputTest()
  end))
  rawTest:SetPoint("LEFT", controls, "RIGHT", 10, 0)

  local preset = AddFocusable(panel, MakeButton(panel, "VYCHOZI PROFIL", 150, function()
    OctoPort:ApplyRecommendedBindings()
  end))
  preset:SetPoint("TOPLEFT", wizard, "BOTTOMLEFT", 0, -12)

  local directions = AddFocusable(panel, MakeButton(panel, "KALIBROVAT 8 SMERU", 180, function()
    OctoPort:StartDirectionalBindingWizard()
  end))
  directions:SetPoint("LEFT", preset, "RIGHT", 10, 0)

  local nativeFace = AddFocusable(panel, MakeButton(panel, "NACIST ABXY 1-4", 160, function()
    OctoPort:StartFaceBindingWizard()
  end))
  nativeFace:SetPoint("LEFT", directions, "RIGHT", 10, 0)

  local restore = AddFocusable(panel, MakeButton(panel, "OBNOVIT PUVODNI", 150, function()
    OctoPort:RestoreBindings()
  end))
  restore:SetPoint("TOPLEFT", preset, "BOTTOMLEFT", 0, -12)

  local enable = AddFocusable(panel, MakeButton(panel, "ZAPNOUT BEZPECNE", 340, function()
    OctoPort:SetEnabled(not OctoPort.config.enabled)
    this:SetText(OctoPort.config.enabled and "VYPNOUT A OBNOVIT BINDY" or "ZAPNOUT BEZPECNE")
  end))
  enable:SetPoint("LEFT", restore, "RIGHT", 10, 0)
  OctoPort.enableControllerButton = enable

  local note = MakeLabel(panel, "GameFontDisableSmall",
    "Vychozi profil jen predvyplni ocekavane klavesy. Pred zapnutim musi KALIBROVAT 8 SMERU skutecne zachytit osm rozdilnych signalu. L-stick a D-pad nelze rozlisit, pokud oba fyzicky vysilaji stejnou klavesu.", 470)
  note:SetPoint("TOPLEFT", restore, "BOTTOMLEFT", 0, -18)
  note:SetJustifyH("LEFT")

  panel:SetScript("OnShow", function()
    enable:SetText(OctoPort.config.enabled and "VYPNOUT A OBNOVIT BINDY" or "ZAPNOUT BEZPECNE")
  end)
end

local function BuildControlsPanel(panel)
  local title = MakeLabel(panel, "GameFontNormalLarge", "MAPOVANI TLACITEK")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -2)
  title:SetTextColor(0.24, 0.84, 0.81)

  OctoPort.bindingRows = {}
  local bindingCount = table.getn(OctoPort.bindingDefinitions)
  local leftCount = math.ceil(bindingCount / 2)
  for index = 1, bindingCount do
    local definition = OctoPort.bindingDefinitions[index]
    local column = index <= leftCount and 0 or 248
    local rowIndex = index <= leftCount and index or index - leftCount
    local y = -38 - ((rowIndex - 1) * 36)

    local row = CreateFrame("Frame", nil, panel)
    row:SetWidth(232)
    row:SetHeight(32)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", column, y)

    local label = MakeLabel(row, "GameFontHighlightSmall", definition.label, 94)
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetJustifyH("LEFT")

    local keyButton = AddFocusable(panel, MakeButton(row, "", 104, function()
      OctoPort:StartSingleBinding(this.bindingDefinition)
    end))
    keyButton.bindingDefinition = definition
    keyButton:SetPoint("LEFT", label, "RIGHT", 4, 0)

    local status = MakeLabel(row, "GameFontNormalSmall", "--", 22)
    status:SetPoint("LEFT", keyButton, "RIGHT", 2, 0)

    row.keyButton = keyButton
    row.status = status
    OctoPort.bindingRows[index] = row
  end

  local wizard = AddFocusable(panel, MakeButton(panel, "CELY PRUVODCE", 150, function()
    OctoPort:StartBindingWizard()
  end))
  wizard:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)

  local help = MakeLabel(panel, "GameFontDisableSmall", "D-pad vybira. A potvrzuje, B zavre. LT/RT musi byt SHIFT/CTRL/ALT.", 320)
  help:SetPoint("LEFT", wizard, "RIGHT", 12, 0)
end

local function BuildGameplayPanel(panel)
  local title = MakeLabel(panel, "GameFontNormalLarge", "HRANI A ROZHRANI")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -2)
  title:SetTextColor(0.24, 0.84, 0.81)

  local autoQuest = AddFocusable(panel, MakeButton(panel, "", 200, function()
    OctoPort.config.autoAcceptQuests = not OctoPort.config.autoAcceptQuests
    SetToggleText(this, "AUTO QUEST", OctoPort.config.autoAcceptQuests)
  end))
  autoQuest:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -22)

  local hud = AddFocusable(panel, MakeButton(panel, "", 200, function()
    OctoPort:SetEnabled(not OctoPort.config.enabled)
    SetToggleText(this, "CONTROLLER HUD", OctoPort.config.enabled)
  end))
  hud:SetPoint("TOPLEFT", autoQuest, "BOTTOMLEFT", 0, -10)

  local editBars = AddFocusable(panel, MakeButton(panel, "UPRAVIT 20 AKCI", 200, function()
    OctoPort:SetActionEditMode(not OctoPort.config.editMode)
    OctoPort.configFrame:Hide()
  end))
  editBars:SetPoint("TOPLEFT", hud, "BOTTOMLEFT", 0, -10)

  local moveHud = AddFocusable(panel, MakeButton(panel, "POSUNOUT HUD", 200, function()
    OctoPort:SetMoveMode(not OctoPort.config.moveMode)
    OctoPort.configFrame:Hide()
  end))
  moveHud:SetPoint("TOPLEFT", editBars, "BOTTOMLEFT", 0, -10)

  local wheel = AddFocusable(panel, MakeButton(panel, "UPRAVIT RADIALNI KOLO", 220, function()
    OctoPort.configFrame:Hide()
    OctoPort:ToggleRadialEditor()
  end))
  wheel:SetPoint("TOPLEFT", panel, "TOPLEFT", 260, -54)

  local holdValues = { 0.20, 0.35, 0.50, 0.75 }
  local hold = AddFocusable(panel, MakeButton(panel, "", 220, function()
    local current = OctoPort.config.radialHold or 0.35
    local nextIndex = 1
    for index = 1, table.getn(holdValues) do
      if holdValues[index] == current then nextIndex = index + 1 end
    end
    if nextIndex > table.getn(holdValues) then nextIndex = 1 end
    OctoPort.config.radialHold = holdValues[nextIndex]
    this:SetText("PODRZENI MENU: " .. OctoPort.config.radialHold .. " s")
  end))
  hold:SetPoint("TOPLEFT", wheel, "BOTTOMLEFT", 0, -10)

  local scaleDown = AddFocusable(panel, MakeButton(panel, "HUD -", 104, function()
    OctoPort.config.scale = math.max(0.7, (OctoPort.config.scale or 1) - 0.1)
    OctoPort:ApplyLayout()
  end))
  scaleDown:SetPoint("TOPLEFT", hold, "BOTTOMLEFT", 0, -10)

  local scaleUp = AddFocusable(panel, MakeButton(panel, "HUD +", 104, function()
    OctoPort.config.scale = math.min(1.6, (OctoPort.config.scale or 1) + 0.1)
    OctoPort:ApplyLayout()
  end))
  scaleUp:SetPoint("LEFT", scaleDown, "RIGHT", 12, 0)

  local rearM1 = AddFocusable(panel, MakeButton(panel, "", 220, function()
    OctoPort:CycleRearAction("M1")
  end))
  rearM1:SetPoint("TOPLEFT", scaleDown, "BOTTOMLEFT", 0, -10)

  local rearM2 = AddFocusable(panel, MakeButton(panel, "", 220, function()
    OctoPort:CycleRearAction("M2")
  end))
  rearM2:SetPoint("TOPLEFT", rearM1, "BOTTOMLEFT", 0, -10)
  OctoPort.rearM1Button = rearM1
  OctoPort.rearM2Button = rearM2

  panel:SetScript("OnShow", function()
    SetToggleText(autoQuest, "AUTO QUEST", OctoPort.config.autoAcceptQuests)
    SetToggleText(hud, "CONTROLLER HUD", OctoPort.config.enabled)
    hold:SetText("PODRZENI MENU: " .. (OctoPort.config.radialHold or 0.35) .. " s")
    OctoPort:RefreshRearActionButtons()
  end)
end

local function BuildDiagnosticsPanel(panel)
  local title = MakeLabel(panel, "GameFontNormalLarge", "ZIVY TEST VSTUPU")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -2)
  title:SetTextColor(0.24, 0.84, 0.81)

  local body = MakeLabel(panel, "GameFontHighlightSmall",
    "Stiskni jednotliva tlacitka. Leva packa musi hlasit ctyri jine vstupy nez D-pad. Modre NATIVE znamena primy Blizzard binding. LT a RT rozsvecuji samostatne osmipozicove akcni vrstvy.", 470)
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
  body:SetJustifyH("LEFT")

  local last = MakeLabel(panel, "GameFontNormal", "Posledni vstup: zadny", 470)
  last:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -16)
  OctoPort.lastInputText = last

  OctoPort.diagnosticRows = {}
  local definitions = {}
  for index = 1, table.getn(OctoPort.bindingDefinitions) do
    table.insert(definitions, OctoPort.bindingDefinitions[index])
  end
  table.insert(definitions, { id = "RSTICK", label = "R-Stick / Mouse" })
  table.insert(definitions, { id = "COMMANDCENTER", label = "Command Center", systemOnly = true })
  table.insert(definitions, { id = "ARMOURY", label = "Armoury Crate", systemOnly = true })
  local leftCount = math.ceil(table.getn(definitions) / 2)

  for index = 1, table.getn(definitions) do
    local definition = definitions[index]
    local column = index <= leftCount and 0 or 248
    local rowIndex = index <= leftCount and index or index - leftCount
    local y = -92 - ((rowIndex - 1) * 28)

    local row = CreateFrame("Frame", nil, panel)
    row:SetWidth(226)
    row:SetHeight(25)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", column, y)
    row:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 8, edgeSize = 8,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    local label = MakeLabel(row, "GameFontHighlightSmall", definition.label, 110)
    label:SetPoint("LEFT", row, "LEFT", 8, 0)
    label:SetJustifyH("LEFT")

    local state = MakeLabel(row, "GameFontNormalSmall", "CEKA", 80)
    state:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    state:SetJustifyH("RIGHT")

    row.id = definition.id
    row.nativeMovement = definition.movement
    row.nativeAction = definition.nativeAction
    row.passthrough = definition.passthrough
    row.systemOnly = definition.systemOnly
    row.state = state
    OctoPort.diagnosticRows[index] = row
  end

  local rebind = AddFocusable(panel, MakeButton(panel, "MAPOVANI", 140, function()
    OctoPort:ShowConfigTab(2, true)
  end))
  rebind:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)

  local rawTest = AddFocusable(panel, MakeButton(panel, "RAW TEST", 120, function()
    OctoPort:StartRawInputTest()
  end))
  rawTest:SetPoint("LEFT", rebind, "RIGHT", 10, 0)

  local version = MakeLabel(panel, "GameFontDisableSmall", "WOW Controller " .. OctoPort.version .. "  |  WoW API 11200")
  version:SetPoint("LEFT", rawTest, "RIGHT", 14, 0)
end

function OctoPort:CreateConfigMenu()
  if self.configFrame then return end
  local frame = CreateFrame("Frame", "OctoPortConfigFrame", UIParent)
  frame:SetWidth(700)
  frame:SetHeight(650)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 25)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 },
  })

  local title = MakeLabel(frame, "GameFontNormalLarge", "WOW CONTROLLER")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -26)
  title:SetTextColor(0.24, 0.84, 0.81)

  local subtitle = MakeLabel(frame, "GameFontDisableSmall", "Controller-first nastaveni pro OctoWoW 1.12")
  subtitle:SetPoint("LEFT", title, "RIGHT", 12, 0)

  local close = MakeButton(frame, "X", 30, function() OctoPort.configFrame:Hide() end)
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -22)

  self.configTabs = {}
  self.configPanels = {}
  for index = 1, table.getn(tabNames) do
    local tabIndex = index
    local tab = MakeButton(frame, tabNames[index], 118, function()
      OctoPort:ShowConfigTab(tabIndex, true)
    end)
    tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -72 - ((index - 1) * 36))
    self.configTabs[index] = tab

    local panel = MakePanel(frame)
    self.configPanels[index] = panel
  end

  BuildSetupPanel(self.configPanels[1])
  BuildControlsPanel(self.configPanels[2])
  BuildGameplayPanel(self.configPanels[3])
  BuildDiagnosticsPanel(self.configPanels[4])

  local hint = MakeLabel(frame, "GameFontDisableSmall", "D-pad navigace  |  A potvrdit  |  B / View zavrit  |  WC = test")
  hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 28)

  frame:SetScript("OnUpdate", function()
    OctoPort.configMenuElapsed = (OctoPort.configMenuElapsed or 0) + arg1
    if OctoPort.configMenuElapsed < 0.10 then return end
    OctoPort.configMenuElapsed = 0
    OctoPort:UpdateInputDiagnostics()
  end)
  frame:SetScript("OnShow", function()
    if OctoPort.ActivateConfigNavigationBindings then OctoPort:ActivateConfigNavigationBindings() end
  end)
  frame:SetScript("OnHide", function()
    if OctoPort.bindingCaptureActive or OctoPort.rawInputTestActive then return end
    if OctoPort.DeactivateConfigNavigationBindings then OctoPort:DeactivateConfigNavigationBindings() end
    OctoPort:RestoreGameplayAfterModal()
  end)

  self.configFrame = frame
  frame:Hide()
  self:ShowConfigTab(self.config.selectedConfigTab or 1, false)
end

function OctoPort:HandleRadialDirection(direction)
  if not self.radialFrame or not self.radialFrame:IsVisible() then return false end
  if self.radialEditor then
    local current = self.radialSelection or 1
    if direction == "left" then current = current - 1
    elseif direction == "right" then current = current + 1
    elseif direction == "up" then current = current - 2
    elseif direction == "down" then current = current + 2 end
    while current < 1 do current = current + 8 end
    while current > 8 do current = current - 8 end
    self:SetRadialSelection(current)
    return true
  end
  local slots = { up = 1, right = 3, down = 5, left = 7 }
  self:SetRadialSelection(slots[direction])
  return true
end
