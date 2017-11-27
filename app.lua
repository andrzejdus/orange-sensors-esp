enduser_setup.start()

local Config = require 'Config';
local Light = require 'Light';
local WifiHandler = require 'WifiHandler';
local Measurement = require 'Measurement';
local OtaUpdate = require 'OtaUpdate';
local HttpJsonClient = require 'HttpJsonClient';


local redLight = Light.create(Config.RED_LIGHT_PIN);
local greenLight = Light.create(Config.GREEN_LIGHT_PIN);

local measurement = Measurement.create();
measurement.addMeasurementFinishedListener('lights', function (measurementData, finishedCallback)
    if (measurementData.isOccupied) then
        redLight.turnOn();
        greenLight.turnOff();
    else
        redLight.turnOff();
        greenLight.turnOn();
    end
end);
measurement.start();

function start()
    local otaUpdate = OtaUpdate.create();
    otaUpdate.startUpdate(function ()
        measurement.addMeasurementFinishedListener('net', function (measurementData, finishedCallback)
            local body = {
                stationId = wifi.sta.getmac():gsub(':', ''),
                distance = measurementData.currentDistance
            };

            print(string.format('Sending measurment %d cm', measurementData.currentDistance));
            HttpJsonClient.post(Config.BASE_URL, 'measurement', body, 201, finishedCallback);
        end);
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
    measurement.removeMeasurementFinishedListener('net');
end);
