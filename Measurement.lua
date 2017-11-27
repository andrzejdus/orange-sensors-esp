local UltrasonicSensor = require 'UltrasonicSensor';
local Stats = require 'Stats';

local Measurement = {}

Measurement.create = function ()
    local export = {};

    local DISTANCE_HYSTERESIS = 20;
    local SPLIT_DISTANCE = 150;
    local MEASUREMENT_INTERVAL = 100;

    local lastDistance = 0;
    local distances = {};

    local measurementFinishedListeners = {};

    local timer = tmr.create();

    function export.start()
        rtctime.set(0, 0);

        timer:register(MEASUREMENT_INTERVAL, tmr.ALARM_SEMI, function ()
            UltrasonicSensor.getDistance(function (distance)
                table.insert(distances, 1, distance);

                local size = table.getn(distances);
                if (size > 10) then
                    table.remove(distances);
                end

                local currentDistance = Stats.median(distances);

                print(string.format('Calculated distance: %d, from: %s', currentDistance, sjson.encode(distances)));

                if (math.abs(lastDistance - currentDistance) > DISTANCE_HYSTERESIS) then
                    lastDistance = currentDistance;

                    local measurementData = {
                        currentDistance = currentDistance,
                        isOccupied = currentDistance < SPLIT_DISTANCE
                    };

                    dispatchMeasurementFinishedListener(measurementData, function ()
                        timer:start();
                    end);
                else
                    timer:start();
                end
            end, function ()
                print('No response from ultrasonic sensor');

                timer:start();
            end);
        end);

        timer:start();
    end

    function export.stop()
        timer:stop();
    end

    function export.addMeasurementFinishedListener(id, measurementFinishedListener)
        measurementFinishedListeners[id] = measurementFinishedListener;
    end

    function export.removeMeasurementFinishedListener(id)
        measurementFinishedListeners[id] = nil;
    end

    function dispatchMeasurementFinishedListener(measurementData, callback)
        local measurementFinishedCallbacksCount = table.getn(measurementFinishedListeners);
        local callbacksFinished = 0;

        for listenerId, listener in pairs(measurementFinishedListeners) do
            listener(measurementData, function ()
                callbacksFinished = callbacksFinished + 1;
                if (callbacksFinished == measurementFinishedCallbacksCount) then
                    callback();
                end
            end);
        end

        if (measurementFinishedCallbacksCount == 0) then
            callback();
        end
    end

    return export;
end

Measurement.destroy = function()
    measureTimer.unregister(measureTimer);
end

return Measurement;
