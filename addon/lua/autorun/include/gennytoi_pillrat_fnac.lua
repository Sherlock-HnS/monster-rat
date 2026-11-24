--NoHealing_OM_Noodles
AddCSLuaFile()
if SERVER then
    resource.AddFile("materials/gentoi/rat/Five Nights at Candys 3 - Shadow Rat Jumpscare.webm")
else
end




if SERVER then
    util.AddNetworkString("rat_shadowlevel")

    net.Receive("rat_shadowlevel", function(_, ply)
        for _, ent in ipairs(ents.GetAll()) do
            if ent.formTable then
                if ent.formTable.gentoi_rat_noodles then
                    ent.RatTimesLost = 6
                    ent.RatKillTimer = ent.RatKillTimer or 1
                    ent.RatKillTimer = math.Clamp(ent.RatKillTimer-0.2*ent.RatTimesLost,0.4,1e9)
                end
            end
        end
    end)
else
    hook.Add("PostDrawTranslucentRenderables", "rat_etes_model", function()
        local ply = LocalPlayer()

        for _, ent in pairs(ents.FindByModel("models/gentoi/anologhorror/monster rat.mdl")) do
            if not IsValid(ent) then continue end
            if ent:GetNoDraw() then continue end

            ent.rat_coloredeyes_transition_gentoi = ent.rat_coloredeyes_transition_gentoi or 0

            local hasbodygroup = ent:GetBodygroup(1)
            if hasbodygroup == 1 then
                ent.rat_coloredeyes_transition_gentoi = Lerp(FrameTime()*5, ent.rat_coloredeyes_transition_gentoi, 1)
            else
                ent.rat_coloredeyes_transition_gentoi = Lerp(FrameTime()*5, ent.rat_coloredeyes_transition_gentoi, 0)
            end

            if ent.rat_coloredeyes_transition_gentoi > 0.05 then
                render.ClearStencil()

                render.SetStencilEnable(true)

                render.SetStencilWriteMask(255)
                render.SetStencilTestMask(255)

                render.SetStencilReferenceValue(1)

                render.SetStencilCompareFunction(STENCIL_ALWAYS)
                render.SetStencilPassOperation(STENCIL_REPLACE)

                local hasbodygroup = ent:GetBodygroup(0)

                --cam.IgnoreZ(true)
                ent:SetBodygroup(0,1)
                render.SetBlend(ent:GetColor().a / 255)
                    ent:DrawModel()
                render.SetBlend(1)
                ent:SetBodygroup(0,hasbodygroup)
                --cam.IgnoreZ(false)

                render.SetStencilCompareFunction(STENCIL_EQUAL)
                render.SetStencilPassOperation(STENCIL_KEEP)
                render.SetStencilFailOperation(STENCIL_KEEP)
                render.SetStencilZFailOperation(STENCIL_KEEP)

                local alpha = ent:GetColor().a / 255

                DrawColorModify({
                    ["$pp_colour_addr"]       = 0 + (-1 * alpha)*ent.rat_coloredeyes_transition_gentoi,
                    ["$pp_colour_addg"]       = 0 + (-1 * alpha)*ent.rat_coloredeyes_transition_gentoi,
                    ["$pp_colour_addb"]       = 0 + (-1 * alpha)*ent.rat_coloredeyes_transition_gentoi,
                    ["$pp_colour_brightness"] = 0,
                    ["$pp_colour_contrast"]   = 1,
                    ["$pp_colour_colour"]     = 1,
                    ["$pp_colour_mulr"]       = 0,
                    ["$pp_colour_mulg"]       = 0,
                    ["$pp_colour_mulb"]       = 0
                })

                render.SetStencilEnable(false)
            end
        end
    end)

    concommand.Add("rat_shadowlevel", function()
        net.Start("rat_shadowlevel")
        net.SendToServer()
    end)
end

local function AdvancedPillSound(SoundData, ent)
    if SERVER then
        if IsValid(ent) then
            SoundData = SoundData or {}
            SoundData.stringe = SoundData.stringe or {}
            SoundData.soundLevel = SoundData.soundLevel or 75
            SoundData.pitchPercent = SoundData.pitchPercent or 100
            SoundData.volume = SoundData.volume or 1
            SoundData.channel = SoundData.channel or CHAN_AUTO
            SoundData.soundFlags = SoundData.soundFlags or 0
            SoundData.dsp = SoundData.dsp or 0
            SoundData.filter = SoundData.filter or nil

            local chosenSound = SoundData.stringe

            if istable(SoundData.stringe) then
                local index = math.random(1, #SoundData.stringe)
                chosenSound = SoundData.stringe[index]
            end

            ent:EmitSound(
                chosenSound,
                SoundData.soundLevel,
                SoundData.pitchPercent,
                SoundData.volume,
                SoundData.channel,
                SoundData.soundFlags,
                SoundData.dsp,
                SoundData.filter
            )
        end
        return true
    end
end

local function tracefuntion(pilluser, functionth, radius)
    if not SERVER then return end
    if not IsValid(pilluser) then return end
    if not IsValid(pilluser.pk_pill_ent) then return end

    local enttable = {}

    local pillent = pilluser.pk_pill_ent
    local puppet = pillent:GetPuppet()

    if not IsValid(puppet) then return end

    local bone = puppet:LookupBone("Model Head")
    if not bone then return end

    local headPos, headangle = puppet:GetBonePosition(bone)
    if not headPos then return end

    for _, v in ipairs(player.GetAll()) do
        if v == pilluser then continue end
        if v:Team() == TEAM_SPECTATOR then continue end
        if v:Health() < 0.1 then continue end
        if not v:FlashlightIsOn() then continue end

        local tr = util.TraceLine({
            start = pilluser:EyePos(),
            endpos = v:EyePos(),
            filter = {pilluser, pillent, puppet, v},
            mask = MASK_VISIBLE
        })

        if tr.Hit then continue end

        local eyePos = v:EyePos()
        local eyeAng = v:EyeAngles()

        local dir = ((headPos + Vector(0, 0, 2)) - eyePos):GetNormalized()
        local targetAng = dir:Angle()

        local yawDiff = math.AngleDifference(
            eyeAng.y,
            targetAng.y
        )

        local pitchDiff = math.AngleDifference(
            eyeAng.p,
            targetAng.p
        )

        local dist = eyePos:Distance(headPos) * 0.5

        local targetRadius = radius or 3

        local angularSize = math.deg(
            math.atan(targetRadius / math.max(dist, 1))
        )

        local sideBias = angularSize
        local halfFOV_V = angularSize

        if math.abs(yawDiff) <= sideBias
        and math.abs(pitchDiff) <= halfFOV_V then

            table.insert(enttable, v)

        end
    end

    functionth(enttable)
end

local function racheljackietien_jumpscare(ply, ent, duration, customanimstuff, specificent)
    if SERVER then
        if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
        if ent.IsInJumpscare >= CurTime() then return end
        if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
        if ent.IsInJumpscareCooldown >= CurTime() then return end

        local jumpscare_entity = nil
        local range = 100
        local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))

        if SherlockHNS then
            if IsValid(specificent) then
                jumpscare_entity = SherlockHNS.FindVictim(ply, targetOrigin, range, {
                    filter = function(v) return v == specificent end,
                })
            else
                jumpscare_entity = SherlockHNS.FindVictim(ply, targetOrigin, range)
            end
        elseif specificent then
            jumpscare_entity = specificent
        else
            for _, ent2 in pairs(ents.FindInSphere(targetOrigin, range)) do
                if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
                    if ent2 == ply then continue end
                    if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

                    if IsValid(ent2) then
                        jumpscare_entity = ent2
                        break
                    end
                end
            end
        end

        if SherlockHNS and IsValid(jumpscare_entity) and jumpscare_entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, jumpscare_entity, duration, {
                camera = "OM_gentoi_rat_jumpscarecam",
                onStart = customanimstuff,
            })
        end

        if jumpscare_entity ~= nil then
            
            ent.JuumpscareStart = CurTime()

            ent.jumpscare_entity = jumpscare_entity
            ent.entitylastpos = jumpscare_entity:GetPos()
            ent.entitylastang = jumpscare_entity:GetAngles()

            local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

            targetAngle.p = 0
            targetAngle.r = 0

            ply:SetNWInt("DisablePlayerMovement_gennytoi_pillrat_fnac1", duration+CurTime())
            jumpscare_entity:SetNWInt("DisablePlayerMovement_gennytoi_pillrat_fnac1", duration+CurTime())
            ent:SetNWFloat("JumpscareDuration", duration+CurTime())

            ent.IsInJumpscare = CurTime() + duration

            local puppet = ent:GetPuppet()

            if not ent.RatTimesLost then ent.RatTimesLost = 0 end

            if ent.RatTimesLost >= 6 then
                net.Start("OM_gentoi_rat_deathscreen")
                net.Send(jumpscare_entity)
            end

            if jumpscare_entity:IsPlayer() then
                net.Start('OM_gentoi_rat_jumpscarecam')
                net.WriteEntity(puppet)
                net.WriteBool(true)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(duration+0.1+CurTime())
            end
            
            jumpscare_entity:AddFlags(FL_NOTARGET)
            ent:CallOnRemove("RachelJumpscare"..ent:EntIndex(), function()
                if !IsValid(jumpscare_entity) then return end

                jumpscare_entity:RemoveFlags(FL_NOTARGET)
                ent.jumpscare_entity = nil

                if jumpscare_entity:IsPlayer() then
                    net.Start('OM_gentoi_rat_jumpscarecam')
                    net.WriteEntity(puppet)
                    net.WriteBool(false)
                    net.Send(jumpscare_entity)
                else
                    jumpscare_entity:NextThink(CurTime())
                end
                jumpscare_entity:SetPos(ent.entitylastpos)
                jumpscare_entity:SetAngles(ent.entitylastang)
                jumpscare_entity:SetNWInt("DisablePlayerMovement_gennytoi_pillrat_fnac1", CurTime())
            end)

            customanimstuff()
        end
    end
end

pk_pills.packStart("Rat", "noodlesPillz_fnac_rat", "gentoi/rat/fnaf3icon.png")
pk_pills.register('pill_gentoi_fnac_rat', {
    printName='Rat',
    gentoi_rat_noodles = true,

    model="models/gentoi/anologhorror/monster rat.mdl",
    
    modelScale='1',

    noragdoll = false,
    muteSteps = true,
    type='ply',

    anims={
        default={
            idle="idle",
            run="run",
            walk="walk",
            kill="kill",
            crouch = "cidle",
            crouch_walk = "Cidle Walk",
        },

        ShouldMoveRotate={
            cidle= function(ent) 
                if IsValid(ent:GetNW2Entity("rat_opponent_gentoi")) then return 'assignedagnles' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            ["Cidle Walk"] = function(ent) 
                if IsValid(ent:GetNW2Entity("rat_opponent_gentoi")) then return 'assignedagnles' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return "notshftlock"
            end,
            idle= function(ent) 
                if IsValid(ent:GetNW2Entity("rat_opponent_gentoi")) then return 'assignedagnles' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            Fall= function(ent)
                if IsValid(ent:GetNW2Entity("rat_opponent_gentoi")) then return 'assignedagnles' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                if ent:GetPillUser():IsOnGround() then
                    return 'notanything'
                else
                    return 'notshftlock'
                end
            end,
            run= function(ent) 
                if IsValid(ent:GetNW2Entity("rat_opponent_gentoi")) then return 'assignedagnles' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return "notshftlock"
            end,
            walk= function(ent) 
                if IsValid(ent:GetNW2Entity("rat_opponent_gentoi")) then return 'assignedagnles' end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return "notshftlock"
            end,
        },

        ShouldAlternate={
            cidle= function(ent) 
                local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
                if IsValid(ent2) then
                    local name
                    if ent:GetNWFloat("RatMode") == 0 then
                        name = "MTop"
                    end
                    if ent:GetNWFloat("RatMode") == 1 then
                        name = "MTopLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 2 then
                        name = "MLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 3 then
                        name = "MBottomLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 4 then
                        name = "MBottomRight"
                    end
                    if ent:GetNWFloat("RatMode") == 5 then
                        name = "MTopRight"
                    end
                    if ent:GetNWFloat("RatMode") == 6 then
                        name = "MRight"
                    end
                    if ent:GetNWBool("FlashLightON") then
                        name = name .. "Shake"
                    end
                    --[[
                    if ent:GetPuppet():GetSkin() == 1 then
                        name = name .. "Shadow"
                    end
                    ]]

                    return name
                end
            end,
            idle= function(ent) 
                local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
                if IsValid(ent2) then
                    local name
                    if ent:GetNWFloat("RatMode") == 0 then
                        name = "MTop"
                    end
                    if ent:GetNWFloat("RatMode") == 1 then
                        name = "MTopLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 2 then
                        name = "MLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 3 then
                        name = "MBottomLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 4 then
                        name = "MBottomRight"
                    end
                    if ent:GetNWFloat("RatMode") == 5 then
                        name = "MTopRight"
                    end
                    if ent:GetNWFloat("RatMode") == 6 then
                        name = "MRight"
                    end
                    if ent:GetNWBool("FlashLightON") then
                        name = name .. "Shake"
                    end
                    --[[
                    if ent:GetPuppet():GetSkin() == 1 then
                        name = name .. "Shadow"
                    end
                    ]]

                    return name
                end
            end,
            Fall= function(ent) 
                local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
                if IsValid(ent2) then
                    local name
                    if ent:GetNWFloat("RatMode") == 0 then
                        name = "MTop"
                    end
                    if ent:GetNWFloat("RatMode") == 1 then
                        name = "MTopLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 2 then
                        name = "MLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 3 then
                        name = "MBottomLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 4 then
                        name = "MBottomRight"
                    end
                    if ent:GetNWFloat("RatMode") == 5 then
                        name = "MTopRight"
                    end
                    if ent:GetNWFloat("RatMode") == 6 then
                        name = "MRight"
                    end
                    if ent:GetNWBool("FlashLightON") then
                        name = name .. "Shake"
                    end
                    --[[
                    if ent:GetPuppet():GetSkin() == 1 then
                        name = name .. "Shadow"
                    end
                    ]]

                    return name
                end
            end,
            run= function(ent) 
                local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
                if IsValid(ent2) then
                    local name
                    if ent:GetNWFloat("RatMode") == 0 then
                        name = "MTop"
                    end
                    if ent:GetNWFloat("RatMode") == 1 then
                        name = "MTopLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 2 then
                        name = "MLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 3 then
                        name = "MBottomLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 4 then
                        name = "MBottomRight"
                    end
                    if ent:GetNWFloat("RatMode") == 5 then
                        name = "MTopRight"
                    end
                    if ent:GetNWFloat("RatMode") == 6 then
                        name = "MRight"
                    end
                    if ent:GetNWBool("FlashLightON") then
                        name = name .. "Shake"
                    end
                    --[[
                    if ent:GetPuppet():GetSkin() == 1 then
                        name = name .. "Shadow"
                    end
                    ]]

                    return name
                end
            end,
            walk= function(ent) 
                local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
                if IsValid(ent2) then
                    local name
                    if ent:GetNWFloat("RatMode") == 0 then
                        name = "MTop"
                    end
                    if ent:GetNWFloat("RatMode") == 1 then
                        name = "MTopLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 2 then
                        name = "MLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 3 then
                        name = "MBottomLeft"
                    end
                    if ent:GetNWFloat("RatMode") == 4 then
                        name = "MBottomRight"
                    end
                    if ent:GetNWFloat("RatMode") == 5 then
                        name = "MTopRight"
                    end
                    if ent:GetNWFloat("RatMode") == 6 then
                        name = "MRight"
                    end
                    if ent:GetNWBool("FlashLightON") then
                        name = name .. "Shake"
                    end
                    --[[
                    if ent:GetPuppet():GetSkin() == 1 then
                        name = name .. "Shadow"
                    end
                    ]]

                    return name
                end
            end,
        },
        animrates={
            run= function(ent) 
                if ent:GetNWFloat("pillrat_fnac2_speedboost") > CurTime() then
                    return (420 + 300) / 420
                end
                return 1
            end,
        },
    },
    
    OM_cameratable = function(ply,ent)
        local basetable =  {
            startoffset = Vector(35,0,15),  -- left-up, front-back, up-down
            dist=100,
            fov = 80,
            id = 0,
            transition = 1,
            bonecenter = "Pelvis",
            bonehelper = "Chest",
        }

        if ent:GetNWBool("Rat_gentoi_invis") then
            basetable =  {
                startoffset = Vector(0,0,25),  -- left-up, front-back, up-down
                dist=0,
                fov = 80,
                id = 1,
                transition = 1,
                bonecenter = "Pelvis",
                bonehelper = "Chest",
            }
        end

        return basetable
    end,

    gentoirat_stats = {
        moveSpeed = {
            walk = 75,
            run = 420,
            ducked= 60,
            jumppower= 0,
        },
    },

    movePoseMode="xy",

    aim={
        xPose="aim_yaw",
        yPose="aim_pitch",
        nocrosshair = true
    },

    HandleAnimEvent_Noodles_gentoi_rat_pill = function(ply, ent, event)
        if SERVER then
            if event == "Step" then
                if not ent.rat_invis_alpha then ent.rat_invis_alpha = 0 end
                if ent.rat_invis_alpha < 20 then return end
                if ply:OnGround() then

                    local volumeless = 1


                    ent.RatTimesLost = ent.RatTimesLost or 0
                    if ent.RatTimesLost >= 6 then
                        volumeless = 0.6
                    end

                    if ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "walk" then
                        AdvancedPillSound(
                            {
                                stringe = {
                                    "gentoi/rat/step1.wav",
                                    "gentoi/rat/step2.wav",
                                    "gentoi/rat/step3.wav",
                                    "gentoi/rat/step4.wav",
                                    "gentoi/rat/step5.wav"
                                },
                                pitchPercent = 100,
                                volume = 2 * volumeless,
                                soundLevel = 87
                            },
                            ent
                        )
                        --[[
                        AdvancedPillSound(
                            {
                                stringe = {
                                    "gentoi/rat/run1.wav",
                                    "gentoi/rat/run2.wav",
                                    "gentoi/rat/run3.wav",
                                    "gentoi/rat/run4.wav",
                                    "gentoi/rat/run5.wav",
                                    "gentoi/rat/run6.wav",
                                    "gentoi/rat/run7.wav"
                                },
                                pitchPercent = 100,
                                volume = 2,
                                soundLevel = 87
                            },
                            ent
                        )
                        
                        AdvancedPillSound(
                            {
                                stringe = {
                                    "gentoi/rat/footstep1.wav",
                                    "gentoi/rat/footstep2.wav",
                                    "gentoi/rat/footstep3.wav"
                                },
                                pitchPercent = 100,
                                volume = 2 * volumeless,
                                soundLevel = 87
                            },
                            ent
                        )
                        ]]
                    elseif ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "run" then
                        --[[
                        AdvancedPillSound(
                            {
                                stringe = {
                                    "gentoi/rat/run1.wav",
                                    "gentoi/rat/run2.wav",
                                    "gentoi/rat/run3.wav",
                                    "gentoi/rat/run4.wav",
                                    "gentoi/rat/run5.wav",
                                    "gentoi/rat/run6.wav",
                                    "gentoi/rat/run7.wav"
                                },
                                pitchPercent = 100,
                                volume = 2,
                                soundLevel = 87
                            },
                            ent
                        )
                        AdvancedPillSound(
                            {
                                stringe = {
                                    "gentoi/rat/footstep1.wav",
                                    "gentoi/rat/footstep2.wav",
                                    "gentoi/rat/footstep3.wav"
                                },
                                pitchPercent = 100,
                                volume = 2 * volumeless,
                                soundLevel = 87
                            },
                            ent
                        )
                        ]]
                        AdvancedPillSound(
                            {
                                stringe = {
                                    "gentoi/rat/step1.wav",
                                    "gentoi/rat/step2.wav",
                                    "gentoi/rat/step3.wav",
                                    "gentoi/rat/step4.wav",
                                    "gentoi/rat/step5.wav"
                                },
                                pitchPercent = 100,
                                volume = 2 * volumeless,
                                soundLevel = 87
                            },
                            ent
                        )
                    elseif ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "Cidle Walk" then
                        AdvancedPillSound(
                            {
                                stringe = {
                                    "gentoi/rat/vent1.wav",
                                    "gentoi/rat/vent2.wav",
                                    "gentoi/rat/vent3.wav",
                                    "gentoi/rat/vent4.wav",
                                    "gentoi/rat/vent5.wav"
                                },
                                pitchPercent = 100,
                                volume = 0.6 * volumeless,
                                soundLevel = 87
                            },
                            ent
                        )
                    end

                end
            end

            if event == "ragdoll" then
                local jumpscare_entity = ent.jumpscare_entity
                if !(IsValid(jumpscare_entity)) then return end

                local ragdoll = ents.Create("prop_ragdoll")
                ragdoll:SetModel(jumpscare_entity:GetModel())
                ragdoll:SetPos(jumpscare_entity:GetPos())
                ragdoll:SetAngles(jumpscare_entity:GetAngles())
                ragdoll:SetSkin(jumpscare_entity:GetSkin() or 0)
                ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                ragdoll:Spawn()


                local physCount = ragdoll:GetPhysicsObjectCount()
                if physCount <= 0 then
                    ragdoll:Remove()
                    return end

                if not jumpscare_entity:IsPlayer() then
                    local wep = jumpscare_entity:GetActiveWeapon()
                    if IsValid(wep) then
                        jumpscare_entity.OldWeapon = wep
                        wep:SetNoDraw(true)
                    end
                end

                if jumpscare_entity.GetBodyGroups then
                    for _, bg in ipairs(jumpscare_entity:GetBodyGroups()) do
                        ragdoll:SetBodygroup(bg.id, jumpscare_entity:GetBodygroup(bg.id))
                    end
                end

                if jumpscare_entity.GetPlayerColor and ragdoll.SetPlayerColor then
                    ragdoll:SetPlayerColor(jumpscare_entity:GetPlayerColor())
                end

                if jumpscare_entity.GetColor then
                    ragdoll:SetColor(jumpscare_entity:GetColor())
                end

                if jumpscare_entity.GetMaterial then
                    ragdoll:SetMaterial(jumpscare_entity:GetMaterial())
                end

                if ragdoll.GetNumSubMaterials and ragdoll.SetSubMaterial and jumpscare_entity.GetSubMaterial then
                    for i = 0, ragdoll:GetNumSubMaterials() - 1 do
                        local sub = jumpscare_entity:GetSubMaterial(i)
                        if sub then
                            ragdoll:SetSubMaterial(i, sub)
                        end
                    end
                end

                jumpscare_entity:SetNoDraw(true)
                jumpscare_entity:SetNotSolid(true)

                ent.CurrentJumpscareRagdoll = ragdoll
                ent:DeleteOnRemove(ragdoll)

                hook.Add("Think", "ragdoll_nosey".. ent:EntIndex(), function()
                    if !IsValid(ragdoll) then return end
                    if SERVER then
                        local headPhys = nil

                        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                            local phys = ragdoll:GetPhysicsObjectNum(i)
                            if IsValid(phys) then
                                local boneIndex = ragdoll:TranslatePhysBoneToBone(i)
                                local boneName = ragdoll:GetBoneName(boneIndex) or ""
                                if string.find(string.lower(boneName), "head") then
                                    headPhys = phys
                                    break
                                end
                            end
                        end

                        if !IsValid(headPhys) then
                            headPhys = ragdoll:GetPhysicsObject()
                        end

                        if IsValid(headPhys) then
                            local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))
                            local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                            local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos)
                            headPhys:SetPos(cam.Pos + Vector(0,0,0))
                            headPhys:SetAngles(cam.Ang)

                            headPhys:Wake()
                        end
                    end
                end)
            end

            if event == "DieFromJumpscare" then
                if SERVER then
                    if ent.CurrentJumpscareRagdoll then
                        if IsValid(ent.CurrentJumpscareRagdoll) then
                            ent:DontDeleteOnRemove(ent.CurrentJumpscareRagdoll)
                        end
                    end
                    hook.Remove('Think', "ragdoll_nosey".. ent:EntIndex())
                    
                    timer.Simple(0,function()
                        if !IsValid(ent) then return end
                        local jumpscare_entity = ent.jumpscare_entity
                        if !(IsValid(jumpscare_entity)) or !IsValid(ent) then return end
                        ent.jumpscare_entity = nil
                        jumpscare_entity:SetPos(ent.entitylastpos)
                        jumpscare_entity:SetAngles(ent.entitylastang)
                        if jumpscare_entity:IsPlayer() then
                            net.Start('OM_gentoi_rat_jumpscarecam')
                            net.WriteEntity(puppet)
                            net.WriteBool(false)
                            net.Send(jumpscare_entity)
                            jumpscare_entity:Kill(ply)
                        else
                            jumpscare_entity:NextThink(CurTime())
                            jumpscare_entity:TakeDamage(1e9, ply)
                        end
                        ent:RemoveCallOnRemove("RachelJumpscare"..ent:EntIndex())
                    end)
                end
            end
        end
    end,

    initialize_noodles_gentoi_rat_pill=function(initializetable,initializetable2,initializetable3)
        if SERVER then
            if initializetable2["player"]:IsPlayer() then
                net.Start("OM_gentoi_rat_CameraCode_n")
                net.WriteEntity(initializetable2["entity"])
                net.Send(initializetable2["player"])
            end
        end

    end,

    onremove_noodles_gentoi_rat_pill=function(initializetable,initializetable2,initializetable3)
        if IsValid(initializetable2["player"]) then
            initializetable2["player"]:SetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2", 0)
            initializetable2["player"]:SetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac1", 0)
        end
        initializetable2["entity"]:StopSound("gentoi/rat/Attack twitch.wav")
        initializetable2["entity"]:StopSound("gentoi/rat/Attack ambiance.wav")

    end,

    think_noodles_gentoi_rat_pill = function(ply, ent)

        local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
        if IsValid(ent2) then
            ent.ShouldPoseParameter = true
            local self = ent
            local puppet = ent:GetPuppet()

            if self.formTable.aim then
                self.SmoothYaw = self.SmoothYaw or 0
                self.SmoothPitch = self.SmoothPitch or 0

                if IsValid(puppet) then

                    local bone = puppet:LookupBone("Model Head")

                    if bone then
                        local pos, ang = puppet:GetBonePosition(bone)

                        local directinangle = (ent2:EyePos() - pos):Angle()

                        local yaw = math.AngleDifference(
                            directinangle.y,
                            puppet:GetAngles().y
                        )

                        local pitch = math.AngleDifference(
                            directinangle.p,
                            puppet:GetAngles().p
                        )

                        self.SmoothYaw = Lerp(FrameTime() * 10, self.SmoothYaw, yaw)
                        self.SmoothPitch = Lerp(FrameTime() * 10, self.SmoothPitch, pitch)

                        puppet:SetPoseParameter(self.formTable.aim.xPose, self.SmoothYaw*0.8)
                        puppet:SetPoseParameter(self.formTable.aim.yPose, self.SmoothPitch)
                    end
                end
            end
        else
            ent.ShouldPoseParameter = false
        end
        local shadowmode = false
        if SERVER then

            ent.RatTimesLost = ent.RatTimesLost or 0
            ent.RatKillTimer = ent.RatKillTimer or 1

            if ent.RatTimesLost >= 6 then
                shadowmode = true
            end
            --[[ Speed handeler
                desc: This is the speed handeler, if a ability gives him speed boost, use this code to boost the values up.
            ]]
            local speed = {
                ['walk'] = GetConVar("GentoiPills_rat_walkspeed"):GetFloat(),
                ['run'] = GetConVar("GentoiPills_rat_runspeed"):GetFloat(),
                ['ducked'] = GetConVar("GentoiPills_rat_crouchspeed"):GetFloat(),
                ['jumppower'] = GetConVar("GentoiPills_rat_jumppower"):GetFloat()
            }

            local currentcolor = ent:GetPuppet():GetColor()
            ent:GetPuppet():SetColor(Color(0,255,0, currentcolor.a))

            if ent:GetNWFloat("pillrat_fnac2_speedboost") > CurTime() then
                speed["run"] = speed["run"] + GetConVar("GentoiPills_rat_SneakUp_invisadd_run"):GetFloat()
            end

            if ent:GetNWBool("Rat_gentoi_invis") then
                speed["walk"] = speed["walk"] + GetConVar("GentoiPills_rat_SneakUp_invisadd_walk"):GetFloat()
                speed["run"] = speed["run"] + GetConVar("GentoiPills_rat_SneakUp_invisadd_run"):GetFloat()
                speed["ducked"] = speed["ducked"] + GetConVar("GentoiPills_rat_SneakUp_invisadd_walk"):GetFloat()
                ent:GetPuppet():DrawShadow(false)
            else
                ent:GetPuppet():DrawShadow(true)
            end
            if shadowmode then 
                speed["walk"] = speed["walk"] + 35
                speed["run"] = speed["run"] + 35
                speed["ducked"] = speed["ducked"] + 35
            end
            --ply:SetNWFloat("NoJump_gentoi_rat", CurTime()+0.2)


            if IsValid(ply) and IsValid(ent) then
                pk_pills.setCostumeMoveSpeed(ent, speed.walk, speed.run, speed.ducked, speed.jumppower)
            end

            local puppet = ent:GetPuppet()
            if ent.jumpscare_entity then
                local entity = ent.jumpscare_entity
                if IsValid(entity) then

                    local lengthofentitybody = (entity:EyePos() - entity:GetPos()):Length() /2

                    local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

                    if entity:Health() < 0.1 and entity:IsPlayer() then
                        ent.jumpscare_entity = nil
                    else
                        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                        local lengthofentitybody = ((maxs.z - mins.z)/2)*0.3

                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - entity:GetUp() * lengthofentitybody)
                        entity:SetPos(NewVector)
                        entity:SetAngles(newAngle)
                    end
                end
            end

            ent.rat_invis_alpha = ent.rat_invis_alpha or 255

            if ent:GetNWBool("Rat_gentoi_invis") or ent:GetNWFloat("StunnedInvis") > CurTime() then
                ent.rat_invis_alpha = Lerp(FrameTime() * 15, ent.rat_invis_alpha, 0)
            else
                ent.rat_invis_alpha = Lerp(FrameTime() * 15, ent.rat_invis_alpha, 255)
            end

            if ent:GetNWFloat("StunnedInvis") > CurTime() then
                ply:SetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2", CurTime()+ 0.1)
            end
            
            ent:GetPuppet():SetRenderMode(RENDERMODE_TRANSCOLOR)

            ent:GetPuppet():SetColor(Color(
                255,
                255,
                255,
                math.Round(ent.rat_invis_alpha)
            ))

            if ent:GetNW2Float("rat_invvis_waiting") > CurTime() then
                if not ent.rat_invvis_waiting then
                    ent.rat_invvis_waiting = true
                end
                ply:SetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2", CurTime()+ 0.1)

                tracefuntion(
                    ply,
                    function(starelist)
                        local closest_entity
                        local closest_dist = math.huge

                        for _, v in ipairs(starelist) do
                            if SERVER and SherlockHNS and v:IsPlayer() and not SherlockHNS.CanTarget(v, ply) then continue end
                            if v:GetNWFloat("gent_rat_hudpaint_border_shadow") > CurTime() or v:GetNWFloat("gent_rat_hudpaint_border_normal") > CurTime() then
                                continue
                            end

                            local dist = ent:GetPos():DistToSqr(v:GetPos())

                            if dist < closest_dist then
                                closest_dist = dist
                                closest_entity = v
                            end
                        end

                        if IsValid(closest_entity) then
                            ent:SetNW2Entity("rat_opponent_gentoi", closest_entity)
                            closest_entity:SetVelocity(Vector(0,0,0))
                            closest_entity:SetLocalVelocity(Vector(0,0,0))

                            ent.rat_invvis_waiting = false
                            ent:SetNW2Float("rat_invvis_waiting", 0)

                            --print(closest_entity)
                        end
                    end,
                    20
                )
            else
                if ent.rat_invvis_waiting then
                    ent.rat_invvis_waiting = false

                    ent:SetNWFloat("pillrat_fnac2_speedboost", CurTime()+ GetConVar("GentoiPills_rat_SneakUp_speedupduration"):GetFloat() )
                end
            end

            local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
            if IsValid(ent2) then
                if shadowmode then
                    ent2:SetNWFloat("gent_rat_hudpaint_border_shadow", CurTime()+0.4)
                else
                    ent2:SetNWFloat("gent_rat_hudpaint_border_normal", CurTime()+0.4)
                end

                if ent2:Health() <= 0.1 then
                    ent:SetNW2Entity("rat_opponent_gentoi", NULL)
                end

                if not ent.rat_rat_opponent_gentoi_bool then
                    ent.rat_rat_opponent_gentoi_bool = true
                    ent:SetNWBool("Twitch_ratmode", false)
                    ent:SetNWFloat("RatMode_swapdelay", CurTime() + 0.2)
                    ent:SetNWFloat("RatMode_killtimer", CurTime() + 1) --ent.RatKillTimer
                    ent:SetNWFloat("RatMode_sethealth", GetConVar("GentoiPills_rat_SneakUp_rathealth"):GetFloat())

                    if shadowmode then
                        ent:SetNWFloat("Gentoi_rat_movesleft", GetConVar("GentoiPills_rat_SneakUp_minigame_shadowmoves"):GetFloat())
                        ent:SetNWFloat("Gentoi_rat_twitchesleft", GetConVar("GentoiPills_rat_SneakUp_minigame_shadowtwitches"):GetFloat())
                    else
                        ent:SetNWFloat("Gentoi_rat_movesleft", GetConVar("GentoiPills_rat_SneakUp_minigame_moves"):GetFloat())
                        ent:SetNWFloat("Gentoi_rat_twitchesleft", GetConVar("GentoiPills_rat_SneakUp_minigame_twitches"):GetFloat())
                    end

                    AdvancedPillSound(
                        {
                            stringe = "gentoi/rat/Attack Begin.wav",
                            pitchPercent = 100,
                            volume = 1,
                            soundLevel = 87
                        },
                        ent
                    )

                    AdvancedPillSound(
                        {
                            stringe = "gentoi/rat/Attack ambiance.wav",
                            pitchPercent = 100,
                            volume = 1,
                            soundLevel = 87
                        },
                        ent
                    )
                else
                    
                    ply:SetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2", CurTime()+ 0.1)
                    ent2:SetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2", CurTime()+ 0.1)


                    local ang = (ent2:GetPos() - ply:GetPos()):Angle()
                    ang.p = 0
                    ang.r = 0
                    ang.y = ang.y
                    ent:SetNW2Angle("pill_assignedangle",ang)

                    local w = ply:KeyDown(IN_FORWARD)
                    local a = ply:KeyDown(IN_MOVELEFT)
                    local s = ply:KeyDown(IN_BACK)
                    local d = ply:KeyDown(IN_MOVERIGHT)
                    local notpressin = false
                    if w and d then
                        ent:SetNWFloat("RatMode_pre", 5)
                    elseif d and s then
                        ent:SetNWFloat("RatMode_pre", 4)
                    elseif s and a then
                        ent:SetNWFloat("RatMode_pre", 3)
                    elseif a and w then
                        ent:SetNWFloat("RatMode_pre", 1)
                    elseif w then
                        ent:SetNWFloat("RatMode_pre", 0)
                    elseif d then
                        ent:SetNWFloat("RatMode_pre", 6)
                    elseif a then
                        ent:SetNWFloat("RatMode_pre", 2)
                    else
                        notpressin = true
                        ent:SetNWFloat("RatMode_pre", math.random(0,6))
                    end

                    if ent:GetNWFloat("RatMode_swapdelay") < CurTime() and (ent:GetNWFloat("RatMode_swapdelay_toolate") > CurTime() ) then
                        if ent:GetNWFloat("Gentoi_rat_twitchesleft") > 0 then
                            if ent:GetNWFloat("RatMode_pre") ~= ent:GetNWFloat("RatMode") and not ent:GetNWBool("Twitch_ratmode") and not notpressin then 
                                ent:SetNWBool("Twitch_ratmode", true)
                                ent:SetNWFloat("RatMode", ent:GetNWFloat("RatMode_pre"))
                                ent:SetNWFloat("Gentoi_rat_twitchesleft", ent:GetNWFloat("Gentoi_rat_twitchesleft")-1)
                                ent:SetNWFloat("RatMode_killtimer", CurTime() + ent.RatKillTimer)
                                AdvancedPillSound(
                                    {
                                        stringe = "gentoi/rat/Attack Dodge.wav",
                                        pitchPercent = 100,
                                        volume = 3,
                                        soundLevel = 87
                                    },
                                    ent
                                )
                            end
                        end
                    end

                    local demomode = false

                    if ent:GetNWBool("FlashLightON") and ent:GetNWFloat("RatMode_flashlightduration") < CurTime() then
                        if ent:GetNWFloat("Gentoi_rat_movesleft") > 0 then
                            ent:SetNWFloat("RatMode_killtimer", CurTime() + ent.RatKillTimer) --ent.RatKillTimer 
                            ent:SetNWFloat("RatMode_preventtime", CurTime() + 0.04)

                            if ent:GetNWFloat("RatMode_pre") ~= ent:GetNWFloat("RatMode") then
                                AdvancedPillSound(
                                    {
                                        stringe = "gentoi/rat/Attack Dodge.wav",
                                        pitchPercent = 100,
                                        volume = 3,
                                        soundLevel = 87
                                    },
                                    ent
                                )
                            end

                            ent:SetNWFloat("RatMode", ent:GetNWFloat("RatMode_pre"))
                            ent:SetNWFloat("RatMode_swapdelay", CurTime() + 0.2)
                            ent:SetNWFloat("RatMode_swapdelay_toolate", CurTime() + 0.5)
                            ent:SetNWBool("FlashLightON", false)

                            ent:SetNWFloat("Gentoi_rat_movesleft", ent:GetNWFloat("Gentoi_rat_movesleft")-1)
                            ent:SetNWBool("Twitch_ratmode", false)
                        end
                    else
                        if ent:GetNWFloat("RatMode_killtimer") < CurTime() and ent:GetNWFloat("RatMode_flashlightduration") < CurTime() then
                            if not demomode then

                                local anim = ent:GetPuppet():LookupSequence("Kill")
                                local dur = ent:GetPuppet():SequenceDuration(anim)
                                racheljackietien_jumpscare(
                                    ply,
                                    ent,
                                    dur,
                                    function()
                                        ent:PillAnim('kill')

                                        AdvancedPillSound(
                                            {
                                                stringe = "gentoi/rat/monster rat kill (1).wav",
                                                pitchPercent = 100,
                                                volume = 2,
                                                soundLevel = 87
                                            },
                                            ent
                                        )
                                    end,
                                    ent:GetNW2Entity("rat_opponent_gentoi")
                                )
                                ent:SetNW2Entity("rat_opponent_gentoi", NULL)
                            end
                        end
                    end

                    if ent:GetNWFloat("RatMode_flashlightduration") > CurTime() then
                        ent:SetNWBool("FlashLightON", false)
                    end


                    if demomode then
                        if ent:GetNWFloat("RatMode_preventtime") < CurTime() then
                            ent:SetNWBool("FlashLightON", true)
                        end
                    else
                        tracefuntion(
                            ply,
                            function(starelist)
                                for _, v in ipairs(starelist) do
                                    if IsValid(v) and v == ent2 then
                                        if ent:GetNWFloat("RatMode_preventtime") > CurTime() then continue end
                                        ent:SetNWBool("FlashLightON", true)
                                    end
                                end
                            end,
                            3.5
                        )
                    end

                    if ent:GetNWBool("FlashLightON") then

                        ent:SetNWFloat("RatMode_sethealth", ent:GetNWFloat("RatMode_sethealth")-0.14 * GetConVar("GentoiPills_rat_SneakUp_minigame_ratheathdrain_multiplyer"):GetFloat())
                        if not ent.rat_FlashLightON_bool then
                            ent.rat_FlashLightON_bool = true

                            if ent:GetPuppet():GetSkin() == 1 then
                                ent:SetNWFloat("RatMode_flashlightduration", CurTime() + ent.RatKillTimer*0.5 )
                            else
                                ent:SetNWFloat("RatMode_flashlightduration", CurTime() + ent.RatKillTimer ) --CurTime()+ent.RatKillTimer
                            end

                            AdvancedPillSound(
                                {
                                    stringe = "gentoi/rat/Attack twitch.wav",
                                    pitchPercent = 100,
                                    volume = 2,
                                    soundLevel = 87
                                },
                                ent
                            )
                        end

                        ent:SetNWFloat("RatMode_killtimer", CurTime() + ent.RatKillTimer)
                    else
                        if ent:GetPuppet():GetSkin() == 1 then
                            ent:SetNWFloat("RatMode_sethealth", math.Clamp(ent:GetNWFloat("RatMode_sethealth")+0.08 * GetConVar("GentoiPills_rat_SneakUp_minigame_ratheathRegain_multiplyer"):GetFloat(),0,100))
                        else
                            ent:SetNWFloat("RatMode_sethealth", math.Clamp(ent:GetNWFloat("RatMode_sethealth")+0.05 * GetConVar("GentoiPills_rat_SneakUp_minigame_ratheathRegain_multiplyer"):GetFloat(),0,100))
                        end
                        if ent.rat_FlashLightON_bool then
                            ent.rat_FlashLightON_bool = false
                            ent:StopSound("gentoi/rat/Attack twitch.wav")
                        end
                    end

                    if ent:GetNWFloat("RatMode_sethealth") < 0 then
                        if ply:IsPlayer() then
                            net.Start("OM_gentoi_rat_flash")
                            net.Send(ply)
                        end
                        if ent2:IsPlayer() then
                            net.Start("OM_gentoi_rat_flash")
                            net.Send(ent2)
                        end

                        ent.RatTimesLost = ent.RatTimesLost + 1
                        ent.RatKillTimer = math.Clamp(ent.RatKillTimer-0.1*ent.RatTimesLost,0.8,2)

                        AdvancedPillSound(
                            {
                                stringe = "gentoi/rat/Thunder 01.wav",
                                pitchPercent = 100,
                                volume = 1,
                                soundLevel = 87
                            },
                            ent
                        )
                        
                        ent:SetNW2Entity("rat_opponent_gentoi", NULL)


                        local dur = GetConVar("GentoiPills_rat_SneakUp_cddetected"):GetFloat()
                        ent:SetNW2Float("rat_invis_ability_cd", CurTime()+ dur)
                        pk_pills.setHNSCooldown(ent, "sneak", ent:GetNW2Float("rat_invis_ability_cd") - CurTime())
                        ent:SetNW2Float("rat_invis_ability_cd_dur", dur)

                        ent:SetNWFloat("StunnedInvis", CurTime()+GetConVar("GentoiPills_rat_SneakUp_minigamefinishedstun"):GetFloat())

                        AdvancedPillSound(
                            {
                                stringe = "gentoi/rat/Crawl Under Bed.wav",
                                pitchPercent = 100,
                                volume = 1,
                                soundLevel = 87
                            },
                            ent
                        )
                    end
                end
            else
                if ent.rat_rat_opponent_gentoi_bool then
                    ent.rat_rat_opponent_gentoi_bool = false
                    ent:StopSound("gentoi/rat/Attack twitch.wav")
                    ent:StopSound("gentoi/rat/Attack ambiance.wav")
                end
            end

            if shadowmode then 

                if not ent.StartShadowMode then
                    ent.StartShadowMode = true

                    net.Start("OM_gentoi_rat_PlayGlobalSound")
                    net.Broadcast()
                end

                ent:GetPuppet():SetSkin(1)
                if ent:GetNWFloat("JumpscareDuration") > CurTime() then
                    ent:GetPuppet():SetBodygroup(1,0)
                else
                    ent:GetPuppet():SetBodygroup(1,1)
                end
            else
                ent:GetPuppet():SetSkin(0)
                ent:GetPuppet():SetBodygroup(1,0)
            end
        else
            local ply = LocalPlayer()
            if IsValid(ply) and ply == ent:GetPillUser() then

                ent.Flashlight_gentoi_rat_lerp = ent.Flashlight_gentoi_rat_lerp or 0
                if ent:GetNWBool("Flashlight_gentoi_rat") then
                    ent.Flashlight_gentoi_rat_lerp = Lerp(FrameTime()*5, ent.Flashlight_gentoi_rat_lerp, 1)
                    if not ent.Flashlight_gentoi_rat_Bool then
                        ent.Flashlight_gentoi_rat_Bool = true
                        LocalPlayer():EmitSound("buttons/lightswitch2.wav", 60, 100, 0.2)
                    end
                else
                    ent.Flashlight_gentoi_rat_lerp = Lerp(FrameTime()*5, ent.Flashlight_gentoi_rat_lerp, 0)
                    if ent.Flashlight_gentoi_rat_Bool then
                        ent.Flashlight_gentoi_rat_Bool = false
                        LocalPlayer():EmitSound("buttons/lightswitch2.wav", 60, 100, 0.2)
                    end
                end

                if ent.Flashlight_gentoi_rat_lerp > 0.1 then
                    local light = DynamicLight(ply:EntIndex())
                    if light then
                        local pos = ply:EyePos()
                        local ang = ply:EyeAngles()

                        light.pos = pos
                        light.r = 7
                        light.g = 7
                        light.b = 7
                        light.brightness = 1 * ent.Flashlight_gentoi_rat_lerp
                        light.Decay = 1000
                        light.Size = 2100 * ent.Flashlight_gentoi_rat_lerp
                        light.DieTime = CurTime() + 0.1

                        light.pos = pos + ang:Forward() * 10
                    end

                    if not ent.SpotLight then
                        ent.SpotLight = ProjectedTexture()
                        local name = "CleanupSpotLight".. tostring(ent)
                        hook.Add("EntityRemoved", name, function(ent)
                            hook.Remove("EntityRemoved", name)
                            if not IsValid(ent) then return end

                            if ent.SpotLight then
                                ent.SpotLight:Remove()
                                ent.SpotLight = nil
                            end
                        end)
                    end

                    local light = ent.SpotLight
                    if light then

                        local pos = ply:EyePos()
                        local ang = ply:EyeAngles()

                        light:SetPos(pos + ang:Forward() * 10)
                        light:SetAngles(ang)

                        light:SetFOV(60)
                        light:SetFarZ(1500 * ent.Flashlight_gentoi_rat_lerp)

                        light:SetBrightness(3 * ent.Flashlight_gentoi_rat_lerp)
                        light:SetColor(Color(255, 255, 245))

                        light:SetTexture("effects/flashlight001")

                        light:Update()
                    end
                else
                    if ent.SpotLight then
                        ent.SpotLight:Remove()
                        ent.SpotLight = nil
                    end
                end

            end
        end
    end,

    noodles_gentoi_rat_keybinds_up = function(ply,ent,button)
        if SERVER then
            if button == KEY_SLASH then
                ent:SetNWBool('HoldingDownMenu_rat', false)
                --ent:SetNW2Float("rat_opponent_gentoi", ply)
                ent:SetNW2Float('HoldingDownMenu_rat_timeframe', CurTime())
            end
        end
    end,

    noodles_gentoi_rat_keybinds_down = function(ply,ent,button)
        if SERVER then
            if button == KEY_SLASH then
                ent:SetNWBool('HoldingDownMenu_rat', true)
                ent:SetNW2Float('HoldingDownMenu_rat_timeframe', CurTime())
                --ent:SetNW2Float("rat_opponent_gentoi", ply)
            end
            if button == KEY_1 then
                if SERVER then

                    local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
                    if IsValid(ent2) then return end
                    if ent:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2") > CurTime() then return end
                    if ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2") > CurTime() then return end
                    if ent:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac1") > CurTime() then return end
                    if ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac1") > CurTime() then return end
                    if ent:GetNWFloat("StunnedInvis") > CurTime() then return end
                    if ent:GetNW2Float("rat_invis_ability_cd") > CurTime() then return end
                    if ent:GetNW2Float("rat_invvis_waiting") > CurTime() then return end

                    local dur = GetConVar("GentoiPills_rat_SneakUp_cdinit"):GetFloat()
                    if ent:GetNWBool("Rat_gentoi_invis") then
                        dur = GetConVar("GentoiPills_rat_SneakUp_cdout"):GetFloat()
                        ent:SetNWBool("Rat_gentoi_invis", false)

                        for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 450)) do
                            if v:IsPlayer() then
                                if SherlockHNS and not SherlockHNS.CanTarget(v, ply) then continue end
                                if v == ent or v == ply then continue end

                                if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or ((v:IsNPC() or v:IsNextBot()) and v:Health() > 0) then
                                    local trace = util.TraceLine({
                                        start = ent:EyePos(),
                                        endpos = v:EyePos(),
                                        filter = {ent, ply},
                                        mask = MASK_VISIBLE
                                    })

                                    if not trace.Hit then
                                        ent:SetNW2Float("rat_invvis_waiting", CurTime() + math.Clamp(GetConVar("GentoiPills_rat_SneakUp_detectionduration"):GetFloat() - math.Clamp(ent.RatTimesLost*0.2,0,2.3), 0.3, 1e9) )
                                        dur = GetConVar("GentoiPills_rat_SneakUp_cddetected"):GetFloat()

                                        if ent.RatTimesLost >= 3 then
                                            AdvancedPillSound(
                                                {
                                                    stringe = "gentoi/rat/Knocking Aggressive.wav",
                                                    pitchPercent = 100,
                                                    volume = 2,
                                                    soundLevel = 87
                                                },
                                                ent
                                            )
                                        else
                                            AdvancedPillSound(
                                                {
                                                    stringe = "gentoi/rat/Knocking Calm.wav",
                                                    pitchPercent = 100,
                                                    volume = 2,
                                                    soundLevel = 87
                                                },
                                                ent
                                            )
                                        end
                                        break
                                    end
                                end
                            end
                        end

                        ply:SetVelocity(Vector(0,0,0))
                        ply:SetLocalVelocity(Vector(0,0,0))
                    else
                        ent:SetNWBool("Rat_gentoi_invis", true)
                    end
                    ent:SetNW2Float("rat_invis_ability_cd", CurTime()+ dur)
                    pk_pills.setHNSCooldown(ent, "sneak", ent:GetNW2Float("rat_invis_ability_cd") - CurTime())
                    ent:SetNW2Float("rat_invis_ability_cd_dur", dur)
                end
            end
            if button == KEY_R then
                if SERVER then
                    if ent:GetNWBool("Shiftlock") then
                        ent:SetNWBool("Shiftlock", false)
                    else
                        ent:SetNWBool("Shiftlock", true)
                    end
                end
            end
            if button == KEY_F then
                if SERVER then
                    if ent:GetNWBool("Flashlight_gentoi_rat") then
                        ent:SetNWBool("Flashlight_gentoi_rat", false)
                    else
                        ent:SetNWBool("Flashlight_gentoi_rat", true)
                    end
                end
            end
        end
    end,
    
    attack = {
        mode = 'trigger',
        func = function(ply, ent)

            local ent2 = ent:GetNW2Entity("rat_opponent_gentoi")
            if IsValid(ent2) then return end
            if ent:GetNWFloat("StunnedInvis") > CurTime() then return end
            if ent:GetNW2Float("rat_invvis_waiting") > CurTime() then return end
            if ent:GetNWBool("Rat_gentoi_invis") then return end
            if ent:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2") > CurTime() then return end
            if ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac2") > CurTime() then return end
            if ent:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac1") > CurTime() then return end
            if ply:GetNWFloat("DisablePlayerMovement_gennytoi_pillrat_fnac1") > CurTime() then return end

            local anim = ent:GetPuppet():LookupSequence("Kill")
            local dur = ent:GetPuppet():SequenceDuration(anim)
            return racheljackietien_jumpscare(
                ply,
                ent,
                dur,
                function()
                    ent:PillAnim('kill')

                    AdvancedPillSound(
                        {
                            stringe = "gentoi/rat/monster rat kill (1).wav",
                            pitchPercent = 100,
                            volume = 2,
                            soundLevel = 87
                        },
                        ent
                    )
                end
            )
        end
    },


    attack2 = {
        mode = "trigger",
        func = function(ply, ent)
        end,
    },

    reload=function(ply,ent)
    end,
    flashlight = function(ply, ent)
    end,
        
    jump = function(ply, ent)
    end
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
    pk_pills.bindHNSButtons(form, "noodles_gentoi_rat_keybinds_down", {
        { id = "sneak", name = "Emboscada", button = KEY_1, keyLabel = "1" },
        { id = "shiftlock", name = "Travar corrida", button = KEY_R, keyLabel = "R" },
        { id = "light", name = "Lanterna", button = KEY_F, keyLabel = "F" },
    })
end )
