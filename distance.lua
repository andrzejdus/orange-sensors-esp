local config = require 'config';
local httpJsonClient = require 'httpJsonClient';
local ultrasonicSensor = require 'ultrasonicSensor';
local stats = require 'stats';

local distance = {}

distance.create = function ()
    local measureTimer = tmr.create();

    local distanceHysteresis = 20;
    local splitDistance = 150;
    local measurementInterval = 100;

    local lastDistance = 0;
    local distances = {};

    function start()
        rtctime.set(0, 0);

        httpJsonClient.get(config.BASE_URL, 'calibration', 200, function(code, jsonData)
            if (code == 200) then
                distanceHysteresis = jsonData.data.distanceHysteresis;
                splitDistance = jsonData.data.splitDistance;
                measurementInterval = jsonData.data.measurementInterval;

                print('Calibration sucessfull');

                print('Hysteresis: ', distanceHysteresis);
                print('Split distance: ', splitDistance);
                print('Measurement interval', measurementInterval);

                startMeasurement();
            else
                print('Calibration unsucessfull, returned HTTP code ', code);
            end
        end);
    end

    function stop()
        measureTimer:stop();
    end

    function startMeasurement()
        measureTimer:register(measurementInterval, tmr.ALARM_SEMI, function ()
            ultrasonicSensor.getDistance(function (distance)
                table.insert(distances, 1, distance);

                local size = table.getn(distances);
                if (size > 10) then
                    table.remove(distances);
                end

                local currentDistance = stats.median(distances);
                
                print(string.format('Calculated distance: %d, from: %s', currentDistance, sjson.encode(distances)));
            
                if (math.abs(lastDistance - currentDistance) > distanceHysteresis) then
                    lastDistance = currentDistance;
                    sendMeasurment(currentDistance, function ()
                        measureTimer:start();
                    end);
                else
                    measureTimer:start();
                end
            end, function ()
                print('No response from ultrasonic sensor');
    
                measureTimer:start();
            end);
        end);
        measureTimer:start();        
    end

    function sendMeasurment(distance, finishedCallback)
        local body = {
            stationId = wifi.sta.getmac():gsub(':', ''),
            distance = distance
        };

        print(string.format('Sending measurment %d cm', distance));
        httpJsonClient.post(config.BASE_URL, 'measurement', body, 201, finishedCallback);
    end
    
    return {
        start = start,
        stop = stop
    };
end

distance.destroy = function()
    measureTimer.unregister(measureTimer);
end

return distance;
