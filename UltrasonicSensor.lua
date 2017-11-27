local Config = require 'Config';

local UltrasonicSensor = {};

function UltrasonicSensor.getDistance(finishedCallback, errorCallback)
    local measurmentFinished = false;
    local startSec, startUsec;
    local endSec, endUsec;

    gpio.mode(Config.TRIGGER_PIN, gpio.OUTPUT);
    gpio.write(Config.TRIGGER_PIN, gpio.LOW);

    gpio.mode(Config.ECHO_PIN, gpio.INT);
    gpio.trig(Config.ECHO_PIN, "both", function(level)
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
            -- print(string.format('Measured %d cm distance (secDelta %d)', distance, secDelta));

            finishedCallback(distance);
        end
    end)

    local timeoutTimer = tmr.create()
    timeoutTimer:register(200, tmr.ALARM_SINGLE, function ()
        if (not measurmentFinished) then
            errorCallback();
        end
    end)
    timeoutTimer:start();
    trigger();
end

function trigger()
    tmr.delay(20);
    gpio.write(Config.TRIGGER_PIN, gpio.HIGH);
    tmr.delay(10);
    gpio.write(Config.TRIGGER_PIN, gpio.LOW);
end

return UltrasonicSensor;
