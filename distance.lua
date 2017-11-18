local config = require 'config';
local httpJsonClient = require 'httpJsonClient';
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
            getDistance(function (distance)
                table.insert(distances, 1, distance);


                local size = table.getn(distances);
                if (size > 10) then
                    table.remove(distances);
                end

                local avg = stats.median(distances);
                
                print(string.format('Calculated distance: %d, from: %s', avg, sjson.encode(distances)));
            
                if (math.abs(lastDistance - avg) > distanceHysteresis) then
                    lastDistance = avg;
                    sendMeasurment(avg, function ()
                        measureTimer:start();
                    end);
                else
                    measureTimer:start();
                end
            end, function ()
                print('No response from distance sensor');
    
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
    
    function getDistance(finishedCallback, errorCallback)
        local measurmentFinished = false;
        local startSec, startUsec;
        local endSec, endUsec;
        
        gpio.mode(config.TRIGGER_PIN, gpio.OUTPUT);
        gpio.write(config.TRIGGER_PIN, gpio.LOW);

        gpio.mode(config.ECHO_PIN, gpio.INT);
        gpio.trig(config.ECHO_PIN, "both", function(level)
            if (level == 1) then
                -- print('Echo pin high');

                startSec, startUsec = rtctime.get();
            end
        
            if (level == 0 and startUsec ~= nil) then
                -- print('Echo pin low');

                endSec, endUsec = rtctime.get();

                local waveTime = endUsec - startUsec;

                local secDelta = endSec - startSec;
                if (secDelta > 0) then
                    waveTime = (1000000 - startUsec) + endUsec + 1000000 * (secDelta - 1);
                end
        
                local distance = waveTime / 58;
                measurmentFinished = true;
                -- print(string.format('Measured %d cm distance (secDelta %d)', distance, secDelta));
                
                finishedCallback(distance);
            end
        end)

        triggerTimer = tmr.create()
        triggerTimer:register(500, tmr.ALARM_SINGLE, function ()
            if (not measurmentFinished) then
                errorCallback();
            end
        end)
        triggerTimer:start();
        trigger();
    end

    function trigger()
        tmr.delay(20);
        gpio.write(config.TRIGGER_PIN, gpio.HIGH);
        tmr.delay(10);
        gpio.write(config.TRIGGER_PIN, gpio.LOW);
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
