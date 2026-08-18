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
  if raw == "SHIFT" or raw == "CTRL" or raw == "ALT" then return raw end

  local key = raw
  if IsShiftKeyDown and IsShiftKeyDown() then key = "SHIFT-" .. key end
  if IsControlKeyDown and IsControlKeyDown() then key = "CTRL-" .. key end
  if IsAltKeyDown and IsAltKeyDown() then key = "ALT-" .. key end
  return key
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
  frame:SetWidth(520)
  frame:SetHeight(230)
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
  frame:SetScript("OnMouseDown", function()
    OctoPort:CaptureControllerKey(arg1)
  end)

  frame.title = title
  frame.instruction = instruction
  frame.progress = progress
  frame.skip = skip
  self.captureFrame = frame
end

function OctoPort:UpdateCapturePrompt()
  if not self.captureFrame or not self.captureDefinition then return end
  self.captureFrame.instruction:SetText("Ted stiskni na ovladaci:  |cffffffff" .. self.captureDefinition.label .. "|r")
  if self.captureSingle then
    self.captureFrame.progress:SetText("Stavajici vazba se nahradi. Funguje i Enter, Escape a tlacitka mysi.")
  else
    local optional = self.captureDefinition.required and "" or "  |  VOLITELNE"
    self.captureFrame.progress:SetText("Krok " .. self.captureIndex .. " / " .. table.getn(self.bindingDefinitions) .. optional)
  end
  if self.captureDefinition.required then self.captureFrame.skip:Hide() else self.captureFrame.skip:Show() end
end

function OctoPort:StartBindingWizard()
  self:CreateConfigMenu()
  self:CreateCaptureOverlay()
  self.captureSingle = false
  self.captureIndex = 1
  self.captureDefinition = self.bindingDefinitions[1]
  self.bindingCaptureActive = true
  self.configFrame:Hide()
  self:UpdateCapturePrompt()
  self.captureFrame:Show()
end

function OctoPort:StartSingleBinding(definition)
  self:CreateCaptureOverlay()
  self.captureSingle = true
  self.captureIndex = nil
  self.captureDefinition = definition
  self.bindingCaptureActive = true
  self:UpdateCapturePrompt()
  self.captureFrame:Show()
end

function OctoPort:StopBindingCapture(completed)
  self.bindingCaptureActive = false
  self.captureDefinition = nil
  self.captureIndex = nil
  self.captureSingle = nil
  if self.captureFrame then self.captureFrame:Hide() end
  self:ShowConfigTab(completed and 4 or 2, true)
  if completed then
    self:Print("Controller wizard complete. Press every control once in Diagnostics.")
  end
end

function OctoPort:AdvanceCaptureStep()
  if self.captureSingle then
    self:StopBindingCapture(false)
    return
  end

  self.captureIndex = self.captureIndex + 1
  if self.captureIndex > table.getn(self.bindingDefinitions) then
    self:StopBindingCapture(true)
    return
  end
  self.captureDefinition = self.bindingDefinitions[self.captureIndex]
  self:UpdateCapturePrompt()
end

function OctoPort:SkipCaptureStep()
  if not self.captureDefinition or self.captureDefinition.required then return end
  self:AdvanceCaptureStep()
end

function OctoPort:CaptureControllerKey(raw)
  if not self.bindingCaptureActive or not self.captureDefinition then return end
  local key = ComposeKey(raw)
  if not key or key == "UNKNOWN" then return end

  if not self:BindControllerKey(self.captureDefinition, key) then
    self.captureFrame.progress:SetText("|cffff5555WoW tuto vazbu odmitl. Zkus jine tlacitko nebo klavesu.|r")
    return
  end

  self:SignalInput(self.captureDefinition.id, "captured")
  self:AdvanceCaptureStep()
end

function OctoPort:RefreshBindingMenu()
  if not self.bindingRows or not self.config then return end
  local complete = true
  for index = 1, table.getn(self.bindingDefinitions) do
    local definition = self.bindingDefinitions[index]
    local key = self:GetControllerBindingKey(definition)
    local row = self.bindingRows[index]
    if row then
      row.keyButton:SetText(key or "NASTAVIT")
      if key then
        row.status:SetText("OK")
        row.status:SetTextColor(0.30, 0.95, 0.45)
      else
        row.status:SetText("--")
        row.status:SetTextColor(1.0, 0.35, 0.25)
      end
    end
    if definition.required and not key then complete = false end
  end

  if self.setupStatus then
    self.setupStatus:SetText(complete and "|cff4df273OVLADAC JE PRIPRAVEN|r" or "|cffff6655DOKONCI PRUVODCE VSTUPU|r")
  end
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
    if row.id == "LB" and ((native.SHIFT == "shift" and IsShiftKeyDown and IsShiftKeyDown()) or (native.CTRL == "shift" and IsControlKeyDown and IsControlKeyDown()) or (native.ALT == "shift" and IsAltKeyDown and IsAltKeyDown())) then
      active = true
    elseif row.id == "LT" and ((native.SHIFT == "ctrl" and IsShiftKeyDown and IsShiftKeyDown()) or (native.CTRL == "ctrl" and IsControlKeyDown and IsControlKeyDown()) or (native.ALT == "ctrl" and IsAltKeyDown and IsAltKeyDown())) then
      active = true
    elseif row.id == "RSTICK" and self.lastRightStickAt and now - self.lastRightStickAt < 0.65 then
      active = true
    end
    if active then
      row:SetBackdropColor(0.04, 0.38, 0.28, 0.98)
      row:SetBackdropBorderColor(0.30, 1.00, 0.62, 1)
      row.state:SetText("SIGNAL")
      row.state:SetTextColor(0.30, 1.00, 0.62)
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
    "DULEZITE: pro OctoWoW nastav v Command Centeru CONTROL MODE = DESKTOP. Klient 1.12 nevidi XInput z Gamepad Mode. Pruvodce zachyti levou packu jako W/A/S/D, tlacitka jako klavesy a prava packa zustane mysi.", 470)
  body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
  body:SetJustifyH("LEFT")
  body:SetJustifyV("TOP")

  local status = MakeLabel(panel, "GameFontNormal", "")
  status:SetPoint("TOPLEFT", body, "BOTTOMLEFT", 0, -24)
  OctoPort.setupStatus = status

  local wizard = AddFocusable(panel, MakeButton(panel, "SPUSTIT PRUVODCE", 180, function()
    OctoPort:StartBindingWizard()
  end))
  wizard:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -18)

  local controls = AddFocusable(panel, MakeButton(panel, "RUCNI MAPOVANI", 150, function()
    OctoPort:ShowConfigTab(2, true)
  end))
  controls:SetPoint("LEFT", wizard, "RIGHT", 10, 0)

  local preset = AddFocusable(panel, MakeButton(panel, "ROG ALLY PRESET", 150, function()
    OctoPort:ApplyRecommendedBindings()
  end))
  preset:SetPoint("TOPLEFT", wizard, "BOTTOMLEFT", 0, -12)

  local restore = AddFocusable(panel, MakeButton(panel, "OBNOVIT PUVODNI", 150, function()
    OctoPort:RestoreBindings()
  end))
  restore:SetPoint("LEFT", preset, "RIGHT", 10, 0)

  local note = MakeLabel(panel, "GameFontDisableSmall",
    "M1/M2: v Armoury Crate vypni Set as Secondary Function a prirad jim vlastni klavesy. View lze pouzit pro nastaveni. Command Center a Armoury Crate tlacitka jsou systemova a ASUS je nepovoluje premapovat.", 470)
  note:SetPoint("TOPLEFT", preset, "BOTTOMLEFT", 0, -28)
  note:SetJustifyH("LEFT")
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
      OctoPort:StartSingleBinding(definition)
    end))
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

  local help = MakeLabel(panel, "GameFontDisableSmall", "D-pad: vlevo/vpravo meni zalozku, nahoru/dolu vybira. A potvrdi, B zavre.", 300)
  help:SetPoint("LEFT", wizard, "RIGHT", 12, 0)
end

local function BuildGameplayPanel(panel)
  local title = MakeLabel(panel, "GameFontNormalLarge", "HRANI A ROZHRANI")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -2)
  title:SetTextColor(0.24, 0.84, 0.81)

  local autoTarget = AddFocusable(panel, MakeButton(panel, "", 200, function()
    OctoPort.config.autoTarget = not OctoPort.config.autoTarget
    SetToggleText(this, "AUTO TARGET", OctoPort.config.autoTarget)
  end))
  autoTarget:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -22)

  local autoQuest = AddFocusable(panel, MakeButton(panel, "", 200, function()
    OctoPort.config.autoAcceptQuests = not OctoPort.config.autoAcceptQuests
    SetToggleText(this, "AUTO QUEST", OctoPort.config.autoAcceptQuests)
  end))
  autoQuest:SetPoint("TOPLEFT", autoTarget, "BOTTOMLEFT", 0, -10)

  local hud = AddFocusable(panel, MakeButton(panel, "", 200, function()
    OctoPort:SetEnabled(not OctoPort.config.enabled)
    SetToggleText(this, "CONTROLLER HUD", OctoPort.config.enabled)
  end))
  hud:SetPoint("TOPLEFT", autoQuest, "BOTTOMLEFT", 0, -10)

  local reticle = AddFocusable(panel, MakeButton(panel, "", 200, function()
    OctoPort.config.reticleEnabled = not OctoPort.config.reticleEnabled
    SetToggleText(this, "ZAMEROVAC", OctoPort.config.reticleEnabled)
    if OctoPort.UpdateReticle then OctoPort:UpdateReticle(true) end
  end))
  reticle:SetPoint("TOPLEFT", hud, "BOTTOMLEFT", 0, -10)

  local editBars = AddFocusable(panel, MakeButton(panel, "UPRAVIT LISTY AKCI", 200, function()
    OctoPort.config.editMode = not OctoPort.config.editMode
    OctoPort:UpdateLayer(true)
    OctoPort.configFrame:Hide()
  end))
  editBars:SetPoint("TOPLEFT", reticle, "BOTTOMLEFT", 0, -10)

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

  local reticleDown = AddFocusable(panel, MakeButton(panel, "ZAMER -", 104, function()
    OctoPort.config.reticleScale = math.max(0.6, (OctoPort.config.reticleScale or 1) - 0.1)
    if OctoPort.UpdateReticle then OctoPort:UpdateReticle(true) end
  end))
  reticleDown:SetPoint("TOPLEFT", scaleDown, "BOTTOMLEFT", 0, -10)

  local reticleUp = AddFocusable(panel, MakeButton(panel, "ZAMER +", 104, function()
    OctoPort.config.reticleScale = math.min(1.8, (OctoPort.config.reticleScale or 1) + 0.1)
    if OctoPort.UpdateReticle then OctoPort:UpdateReticle(true) end
  end))
  reticleUp:SetPoint("LEFT", reticleDown, "RIGHT", 12, 0)

  local rearM1 = AddFocusable(panel, MakeButton(panel, "", 220, function()
    OctoPort:CycleRearAction("M1")
  end))
  rearM1:SetPoint("TOPLEFT", reticleDown, "BOTTOMLEFT", 0, -10)

  local rearM2 = AddFocusable(panel, MakeButton(panel, "", 220, function()
    OctoPort:CycleRearAction("M2")
  end))
  rearM2:SetPoint("TOPLEFT", rearM1, "BOTTOMLEFT", 0, -10)
  OctoPort.rearM1Button = rearM1
  OctoPort.rearM2Button = rearM2

  panel:SetScript("OnShow", function()
    SetToggleText(autoTarget, "AUTO TARGET", OctoPort.config.autoTarget)
    SetToggleText(autoQuest, "AUTO QUEST", OctoPort.config.autoAcceptQuests)
    SetToggleText(hud, "CONTROLLER HUD", OctoPort.config.enabled)
    SetToggleText(reticle, "ZAMEROVAC", OctoPort.config.reticleEnabled)
    hold:SetText("PODRZENI MENU: " .. (OctoPort.config.radialHold or 0.35) .. " s")
    OctoPort:RefreshRearActionButtons()
  end)
end

local function BuildDiagnosticsPanel(panel)
  local title = MakeLabel(panel, "GameFontNormalLarge", "ZIVY TEST VSTUPU")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -2)
  title:SetTextColor(0.24, 0.84, 0.81)

  local body = MakeLabel(panel, "GameFontHighlightSmall",
    "Stiskni jednotliva tlacitka. Zelene SIGNAL potvrzuje, ze klavesa prosla pres Armoury Crate, WoW binding i addon.", 470)
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
    row.state = state
    OctoPort.diagnosticRows[index] = row
  end

  local rebind = AddFocusable(panel, MakeButton(panel, "MAPOVANI", 140, function()
    OctoPort:ShowConfigTab(2, true)
  end))
  rebind:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)

  local version = MakeLabel(panel, "GameFontDisableSmall", "WOW Controller " .. OctoPort.version .. "  |  WoW API 11200")
  version:SetPoint("LEFT", rebind, "RIGHT", 14, 0)
end

function OctoPort:CreateConfigMenu()
  if self.configFrame then return end
  local frame = CreateFrame("Frame", "OctoPortConfigFrame", UIParent)
  frame:SetWidth(700)
  frame:SetHeight(520)
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

  local hint = MakeLabel(frame, "GameFontDisableSmall", "D-pad navigace  |  A potvrdit  |  B zavrit  |  /wc otevrit")
  hint:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 28, 28)

  frame:SetScript("OnUpdate", function()
    OctoPort.configMenuElapsed = (OctoPort.configMenuElapsed or 0) + arg1
    if OctoPort.configMenuElapsed < 0.10 then return end
    OctoPort.configMenuElapsed = 0
    OctoPort:UpdateInputDiagnostics()
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
