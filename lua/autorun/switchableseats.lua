AddCSLuaFile( "switchableseats.lua" )

if CLIENT then
	SWITCHABLESEATS = {}
	
	CreateClientConVar("switchableseats_playerlist", "1", true, false)
	
	local function HighlightExit( Pos, Parent )
		local ent = ents.CreateClientProp( "models/player.mdl" )
		ent:SetParent( Parent )
		ent:SetPos( Parent:LocalToWorld(Pos) )
		ent:SetMaterial( "models/debug/debugwhite" )
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		ent:SetColor(Color( 200, 200, 0, 150 ))
		ent:Spawn()
		
		table.insert(SWITCHABLESEATS.ExitHighlight, ent)
	end

	net.Receive( "SWITCHABLESEATS_update", function()
		local Table, Exit = net.ReadTable(), nil
		
		if SWITCHABLESEATS.ExitHighlight then
			for _,v in pairs( SWITCHABLESEATS.ExitHighlight ) do
				v:Remove()
			end
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
			SWITCHABLESEATS.ExitHighlight = {}
			for _,v in pairs( Exit[1] ) do
				HighlightExit( v, Exit[2] )
			end
		end
	end)
	
	net.Receive( "SWITCHABLESEATS_list", function()
		SWITCHABLESEATS.PlyList = net.ReadTable()
	end)
	
	function SWITCHABLESEATS:Hint( msg )
		notification.AddLegacy( msg, NOTIFY_ERROR, 5 )
		surface.PlaySound("buttons/button10.wav")
	end

	hook.Add( "PreDrawHalos", "SWITCHABLESEATS_Halos", function()
		if SWITCHABLESEATS and SWITCHABLESEATS.highlightall then
			halo.Add( SWITCHABLESEATS.highlightall, Color(255,255,255), 5, 5, 1, true, true )
		end
		if SWITCHABLESEATS and  SWITCHABLESEATS.highlightone then
			halo.Add( SWITCHABLESEATS.highlightone, Color(255,255,0), 5, 5, 2, true, true )
		end
	end)
	
	hook.Add( "HUDPaint", "SWITCHABLESEATS_playerlist", function()
		if not GetConVar("switchableseats_playerlist"):GetBool() or not SWITCHABLESEATS.PlyList or not LocalPlayer():InVehicle() then return end
		
		local tbl = SWITCHABLESEATS.PlyList
		local num, ScrX, ScrY = table.Count(tbl), ScrW()/2-100, 0
		
		surface.SetDrawColor( Color( 100, 100, 100, 100 ) )
		surface.DrawRect( ScrX, ScrY, 200, (num+1)*12  )
		
		surface.SetFont("Trebuchet18")
		local X, C = ScrX+12, 0
	
		for k,v in pairs( tbl ) do
		
			local num = tostring(k)
			if k == 10 then num = "0" end
			if k > 10 then num = "X" end
			local txt = num..": "..string.Left(v,23)
			
			local Y = C*12
			C = C + 1
			
			if v == LocalPlayer():GetName() then surface.SetTextColor( Color( 255, 255, 200 ) ) else surface.SetTextColor( Color( 255, 255, 255 ) ) end
			
			surface.SetTextPos(X, Y) 
			surface.DrawText(txt)
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
								
								local Text = tostring(v.Key)
								if v.Key == 10 then Text = "0" end
								
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
				for k,v in pairs( SWITCHABLESEATS.ExitHighlight ) do
					if IsValid( v ) then
						local Ang = (v:GetPos() - LocalPlayer():GetPos()):Angle()
								
						cam.Start3D2D( v:GetPos() + Vector(0, 0, 90), Angle(0,Ang.y-90,90), 1)
						
							cam.IgnoreZ( true )
							surface.SetFont("ChatFont")
							
							local Text = "exit "..k
							
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
		end
	end)
end

if SERVER then
	
	util.AddNetworkString("SWITCHABLESEATS_update")
	util.AddNetworkString("SWITCHABLESEATS_list")
	
	if not SWITCHABLESEATS then SWITCHABLESEATS = {} end
	
	/*
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
	*/
	local CanUse = function( ply, ent ) local ret = hook.Run( "PlayerUse", ply, ent ); return ret != false end
		
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
	
	local function PlyList( tbl )
		local List, Rec = {}, {}
		local C = 1
		for _,v in pairs( tbl ) do
			if IsValid(v) and v:IsVehicle() and v:GetDriver() ~= NULL then
				if v.SSeat then
					List[v.SSeat] = v:GetDriver():GetName()
				else
					List[(C+10)] = v:GetDriver():GetName()
					C = C + 1
				end
				table.insert(Rec, v:GetDriver())
			end
		end
		

		net.Start( "SWITCHABLESEATS_list" )
		net.WriteTable( List )
		net.Send( Rec )
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
		local Entities = constraint.GetAllConstrainedEntities( ent ) or {}
		local Table, ent2, rounds = {}, ent, 0
		
		Entities[ ent ] = {}
		
		while ent2:GetParent() ~= NULL do
			ent2 = ent2:GetParent()
			Entities = constraint.GetAllConstrainedEntities( ent2 )
			rounds = rounds + 1
			if rounds > 9 then return end
		end
		
		for k,_ in pairs( Entities ) do
			if IsValid(k) and k ~= NULL then
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
		
		if not TOOL.Seats then ply:SendLua( "SWITCHABLESEATS:Hint( 'You need to select vehicle with seats first!' )" ); return end
		if TOOL.Exits and table.Count(TOOL.Exits)>9 then ply:SendLua( "SWITCHABLESEATS:Hint( 'Cant add more exits.' )" ); return end
		local Pos = ply:GetPos()
		
		for k,v in pairs( TOOL.Seats ) do
			local ent = Entity(k)
			if IsValid(ent) then
				if not v.Exit then v.Exit = {} end
				table.insert(v.Exit, ent:WorldToLocal(Pos))
			end
		end
		if not TOOL.Exits then TOOL.Exits = {} end 
		
		SWITCHABLESEATS:SendUpdate( TOOL.Seats, ply )
		
	end)
	
	concommand.Add( "switchableseats_deleteout", function( ply, _, args )
		if ply:GetActiveWeapon():GetClass() != "gmod_tool" then return end
		local TOOL = ply:GetActiveWeapon():GetToolObject()
		
		if not TOOL.Seats then ply:SendLua( "SWITCHABLESEATS:Hint( 'You need to select vehicle with seats first!' )" ); return end
		for k,v in pairs( TOOL.Seats ) do
			local ent = Entity(k)
			if IsValid(ent) then
				if v.Exit then
					table.remove( v.Exit )
				end
			end
		end
		
		SWITCHABLESEATS:SendUpdate( TOOL.Seats, ply )
		
	end)
	
	
	concommand.Add( "switchableseats_setkey", function( ply, _, args )
		if not args or not args[1] then return end
		if ply:GetActiveWeapon():GetClass() != "gmod_tool" then return end
		local TOOL = ply:GetActiveWeapon():GetToolObject()
		
		if not TOOL.Seats then ply:SendLua( "SWITCHABLESEATS:Hint( 'You need to select vehicle with seats first!' )" ); return end
		if not TOOL.SelectedSeat then ply:SendLua( "SWITCHABLESEATS:Hint( 'You need to select a seat first!' )" ); return end
		
		local arg = math.modf(args[1])
		if arg == 0 then arg = 10 end
		
		for k,v in pairs( TOOL.Seats ) do
			if v.Key == arg then
				v.Key = nil
			end
		end
		TOOL.Seats[ TOOL.SelectedSeat ].Key = arg
		SWITCHABLESEATS:SendUpdate( TOOL.Seats, ply )

	end)
	hook.Add("PlayerEnteredVehicle", "SWITCHABLESEATS_PlayerEnteredVehicle", function( ply, veh )
		PlyList( SS_FormatTable( veh ) )
	end)
	
	hook.Add("PlayerLeaveVehicle", "SWITCHABLESEATS_Enter", function( ply, veh )
		
		PlyList( SS_FormatTable( veh ) )
	
		if not veh.SSExit then return end
		local pos = nil
		for k,v in pairs( veh.SSExit ) do
			local trace = util.QuickTrace( veh:LocalToWorld(v) + Vector(0,0,75), Vector(0,0,-100) )

			if not trace.StartSolid and not trace.HitNonWorld then
				pos = trace.HitPos
				break
			end
		end
		
		if not pos then return end
		ply:SetPos( pos )
		
		ply.SSJustLeft = true
	end)
		
	local function SwitchSeats( ply, ent )
		if ent:GetDriver() and ent:GetDriver():IsPlayer() then
			ply:SendLua( "SWITCHABLESEATS:Hint( 'This seat is occupied by "..ent:GetDriver():GetName().."' )" );
		elseif CanUse(ply, ent) then
			local mode = ply:GetVehicle():GetThirdPersonMode()
			ply:GetVehicle():SetThirdPersonMode(false)
			ply:ExitVehicle()
			ply:EnterVehicle(ent)
			ply:GetVehicle():SetThirdPersonMode(mode)
			FixView( ply )
		end
	end
	
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
		
		ply:SendLua( "SWITCHABLESEATS:Hint( 'Vehicle is full or you dont have access!' )" );
	end)
	
	hook.Add("PlayerButtonUp", "SWITCHABLESEATS_Switching", function( ply, key )
		if not ply:InVehicle() then return end
		
		if key<1 or key>10 then return end
		
		if key == 1 then key = 10 else key = key - 1 end
		
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