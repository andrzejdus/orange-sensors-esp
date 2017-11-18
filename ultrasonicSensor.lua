local ultrasonicSensor = {};

function ultrasonicSensor.getDistance(finishedCallback, errorCallback)
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

return ultrasonicSensor;