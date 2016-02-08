ENT.Base = "eap_base"
ENT.Type = "vehicle"
ENT.Spawnable = true

ENT.PrintName = Lib.Language.GetMessage('ent_ship_orims');
ENT.Author = ""
list.Set("EAP", ENT.PrintName, ENT);

--ENT.IsSGVehicleCustomView = true

if SERVER then

--########Header########--
AddCSLuaFile()

ENT.Model = Model("models/ship/ori.mdl")

ENT.Sounds = {
	Staff=Sound("weapons/ori_beam.wav"),
}

function ENT:SpawnFunction(ply, tr) --######## Pretty useless unless we can spawn it @RononDex
	if (!tr.HitWorld) then return end

	local PropLimit = GetConVar("Count_ships_max"):GetInt()
	if(ply:GetCount("Count_ships")+1 > PropLimit) then
		ply:SendLua("GAMEMODE:AddNotify(Lib.Language.GetMessage(\"entity_limit_ships\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
		return
	end

	local e = ents.Create("eap_ori")
	e:SetPos(tr.HitPos + Vector(0,0,750))
	e:SetAngles(ply:GetAngles())
	e:Spawn()
	e:Activate()
	e:SetWire("Health",e:GetNetworkedInt("health"));
	ply:AddCount("Count_ships", e)
	return e
end

function ENT:Initialize() --######## What happens when it first spawns(Set Model, Physics etc.) @RononDex
	self.BaseClass.Initialize(self);
	self.Vehicle = "OriMs"
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.EntHealth = 20000
	self:SetNetworkedInt("health",self.EntHealth)
	self:SetNetworkedInt("maxEntHealth",self.EntHealth)
	self:SetNWInt("CanFire",1)
	self:SetUseType(SIMPLE_USE)
	self:StartMotionController()

	--####### Attack vars
	self.LastBlast=0
	self.Delay=5
	self.CanShoot = true

	self.Shields = nil
	self.Shielded = false 

	--######### Flight Vars
	self.Accel = {}
	self.Accel.FWD = 0
	self.Accel.RIGHT = 0
	self.Accel.UP = 0
	self.ForwardSpeed = 1500
	self.BackwardSpeed = -750
	self.UpSpeed=600
	self.MaxSpeed = 2000
	self.RightSpeed = 750
	self.Accel.SpeedForward = 10
	self.Accel.SpeedRight = 7
	self.Accel.SpeedUp = 7
	self.RollSpeed = 5
	self.num = 0
	self.num2 = 0
	self.num3 =0
	self.Roll=0
	self.Hover=true
	self.GoesRight=true
	self.GoesUp=true
	self.CanRoll=true

	self.Target = Vector(0,0,0)

	self:CreateWireOutputs("Health","Can Shoot","Shooting");

	local phys = self:GetPhysicsObject()
	self:GetPhysicsObject():EnableMotion(false)

	if(phys:IsValid()) then
		phys:Wake()
		phys:SetMass(10000)
	end
end

function ENT:Think()

	self.BaseClass.Think(self);
	self.ExitPos = self:GetPos()+self:GetForward()*175;
	self:SetWire("Can Shoot",self.CanShoot)

	if(self.EntHealth <= 500)then
		self.CanShoot = false
		self:SetNWInt("CanFire",0)
	end

	if(timer.Exists("CanShootOri")) then
		self:SetNWInt("WeaponsTimer",timer.TimeLeft("CanShootOri"))
	end

	if(IsValid(self.Pilot)) then
		if(self.Pilot:KeyDown(self.Vehicle,"FIRE")) then
			local Entities = ents.FindInSphere(self:GetPos(),2000)
			if(Entities)then
				for _,v in pairs(Entities) do
					if(v:GetClass()==("Player" or "eap_ori"))then
						self.Target = v:GetPos()
					end
				end	
			end
			if(self.CanShoot) then
				local trace = {}
					trace.start = self.Pilot:GetPos();
					trace.endpos = self.Pilot:GetAimVector() * 10^14;
					trace.filter = {self.Entity, self.Pilot};
				local tr = util.TraceLine(trace);
				self:FireBlast(tr.HitPos);
			end
		end
	end
end

function ENT:OnRemove()
	if timer.Exists("CanShootOri"..self:EntIndex()) then timer.Destroy("CanShootOri"..self:EntIndex()); end
	self.BaseClass.OnRemove(self)
end

function ENT:OnTakeDamage(dmg) --########## Gliders aren't invincible are they? @RononDex

	local health=self:GetNetworkedInt("health")
	self:SetNetworkedInt("health",health-(dmg:GetDamage())) -- Sets heath(Takes away damage from health)
	self:SetWire("Health",health-dmg:GetDamage());

	if((health-dmg:GetDamage())<=0) then
		self:Bang() -- Go boom
	end
end

function ENT:FireBlast(target)
	local FiringPos = self:GetPos()+(self:GetForward()*1500)-Vector(0,0,500);
	local ShootDir = (self.Target - FiringPos):GetNormal();

	local trace = {}
		trace.start = self:GetAngles():Forward()*50;
		trace.endpos = target;
	local tr = util.TraceLine( trace );
	if(self.CanShoot) then
		if (!tr.Entity or tr.Entity != self.Entity) then
			self:SetWire("Shooting",1)
			local ShootDir = (target - self:GetPos()):GetNormal();
			local ent = ents.Create("energy_beam2");
			ent.Owner = self.Entity;
			ent:SetPos(FiringPos);
			ent:Spawn();
			ent:Activate();
			ent:SetOwner(self.Entity);
			ent:Setup(FiringPos,ShootDir,1200,1.5,"Ori");
			self:EmitSound(self.Sounds.Staff,90,math.random(90,110))
			self.CanShoot = false
			self.Target = Vector(0,0,0)
			self:SetNWInt("CanFire",0)
			self:SetWire("Shooting",0)
			timer.Create("CanShootOri"..self:EntIndex(),self.Delay,0,function()
				if(not self.CanShoot)then
					self.CanShoot = true
					self:SetNWInt("CanFire",1)
				end
			end)
		end
	end
end

end

if CLIENT then

if (Lib.Language!=nil and Lib.Language.GetMessage!=nil) then
ENT.Category = Lib.Language.GetMessage("cat_ship");
ENT.PrintName = Lib.Language.GetMessage('ent_ship_orims');
end
ENT.RenderGroup = RENDERGROUP_BOTH

if (Lib==nil or Lib.KeyBoard==nil or Lib.KeyBoard.New==nil) then return end

--########## Keybinder stuff
local KBD = Lib.KeyBoard:New("OriMs")
--Navigation
KBD:SetDefaultKey("FWD",Lib.KeyBoard.BINDS["+forward"] or "W") -- Forward
KBD:SetDefaultKey("LEFT",Lib.KeyBoard.BINDS["+moveleft"] or "A")
KBD:SetDefaultKey("RIGHT",Lib.KeyBoard.BINDS["+moveright"] or "D")
KBD:SetDefaultKey("BACK",Lib.KeyBoard.BINDS["+back"] or "S")
KBD:SetDefaultKey("UP",Lib.KeyBoard.BINDS["+jump"] or "SPACE")
KBD:SetDefaultKey("DOWN",Lib.KeyBoard.BINDS["+duck"] or "CTRL")
KBD:SetDefaultKey("SPD",Lib.KeyBoard.BINDS["+speed"] or "SHIFT")
--Roll
KBD:SetDefaultKey("RL","MWHEELDOWN") -- Roll left
KBD:SetDefaultKey("RR","MWHEELUP") -- Roll right
KBD:SetDefaultKey("RROLL","MOUSE3") -- Reset Roll
--Attack
KBD:SetDefaultKey("FIRE",Lib.KeyBoard.BINDS["+attack"] or "MOUSE1")
KBD:SetDefaultKey("TRACK",Lib.KeyBoard.BINDS["+attack2"] or "MOUSE2")
--Special Actions
KBD:SetDefaultKey("BOOM","BACKSPACE")
--View
KBD:SetDefaultKey("VIEW","1")
KBD:SetDefaultKey("Z+","UPARROW")
KBD:SetDefaultKey("Z-","DOWNARROW")
KBD:SetDefaultKey("A+","LEFTARROW")
KBD:SetDefaultKey("A-","RIGHTARROW")

KBD:SetDefaultKey("EXIT",Lib.KeyBoard.BINDS["+use"] or "E")

ENT.Sounds={
	Engine=Sound("eap/ship/moteur/wraithcruiser.wav"),
}

function ENT:Initialize( )
	self.BaseClass.Initialize(self)
	self.Dist=-750
	self.UDist=120
	self.KBD = self.KBD or KBD:CreateInstance(self)
	self.FirstPerson=false
	self.Vehicle = "OriMs"
end

--[[

function SGGGCalcView(Player, Origin, Angles, FieldOfView)
	local view = {}
	--self.BaseClass.CalcView(self,Player, Origin, Angles, FieldOfView)
	local p = LocalPlayer()
	local self = p:GetNetworkedEntity("ScriptedVehicle", NULL)

	if(IsValid(self) and self:GetClass()=="sg_vehicle_gate_glider") then
		if(self.FirstPerson) then
			local pos = self:GetPos()+self:GetUp()*20+self:GetForward()*70;
			local angle = self:GetAngles( );
				view.origin = pos		;
				view.angles = angle;
				view.fov = FieldOfView + 20;
			return view;
		else
			local pos = self:GetPos()+self:GetUp()*self.Udist+Player:GetAimVector():GetNormal()*-self.Dist;
			local face = ( ( self.Entity:GetPos() + Vector( 0, 0, 100 ) ) - pos ):Angle() + Angle(0,180,0);
				view.origin = pos;
				view.angles = face;
			return view;
		end
	end
end
hook.Add("CalcView", "SGGGCalcView", SGGGCalcView)
]]--

--######## Mainly Keyboard stuff @RononDex
function ENT:Think()

	self.BaseClass.Think(self)

	local p = LocalPlayer()
	local GateGlider = p:GetNetworkedEntity("ScriptedVehicle", NULL)

	if((GateGlider)and((GateGlider)==self)and(GateGlider:IsValid())) then
		self.KBD:SetActive(true)
	else
		self.KBD:SetActive(false)
	end

	if((GateGlider)and((GateGlider)==self)and(GateGlider:IsValid())) then
		if(p:KeyDown("Ori","Z+")) then
			self.Dist = self.Dist-5
		elseif(p:KeyDown("Ori","Z-")) then
			self.Dist = self.Dist+5
		end

		if(p:KeyDown("Ori","VIEW")) then
			if(self.FirstPerson) then
				self.FirstPerson=false
			else
				self.FirstPerson=true
			end
		end

		if(p:KeyDown("Ori","A+")) then
			self.UDist=self.UDist+5
		elseif(p:KeyDown("Ori","A-")) then
			self.UDist=self.UDist-5
		end
	end
end
end