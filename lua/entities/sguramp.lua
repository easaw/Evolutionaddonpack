/*   Copyright 2010 by Llapp   */
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "SGU Ramp"
ENT.Author = "Llapp"
ENT.Category = ""

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.IsRamp = true

if SERVER then

AddCSLuaFile();

ENT.SguRamps = {"models/boba_fett/ramps/sgu_ramp/sgu_ramp.mdl",
				"models/boba_fett/ramps/sgu_ramp/sgu_ramp_old.mdl",
				"models/boba_fett/ramps/sgu_ramp/sgu_ramp_small.mdl",
                "models/markjaw/sgu_ramp.mdl",
				"models/iziraider/sguramp/sgu_ramp.mdl"};

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS ) ;
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS );
	self.Entity:SetSolid( SOLID_VPHYSICS );
	local phys = self.Entity:GetPhysicsObject();
	if(phys:IsValid()) then
		phys:Wake();
		phys:SetMass(5000);
	end
	if(self.Entity:GetModel() == self.SguRamps[1] or self.Entity:GetModel() == self.SguRamps[2] or self.Entity:GetModel() == self.SguRamps[3])then return false end;
    self.Entity:Fire("skin",1);
end

function ENT:SpawnFunction(p,t)
	if(not t.Hit) then return end;
	local e = ents.Create("sguramp");
	e:SetPos(t.HitPos+Vector(0,0,150));
	e:DrawShadow(true);
	e:Spawn();
	return e;
end

function ENT:SguRampSkin(skin)
    local RampOffset = Lib.RampOffset.Gates[self.Entity:GetModel()]
	if(RampOffset and (self.Entity:GetModel() == self.SguRamps[1] or self.Entity:GetModel() == self.SguRamps[2] or self.Entity:GetModel() == self.SguRamps[3]))then
        if(skin == 2)then
            self.Entity:Fire("skin",skin);
	    elseif(skin == 1)then
	        self.Entity:Fire("skin",skin);
	    elseif(skin == 0)then
	        self.Entity:Fire("skin",skin);
	    end
	elseif(RampOffset and (self.Entity:GetModel() == self.SguRamps[4] or self.Entity:GetModel() == self.SguRamps[5]))then
	    if(skin == 1 or skin == 2)then
	        self.Entity:Fire("skin",0);
	    elseif(skin == 0)then
	        self.Entity:Fire("skin",1);
        end
	end
end

function ENT:PostEntityPaste(ply, Ent, CreatedEntities)
	if (Lib.NotSpawnable("anim_ramps",ply,"tool") ) then self.Entity:Remove(); return end
	if (IsValid(ply)) then
		local PropLimit = GetConVar("sbox_maxanim_ramps"):GetInt()
		if(ply:GetCount("Count_anim_ramps")+1 > PropLimit) then
			ply:SendLua("GAMEMODE:AddNotify(Lib.Language.GetMessage(\"stool_ramp_anim_limit\"), NOTIFY_ERROR, 5); surface.PlaySound( \"buttons/button2.wav\" )");
			self.Entity:Remove();
			return
		end
		ply:AddCount("Count_anim_ramps", self.Entity)
	end
end

if (Lib and Lib.EAP_GmodDuplicator) then
	duplicator.RegisterEntityClass( "sguramp", Lib.EAP_GmodDuplicator, "Data" )
end

end

if CLIENT then
ENT.RenderGroup = RENDERGROUP_BOTH

if (Lib.Language!=nil and Lib.Language.GetMessage!=nil) then
language.Add("sguramp",Lib.Language.GetMessage("ramp_kill"));
end

end