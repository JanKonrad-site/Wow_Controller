-- Always-visible center reticle with target state and health feedback.

local function CreateReticleTexture(parent, width, height, point, relativePoint, x, y)
  local texture = parent:CreateTexture(nil, "OVERLAY")
  texture:SetTexture("Interface\\Buttons\\WHITE8X8")
  texture:SetWidth(width)
  texture:SetHeight(height)
  texture:SetPoint(point, parent, relativePoint, x, y)
  return texture
end

function OctoPort:SetReticleColor(red, green, blue, alpha)
  if not self.reticleParts then return end
  for index = 1, table.getn(self.reticleParts) do
    self.reticleParts[index]:SetVertexColor(red, green, blue, alpha or 1)
  end
end

function OctoPort:CreateReticle()
  if self.reticleFrame then return end

  local frame = CreateFrame("Frame", "OctoPortReticle", UIParent)
  frame:SetWidth(128)
  frame:SetHeight(128)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetFrameStrata("HIGH")
  frame:EnableMouse(false)

  self.reticleParts = {
    CreateReticleTexture(frame, 28, 3, "RIGHT", "CENTER", -12, 0),
    CreateReticleTexture(frame, 28, 3, "LEFT", "CENTER", 12, 0),
    CreateReticleTexture(frame, 3, 28, "BOTTOM", "CENTER", 0, 12),
    CreateReticleTexture(frame, 3, 28, "TOP", "CENTER", 0, -12),
    CreateReticleTexture(frame, 5, 5, "CENTER", "CENTER", 0, 0),
  }

  local targetName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  targetName:SetWidth(190)
  targetName:SetPoint("TOP", frame, "BOTTOM", 0, -2)
  targetName:SetText("NO TARGET")

  local healthBackground = CreateFrame("Frame", nil, frame)
  healthBackground:SetWidth(94)
  healthBackground:SetHeight(8)
  healthBackground:SetPoint("TOP", targetName, "BOTTOM", 0, -3)
  healthBackground:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 4, edgeSize = 4,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  healthBackground:SetBackdropColor(0.02, 0.03, 0.04, 0.85)
  healthBackground:SetBackdropBorderColor(0.35, 0.38, 0.42, 0.90)

  local health = healthBackground:CreateTexture(nil, "ARTWORK")
  health:SetTexture("Interface\\Buttons\\WHITE8X8")
  health:SetHeight(4)
  health:SetWidth(90)
  health:SetPoint("LEFT", healthBackground, "LEFT", 2, 0)
  health:SetVertexColor(0.82, 0.16, 0.12, 1)

  self.reticleFrame = frame
  self.reticleTargetName = targetName
  self.reticleHealthBackground = healthBackground
  self.reticleHealth = health
  self:UpdateReticle(true)
end

function OctoPort:PulseReticle()
  self.reticlePulseUntil = GetTime() + 0.22
end

function OctoPort:UpdateReticle(force)
  if not self.reticleFrame or not self.config then return end

  if not self.config.reticleEnabled or (self.configFrame and self.configFrame:IsVisible()) then
    self.reticleFrame:Hide()
    return
  end

  self.reticleFrame:Show()
  local pulse = self.reticlePulseUntil and GetTime() < self.reticlePulseUntil
  self.reticleFrame:SetScale((self.config.reticleScale or 1) * (pulse and 1.14 or 1))
  self.reticleFrame:SetAlpha(pulse and 1 or 0.88)

  if not UnitExists("target") then
    self:SetReticleColor(0.55, 0.82, 0.86, 0.82)
    self.reticleTargetName:SetText("NO TARGET")
    self.reticleTargetName:SetTextColor(0.62, 0.72, 0.74)
    self.reticleHealthBackground:Hide()
    return
  end

  local hostile = UnitCanAttack("player", "target")
  if hostile then
    self:SetReticleColor(1.00, 0.22, 0.16, 1)
    self.reticleTargetName:SetTextColor(1.00, 0.30, 0.24)
    self.reticleHealth:SetVertexColor(0.88, 0.15, 0.10, 1)
  else
    self:SetReticleColor(0.24, 0.95, 0.43, 1)
    self.reticleTargetName:SetTextColor(0.30, 0.95, 0.45)
    self.reticleHealth:SetVertexColor(0.20, 0.82, 0.35, 1)
  end

  local name = UnitName("target") or "TARGET"
  self.reticleTargetName:SetText(string.upper(name))
  local health = UnitHealth and UnitHealth("target") or 0
  local maximum = UnitHealthMax and UnitHealthMax("target") or 0
  local ratio = maximum > 0 and health / maximum or 0
  if ratio < 0 then ratio = 0 end
  if ratio > 1 then ratio = 1 end
  self.reticleHealth:SetWidth(math.max(1, 90 * ratio))
  self.reticleHealthBackground:Show()
end

local reticleDriver = CreateFrame("Frame", "OctoPortReticleDriver", UIParent)
reticleDriver.elapsed = 0
reticleDriver:SetScript("OnUpdate", function()
  this.elapsed = this.elapsed + arg1
  if this.elapsed < 0.08 then return end
  this.elapsed = 0
  if OctoPort.reticleFrame then OctoPort:UpdateReticle(false) end
end)
