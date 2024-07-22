
local function print(item)
    log.debug(tostring(item))
end
local worldtab = gui.get_tab("GUI_TAB_WORLD")
local tab = worldtab:add_tab("Carmageddon")

local is_enabled = false
local add_vel = false
local down_force = false
local boost_z = false
local boostSpeed = 100
local frequency = 1000

local exclude_own = true
local exclude_players = true
local exclude_exploded = true
local exclude_empty = true
tab:add_imgui(function()
    is_enabled, _ = ImGui.Checkbox("Enabled", is_enabled)
    add_vel, _ = ImGui.Checkbox("Additional Velocity", add_vel)
    down_force, _ = ImGui.Checkbox("Increase Downforce", down_force)
    boost_z, _ = not ImGui.Checkbox("Don't touch Z", not boost_z)
    boostSpeed, _ = ImGui.SliderInt("Speed", boostSpeed, 10, 1000)
    frequency, _ = ImGui.SliderInt("Frequency", frequency, 100, 10000)
    ImGui.Separator()
    ImGui.Text("Exclusions:")
    exclude_own, _ = ImGui.Checkbox("Own Vehicle", exclude_own)
    exclude_players, _ = ImGui.Checkbox("Players", exclude_players)
    exclude_exploded, _ = ImGui.Checkbox("Exploded Vehicles", exclude_exploded)
    exclude_empty, _ = ImGui.Checkbox("Empty Vehicles", exclude_empty)
end)

script.register_looped("carmageddonScriptLoop", function(s)
    s:yield()
    if not is_enabled then return end 

    local vehs = entities.get_all_vehicles_as_handles()
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
        local forward = ENTITY.GET_ENTITY_FORWARD_VECTOR(v)
        local speed = boostSpeed

        vel = ENTITY.GET_ENTITY_VELOCITY(v)
        if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(v) then
            if not entities.take_control_of(v, 1) then
                goto c
            end
        end
        if add_vel then
            ENTITY.SET_ENTITY_VELOCITY(v, vel.x + (forward.x * speed), vel.y + (forward.y * speed), down_force and -10 or (vel.z + (forward.z * (boost_z and speed or 0))))
        else
            ENTITY.SET_ENTITY_VELOCITY(v, forward.x * speed, forward.y * speed, down_force and -10 or (vel.z + (forward.z * (boost_z and speed or 0))))
        end
        ::c::
    end
    s:sleep(frequency)
end)
