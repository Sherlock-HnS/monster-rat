if SERVER then
else
end

if !pcall(require,"pk_pills") then
    if SERVER then
        hook.Add("PlayerInitialSpawn","pk_pill_extfail_cl",function(ply)
            if game.SinglePlayer() || ply:IsListenServerHost() then
                ply:SendLua('notification.AddLegacy("One or more pill extensions failed to load. Did you forget to install Parakeet\'s Pill Pack?",NOTIFY_ERROR,30)')
            end
        end)
        hook.Add("Initialize","pk_pill_extfail_sv",function(ply)
            print("[ALERT] One or more pill extensions failed to load. Did you forget to install Enhanced Parakeet's Pill Base?")
        end)
    end
    return
end

AddCSLuaFile()
include("include/gennytoi_pillrat_fnac.lua")

hook.Add("SetupMove", "DisablePlayerMovement_gennytoi_pillrat_fnac", function(ply, mv, cmd)
    if ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac1") >= CurTime() or ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2") >= CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end

    if ply:GetNWFloat("NoJump_gentoi_rat") > CurTime() then
        mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    end
end)

hook.Add("StartCommand", "DisablePlayerMovement_gennytoi_pillrat_fnac", function(ply, cmd)
    if ply:GetNWFloat("NoJump_gentoi_rat") > CurTime() then
        cmd:RemoveKey(IN_JUMP)
    end
    if ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac1") >= CurTime() or ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2") >= CurTime() then
        cmd:ClearMovement()
    end
end)

if CLIENT then
--

end

local thinkcode = function(thinktable)


    local self = thinktable.self
    local ent = thinktable.ent


    local currentanim = 'idle'
    local ply = self:GetPillUser()
    local puppet = self:GetPuppet()
    if not IsValid(puppet) or not IsValid(ply) then return end
    local vel = ply:GetVelocity():Length()

    if not self.intializeangle then
        self.intializeangle = true
        local angle = ply:GetAngles()
        angle.p = 0
        if SERVER then puppet:SetAngles(angle) end
        if CLIENT then puppet:SetRenderAngles(angle) end
    end

    if SERVER then
        --Anims
        local anims = table.Copy(self.formTable.anims.default or {})
        table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
        local anim
        --local useSeqVel=true
        local overrideRate

        if (not self.anim or not anims[self.anim]) then
            self.animFreeze = nil
            self.animStart = nil
        end

        if self.animFreeze and not self.plyFrozen then
            self.plyFrozen = true
        elseif not self.animFreeze and self.plyFrozen then
            local speed = self.formTable.moveSpeed or {}
            self.plyFrozen = nil
        end

        if self.anim and anims[self.anim] then
            anim = anims[self.anim]
            overrideRate = anims[self.anim .. "_rate"] or 1
            local cycle = puppet:GetCycle()

            if not self.animStart then
                if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                    self.anim = nil
                    self.animCycle = nil

                    --if self.animFreeze then
                    --    self.animFreeze = nil
                    --end
                elseif self.animCycle then
                    self.animCycle = cycle
                end
            end
        elseif self.tickAnim and anims[self.tickAnim] then
            anim = anims[self.tickAnim]
            overrideRate = anims[self.tickAnim .. "_rate"] or 1
            self.tickAnim = nil
        elseif self.burrowed then
            anim = anims["burrow_loop"]
        elseif ply:WaterLevel() > 2 then
            anim = anims["swim"] or anims["glide"] or anims["idle"]
        elseif ply:IsOnGround() then
            if ply:Crouching() then
                if vel > ply:GetCrouchedWalkSpeed() / 4 then
                    anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                else
                    anim = anims["crouch"] or anims["idle"]
                end
            else
                if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                    anim = anims["run"] or anims["walk"] or anims["idle"]
                elseif vel > ply:GetWalkSpeed() / 4 then
                    anim = anims["walk"] or anims["idle"]
                else
                    anim = anims["idle"]
                end
            end
        else
            anim = anims["glide"] or anims["idle"]
        end

        if anim == anims["idle"] or anim == anims["crouch"] then
            overrideRate = 1
        end
        self:SetNW2String("Animlastplayed", anim)

        local ShouldAlternate = table.Copy(self.formTable.anims.ShouldAlternate or {})
        if type(ShouldAlternate[anim]) == "function" and ShouldAlternate[anim](self) then
            if ShouldAlternate[anim](self) ~= nil and isstring(ShouldAlternate[anim](self)) then
                anim = ShouldAlternate[anim](self)
            end
        end
        
        --print(self.animFreeze)

        if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then
            if self.currentanim ~= puppet:GetSequence() then
                if not animFreeze then 
                    puppet:ResetSequence(puppet:LookupSequence(anim))
                    puppet:SetCycle(0)
                    self.animCycle = 0
                    self.currentanim = anim
                end
            end
        end


        self.animStart = nil

        --Aimage
        if self.formTable.aim and not self.ShouldPoseParameter then
            self.SmoothYaw = self.SmoothYaw or 0
            self.SmoothPitch = self.SmoothPitch or 0

            local yaw = math.AngleDifference(
                ply:EyeAngles().y,
                puppet:GetAngles().y
            )

            local pitch = math.AngleDifference(
                ply:EyeAngles().p,
                puppet:GetAngles().p
            )

            self.SmoothYaw = Lerp(FrameTime() * 10, self.SmoothYaw, yaw)
            self.SmoothPitch = Lerp(FrameTime() * 10, self.SmoothPitch, pitch)

            puppet:SetPoseParameter(self.formTable.aim.xPose, self.SmoothYaw)
            puppet:SetPoseParameter(self.formTable.aim.yPose, self.SmoothPitch)
        end

        --tick attack
        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
            self.formTable.attack.func(ply, self, self.formTable.attack)
        end

        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
            self.formTable.attack2.func(ply, self, self.formTable.attack2)
        end

        --if !IsValid(ply) then self:NextThink(CurTime()) return true end
        --wepon-no longer SO hackey
        if not self.formTable.hideWeapons then
            local realWep = self:GetPillUser():GetActiveWeapon()

            --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
            if IsValid(realWep) and realWep:GetModel() ~= "" then
                --hiding the real thing [BROKEN]
                --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                    realWep:SetRenderMode(RENDERMODE_NONE)
                end]]
                if realWep.pill_attachment then
                    if IsValid(self.wepmdl) then
                        self.wepmdl:Remove()
                    end

                    self.wepmdl = ents.Create("pill_attachment_wep")
                    self.wepmdl:SetParent(self:GetPuppet())
                    self.wepmdl:SetModel(realWep:GetModel())
                    self.wepmdl.attachment = realWep.pill_attachment
                    self.wepmdl:Spawn()

                    if realWep.pill_offset then
                        self.wepmdl:SetWepOffset(realWep.pill_offset)
                    end

                    if realWep.pill_angle then
                        self.wepmdl:SetWepAng(realWep.pill_angle)
                    end

                    realWep.pill_proxy = self.wepmdl
                elseif not IsValid(self.wepmdl) then
                    self.wepmdl = ents.Create("pill_attachment_wep")
                    self.wepmdl:SetParent(self:GetPuppet())
                    self.wepmdl:SetModel(realWep:GetModel())
                    self.wepmdl:Spawn()
                    realWep.pill_proxy = self.wepmdl
                elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                    self.wepmdl:SetModel(realWep:GetModel())
                end
            elseif IsValid(self.wepmdl) then
                self.wepmdl:Remove()
            end
        end
    else
        if self:GetPillUser() ~= LocalPlayer() or pk_pills.convars.cl_thirdperson:GetBool() then
            puppet:SetNoDraw(false)
        else
            puppet:SetNoDraw(true)
        end

        local realWep = self:GetPillUser():GetActiveWeapon()

        if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
            realWep:SetNoDraw(true)
        end
    end

    --Align pos and angles with player

    local animsshouldspn = table.Copy(self.formTable.anims.ShouldPosition or {})
    local SetPosition

    if animsshouldspn[currentanim] or (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) then
        local typeofitem = (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) or animsshouldspn[currentanim]

        local CurrentPos

        if SERVER then CurrentPos = puppet:GetPos() else CurrentPos = puppet:GetRenderOrigin() end

        local lerpspeed = 7

        local animsshouldspnLerpSpeed = table.Copy(self.formTable.anims.ShouldPosition_lerpspeed or {})
        if animsshouldspnLerpSpeed[currentanim] or (type(animsshouldspnLerpSpeed[currentanim]) == "function" and animsshouldspnLerpSpeed[currentanim](self)) then
            lerpspeed = (type(animsshouldspnLerpSpeed[currentanim]) == "function" and animsshouldspnLerpSpeed[currentanim](self)) or animsshouldspnLerpSpeed[currentanim]
        end

        if isvector(typeofitem) then
            SetPosition = LerpVector(FrameTime() * lerpspeed, CurrentPos, typeofitem)
        end
    end
    if not SetPosition then
        if SERVER then puppet:SetPos(ply:GetPos()) else puppet:SetRenderOrigin(ply:GetPos()) end
    else
        if SERVER then puppet:SetPos(CurrentPos) else puppet:SetRenderOrigin(CurrentPos) end
    end
    
    currentanim = self:GetNW2String("Animlastplayed")
    
    --if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 then

    local animsshouldspn = table.Copy(self.formTable.anims.ShouldMoveRotate or {})
    
    if SERVER then
        local rate = 1
        local animsshouldspn = table.Copy(self.formTable.anims.animrates or {})
        if animsshouldspn[currentanim] or (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) then
            rate = (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) or animsshouldspn[currentanim]
        end
        if rate > 12 then
            rate = 12
        end
        puppet:SetPlaybackRate(rate)
    end
    
    if animsshouldspn[currentanim] or (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) then
        local typeofitem = (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) or animsshouldspn[currentanim]

        local SetAngleto
        local curAng

        local lerpspeed = 7

        local animsshouldspnLerpSpeed = table.Copy(self.formTable.anims.ShouldMoveRotate_lerpspeed or {})
        if animsshouldspnLerpSpeed[currentanim] or (type(animsshouldspnLerpSpeed[currentanim]) == "function" and animsshouldspnLerpSpeed[currentanim](self)) then
            lerpspeed = (type(animsshouldspnLerpSpeed[currentanim]) == "function" and animsshouldspnLerpSpeed[currentanim](self)) or animsshouldspnLerpSpeed[currentanim]
        end

        local lerpfactor = math.min(FrameTime() * lerpspeed, 1)

        if SERVER then curAng = puppet:GetAngles() else curAng = puppet:GetRenderAngles() or Angle(0,0,0) end
        if typeofitem == "notshftlock" then
            local vel = ply:GetVelocity()
            vel.z = 0
            if vel:Length2DSqr() > 1 then
                local targetAng = vel:Angle()
                targetAng.p = 0
                targetAng.r = 0

                SetAngleto = LerpAngle(lerpfactor, curAng, targetAng)
            end
        elseif typeofitem == "assignedagnles_instant" then SetAngleto = self:GetNW2Angle("pill_assignedangle")
        elseif typeofitem == "shiftlock" then
            local angs = ply:EyeAngles()
            angs.p = 0
            SetAngleto = LerpAngle(lerpfactor, curAng, angs)
        elseif typeofitem == "Playerangles" then
            local angs = ply:GetAngles()
            angs.p = 0
            SetAngleto = LerpAngle(lerpfactor, curAng, angs)
        elseif typeofitem == "assignedagnles" then SetAngleto = LerpAngle(lerpfactor, curAng, self:GetNW2Angle("pill_assignedangle"))
        elseif typeofitem == "notanything" then SetAngleto = curAng
        end

        if SetAngleto then
            if SERVER then puppet:SetAngles(SetAngleto) end
            if CLIENT then puppet:SetRenderAngles(SetAngleto) end
        end
    end

    if self.formTable.think_noodles_gentoi_rat_pill then
        self.formTable.think_noodles_gentoi_rat_pill(ply, ent)
    end
end

if SERVER then
    util.AddNetworkString("clientside_thinkcodeinitialize_OM_rat_gentoi")
else




    net.Receive("clientside_thinkcodeinitialize_OM_rat_gentoi", function()
        local ply = LocalPlayer()
        local ent = net.ReadEntity()

        ent.Think = function()
            thinkcode({
                self = ent,
                ent = ent,
            })

            ent:NextThink(CurTime())
            return ent
        end
    end)
end

hook.Add("OnEntityCreated", "rat_gentoi_noodles_pill_initialize", function(ent)
    timer.Simple(0, function()
        if !IsValid(ent) then return end
        if ent:GetClass() == "pill_ent_costume" then
            if not ent then return end
            if ent.formTable then
                local PuppetEntity = ent:GetPuppet()
                local entityply = ent:GetPillUser()
                local hookName = "ThinkHookForEntity_OM_" .. ent:EntIndex()

                if ent.formTable.HandleAnimEvent_Noodles_gentoi_rat_pill then
                    local PuppetEntity = ent:GetPuppet()
                    local entityply = ent:GetPillUser()

                    if IsValid(PuppetEntity) then
                        function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                            ent.formTable.HandleAnimEvent_Noodles_gentoi_rat_pill(entityply, ent, inputName)
                            return true
                        end
                    end
                end

                local tablevarable = {["player"] = entityply, ["entity"] = ent, ["puppet"] = PuppetEntity}
                local name = "MutePlayerFootsteps"..entityply:EntIndex()

                if ent.formTable.onremove_noodles_gentoi_rat_pill then
                    ent:CallOnRemove("RemoveHook_OM"..ent:EntIndex(), function()
                        hook.Remove("PlayerFootstep", name)
                        ent.formTable:onremove_noodles_gentoi_rat_pill(tablevarable,tablevarable,tablevarable)
                    end)
                end

                if ent.formTable.initialize_noodles_gentoi_rat_pill then
                    timer.Simple(0.1, function()
                        if !IsValid(ent) then return end
                        hook.Add("PlayerFootstep", name, function(ply, pos, foot, sound, volume, filter)
                            if ply == entityply then
                                return true
                            end
                        end)

                        ent.PillAnim = function(e,name, freeze)
                            local anims = table.Copy(ent.formTable.anims.default or {})
                            table.Merge(anims, (IsValid(entityply:GetActiveWeapon()) and ent.formTable.anims[entityply:GetActiveWeapon():GetHoldType()]) or (ent.forceAnimSet and ent.formTable.anims[ent.forceAnimSet]) or {})
                            if not anims[name] then return end

                            ent.anim = name
                            ent.animStart = true
                            ent.animFreeze = true
                        end

                        PuppetEntity.SetupDataTables = function()
                            PuppetEntity:NetworkVar("String", 0, "PillForm")
                            PuppetEntity:NetworkVar("Entity", 1, "PillCostume")
                            PuppetEntity:NetworkVar("Entity", 2, "PillUser")
                        end

                        PuppetEntity.Initialize = function()
                            PuppetEntity:SetRenderMode(RENDERMODE_TRANSALPHA)
                        end

                        PuppetEntity.Draw = function()
                            PuppetEntity:DrawModel()
                        end

                        PuppetEntity.DrawTranslucent = function()
                            PuppetEntity:Draw()
                        end
                        
                        PuppetEntity.QueueEvent = function()
                        end

                        PuppetEntity.RunAI = function()
                        end

                        ent.formTable:initialize_noodles_gentoi_rat_pill(tablevarable,tablevarable,tablevarable)

                        local self = ent
                        self.formTable = pk_pills.getPillTable(self:GetPillForm())
                        local ply = self:GetPillUser()

                        if not self.formTable or not IsValid(ply) then
                            self:Remove()

                            return
                        end

                        local hull = self.formTable.hull or Vector(32, 32, 72)
                        local duckBy = self.formTable.duckBy or (self.formTable.hull and 0 or 36)
                        ply:SetHull(-Vector(hull.x / 2, hull.y / 2, 0), Vector(hull.x / 2, hull.y / 2, hull.z))
                        ply:SetHullDuck(-Vector(hull.x / 2, hull.y / 2, 0), Vector(hull.x / 2, hull.y / 2, hull.z - duckBy or 0))--
                        ply:SetRenderMode(RENDERMODE_NONE)
                        pk_pills.mapEnt(ply, nil)

                        if SERVER then
                            if ply:FlashlightIsOn() then
                                ply:Flashlight(false)
                            end

                            ply:Freeze(false)
                            ply:SetNotSolid(false)
                            ply:DrawViewModel(false)

                            local camOffset = Vector(0, 0, 64) --
                            --clside this?
                            ply:SetStepSize(hull.z / 4)
                            ply:SetViewOffset(camOffset)
                            ply:SetViewOffsetDucked(camOffset - Vector(0, 0, duckBy*0.15) )
                        end
                        pk_pills.mapEnt(ply, self)

                    end)

                    local self = ent

                    ent.DoKeyPress = function(_, ply, key)
                        if key == IN_ATTACK and self.formTable.attack and self.formTable.attack.mode == "trigger" then
                            self.formTable.attack.func(ply, self, self.formTable.attack)
                        end
                        if key == IN_ATTACK2 and self.formTable.attack2 and self.formTable.attack2.mode == "trigger" then
                            self.formTable.attack2.func(ply, self, self.formTable.attack2)
                        end
                        if key == IN_RELOAD and self.formTable.reload then
                            self.formTable.reload(ply, self)
                        end
                        if key == IN_DUCK then
                        end
                    end

                    local ply = self:GetPillUser()
                    if SERVER then

                        ent.Think = function()
                            thinkcode({
                                self = self,
                                ent = ent,
                            })

                            self:NextThink(CurTime())
                            return true
                        end
                        timer.Simple(0.1,function()
                            if !IsValid(ent) then return end
                            net.Start("clientside_thinkcodeinitialize_OM_rat_gentoi")
                                net.WriteEntity(ent)
                            net.Broadcast()
                        end)
                    end
                end
            end
        end
    end)
end)

if SERVER then
    util.AddNetworkString("OM_gentoi_rat_CameraCode_n")
    util.AddNetworkString("OM_gentoi_rat_flash")
    util.AddNetworkString('OM_gentoi_rat_jumpscarecam')
    util.AddNetworkString('OM_gentoi_rat_deathscreen')
    util.AddNetworkString("OM_gentoi_rat_PlayGlobalSound")

else

    net.Receive("OM_gentoi_rat_PlayGlobalSound", function()
        surface.PlaySound("gentoi/rat/Shadow Rat Ping.wav")
    end)


	net.Receive('OM_gentoi_rat_jumpscarecam', function()
		local ent = net.ReadEntity()
		local state = net.ReadBool()
		local startTime = CurTime()
	
		local hookID = "gentoi_rat_jumpscarecam_" .. LocalPlayer():SteamID()
	
		if not state then
			hook.Remove('CalcView', hookID)
		else
			hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
				if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
					hook.Remove('CalcView', hookID)
					if IsValid(ply) then
						ply:RemoveFlags(FL_NOTARGET)
						ply:Freeze(false)
						ply:DrawViewModel(true)
					end
					return
				end
	
				local cam = ent:GetAttachment(ent:LookupAttachment('camera'))
	
				ply:AddFlags(FL_NOTARGET)
				ply:Freeze(true)
				ply:DrawViewModel(false)
	
				local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
				
				local targetFOV = 80 
	
				local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos+Vector(0,0,5))
				local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
				local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)
	
				local view = {
					origin = orgiginlerpto,
					angles = angleslerpto,
					fov = interpolatedFOV,
					drawviewer = false
				}
				return view
			end)
		end
	end)
	
	net.Receive("OM_gentoi_rat_flash", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
	
		local function FlashInOut(fadeTime, holdTime)
			ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), fadeTime, holdTime)
	
			timer.Simple(fadeTime + holdTime, function()
				if IsValid(ply) then
					ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), fadeTime, 0)
				end
			end)
		end
	
		FlashInOut(0.15, 0.075)
	
		timer.Simple(0.2, function()
			if IsValid(ply) then
				FlashInOut(0.15, 0.075)
			end
		end)
	
		timer.Simple(0.3, function()
			if IsValid(ply) then
				ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 0.2, 2)
			end
		end)
	end)
	
	
	net.Receive("OM_gentoi_rat_flash", function()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
	
		local function FlashInOut(fadeTime, holdTime)
			ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0, 255), fadeTime, holdTime)
	
			timer.Simple(fadeTime + holdTime, function()
				if IsValid(ply) then
					ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), fadeTime, 0)
				end
			end)
		end
	
		FlashInOut(0.15, 0.075)
	
		timer.Simple(0.2, function()
			if IsValid(ply) then
				FlashInOut(0.15, 0.075)
			end
		end)
	
		timer.Simple(0.3, function()
			if IsValid(ply) then
				ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 0.2, 2)
			end
		end)
	end)
	
	net.Receive("OM_gentoi_rat_CameraCode_n", function()
	
		local ply = LocalPlayer()
		local ent = net.ReadEntity()
	
		timer.Simple(0,function()
			if !IsValid(ent) then return end
	
			local savedCalcViewHooks = {}
	
			local calcViewHooks = hook.GetTable().CalcView or {}
			for k, v in pairs(calcViewHooks) do
				if k ~= hookID then
					savedCalcViewHooks[k] = v
					hook.Remove("CalcView", k)
				end
			end
	
			local name6 = "momo_calcview_".. ply:Nick()
			local name5 = "gentoi_remove_n_".. ply:Nick()
			hook.Add("EntityRemoved", name5, function(removedent)
				if removedent == ent then
					hook.Remove('CalcView', name6)
					hook.Remove("EntityRemoved", name5)
					for savedID, func in pairs(savedCalcViewHooks) do
						hook.Add("CalcView", savedID, func)
					end
					savedCalcViewHooks = {}
				end
			end)
			
			local lastID = nil
			local lastOrigin = nil
			local lastFOV = nil
			local transitionStart = 0
			local transitionTime = 0.25
			
			local mins = Vector(-5,-5,-5)
			local maxs = Vector(5,5,5)
	
			hook.Add("CalcView", name6, function(ply, pos, ang, fov)
				local ent = pk_pills.getMappedEnt(ply)
				if not IsValid(ent) or ply:GetViewEntity() ~= ply then return end
	
				local currentOMTable = ent.formTable.OM_cameratable(ply, ent)
				if not currentOMTable then return end
	
				if lastID ~= currentOMTable.id then
					lastID = currentOMTable.id
					transitionStart = CurTime()
					lastOrigin = lastOrigin or pos
					lastFOV = lastFOV or fov
				end
	
				if transitionTime ~= currentOMTable.transition then
					transitionTime = currentOMTable.transition
				end
	
				local up = ang:Up() * currentOMTable.startoffset.z
				local right = ang:Right() * currentOMTable.startoffset.x
				local forward = ang:Forward() * currentOMTable.startoffset.y
				local startpos = ply:GetPos() + up + right + forward
				
				local puppet = ent:GetPuppet()
				
				if currentOMTable.bonecenter and currentOMTable.bonehelper then
					-- Pelvis bone
					local boneID = puppet:LookupBone(currentOMTable.bonecenter)
					local bonePos, boneAng = puppet:GetBonePosition(boneID)
					
					-- Chest bone
					local bone2ID = puppet:LookupBone(currentOMTable.bonehelper)
					local bone2Pos, bone2Ang = puppet:GetBonePosition(bone2ID)
					
					local mergedPos = bonePos + (bone2Pos - bonePos) * 0.5
					
					startpos = mergedPos
				elseif currentOMTable.bonecenter then
					local boneID = puppet:LookupBone(currentOMTable.bonecenter)
					local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
					startpos = bonePos
				end
				
				startpos = startpos + up + right + forward
	
				if pk_pills.convars.cl_thirdperson:GetBool() then
					local dist = currentOMTable.dist
					local offset = ang:Forward() * -dist
	
					local tr = util.TraceHull({
						start = startpos,
						endpos = startpos + offset,
						filter = ent.camTraceFilter,
						mins = mins,
						maxs = maxs,
						mask = MASK_VISIBLE
					})
	
					local targetOrigin = tr.HitPos
					local targetFOV = currentOMTable.fov
	
					local t = math.Clamp((CurTime() - transitionStart) / transitionTime, 0, 1)
	
					local smoothOrigin = LerpVector(t, lastOrigin, targetOrigin)
					local smoothFOV = Lerp(t, lastFOV, targetFOV)
	
					lastOrigin = smoothOrigin
					lastFOV = smoothFOV
	
					return {
						origin = smoothOrigin,
						angles = ang,
						fov = smoothFOV,
						drawviewer = true
					}
				end
			end)
		end)
	end)





    local preservedmats = {
        ["RATABIL1"] = Material("gentoi/rat/RATABIL1.png"),
        ["RATABIL1SHADOW"] = Material("gentoi/rat/RATABIL1SHADOW.png"),
        ["RATSCREEN"] = Material("gentoi/rat/RATSCREEN1_edit_test.png"),
        ["RATSCREENSHADOW"] = Material("gentoi/rat/RATSCREENSHADOW_edit_test.png"),
        ["SHADOWRATICONGMOD"] = Material("gentoi/rat/SHADOWRATICONGMOD.png"),
        ["RATICONGMOD"] = Material("gentoi/rat/RATICONGMOD.png"),

        ["MONSTERRATBG"] = Material("gentoi/rat/MONSTERRATBG.png"),
        ["MONSTERRATICONUI"] = Material("gentoi/rat/MONSTERRATICONUI.png"),
        ["MONSTERRATTEXTUI"] = Material("gentoi/rat/MONSTERRATTEXTUI.png"),
        ["MONSTERRATABILITYINFOUI"] = Material("gentoi/rat/MONSTERRATABILITYINFOUI.png"),
        ["MONSTERRATABILITYICONUI"] = Material("gentoi/rat/MONSTERRATABILITYICONUI.png"),
    }

    local preservedmats2 = {}
    for i = 0, 29 do
        local frame = string.format("frame_%02d_delay-0.07s", i)
        preservedmats2[i] = Material("gentoi/rat/frames/" .. frame .. ".png")
    end

    local old = "Normal"

    surface.CreateFont("CreditsText_Large_rat", {
        font = "Arial",
        size = 70,
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("OM_SlashKey", {
        font = "Roboto",
        size = 32,
        weight = 700,
        antialias = true
    })



    local currentFrame = 0
    local nextFrameTime = 0
    local jumpscareenabled = false

    net.Receive("OM_gentoi_rat_deathscreen", function()
        jumpscareenabled = true
        currentFrame = 0
        nextFrameTime = CurTime() + 0.07

        RunConsoleCommand("stopsound")

        timer.Simple(0.1, function()
            if !IsValid(LocalPlayer()) then return end
            surface.PlaySound("gentoi/rat/jumpscaresound.wav")
        end)
    end)

    hook.Add("HUDPaint", "gent_rat_hudpaint_fnac", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if jumpscareenabled then
            if CurTime() >= nextFrameTime then
                currentFrame = currentFrame + 1
                nextFrameTime = nextFrameTime + 0.07

                if currentFrame >= 29 then
                    jumpscareenabled = false
                    return
                end
            end

            local mat = preservedmats2[currentFrame]
            print(mat)
            if mat then
                surface.SetDrawColor(255, 255, 255)
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
            end
        end

        if not ply.RatScrenTransition then ply.RatScrenTransition = 0 end

        if ply:GetNWFloat("gent_rat_hudpaint_border_normal") > CurTime() or ply:GetNWFloat("gent_rat_hudpaint_border_shadow") > CurTime() then
            ply.RatScrenTransition = Lerp(FrameTime()*2, ply.RatScrenTransition, 1)
            if ply:GetNWFloat("gent_rat_hudpaint_border_normal") > CurTime() then old = "Normal" end
            if ply:GetNWFloat("gent_rat_hudpaint_border_shadow") > CurTime() then old = "Shadow" end
        else
            ply.RatScrenTransition = Lerp(FrameTime()*2, ply.RatScrenTransition, 0)
        end
        if old == "Normal" then surface.SetMaterial(preservedmats["RATSCREEN"]) end
        if old == "Shadow" then surface.SetMaterial(preservedmats["RATSCREENSHADOW"]) end
        if ply.RatScrenTransition > 0.1 then
            local screenW, screenH = ScrW(), ScrH()

            local fadeTime = 0.85
            local holdTime = 0.1

            local cycle = fadeTime + holdTime
            local t = RealTime() % cycle

            local alpha

            if t < holdTime then
                alpha = 255
            else
                alpha = 255 * (1 - ((t - holdTime) / fadeTime))
            end

            surface.SetDrawColor(255, 255, 255, alpha * ply.RatScrenTransition)
            surface.DrawTexturedRect(0, 0, screenW, screenH)
        end

        local pillentity = ply.pk_pill_ent
        if not IsValid(pillentity) then return end
        if not pillentity.GetPuppet then return end
        if not IsValid(pillentity:GetPuppet()) then return end
        if not pillentity.formTable.gentoi_rat_noodles then return end



        local screenW, screenH = ScrW(), ScrH()
        local iconize = ScreenScale(60)
        local biggericoon = ScreenScale(100)

        local rx, ry = screenW/2 + screenW/6, screenH - ScreenScale(40)

        local yaxis = screenH - biggericoon/2

        pillentity.HoldingDownMenu_rat_lerp = pillentity.HoldingDownMenu_rat_lerp or 0
        pillentity.HoldingDownMenu_rat_lerp_bg = pillentity.HoldingDownMenu_rat_lerp_bg or 0
        pillentity.HoldingDownMenu_rat_lerp_char = pillentity.HoldingDownMenu_rat_lerp_char or 0
        pillentity.HoldingDownMenu_rat_lerp_text = pillentity.HoldingDownMenu_rat_lerp_text or 0
        pillentity.HoldingDownMenu_rat_lerp_bio = pillentity.HoldingDownMenu_rat_lerp_bio or 0
        pillentity.HoldingDownMenu_rat_lerp_ability = pillentity.HoldingDownMenu_rat_lerp_ability or 0

        if pillentity:GetNWBool("HoldingDownMenu_rat") then
            pillentity.HoldingDownMenu_rat_lerp = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_rat_lerp, 1)
            if CurTime()-pillentity:GetNW2Float('HoldingDownMenu_rat_timeframe') > 0.45 then
                pillentity.HoldingDownMenu_rat_lerp_bg = Lerp( FrameTime() * 13, pillentity.HoldingDownMenu_rat_lerp_bg, 1)
                pillentity.HoldingDownMenu_rat_lerp_ability = Lerp( FrameTime() * 13, pillentity.HoldingDownMenu_rat_lerp_ability, 1)

                pillentity.HoldingDownMenu_rat_lerp_char = Lerp( FrameTime() * 7, pillentity.HoldingDownMenu_rat_lerp_char, 1)
                pillentity.HoldingDownMenu_rat_lerp_text = Lerp( FrameTime() * 7, pillentity.HoldingDownMenu_rat_lerp_text, 1)
                pillentity.HoldingDownMenu_rat_lerp_bio = Lerp( FrameTime() * 7, pillentity.HoldingDownMenu_rat_lerp_bio, 1)

                if not pillentity.PlayRatSound_1 then
                    pillentity.PlayRatSound_1 = true
                    sound.PlayFile("sound/gentoi/rat/HELPHUDOPEN.wav", "noplay", function(station, err)
                        if IsValid(station) then
                            station:SetVolume(0.3)
                            station:Play()
                        end
                    end)
                end
            end
        else
            pillentity.HoldingDownMenu_rat_lerp_bg = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_rat_lerp_bg, 0)
            pillentity.HoldingDownMenu_rat_lerp_char = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_rat_lerp_char, 0)
            pillentity.HoldingDownMenu_rat_lerp_text = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_rat_lerp_text, 0)
            pillentity.HoldingDownMenu_rat_lerp_bio = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_rat_lerp_bio, 0)
            pillentity.HoldingDownMenu_rat_lerp_ability = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_rat_lerp_ability, 0)
            if pillentity.PlayRatSound_1 then
                pillentity.PlayRatSound_1 = false
                sound.PlayFile("sound/gentoi/rat/HELPHUDEXIT.wav", "noplay", function(station, err)
                    if IsValid(station) then
                        station:SetVolume(0.3)
                        station:Play()
                    end
                end)
            end
            if CurTime()-pillentity:GetNW2Float('HoldingDownMenu_rat_timeframe') > 0.45 then
                pillentity.HoldingDownMenu_rat_lerp = Lerp( FrameTime() * 5, pillentity.HoldingDownMenu_rat_lerp, 0)
            end
        end


        local w = ScreenScale(20)
        local h = ScreenScale(40)
        local inset = ScreenScale(10)

        local offset = Lerp(pillentity.HoldingDownMenu_rat_lerp, 0, ScreenScale(25))

        local x = 0
        local y = ScreenScale(25)

        draw.NoTexture()

        surface.SetDrawColor(25, 25, 25, 220)
        surface.DrawPoly({
            {x = x- offset,     y = y},
            {x = x + w- offset, y = y + inset},
            {x = x + w- offset, y = y + h - inset},
            {x = x- offset,     y = y + h},
        })


        surface.SetDrawColor(255, 0, 0)

        surface.DrawLine(x - offset,     y,             x + w - offset, y + inset)
        surface.DrawLine(x + w - offset, y + inset,     x + w - offset, y + h - inset)
        surface.DrawLine(x + w - offset, y + h - inset, x - offset,     y + h)

        draw.SimpleText(
            "/",
            "OM_SlashKey",
            x + w * 0.55- offset,
            y + h * 0.5,
            color_white,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )

        ry = Lerp(pillentity.HoldingDownMenu_rat_lerp, ry, screenH + biggericoon/1.5)
        yaxis = Lerp(pillentity.HoldingDownMenu_rat_lerp, yaxis, screenH + biggericoon/1.5)

        local currentaadd = Lerp(pillentity.HoldingDownMenu_rat_lerp, 0, screenW*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_rat_lerp_bg))
        surface.SetMaterial(preservedmats["MONSTERRATBG"])
        surface.DrawTexturedRect(-screenW*0.1+currentaadd,0,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_rat_lerp_char, 0, screenW*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_rat_lerp_char))
        surface.SetMaterial(preservedmats["MONSTERRATICONUI"])
        surface.DrawTexturedRect(-screenW*0.1+currentaadd,0,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_rat_lerp_text, 0, screenH*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_rat_lerp_text))
        surface.SetMaterial(preservedmats["MONSTERRATTEXTUI"])
        surface.DrawTexturedRect(0,screenH*0.1-currentaadd,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_rat_lerp_bio, 0, screenW*0.1)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_rat_lerp_bio))
        surface.SetMaterial(preservedmats["MONSTERRATABILITYINFOUI"])
        surface.DrawTexturedRect(screenW*0.1-currentaadd,0,screenW,screenH)


        local currentaadd = Lerp(pillentity.HoldingDownMenu_rat_lerp_ability, 0, screenW*0.025)

        surface.SetDrawColor(255,255,255,math.Round(255 * pillentity.HoldingDownMenu_rat_lerp_ability))
        surface.SetMaterial(preservedmats["MONSTERRATABILITYICONUI"])
        surface.DrawTexturedRect(-screenW*0.025+currentaadd,0,screenW,screenH)

        --

        surface.SetDrawColor(255,255,255,255)
        if pillentity:GetPuppet():GetSkin() == 1 then
            surface.SetMaterial(preservedmats["SHADOWRATICONGMOD"])
        else
            surface.SetMaterial(preservedmats["RATICONGMOD"])
        end
        surface.DrawTexturedRectRotated(0 + biggericoon/2, yaxis,biggericoon,biggericoon,0)

        surface.SetDrawColor(255,255,255,255)
        if pillentity:GetPuppet():GetSkin() == 1 then
            surface.SetMaterial(preservedmats["RATABIL1SHADOW"])
        else
            surface.SetMaterial(preservedmats["RATABIL1"])
        end
        surface.DrawTexturedRectRotated(0 + biggericoon/2 + iconize * 1.5, ry, iconize, iconize, 0)

        if pillentity:GetNW2Float("rat_invis_ability_cd") > CurTime()then
            local frac = math.Clamp(
                (pillentity:GetNW2Float("rat_invis_ability_cd") - CurTime()) /
                (pillentity:GetNW2Float("rat_invis_ability_cd_dur")),
                0, 1
            )

            local h  = Lerp(frac, 0, iconize)
            local y2 = Lerp(frac, ry + iconize/2, ry - iconize/2)
            local uv = Lerp(frac, 1, 0)

            surface.SetDrawColor(25,25,25,255)
            surface.DrawTexturedRectUV(0 + biggericoon/2 + iconize * 1,y2,iconize,h,0,uv,1,1)
        end

        draw.SimpleTextOutlined("1","CreditsText_Large_rat",0 + biggericoon/2 + iconize * 1,ry -iconize /2+ ScreenScale(2),color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,6,color_black)



        local ent2 = pillentity:GetNW2Entity("rat_opponent_gentoi")
        if IsValid(ent2) then
            OM_CirclePosX = OM_CirclePosX or 0
            OM_CirclePosY = OM_CirclePosY or 0

            local centerX = screenW / 2 - 80
            local centerY = screenH / 2 + iconize * 1.75

            local radius = 150
            local segments = 32

            draw.NoTexture()
            surface.SetDrawColor(5, 5, 5, 255)

            local poly = {}

            for i = 0, segments do
                local a = math.rad((i / segments) * 360)

                poly[#poly + 1] = {
                    x = centerX + math.cos(a) * radius,
                    y = centerY + math.sin(a) * radius
                }
            end

            surface.DrawPoly(poly)

            surface.SetDrawColor(255, 255, 255, 255)

            for i = 0, segments - 1 do
                local a1 = math.rad((i / segments) * 360)
                local a2 = math.rad(((i + 1) / segments) * 360)

                surface.DrawLine(
                    centerX + math.cos(a1) * radius,
                    centerY + math.sin(a1) * radius,
                    centerX + math.cos(a2) * radius,
                    centerY + math.sin(a2) * radius
                )
            end

            local w, a, s, d = input.IsKeyDown(KEY_W), input.IsKeyDown(KEY_A), input.IsKeyDown(KEY_S), input.IsKeyDown(KEY_D)

            local angle

            if w and d then angle = -45
            elseif d and s then angle = 45
            elseif s and a then angle = 135
            elseif a and w then angle = 225
            elseif w then angle = -90
            elseif d then angle = 0
            elseif s then angle = 90
            elseif a then angle = 180 end

            local targetX, targetY = centerX, centerY

            if angle then
                local rad = math.rad(angle)
                local indicatorRadius = radius - 20

                targetX = centerX + math.cos(rad) * indicatorRadius
                targetY = centerY + math.sin(rad) * indicatorRadius
            end

            OM_CirclePosX = Lerp(FrameTime() * 9, OM_CirclePosX, targetX)
            OM_CirclePosY = Lerp(FrameTime() * 9, OM_CirclePosY, targetY)

            local indicatorX = OM_CirclePosX
            local indicatorY = OM_CirclePosY

            local indicatorSize = 14

            surface.SetDrawColor(255, 255, 255, 255)

            local indicatorPoly = {}

            for i = 0, segments do
                local a = math.rad((i / segments) * 360)

                indicatorPoly[#indicatorPoly + 1] = {
                    x = indicatorX + math.cos(a) * indicatorSize,
                    y = indicatorY + math.sin(a) * indicatorSize
                }
            end

            surface.DrawPoly(indicatorPoly)

            surface.SetDrawColor(0, 0, 0, 255)

            for i = 0, segments - 1 do
                local a1 = math.rad((i / segments) * 360)
                local a2 = math.rad(((i + 1) / segments) * 360)

                surface.DrawLine(
                    indicatorX + math.cos(a1) * indicatorSize,
                    indicatorY + math.sin(a1) * indicatorSize,
                    indicatorX + math.cos(a2) * indicatorSize,
                    indicatorY + math.sin(a2) * indicatorSize
                )
            end


            draw.SimpleTextOutlined(
                "Use W, A, S, D to move head position",
                "DermaLarge",
                centerX + 80,
                centerY - radius - 50,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            local keyFont = "DermaLarge"
            local offset = 15

            draw.SimpleTextOutlined(
                "W",
                keyFont,
                centerX,
                centerY - radius - offset,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            draw.SimpleTextOutlined(
                "S",
                keyFont,
                centerX,
                centerY + radius + offset,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            draw.SimpleTextOutlined(
                "A",
                keyFont,
                centerX - radius - offset,
                centerY,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            draw.SimpleTextOutlined(
                "D",
                keyFont,
                centerX + radius + offset,
                centerY,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            local miniRadius = 60
            local miniSegments = 24

            local miniX = centerX - radius*1.1
            local miniY = centerY - 65 - radius/2.5

            draw.NoTexture()
            surface.SetDrawColor(20, 20, 20, 255)

            local miniPoly = {}

            for i = 0, miniSegments do
                local a = math.rad((i / miniSegments) * 360)

                miniPoly[#miniPoly + 1] = {
                    x = miniX + math.cos(a) * miniRadius,
                    y = miniY + math.sin(a) * miniRadius
                }
            end

            surface.DrawPoly(miniPoly)
            surface.SetDrawColor(255, 255, 255, 255)

            for i = 0, miniSegments - 1 do
                local a1 = math.rad((i / miniSegments) * 360)
                local a2 = math.rad(((i + 1) / miniSegments) * 360)

                surface.DrawLine(
                    miniX + math.cos(a1) * miniRadius,
                    miniY + math.sin(a1) * miniRadius,
                    miniX + math.cos(a2) * miniRadius,
                    miniY + math.sin(a2) * miniRadius
                )
            end
            draw.SimpleTextOutlined(
                pillentity:GetNWFloat("Gentoi_rat_movesleft"),
                keyFont,
                miniX,
                miniY,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            draw.SimpleTextOutlined(
                "Moves",
                keyFont,
                miniX,
                miniY-miniRadius - 5,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            local miniRadius = 60
            local miniSegments = 24

            local miniX = centerX + radius/2 + 180
            local miniY = centerY

            draw.NoTexture()
            if pillentity:GetNWFloat("RatMode_swapdelay") < CurTime() and pillentity:GetNWFloat("RatMode_swapdelay_toolate") > CurTime() then
                surface.SetDrawColor(35, 85, 35, 255)
            else
                surface.SetDrawColor(20, 20, 20, 255)
            end

            local miniPoly = {}

            for i = 0, miniSegments do
                local a = math.rad((i / miniSegments) * 360)

                miniPoly[#miniPoly + 1] = {
                    x = miniX + math.cos(a) * miniRadius,
                    y = miniY + math.sin(a) * miniRadius
                }
            end

            surface.DrawPoly(miniPoly)


            if pillentity:GetNWFloat("RatMode_swapdelay") < CurTime() and pillentity:GetNWFloat("RatMode_swapdelay_toolate") > CurTime() then
                surface.SetDrawColor(75, 255, 75, 255)
            else
                surface.SetDrawColor(255, 255, 255, 255)
            end

            for i = 0, miniSegments - 1 do
                local a1 = math.rad((i / miniSegments) * 360)
                local a2 = math.rad(((i + 1) / miniSegments) * 360)

                surface.DrawLine(
                    miniX + math.cos(a1) * miniRadius,
                    miniY + math.sin(a1) * miniRadius,
                    miniX + math.cos(a2) * miniRadius,
                    miniY + math.sin(a2) * miniRadius
                )
            end

            draw.SimpleTextOutlined(
                pillentity:GetNWFloat("Gentoi_rat_twitchesleft"),
                keyFont,
                miniX + miniRadius / 30,
                miniY + miniRadius / 30,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            draw.SimpleTextOutlined(
                "Twitches",
                keyFont,
                miniX,
                miniY-miniRadius - 5,
                Color(255,255,255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0,0,0,200)
            )

            local possibleAngles = {
                -90,  -- W
                -45,  -- WD
                0,    -- D
                45,   -- SD
                90,   -- S
                135,  -- SA
                180,  -- A
                225   -- WA
            }

            for _, ang in ipairs(possibleAngles) do
                local rad = math.rad(ang)

                draw.RoundedBox(
                    16,
                    centerX + math.cos(rad) * (radius - 20) - 6,
                    centerY + math.sin(rad) * (radius - 20) - 6,
                    12,
                    12,
                    Color(255,255,255,80)
                )
            end

            -- center position
            draw.RoundedBox(
                16,
                centerX - 6,
                centerY - 6,
                12,
                12,
                Color(255,255,255,80)
            )


            -- health

            local screenW, screenH = ScrW(), ScrH()
            local middlex, middley = screenW * 0.5, screenH * 0.5
            local iconsize = screenW / 13

            local barW = iconsize * 3.75
            local barH = iconsize * 0.15

            local x = middlex - barW * 0.5
            local y = middley + iconsize * 0.4

            local starttime = pillentity:GetNWFloat("RatMode_sethealth")
            local factorClamped = math.Clamp(starttime / 100, 0, 1)
            local factor = Lerp(factorClamped, 0, 1)

            local shakeFrac = math.Clamp((factorClamped - 0.65) / 0.35, 0, 1)

            local shakeX = math.sin(CurTime() * 25) * shakeFrac * 3
            local shakeY = math.cos(CurTime() * 21) * shakeFrac * 2

            x = x + shakeX
            y = y + shakeY

            draw.RoundedBox(8, x - 2, y + 2, barW + 4, barH + 4, Color(0, 0, 0, 120))
            draw.RoundedBox(8, x, y, barW, barH, Color(20, 20, 20, 220))

            surface.SetDrawColor(255, 255, 255, 15)
            surface.DrawOutlinedRect(x, y, barW, barH, 1)

            local currentW = math.max(barW * factor, 0)
            local currentX = x + (barW - currentW) * 0.5

            draw.RoundedBox(8, currentX, y, currentW, barH, Color(255, 60, 60))

            if currentW > 4 then
                surface.SetDrawColor(255, 255, 255, 20)
                surface.DrawRect(
                    currentX + 2,
                    y + 2,
                    currentW - 4,
                    math.max((barH - 4) * 0.35, 1)
                )
            end
        end

    end)



end

hook.Add("PlayerButtonDown", "keybind_rat_gentoi_pills_noodles_down", function(ply, button)
    local pillentity = ply.pk_pill_ent

    if IsValid(pillentity) then
        if pillentity.formTable.noodles_gentoi_rat_keybinds_down then
            pillentity.formTable.noodles_gentoi_rat_keybinds_down(ply, pillentity, button)
        end
    end
end)

hook.Add("PlayerButtonUp", "keybind_rat_gentoi_pills_noodles_up", function(ply, button)
    local pillentity = ply.pk_pill_ent

    if IsValid(pillentity) then
        if pillentity.formTable.noodles_gentoi_rat_keybinds_up then
            pillentity.formTable.noodles_gentoi_rat_keybinds_up(ply, pillentity, button)
        end
    end
end)



if SERVER then

    local function CreateAConvVarConstant(VarName, DefaultSetting, Text,min,max)
        CreateConVar(VarName, DefaultSetting, FCVAR_ARCHIVE, Text, min, max)     
    end
    --rat_gentoi_stats

    CreateAConvVarConstant("GentoiPills_rat_walkspeed",75,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_runspeed",420,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_crouchspeed",60,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_jumppower",0,"", 0,1e9)  

    CreateAConvVarConstant("GentoiPills_rat_SneakUp",1,"", 0,1)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_speedupadd",300,"", 0,1e9) 
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_invisadd_walk",200,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_invisadd_run",400,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_speedupduration",7,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_detectionduration",3.5,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_cdinit",1,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_cdout",5,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_cddetected",10,"", 0,1e9)  

    CreateAConvVarConstant("GentoiPills_rat_SneakUp_minigamefinishedstun",5,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_minigame_ratheathdrain_multiplyer",1,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_minigame_ratheathRegain_multiplyer",1,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_minigame_shadowmoves",35,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_minigame_shadowtwitches",25,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_minigame_moves",25,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_minigame_twitches",10,"", 0,1e9)  
    CreateAConvVarConstant("GentoiPills_rat_SneakUp_rathealth",100,"", 0,1e9)  
else

    hook.Add("PopulateToolMenu", "Gentoi_pill_rat_populate", function()   

        spawnmenu.AddToolMenuOption("Gentoi Pill Settings", "Pills", "Gentoi_pills_rat", "Rat", "", "", function(panel)

            panel:Help("------------ Rat ------------")


            panel:Help("-- Preset --")
            local presettable = {
                name = "Gentoi_pills_rat_presets",

                listofdefualtconvars = {

                    "GentoiPills_rat_walkspeed",
                    "GentoiPills_rat_runspeed",
                    "GentoiPills_rat_crouchspeed",
                    "GentoiPills_rat_jumppower",

                    "GentoiPills_rat_SneakUp",
                    "GentoiPills_rat_SneakUp_speedupadd",
                    "GentoiPills_rat_SneakUp_invisadd_walk",
                    "GentoiPills_rat_SneakUp_invisadd_run",
                    "GentoiPills_rat_SneakUp_speedupduration",
                    "GentoiPills_rat_SneakUp_detectionduration",
                    "GentoiPills_rat_SneakUp_cdinit",
                    "GentoiPills_rat_SneakUp_cdout",
                    "GentoiPills_rat_SneakUp_cddetected",

                    "GentoiPills_rat_SneakUp_minigamefinishedstun",
                    "GentoiPills_rat_SneakUp_minigame_ratheathdrain_multiplyer",
                    "GentoiPills_rat_SneakUp_minigame_ratheathRegain_multiplyer",
                }
            }

            local presetName = presettable.name
            local listofdefualtconvars = presettable.listofdefualtconvars

            local combo = vgui.Create("DComboBox")
            combo:Dock(TOP)
            combo:SetTall(30)
            combo:SetValue("Default")

            local saveButton = vgui.Create("DButton")
            saveButton:Dock(TOP)
            saveButton:SetTall(25)
            saveButton:SetText("Save Current")

            local editButton = vgui.Create("DButton")
            editButton:Dock(TOP)
            editButton:SetTall(25)
            editButton:SetText("Edit Presets")

            panel:AddItem(combo)
            panel:AddItem(saveButton)
            panel:AddItem(editButton)

            local PRESET_FOLDER = "OM_LNZ"
            local PRESET_FILE = PRESET_FOLDER .. "/preset_" .. presetName .. ".json"

            local function EnsureFolder()
                if not file.Exists(PRESET_FOLDER, "DATA") then
                    file.CreateDir(PRESET_FOLDER)
                end
            end

            local function LoadPresets()
                EnsureFolder()

                if not file.Exists(PRESET_FILE, "DATA") then
                    return {}
                end

                return util.JSONToTable(file.Read(PRESET_FILE, "DATA")) or {}
            end

            local function SavePresets(presets)
                EnsureFolder()
                file.Write(PRESET_FILE, util.TableToJSON(presets, true))
            end

            local defaultValues = {}

            for _, cvar in ipairs(listofdefualtconvars) do
                local cv = GetConVar(cvar)

                if cv then
                    defaultValues[cvar] = cv:GetDefault()
                end
            end

            local function RefreshDropdown()
                combo:Clear()
                combo:AddChoice("Default")

                for name in pairs(LoadPresets()) do
                    combo:AddChoice(name)
                end
            end

            RefreshDropdown()

            function combo:OnSelect(_, value)
                if value == "Default" then
                    for cvar, default in pairs(defaultValues) do
                        RunConsoleCommand(cvar, tostring(default))
                    end

                    return
                end

                local preset = LoadPresets()[value]
                if not preset then return end

                for cvar, value in pairs(preset) do
                    RunConsoleCommand(cvar, tostring(value))
                end
            end

            saveButton.DoClick = function()
                Derma_StringRequest(
                    "Save Preset",
                    "Preset name:",
                    "",
                    function(name)
                        if not name or name == "" then return end

                        local presets = LoadPresets()
                        presets[name] = {}

                        for _, cvar in ipairs(listofdefualtconvars) do
                            local cv = GetConVar(cvar)

                            if cv then
                                presets[name][cvar] = cv:GetString()
                            end
                        end

                        SavePresets(presets)
                        RefreshDropdown()
                        combo:SetValue(name)
                    end
                )
            end

            local function OpenPresetEditor()
                local presets = LoadPresets()

                local frame = vgui.Create("DFrame")
                frame:SetSize(550, 420)
                frame:Center()
                frame:SetTitle("Preset Editor - " .. presetName)
                frame:MakePopup()

                local list = vgui.Create("DListView", frame)
                list:Dock(LEFT)
                list:SetWide(160)
                list:AddColumn("Presets")

                for name in pairs(presets) do
                    list:AddLine(name)
                end

                local right = vgui.Create("DScrollPanel", frame)
                right:Dock(FILL)

                local selected

                list.OnRowSelected = function(_, _, row)
                    right:Clear()
                    selected = row:GetColumnText(1)

                    for cvar, value in pairs(presets[selected] or {}) do
                        local rowPanel = right:Add("DPanel")
                        rowPanel:Dock(TOP)
                        rowPanel:SetTall(30)
                        rowPanel:DockMargin(4, 4, 4, 4)

                        local label = rowPanel:Add("DLabel")
                        label:Dock(LEFT)
                        label:SetWide(250)
                        label:SetText(cvar)

                        local entry = rowPanel:Add("DTextEntry")
                        entry:Dock(FILL)
                        entry:SetValue(value)

                        entry.OnChange = function(self)
                            presets[selected][cvar] = self:GetValue()
                        end
                    end
                end

                local bottom = vgui.Create("DPanel", frame)
                bottom:Dock(BOTTOM)
                bottom:SetTall(35)

                local save = bottom:Add("DButton")
                save:Dock(LEFT)
                save:SetWide(100)
                save:SetText("Save")
                save.DoClick = function()
                    SavePresets(presets)
                    RefreshDropdown()
                end

                local delete = bottom:Add("DButton")
                delete:Dock(RIGHT)
                delete:SetWide(100)
                delete:SetText("Delete")
                delete.DoClick = function()
                    if not selected then return end

                    presets[selected] = nil
                    SavePresets(presets)

                    frame:Close()
                    RefreshDropdown()
                end

                local rename = bottom:Add("DButton")
                rename:Dock(FILL)
                rename:SetText("Rename")
                rename.DoClick = function()
                    if not selected then return end

                    Derma_StringRequest(
                        "Rename Preset",
                        "New name:",
                        selected,
                        function(name)
                            if not name or name == "" or presets[name] then return end

                            presets[name] = presets[selected]
                            presets[selected] = nil

                            SavePresets(presets)
                            frame:Close()
                            RefreshDropdown()
                        end
                    )
                end
            end

            editButton.DoClick = OpenPresetEditor

            panel:Help("-- Speed --")
            panel:NumSlider("Walk Speed","GentoiPills_rat_walkspeed",1,200)
            panel:NumSlider("Run Speed","GentoiPills_rat_runspeed",200,500)
            panel:NumSlider("Crouch Speed","GentoiPills_rat_crouchspeed",1,200)
            panel:NumSlider("Jump Power","GentoiPills_rat_jumppower",0,200)
            panel:Help("")

            panel:Help("-- Sneak Up --")
            panel:CheckBox("Can Be Used","GentoiPills_rat_SneakUp")
            panel:NumSlider("Speed Add Up","GentoiPills_rat_SneakUp_speedupadd",0,400)
            panel:NumSlider("Invis Walk Add Up","GentoiPills_rat_SneakUp_invisadd_walk",0,400)
            panel:NumSlider("Invis Run Add Up","GentoiPills_rat_SneakUp_invisadd_run",0,400)
            panel:NumSlider("Speed Up Duration","GentoiPills_rat_SneakUp_speedupduration",0,10)
            panel:NumSlider("Detection Duration","GentoiPills_rat_SneakUp_detectionduration",0,10)
            panel:NumSlider("CD Init","GentoiPills_rat_SneakUp_cdinit",0,10)
            panel:NumSlider("CD Exit","GentoiPills_rat_SneakUp_cdout",0,10)
            panel:NumSlider("CD Mini Game","GentoiPills_rat_SneakUp_cddetected",0,10)
            panel:Help("")

            panel:Help("-- Mini Game --")
            panel:NumSlider("End stun duration","GentoiPills_rat_SneakUp_minigamefinishedstun",0,10)
            panel:NumSlider("Health Drain Multiplyer","GentoiPills_rat_SneakUp_minigame_ratheathdrain_multiplyer",0,10)
            panel:NumSlider("Health Regain Multiplyer","GentoiPills_rat_SneakUp_minigame_ratheathRegain_multiplyer",0,10)
            panel:NumSlider("Shadow Moves Limit","GentoiPills_rat_SneakUp_minigame_shadowmoves",0,50)
            panel:NumSlider("Shadow Twitches Limit","GentoiPills_rat_SneakUp_minigame_shadowtwitches",0,50)
            panel:NumSlider("Moves Limit","GentoiPills_rat_SneakUp_minigame_moves",0,50)
            panel:NumSlider("Twitches Limit","GentoiPills_rat_SneakUp_minigame_twitches",0,50)
            panel:NumSlider("Health","GentoiPills_rat_SneakUp_rathealth",0,100)

        end)        
    end)
end
