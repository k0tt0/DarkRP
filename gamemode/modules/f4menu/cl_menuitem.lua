local PANEL = {}

AccessorFunc(PANEL, "borderColor", "BorderColor")

/*---------------------------------------------------------------------------
Generic item
---------------------------------------------------------------------------*/
function PANEL:Init()
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)

	self:SetCursor("hand")

	self:SetFont("F4MenuFont1")
	self:SetTextColor(Color(255, 255, 255, 255))
	self:SetTall(60)
	self:DockPadding(0, 0, 10, 5)

	self.model = self.model or vgui.Create("ModelImage", self)
	self.model:SetSize(60, 60)
	self.model:SetPos(0, 0)

	self.txtRight = self.txtRight or vgui.Create("DLabel", self)
	self.txtRight:SetFont("F4MenuFont1")
	self.txtRight:Dock(RIGHT)
	self.txtRight:SetTextColor(Color(255, 255, 255, 255))
end

local black = Color(0, 0, 0, 255)
local gray = Color(140, 140, 140, 255)
local darkgray = Color(50, 50, 50, 255)
function PANEL:Paint(w, h)
	local disabled = self:GetDisabled()
	draw.RoundedBox(4, 0, 0, w, h, disabled and darkgray or black) -- background

	draw.RoundedBoxEx(4, h, h - 10, w - 60, 10, not disabled and (self:GetBorderColor() or black) or darkgray, false, false, false, true) -- the colored bar

	draw.RoundedBoxEx(4, 0, 0, h, h, disabled and darkgray or gray, true, false, false, false) -- gray box for the model
end

function PANEL:SetModel(mdl, skin)
	self.model:SetModel(mdl, skin, "000000000")
end

function PANEL:SetTextRight(text)
	self.txtRight:SetText(text)
	self.txtRight:SizeToContents()
	self.txtRight:Dock(RIGHT)
end

-- For overriding
function PANEL:setDarkRPItem(item)
	self.DarkRPItem = item
end

function PANEL:Refresh()

end

-- SetDisabled. Disables the button and hides it when the config options are set right
-- rules: always hide if hideNonBuyable, only hide items that have nothing to do with your situation (like items for another job) with hideTeamUnbuyable
function PANEL:SetDisabled(b, isImportant)
	self.m_bDisabled = b
	if GAMEMODE.Config.hideNonBuyable or (isImportant and GAMEMODE.Config.hideTeamUnbuyable) and b then
		self:SetVisible(false)
	else
		self:SetVisible(true)
	end
end

derma.DefineControl("F4MenuItemButton", "", PANEL, "DButton")

/*---------------------------------------------------------------------------
Job item
---------------------------------------------------------------------------*/
PANEL = {}

local function getMaxOfTeam(job)
	if not job.max or job.max == 0 then return "∞" end
	if job.max % 1 == 0 then return tostring(job.max) end

	return tostring(math.floor(job.max * #player.GetAll()))
end

local function canGetJob(job)
	local ply = LocalPlayer()

	if isnumber(job.NeedToChangeFrom) and ply:Team() ~= job.NeedToChangeFrom then return false, true end
	if istable(job.NeedToChangeFrom) and not table.HasValue(job.NeedToChangeFrom, ply:Team()) then return false, true end
	if job.customCheck and not job.customCheck(ply) then return false, true end
	if ply:Team() == job.team then return false, true end
	if job.max ~= 0 and ((job.max % 1 == 0 and team.NumPlayers(job.team) >= job.max) or (job.max % 1 ~= 0 and (team.NumPlayers(job.team) + 1) / #player.GetAll() > job.max)) then return false, false end
	if job.admin == 1 and not ply:IsAdmin() then return false, true end
	if job.admin > 1 and not ply:IsSuperAdmin() then return false, true end


	return true
end

function PANEL:setDarkRPItem(job)
	self.BaseClass.setDarkRPItem(self, job)

	self:SetBorderColor(job.color)
	self:SetModel(istable(job.model) and job.model[1] or job.model)
	self:SetText(job.name)
	self:SetTextRight(string.format("%s/%s", team.NumPlayers(job.team), getMaxOfTeam(job)))

	local canGet, important = canGetJob(job)
	self:SetDisabled(not canGet, important)
end

function PANEL:DoDoubleClick()
	if self:GetDisabled() then return end

	local job = self.DarkRPItem
	if job.vote or job.RequiresVote and job.RequiresVote(LocalPlayer(), job.team) then
		RunConsoleCommand("darkrp", "vote" .. job.command)
	else
		RunConsoleCommand("darkrp", job.command)
	end

	timer.Simple(1, fn.Partial(self:GetParent():GetParent().Refresh, self:GetParent():GetParent()))
end

function PANEL:Refresh()
	self:SetTextRight(string.format("%s/%s", team.NumPlayers(self.DarkRPItem.team), getMaxOfTeam(self.DarkRPItem)))

	local canGet, important = canGetJob(self.DarkRPItem)
	self:SetDisabled(not canGet, important)
end

derma.DefineControl("F4MenuJobButton", "", PANEL, "F4MenuItemButton")

/*---------------------------------------------------------------------------
custom entity button
---------------------------------------------------------------------------*/
PANEL = {}

function PANEL:setDarkRPItem(item)
	self.BaseClass.setDarkRPItem(self, item)
	self:SetBorderColor(Color(140, 0, 0, 180))
	self:SetModel(item.model)
	self:SetText(item.name)
	self:SetTextRight(string.format("%s%s", GAMEMODE.Config.currency, item.price))
end

derma.DefineControl("F4MenuEntityButton", "", PANEL, "F4MenuItemButton")

/*---------------------------------------------------------------------------
Button for purchasing guns
---------------------------------------------------------------------------*/
PANEL = {}

function PANEL:setDarkRPItem(item)
	self.BaseClass.setDarkRPItem(self, item)
	self:SetBorderColor(Color(140, 0, 0, 180))
	self:SetModel(item.model)
	self:SetText(item.name)
	self:SetTextRight(string.format("%s%s", GAMEMODE.Config.currency, item.pricesep))

	self.DoClick = fn.Partial(RunConsoleCommand, "DarkRP", "buy", self.DarkRPItem.name)
end

derma.DefineControl("F4MenuPistolButton", "", PANEL, "F4MenuItemButton")
