local worldtab = gui.get_tab("GUI_TAB_WORLD")
local tab = worldtab:add_tab("Carmageddon")

local is_enabled = false
local add_vel = false
local down_force = false
local boost_z = false
local towards_closest = false
local boostSpeed = 100
local frequency = 1000

local exclude_own = true
local exclude_players = true
local exclude_exploded = true
local exclude_empty = true
local exclude_dead = true

local exclude_self = true

tab:add_imgui(function()
    is_enabled, _ = ImGui.Checkbox("Enabled", is_enabled)
    add_vel, _ = ImGui.Checkbox("Additive Velocity", add_vel)
    down_force, _ = ImGui.Checkbox("Increase Downforce", down_force)
    boost_z, _ = not ImGui.Checkbox("Don't touch Z", not boost_z)
    towards_closest, _ = ImGui.Checkbox("Boost towards closest player", towards_closest)
    boostSpeed, _ = ImGui.SliderInt("Speed", boostSpeed, 10, 1000)
    frequency, _ = ImGui.SliderInt("Frequency", frequency, 100, 10000)

    ImGui.Separator()

    ImGui.Text("Vehicle Exclusions:")

    exclude_own, _ = ImGui.Checkbox("Own Vehicle", exclude_own)
    exclude_players, _ = ImGui.Checkbox("Players", exclude_players)
    exclude_exploded, _ = ImGui.Checkbox("Exploded Vehicles", exclude_exploded)
    exclude_empty, _ = ImGui.Checkbox("Empty Vehicles", exclude_empty)
    exclude_dead, _ = ImGui.Checkbox("Dead Drivers", exclude_dead)

    ImGui.Text("Player Exclusions:")

    exclude_self, _ = ImGui.Checkbox("Self", exclude_self)
end)

script.register_looped("carmageddonScriptLoop", function(s)
    s:yield()
    if not is_enabled then return end 

    local vehs = entities.get_all_vehicles_as_handles()
    local player_poses = {}
    if towards_closest then
        for i = 0, 31 do 
            ped = PLAYER.GET_PLAYER_PED(i)
            if ped == 0 then 
                goto c1
            end

            if exclude_self and ped == self.get_ped() then
                goto c1
            end

            if ENTITY.IS_ENTITY_DEAD(ped, 0) then
                goto c1
            end

            table.insert(player_poses, ENTITY.GET_ENTITY_COORDS(ped, true))
            ::c1::
        end
    end
    for k,v in pairs(vehs) do

        if exclude_exploded then
            if not VEHICLE.IS_VEHICLE_DRIVEABLE(v) then
                goto c
            end
        end
        if exclude_own then
            if self.get_veh() == v then
                goto c
            end
        end
        if exclude_players then
            if PED.IS_PED_A_PLAYER(VEHICLE.GET_PED_IN_VEHICLE_SEAT(v, -1, 0)) then
                goto c
            end
        end
        if exclude_empty then
            if VEHICLE.GET_PED_IN_VEHICLE_SEAT(v, -1, 0) == 0 then
                goto c
            end
        end
        if exclude_dead then
            if ENTITY.IS_ENTITY_DEAD(VEHICLE.GET_PED_IN_VEHICLE_SEAT(v, -1, 0), 0) then
                goto c
            end
        end

        local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(v)
        
        local speed = boostSpeed

        vel = ENTITY.GET_ENTITY_VELOCITY(v)

        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(v) then
            if not entities.take_control_of(v, 1) then
                goto c
            end
        end

        if towards_closest then
            local veh_pos = ENTITY.GET_ENTITY_COORDS(v, true)
            local closest_dist = nil
            local closest_vec = vec3.new(0, 0, 0)
            for _, ped_pos in pairs(player_poses) do 
                distance = SYSTEM.VDIST2(veh_pos.x, veh_pos.y, veh_pos.z, ped_pos.x, ped_pos.y, ped_pos.z)

                if not closest_dist then
                    closest_dist = distance
                    closest_vec = ped_pos
                end

                if distance < closest_dist then
                    closest_dist = distance
                    closest_vec = ped_pos
                end
            end 
            local multiplier = 0.1
            forward = vec3.new((closest_vec.x - veh_pos.x) * multiplier, (closest_vec.y - veh_pos.y) * multiplier, (closest_vec.z - veh_pos.z) * multiplier)
        end

        if not add_vel then
            vel.x = 0
            vel.y = 0
        end
        
        ENTITY.SET_ENTITY_VELOCITY(v, vel.x + (forward.x * speed), vel.y + (forward.y * speed), down_force and -10 or (vel.z + (forward.z * (boost_z and speed or 0))))
        ::c::
    end
    s:sleep(frequency)
end)
