local Light = {};

function Light.create(pin)
    local export = {};

    gpio.mode(pin, gpio.OUTPUT);
    local timer = tmr.create();

    function export.blink()
        local b = false;
        gpio.write(pin, gpio.LOW);
        timer:register(100, tmr.ALARM_AUTO, function()
            if (b) then
                gpio.write(pin, gpio.HIGH);
            else
                gpio.write(pin, gpio.LOW);
            end
            b = not b;
        end)
        timer:start();
    end

    function export.turnOn()
        gpio.write(pin, gpio.HIGH);
        timer:unregister();
    end

    function export.turnOff()
        gpio.write(pin, gpio.LOW);
        timer:unregister();
    end

    return export;
end

return Light;
