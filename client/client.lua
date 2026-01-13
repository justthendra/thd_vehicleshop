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
local vehiclePos = vector4(1379.95, 223.39, -48.99, 223.8) -- showroom içi

-------------------------------------------------------------
-- INTERIOR LOAD
-------------------------------------------------------------
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

-------------------------------------------------------------
-- VEHICLE PREVIEW SPAWN
-------------------------------------------------------------
function SpawnPreviewVehicle(model)
    if spawnedVehicle then
        DeleteVehicle(spawnedVehicle)
    end

    local temp = vector3(0.0, 0.0, 150.0)

    QBCore.Functions.SpawnVehicle(model, function(veh)
        spawnedVehicle = veh

        SetEntityCoordsNoOffset(veh, vehiclePos.x, vehiclePos.y, vehiclePos.z)
        SetEntityHeading(veh, vehiclePos.w)

        FreezeEntityPosition(veh, true)
        SetEntityInvincible(veh, true)
        SetVehicleDoorsLocked(veh, 2)

        SetupPreviewCam()
    end, temp, true)
end

-------------------------------------------------------------
-- CAMERA
-------------------------------------------------------------
function SetupPreviewCam()
    local veh = spawnedVehicle
    if previewCam then DestroyCam(previewCam) end

    Wait(100)
    local camCoords = GetOffsetFromEntityInWorldCoords(veh, -4.0, 3.0, 2.0)

    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(previewCam, veh, 0, 0, 0)

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
    local vx, vy, vz = vehiclePos.x, vehiclePos.y, vehiclePos.z
    local camX = vx - 4.5
    local camY = vy + 3.0
    local camZ = vz + 2.0

    if previewCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCam)
    end

    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, camX, camY, camZ)
    PointCamAtCoord(previewCam, vx, vy, vz + 1.0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 600, true, true)
end

-------------------------------------------------------------
-- MENU OPEN THREAD
-------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)

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
    end
end)

-------------------------------------------------------------
-- MENU OPEN (LOCALE DESTEKLİ)
-------------------------------------------------------------
RegisterNetEvent("thd_vehicleshop:openShop")
AddEventHandler("thd_vehicleshop:openShop", function(data)

    lastMenuPos = GetEntityCoords(PlayerPedId())
    isOpen = true

    TriggerEvent("thd_hud:toggle", false)
    SetNuiFocus(true, true)

    TriggerServerEvent("thd_vehicleshop:setBucket", 901)

    LoadGarageInterior()
    StartShowroomCamera()

    SendNUIMessage({
        action = "openShop",
        vehicles = data.vehicles,
        categories = data.categories,
        locale = data.locale
    })
end)

-------------------------------------------------------------
-- SELECT VEHICLE
-------------------------------------------------------------
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

-------------------------------------------------------------
-- CATEGORY CHANGE
-------------------------------------------------------------
RegisterNUICallback("selectCategory", function(data, cb)
    TriggerServerEvent("thd_vehicleshop:requestCategory", data.category)
    cb("ok")
end)

RegisterNetEvent("thd_vehicleshop:updateVehicles")
AddEventHandler("thd_vehicleshop:updateVehicles", function(list)
    SendNUIMessage({ action = "updateVehicles", vehicles = list })
end)

-------------------------------------------------------------
-- BUY VEHICLE
-------------------------------------------------------------
RegisterNUICallback("buyVehicle", function(data, cb)
    TriggerServerEvent("thd_vehicleshop:buyVehicle", data.model, data.price)
    cb("ok")
end)

-------------------------------------------------------------
-- SPAWN PURCHASED VEHICLE
-------------------------------------------------------------

-- 🔥 SATIN ALMA TAM AKIŞI (MENÜ KAPAT + BUCKET 0 + ARAÇ SPAWN)
RegisterNetEvent("thd_vehicleshop:onVehiclePurchased")
AddEventHandler("thd_vehicleshop:onVehiclePurchased", function(model, plate, spawn)
    local ped = PlayerPedId()

    -- 1) Menüyü kapat
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })

    TriggerEvent("thd_hud:toggle", true)

    -- showroom kamerasını kapat
    StopCam()

    -- showroom preview aracını sil
    if spawnedVehicle then
        DeleteVehicle(spawnedVehicle)
        spawnedVehicle = nil
    end

    -- 2) Bucket'ı 0'a çek (dünyaya dön)
    TriggerServerEvent("thd_vehicleshop:setBucket", 0)

    -- Küçük bir gecikme ver ki bucket değişsin, sonra aracı spawn et
    Wait(250)

    -- 3) Satın alınan aracı dünyaya spawn et
    QBCore.Functions.SpawnVehicle(model, function(veh)
        SetVehicleNumberPlateText(veh, plate)
        TriggerServerEvent("thd_garages:server:RegisterVehicleEntity", plate, NetworkGetNetworkIdFromEntity(veh))
        SetEntityCoords(veh, spawn.x, spawn.y, spawn.z)
        SetEntityHeading(veh, spawn.w)

        SetVehicleFuelLevel(veh, 100.0)
        SetVehicleEngineOn(veh, true, true)

        SetPedIntoVehicle(ped, veh, -1)

        QBCore.Functions.Notify("Yeni aracın hazır!", "success")
    end, vector3(spawn.x, spawn.y, spawn.z), true)
end)


-------------------------------------------------------------
-- CLOSE SHOP
-------------------------------------------------------------
RegisterNUICallback("closeShop", function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeShop" })

    TriggerEvent("thd_hud:toggle", true)
    StopCam()

    if spawnedVehicle then
        DeleteVehicle(spawnedVehicle)
        spawnedVehicle = nil
    end

    TriggerServerEvent("thd_vehicleshop:setBucket", 0)

    cb("ok")
end)



-------------------------------------------------------------
-- TEST DRIVE
-------------------------------------------------------------
RegisterNUICallback("testDrive", function(data, cb)
    TriggerEvent("thd_vehicleshop:startTestDrive", data.model)
    cb("ok")
end)

RegisterNetEvent("thd_vehicleshop:startTestDrive")
AddEventHandler("thd_vehicleshop:startTestDrive", function(model)

    if isTesting then return end
    isTesting = true

    TriggerEvent("thd_hud:toggle", true)

    local ped = PlayerPedId()
    local startPos = lastMenuPos or menuCoords

    SendNUIMessage({ action = "closeShop" })
    SetNuiFocus(false, false)
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
                remaining -= 1
                if remaining == 10 then
                    QBCore.Functions.Notify("Test sürüşü 10 saniye içinde bitecek!", "error")
                end
            end

            if isTesting then
                isTesting = false

                if DoesEntityExist(testVehicle) then DeleteVehicle(testVehicle) end

                SetEntityCoords(ped, startPos.x, startPos.y, startPos.z)
                Wait(300)

                TriggerServerEvent("thd_vehicleshop:requestVehicles")
                QBCore.Functions.Notify("Test sürüşü sona erdi!", "error")
            end
        end)
    end, startPos, true)
end)

-------------------------------------------------------------
-- KEY CHECK (Araç anahtarı)
-------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsTryingToEnter(ped)
        if veh ~= 0 then
            TriggerServerEvent("thd_garages:checkKey", QBCore.Functions.GetPlate(veh))
        end
    end
end)

RegisterNetEvent("thd_garages:forceOut")
AddEventHandler("thd_garages:forceOut", function()
    ClearPedTasksImmediately(PlayerPedId())
    QBCore.Functions.Notify("Bu aracın anahtarı sende yok!", "error")
end)

-------------------------------------------------------------
-- STATS LOADED
-------------------------------------------------------------
RegisterNetEvent("thd_vehicleshop:loadStats")
AddEventHandler("thd_vehicleshop:loadStats", function(stats)
    VehicleStats = stats
end)
