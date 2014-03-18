AddCSLuaFile( "switchableseats.lua" )

if CLIENT then
	SWITCHABLESEATS = {}
	
	local function HighlightExit( Tbl )
		local Pos, Parent = Tbl[1], Tbl[2]
		local ent = ents.CreateClientProp()
		ent:SetPos( Parent:LocalToWorld(Pos) )
		ent:SetParent( Parent )
		ent:SetModel( "models/player.mdl" )
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		ent:SetColor(Color( 200, 200, 0, 150 ))
		ent:Spawn()
		
		SWITCHABLESEATS.ExitHighlight = ent
	end

	net.Receive( "SWITCHABLESEATS_update", function()
		local Table, Exit = net.ReadTable(), nil
		
		if SWITCHABLESEATS.ExitHighlight then
			SWITCHABLESEATS.ExitHighlight:Remove()
			SWITCHABLESEATS.ExitHighlight = nil
		end
		SWITCHABLESEATS.highlightall = {}
		SWITCHABLESEATS.highlightone = {}
		SWITCHABLESEATS.Seats = Table
		for k,v in pairs( Table ) do
			if Entity(k) and IsValid(Entity(k)) then
				if v.Selected then SWITCHABLESEATS.highlightone = { Entity(k) } end
				if v.Exit and not Exit then Exit = {v.Exit, Entity(k)} end 
				table.insert( SWITCHABLESEATS.highlightall, Entity(k) )
			end
		end
		
		if Exit then
			HighlightExit( Exit )
		end
	end)

	hook.Add( "PreDrawHalos", "SWITCHABLESEATS_Halos", function()
		if SWITCHABLESEATS and SWITCHABLESEATS.highlightall then
			halo.Add( SWITCHABLESEATS.highlightall, Color(255,255,255), 5, 5, 1, true, true )
		end
		if SWITCHABLESEATS and  SWITCHABLESEATS.highlightone then
			halo.Add( SWITCHABLESEATS.highlightone, Color(255,255,0), 5, 5, 2, true, true )
		end
	end)
	
	hook.Add( "PostDrawTranslucentRenderables", "SWITCHABLESEATS_Numbers", function()
		if SWITCHABLESEATS then
			if SWITCHABLESEATS.Seats  then
				for k,v in pairs( SWITCHABLESEATS.Seats ) do
					if v.Key then
					
						local ent = Entity(k)
						
						if IsValid( ent ) then
						
							local Ang = (ent:GetPos() - LocalPlayer():GetPos()):Angle()
							
							cam.Start3D2D( ent:GetPos() + Vector(0, 0, 60), Angle(0,Ang.y-90,90), 1)
								cam.IgnoreZ( true )
								surface.SetFont("ChatFont")
								local Text = ""..v.Key
								local X = surface.GetTextSize(Text)/2
								surface.SetTextPos(-X, 0) 
								local Col = Color(255,255,255)
								if v.Selected then Col = Color(255,255,150) end
								surface.SetTextColor( Col )
								surface.DrawText( Text )
								cam.IgnoreZ( false )
							cam.End3D2D()
							
						end
					end
				end
			end
			if SWITCHABLESEATS.ExitHighlight then
				local ent = SWITCHABLESEATS.ExitHighlight
				if IsValid( ent ) then
					local Ang = (ent:GetPos() - LocalPlayer():GetPos()):Angle()
							
					cam.Start3D2D( ent:GetPos() + Vector(0, 0, 90), Angle(0,Ang.y-90,90), 1)
						cam.IgnoreZ( true )
						surface.SetFont("ChatFont")
						local Text = "exit"
						local X = surface.GetTextSize(Text)/2
						surface.SetTextPos(-X, 0) 
						local Col = Color(255,255,255)
						surface.SetTextColor( Col )
						surface.DrawText( Text )
						cam.IgnoreZ( false )
					cam.End3D2D()
				end
			end
		end
	end)
end

if SERVER then
	
	util.AddNetworkString("SWITCHABLESEATS_update")
	
	if not SWITCHABLESEATS then SWITCHABLESEATS = {} end
	
	local CanUse = function(ply, ent) print("pingaz"); return true end
	if CPPI then 
		local Name = CPPI:GetName()
		if Name == "Falco's prop protection" then
			print("Falco's prop protection")
			CanUse = function(ply, ent) return not FPP.Protect.PlayerUse(ply, ent) != false end
		end
		if Name == "Nadmod Prop Protection" then
			print("Nadmod Prop Protection")
			CanUse = function(ply, ent) return NADMOD.PlayerUse(ply, ent) != false end
		end
		if Name == "Simple Prop Protection" then
			print("Simple Prop Protection")
			CanUse = function(ply, ent) return not SPropProtection.PlayerUse(ply, ent) != false end
		end
		if Name == "Ulysses Prop Share (UPS)" then
			print("Ulysses Prop Share (UPS)")
			CanUse = function(ply, ent) return query(ply, ent, "use") end
		end
	end
	 
	duplicator.RegisterEntityModifier( "SWITCHABLESEATS_Seats", function( ply , Entity , data)
		if !IsValid( Entity ) then return end
		Entity.SSeat = data[1]
		Entity.SSExit = data[2]
		duplicator.StoreEntityModifier( Entity, "SWITCHABLESEATS_Seats", data )
	end)
	
	duplicator.RegisterEntityModifier( "SWITCHABLESEATS_Doors", function( ply , Entity , data)
		if !IsValid( Entity ) then return end
		Entity.SSDoor = data[1]
		duplicator.StoreEntityModifier( Entity, "SWITCHABLESEATS_Doors", data )
	end)
	
	local function FixView( ply )
		ply:SetEyeAngles( (Vector(0,1,0)):Angle() )
	end
	
	local function SwitchSeats( ply, ent )
		if ent:GetDriver() and ent:GetDriver():IsPlayer() then
			ply:SendHint("#tool.switchableseats.occupied"..ent:GetDriver():GetName(),3)
		elseif CanUse(ply, ent) then
			--local Ang = ply:EyeAngles()
			--Ang.r = 0
			ply:GetVehicle():SetThirdPersonMode(false)
			ply:ExitVehicle()
			ply:EnterVehicle(ent)
			FixView( ply )
		end
	end
	
	local function SS_AddChildren( Children )
		local Table = {}
		for _, v in pairs( Children ) do
			if IsValid(v) and v != NULL then
				if (v.SSDoor or v:IsVehicle()) and not Table[v:EntIndex()] then
					Table[v:EntIndex()] = v
				end
				if v:GetChildren() != {} then
					table.Merge(Table, SS_AddChildren( v:GetChildren() ))
				end
			end
		end
		return Table
	end

	function SS_FormatTable( ent )
		if not IsValid( ent ) then return end
		local Table, Entities, ent2, rounds = {}, constraint.GetAllConstrainedEntities( ent ), ent, 0
		
		while Entities and table.Count(Entities)<=1 do
			if ent2:GetParent() then ent2 = ent2:GetParent() end
			Entities = constraint.GetAllConstrainedEntities( ent2 )
			rounds = rounds + 1
			if rounds > 9 then return end
		end
		
		for k,_ in pairs( Entities ) do
			if IsValid(k) and k != NULL then
				if (k.SSDoor or k:IsVehicle()) and not Table[k:EntIndex()] then
					Table[k:EntIndex()] = k
				end
				if k:GetChildren() != {} then
					table.Merge(Table, SS_AddChildren( k:GetChildren() ))
				end
			end
		end
		
		return Table
	end
	
	function SWITCHABLESEATS:SendUpdate( Table, ply )
		net.Start( "SWITCHABLESEATS_update" )
		net.WriteTable( Table )
		net.Send( ply )
	end
	
	
	concommand.Add( "switchableseats_setout", function( ply, _, args )
		if ply:GetActiveWeapon():GetClass() != "gmod_tool" then return end
		local TOOL = ply:GetActiveWeapon():GetToolObject()
		
		if not TOOL.Seats then ply:SendHint("#tool.switchableseats.selvegfirst", 3); return end
		
		local Pos = ply:GetPos()
		
		for k,v in pairs( TOOL.Seats ) do
			local ent = Entity(k)
			if IsValid(ent) then
				v.Exit = ent:WorldToLocal(Pos)
			end
		end
		
		SWITCHABLESEATS:SendUpdate( TOOL.Seats, ply )
		
	end)
	
	
	concommand.Add( "switchableseats_setkey", function( ply, _, args )
		if not args or not args[1] then return end
		local arg = math.modf(args[1])
		if ply:GetActiveWeapon():GetClass() != "gmod_tool" then return end
		local TOOL = ply:GetActiveWeapon():GetToolObject()
		
		if not TOOL.Seats then ply:SendHint("#tool.switchableseats.selvegfirst", 3); return end
		if not TOOL.SelectedSeat then ply:SendHint("#tool.switchableseats.selseatfirst", 3); return end
		
		for k,v in pairs( TOOL.Seats ) do
			if v.Key == arg then
				v.Key = nil
			end
		end
		TOOL.Seats[ TOOL.SelectedSeat ].Key = arg
		SWITCHABLESEATS:SendUpdate( TOOL.Seats, ply )

	end)
	hook.Add("PlayerLeaveVehicle", "SWITCHABLESEATS_Enter", function( ply, veh )
		if not veh.SSExit then return end
		local pos = veh:LocalToWorld(veh.SSExit)
		local trace = util.QuickTrace( pos + Vector(0,0,100), Vector(0,0,-1) )
		if trace.StartSolid then return end
		pos = trace.HitPos
		
		ply:SetPos( pos )
		
		ply.SSJustLeft = true
	end)
	
	hook.Add("KeyRelease", "SWITCHABLESEATS_Enter", function( ply, key )
		if key != IN_USE then return end
		if ply.SSJustLeft then ply.SSJustLeft = nil; return end
		
		local trace = util.TraceLine( util.GetPlayerTrace( ply ) )
		local ent = trace.Entity		

		if not IsValid(ent) or not ent.SSDoor then return end
		local dist = ent:GetPos():Distance(ply:GetPos())
		if dist > 100 then return end
				
		local Entities = SS_FormatTable( ent )
		if not Entities then return end
		local Seats = {}
		for _,v	in pairs( Entities ) do
			if v.SSeat then
				Seats[v.SSeat] = v
			end
		end
		for _,v	in pairs( Entities ) do
			if v:IsVehicle() and not table.HasValue( Seats, v ) then
				table.insert( Seats, v )
			end
		end
		
		for k,v in ipairs( Seats ) do
			if v:GetDriver() == NULL and CanUse(ply, v) then
				ply:EnterVehicle( v )
				FixView( ply )
				return
			end
		end
		
		ply:SendHint("#tool.switchableseats.vehfull", 5)
	end)
	
	hook.Add("PlayerButtonUp", "SWITCHABLESEATS_Switching", function( ply, keypressed )
		if not ply:InVehicle() then return end
		
		local key = keypressed - 1
		if key<1 or key>9 then return end
		
		local veh = ply:GetVehicle()
		if not veh.SSeat then return end
		
		local Entities = SS_FormatTable( veh )
		
		for _ ,v in pairs( Entities ) do
			if v != veh and v.SSeat then
				if v.SSeat == key then
					SwitchSeats( ply, v )
				end
			end
		end		
	end)
end