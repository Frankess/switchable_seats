TOOL.Category		= "Construction"
TOOL.Name			= "#tool.switchableseats.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	language.Add( "tool.switchableseats.name", "Switchable seats - BETA" )
	language.Add( "Tool.switchableseats.desc", "Allows you to switch between seats without leaving vehicle." )
	language.Add( "Tool.switchableseats.0", " E+LMB - select vehicle, LMB - select single chair in vehicle, SHIFT+LMB - select entrance props, RMB - Accept changes" )
	language.Add( "tool.switchableseats.setexit", "Set exit point for this vehicle" )
	language.Add( "tool.switchableseats.deleteexit", "Delete exit point for this vehicle" )
end
if SERVER then	
	function TOOL:SendUpdate( Table )
		SWITCHABLESEATS:SendUpdate( Table, self:GetOwner() )
	end
end

function TOOL:SelectSeat( ent )
	self.SelectedSeat = ent:EntIndex()
	for k,v in pairs(self.Seats) do
		v.Selected = false
	end
	self.Seats[ ent:EntIndex() ].Selected = true
	self:SendUpdate( self.Seats )
end

function TOOL:SelectVehicle( ent )
	self:Cleanup()

	local Table = {}
	
	self.Doors = {}
	self.SelectedSeat = nil
	
	local Entities = SS_FormatTable( ent )
	
	for _,v in pairs( Entities ) do
		if v.SSDoor then
			self:SelectDoor( v )
			v.SSDoor = false
			duplicator.StoreEntityModifier( v , "SWITCHABLESEATS_Doors", {false} )
		elseif v:IsVehicle() then
			if v.SSeat or v.SSExit then
				Table[ v:EntIndex() ] = {["Key"] = v.SSeat, ["Exit"] = v.SSExit}
				v.SSeat = nil
				v.SSExit = nil
				duplicator.StoreEntityModifier( v , "SWITCHABLESEATS_Seats", {} )
			else			
				Table[ v:EntIndex() ] = {}
			end
		end
	end
		
	self.Seats = Table		
	self:SendUpdate( Table )
		
end

function TOOL:SelectDoor( ent )
	for k,v in pairs( self.Doors ) do
		if IsValid(v[1]) and v[1] == ent then
			ent:SetColor( v[2] )
			table.remove( self.Doors, k )
			return
		end
	end
	
	local Col = ent:GetColor()
	if not Col then Col = Color(255,255,255) end
	table.insert( self.Doors, { ent, Col } )
	ent:SetColor( Color(0, 200, 0) )
end

function TOOL:VehicleHasThat( ent )

	if not self.Seats then return false end
	if self.Seats[ ent:EntIndex() ] then return true end
	
	return false
end

function TOOL:Cleanup()
	if self.Doors then
		for k,v in pairs( self.Doors ) do
			if IsValid( v[1] ) then
				v[1]:SetColor(v[2])
			end
		end
	end

	self.Seats = nil
	self.SelectedSeat = nil
	self.Doors = nil
	
	self:SendUpdate( {} )
end

function TOOL:Holster()
	if CLIENT or not SWITCHABLESEATS then return end
	self:SendUpdate( {} )
end

function TOOL:LeftClick( trace )
	if CLIENT then return end
	
	local ent = trace.Entity
	local ply = self:GetOwner()
	
	if ply:KeyDown(IN_USE) then -- Zaznaczamy caly pojazd		
	
		if not IsValid( ent ) or ent:IsPlayer() then return false end
		self:SelectVehicle( ent )
		
	elseif self.Seats then -- czy jest jakis zaznaczony pojazd i czy zaznaczamy jedno z jego krzesl
	
		if ply:KeyDown(IN_SPEED) then
			if not IsValid( ent ) or ent:GetClass() != "prop_physics" then return false end
			self:SelectDoor( ent )
		else
			local plytrace = util.GetPlayerTrace( ply )
			plytrace.filter = function( entity ) if ( entity:GetClass() == "prop_vehicle_prisoner_pod" ) then return true end end -- chcemy wylacznie dzialac na krzeslach
			trace2 = util.TraceLine( plytrace )
			local ent2 = trace2.Entity
			
			if IsValid( ent2 ) and self:VehicleHasThat( ent2 ) then
				self:SelectSeat( ent2 )
			end
		end
	end
	
	return true
end

function TOOL:RightClick()
	if CLIENT or not SWITCHABLESEATS or not self.Seats then return false end
	
	
	for k,v in pairs( self.Seats ) do
		local ent = Entity(k)
		if IsValid(ent) then 
			ent.SSeat = v.Key
			ent.SSExit = v.Exit
			duplicator.StoreEntityModifier( ent , "SWITCHABLESEATS_Seats", {v.Key, v.Exit} )
		end
	end
	
	for k,v in pairs( self.Doors ) do
		local ent = v[1]
		if IsValid(ent) then
			ent.SSDoor = true
			duplicator.StoreEntityModifier( ent , "SWITCHABLESEATS_Doors", {true} )
		end
	end
	
	self:Cleanup()
	
	return false
end

function TOOL:Reload()
	if CLIENT then return end
	self:Cleanup()
end

if CLIENT then
	function TOOL.BuildCPanel(panel)
		
		panel:AddControl( "Header", { Text = "#tool.switchableseats.name", Description = "#tool.switchableseats.desc" } )
		
		panel:AddControl( "Button", { Label = "#tool.switchableseats.setexit", Command = "switchableseats_setout"} )
		
		local Parent = vgui.Create("DSizeToContents")
		Parent:SetParent( panel )
		Parent:SetSizeX( false )
		Parent:Dock( TOP )
		Parent:DockMargin( 10, 10, 10, 0 )
		Parent:InvalidateLayout()
		
		for num = 1, 9 do
			
			local X = ((num-1)%3)*55
			local Y = math.floor((num-1)/3)*55
		
			local Button = vgui.Create("DButton")
			Button:SetParent(Parent)
			Button:SetText(num)
			Button:SetPos(X,Y)
			Button:SetSize(50,50)
			Button.DoClick = function()
				RunConsoleCommand("switchableseats_setkey", num)
			end
			
		end
	
	end
end