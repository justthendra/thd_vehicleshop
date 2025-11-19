local QBCore = exports['qb-core']:GetCoreObject()

VehicleStats = {}

local isOpen = false
local spawnedVehicle = nil
local previewCam = nil
local isTesting = false
local testVehicle = nil
local testTime = 60
local lastMenuPos = nil


local menuCoords = vector3(-33.97, -1103.23, 26.42)

local vehiclePos = vector4(1379.95, 223.39, -48.99, 223.8)


---------------------------------------------------------------------
-- BLIP
---------------------------------------------------------------------
CreateThread(function()
    local blip = AddBlipForCoord(menuCoords.x, menuCoords.y, menuCoords.z)
    SetBlipSprite(blip, 225)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Araç Galerisi")
    EndTextCommandSetBlipName(blip)
end)

----------------------------------------------------------------
-- INTERIOR LOAD
----------------------------------------------------------------
function LoadGarageInterior()
    RequestIpl("vw_casino_garage")
    RequestIpl("vw_casino_garage_lod")
    RequestIpl("vw_casino_garage_milo_")

    local interiorID = GetInteriorAtCoords(vehiclePos.x, vehiclePos.y, vehiclePos.z)
    if interiorID ~= 0 then
        LoadInterior(interiorID)
        Wait(300)
    end
end

RegisterNUICallback("testDrive", function(data, cb)
    TriggerServerEvent("thd_vehicleshop:testDrive", data.model)
    cb("ok")
end)

----------------------------------------------------------------
-- VEHICLE SPAWN
----------------------------------------------------------------
function SpawnPreviewVehicle(model)

    if spawnedVehicle then
        DeleteVehicle(spawnedVehicle)
    end

    -- Geçici spawn
    local temp = vector3(0.0, 0.0, 150.0)

    QBCore.Functions.SpawnVehicle(
        model,
        function(veh)
            spawnedVehicle = veh

            -- İÇ MEKANA IŞINLA
            SetEntityCoordsNoOffset(veh, vehiclePos.x, vehiclePos.y, vehiclePos.z)
            SetEntityHeading(veh, vehiclePos.w)

            FreezeEntityPosition(veh, true)
            SetEntityInvincible(veh, true)
            SetVehicleDoorsLocked(veh, 2)

            SetupPreviewCam()
        end,
        temp,
        true
    )
end


----------------------------------------------------------------
-- CAMERA
----------------------------------------------------------------
function SetupPreviewCam()
    local veh = spawnedVehicle

    if previewCam then
        DestroyCam(previewCam)
    end

    Wait(100)

    local camCoords = GetOffsetFromEntityInWorldCoords(veh, -4.0, 3.0, 2.0)

    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, camCoords.x, camCoords.y, camCoords.z)

    PointCamAtEntity(previewCam, veh, 0.0, 0.0, 0.0)

    SetCamActive(previewCam, true)
    RenderScriptCams(true, true)
end


function StopCam()
    if previewCam then
        RenderScriptCams(false, true)
        DestroyCam(previewCam)
        previewCam = nil
    end
end

function StartShowroomCamera()

    local vx, vy, vz, vh = vehiclePos.x, vehiclePos.y, vehiclePos.z, vehiclePos.w


    local camX = vx - 4.5
    local camY = vy + 3.0
    local camZ = vz + 2.0

    if previewCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCam)
        previewCam = nil
    end

    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, camX, camY, camZ)

    PointCamAtCoord(previewCam, vx, vy, vz + 1.0)

    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 600, true, true)
end



--------------------------------------------------------------------
-- OPEN MENU 
---------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)

        if menuOpen then goto skip end

        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        if #(pos - menuCoords) < 2.0 then

            DrawMarker(36, menuCoords.x, menuCoords.y, menuCoords.z + 0.1,
                0,0,0, 0,0,0,
                0.5,0.5,0.5,
                0,255,100,180, false,true,2)

            if IsControlJustPressed(0, 38) then
                lastMenuPos = pos
                TriggerServerEvent("thd_vehicleshop:requestVehicles")
            end
        end

        ::skip::
    end
end)

----------------------------------------------------------------
-- OPEN MENU (UI)
----------------------------------------------------------------
RegisterNetEvent("thd_vehicleshop:openMenu", function(vehicles, categories)
    lastMenuPos = GetEntityCoords(PlayerPedId())
    isOpen = true

    TriggerEvent("thd_hud:toggle", false)

    SetNuiFocus(true,true)
    TriggerServerEvent("thd_vehicleshop:setBucket", 901)

    LoadGarageInterior()

    StartShowroomCamera()

    SendNUIMessage({
        action = "openShop",
        vehicles = vehicles,
        categories = categories
    })
end)


----------------------------------------------------------------
-- NUI CALLBACKS
----------------------------------------------------------------
RegisterNUICallback("selectVehicle", function(data, cb)
    SpawnPreviewVehicle(data.model)

    local stats = VehicleStats[data.model] or {
        max_speed = 0,
        acceleration = 0,
        braking = 0,
        handling = 0
    }

    SendNUIMessage({
        action = "updateStats",
        speed = stats.max_speed,
        accel = stats.acceleration,
        braking = stats.braking,
        handling = stats.handling
    })

    cb("ok")
end)


RegisterNUICallback("selectCategory", function(data, cb)
    TriggerServerEvent("thd_vehicleshop:requestCategory", data.category)
    cb("ok")
end)

RegisterNetEvent("thd_vehicleshop:updateVehicles", function(list)
    SendNUIMessage({
        action = "updateVehicles",
        vehicles = list
    })
end)

RegisterNUICallback("buyVehicle", function(data, cb)
    TriggerServerEvent("thd_vehicleshop:buyVehicle", data.model, data.price)
    cb("ok")
end)

RegisterNUICallback("closeShop", function(_,cb)
    isOpen = false
    SetNuiFocus(false,false)


    StopCam()

    if spawnedVehicle then
        DeleteVehicle(spawnedVehicle)
    end

    TriggerServerEvent("thd_vehicleshop:setBucket", 0)

    SendNUIMessage({ action = "closeShop" })
    cb("ok")
end)

----------------------------------------------------------------
-- TEST DRIVE
----------------------------------------------------------------

RegisterNUICallback("testDrive", function(data, cb)
    TriggerEvent("thd_vehicleshop:startTestDrive", data.model)
    cb("ok")
end)

RegisterNetEvent("thd_vehicleshop:startTestDrive", function(model)
    if isTesting then return end
    isTesting = true


    local ped = PlayerPedId()
    local startPos = lastMenuPos or menuCoords

    SendNUIMessage({ action = "closeShop" })
    
    SetNuiFocus(false,false)
    StopCam()

    QBCore.Functions.SpawnVehicle(model, function(veh)
        testVehicle = veh

        SetVehicleNumberPlateText(veh, "TEST"..math.random(100,999))
        SetEntityCoords(veh, -45.12, -1098.10, 26.42)
        SetEntityHeading(veh, 70.0)

        SetPedIntoVehicle(ped, veh, -1)

        QBCore.Functions.Notify("Test sürüşü başladı! Süre: "..testTime.." saniye", "primary")

        CreateThread(function()
            local remaining = testTime

            while remaining > 0 and isTesting do
                Wait(1000)
                remaining = remaining - 1
                if remaining == 10 then
                    QBCore.Functions.Notify("Test sürüşü 10 saniye içinde bitecek!", "error")
                end
            end

            if isTesting then
                isTesting = false

                if DoesEntityExist(testVehicle) then
                    DeleteVehicle(testVehicle)
                end

                SetEntityCoords(ped, startPos.x, startPos.y, startPos.z)
                Wait(300)

                TriggerServerEvent("thd_vehicleshop:requestVehicles")
                QBCore.Functions.Notify("Test sürüşü sona erdi!", "error")
            end
        end)
    end, startPos, true)
end)

RegisterNetEvent("thd_vehicleshop:closeMenuAuto", function()

    SendNUIMessage({ action = "closeShop" })
    SetNuiFocus(false, false)

    StopCam()

    if spawnedVehicle then
        DeleteVehicle(spawnedVehicle)
        spawnedVehicle = nil
    end

    TriggerServerEvent("thd_vehicleshop:setBucket", 0)
end)

RegisterNetEvent("thd_vehicleshop:spawnPurchasedVehicle", function(model, plate, spawn)
    QBCore.Functions.SpawnVehicle(model, function(veh)
        SetVehicleNumberPlateText(veh, plate)
        SetEntityCoords(veh, spawn.x, spawn.y, spawn.z)
        SetEntityHeading(veh, spawn.w)

        SetVehicleFuelLevel(veh, 100.0)
        SetVehicleEngineOn(veh, true, true)

        local ped = PlayerPedId()
        SetPedIntoVehicle(ped, veh, -1)

        QBCore.Functions.Notify("Yeni aracın hazır!", "success")
    end, vector3(spawn.x, spawn.y, spawn.z), true)
end)


CreateThread(function()
    while true do
        Wait(250)

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsTryingToEnter(ped)

        if veh ~= 0 then
            local plate = QBCore.Functions.GetPlate(veh)

            TriggerServerEvent("thd_garages:checkKey", plate)
        end
    end
end)

RegisterNetEvent("thd_garages:forceOut", function()
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    QBCore.Functions.Notify("Bu aracın anahtarı sende yok!", "error")
end)

RegisterNetEvent("thd_vehicleshop:loadStats", function(stats)
    VehicleStats = stats

end)
