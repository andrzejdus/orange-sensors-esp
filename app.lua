enduser_setup.start()

local Config = require 'Config';
local Light = require 'Light';
local WifiHandler = require 'WifiHandler';
local Measurement = require 'Measurement';
local CalibrationClient = require 'CalibrationClient';
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

local function sendMeasurement(measurementData, onListenerProcessingFinished)
    local body = {
        stationId = wifi.sta.getmac():gsub(':', ''),
        isOccupied = measurementData.isOccupied,
        distance = measurementData.currentDistance
    };

    print(string.format('Sending measurment %d cm', measurementData.currentDistance));

    HttpJsonClient.post(Config.BASE_URL, 'measurement', body, 201, onListenerProcessingFinished);
end

local function start()
    CalibrationClient.getCalibrationData(function (calibrationData)
        measurement.setSplitDistance(calibrationData.splitDistance);
        measurement.setMeasurementInterval(calibrationData.measurementInterval);

        measurement.addMeasurementFinishedListener(sendMeasurement);
    end, function ()
        measurement.addMeasurementFinishedListener(sendMeasurement);
    end);
end

WifiHandler.init(function ()
    sntp.sync({'0.pool.ntp.org', '1.pool.ntp.org'}, function (seconds, microseconds, server, info)
        print('NTP sync finished', seconds, microseconds, server, info);

        start();
    end, function (code, message)
        print('NTP sync error, code', code, message);

        start();
    end);
end, function ()
    measurement.removeMeasurementFinishedListener(sendMeasurement);
end);
