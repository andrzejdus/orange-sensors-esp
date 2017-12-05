enduser_setup.start()

local Config = require 'Config';
local Light = require 'Light';
local WifiHandler = require 'WifiHandler';
local Measurement = require 'Measurement';
local HttpJsonClient = require 'HttpJsonClient';


local redLight = Light.create(Config.RED_LIGHT_PIN);
local greenLight = Light.create(Config.GREEN_LIGHT_PIN);

local measurement = Measurement.create();
measurement.addMeasurementFinishedListener(function (measurementData, onListenerProcessingFinished)
    if (measurementData.isOccupied) then
        redLight.turnOn();
        greenLight.turnOff();
    else
        redLight.turnOff();
        greenLight.turnOn();
    end

    onListenerProcessingFinished();
end);
measurement.start();

function onMeasurementFinished(measurementData, onListenerProcessingFinished)
    local body = {
        stationId = wifi.sta.getmac():gsub(':', ''),
        isOccupied = measurementData.isOccupied,
        distance = measurementData.currentDistance
    };

    print(string.format('Sending measurment %d cm', measurementData.currentDistance));

    HttpJsonClient.post(Config.BASE_URL, 'measurement', body, 201, onListenerProcessingFinished);
end

WifiHandler.init(function ()
    sntp.sync({'0.pool.ntp.org', '1.pool.ntp.org'}, function (seconds, microseconds, server, info)
        print('NTP sync finished', seconds, microseconds, server, info);

        measurement.addMeasurementFinishedListener(onMeasurementFinished);
    end, function (code, message)
        print('NTP sync error, code', code, message);

        measurement.addMeasurementFinishedListener(onMeasurementFinished);
    end);
end, function ()
    measurement.removeMeasurementFinishedListener(onMeasurementFinished);
end);
