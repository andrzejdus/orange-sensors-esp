enduser_setup.start()

local Config = require 'Config';
local Light = require 'Light';
local WifiHandler = require 'WifiHandler';
local Measurement = require 'Measurement';
local HttpJsonClient = require 'HttpJsonClient';


local redLight = Light.create(Config.RED_LIGHT_PIN);
local greenLight = Light.create(Config.GREEN_LIGHT_PIN);

local measurement = Measurement.create();
measurement.addMeasurementFinishedListener(function (measurementData, finishedCallback)
    if (measurementData.isOccupied) then
        redLight.turnOn();
        greenLight.turnOff();
    else
        redLight.turnOff();
        greenLight.turnOn();
    end
end);
measurement.start();

function onMeasurementFinished(measurementData, finishedCallback)
    local body = {
        stationId = wifi.sta.getmac():gsub(':', ''),
        isOccupied = measurementData.isOccupied,
        distance = measurementData.currentDistance
    };

    print(string.format('Sending measurment %d cm', measurementData.currentDistance));

    HttpJsonClient.post(Config.BASE_URL, 'measurement', body, 201, finishedCallback);
end

WifiHandler.init(function ()
    measurement.addMeasurementFinishedListener(onMeasurementFinished);
end, function ()
    measurement.removeMeasurementFinishedListener(onMeasurementFinished);
end);
