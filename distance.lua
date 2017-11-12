local config = require 'config';
local httpJsonClient = require 'httpJsonClient';

local distance = {}

if (measureTimer) then
    tmr.unregister(measureTimer);
end
measureTimer = tmr.create();

distance.start = function ()
    local distanceHysteresis = 25;
    local splitDistance = 150;
    local measurmentInterval = 1500;

    function start()
        rtctime.set(0, 0);

        httpJsonClient.get(config.BASE_URL, 'calibration', function(code, jsonData)
            if (code == 200) then
                distanceHysteresis = jsonData.data.distanceHysteresis;
                splitDistance = jsonData.data.splitDistance;
                measurmentInterval = jsonData.data.measurmentInterval;
                
                print(distanceHysteresis);
                print(splitDistance);
                print(measurmentInterval);
            else
                print('Calibration unsucessfull, returned HTTP code ', code);
            end       

            measureTimer:register(measurmentInterval, tmr.ALARM_SEMI, function ()
                getDistance(function (distance)
                    sendMeasurment(distance, function ()
                        measureTimer:start();
                    end);
                end);
            end);
            measureTimer:start();        
        end);
    end

    function sendMeasurment(distance, finishedCallback)
        local body = {
            macAddress = wifi.sta.getmac(),
            distance = distance
        };

        print(string.format('Sending measurment %d cm', distance));
        httpJsonClient.post(config.BASE_URL, 'measurement', body, finishedCallback);
    end
    
    function getDistance(finishedCallback)
        local measurmentFinished = false;
        local startSec, startUsec;
        local endSec, endUsec;
        
        gpio.mode(config.TRIGGER_PIN, gpio.OUTPUT);
        gpio.write(config.TRIGGER_PIN, gpio.LOW);

        gpio.mode(config.ECHO_PIN, gpio.INT);
        gpio.trig(config.ECHO_PIN, "both", function(level)
            if (level == 1) then
                startSec, startUsec = rtctime.get();
            end
        
            if (level == 0 and startUsec ~= nil) then
                endSec, endUsec = rtctime.get();

                local waveTime = endUsec - startUsec;

                local secDelta = endSec - startSec;
                if (secDelta > 0) then
                    waveTime = (1000000 - startUsec) + endUsec + 1000000 * (secDelta - 1);
                end
        
                local distance = waveTime / 58;
                measurmentFinished = true;
                print(string.format('Measured %d cm distance (secDelta %d)', distance, secDelta));
                finishedCallback(distance);
            end
        end)

        triggerTimer = tmr.create()
        triggerTimer:register(500, tmr.ALARM_SINGLE, function ()
            if (not measurmentFinished) then
                print('Repeating...');
                getDistance(finishedCallback);
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

    start();
end

distance.stop = function()
    measureTimer.unregister(measureTimer);
end

return distance;
