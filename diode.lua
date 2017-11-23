local diode = {};

function diode.create(statusDiodePin)
    gpio.mode(statusDiodePin, gpio.OUTPUT);

    local statusDiodeTimer = tmr.create();

    function startBlink()
        local b = false;
        gpio.write(statusDiodePin, gpio.LOW);
        statusDiodeTimer:register(100, tmr.ALARM_AUTO, function()
            if (b) then
                gpio.write(statusDiodePin, gpio.HIGH);
            else
                gpio.write(statusDiodePin, gpio.LOW);
            end
            b = not b;
        end)
        statusDiodeTimer:start();   
    end

    function turnOn()
        gpio.write(statusDiodePin, gpio.HIGH);
        statusDiodeTimer:unregister();
    end

    function turnOff()
        gpio.write(statusDiodePin, gpio.LOW);
        statusDiodeTimer:unregister();
    end

    local export = {
        blink = startBlink,
        turnOn = turnOn,
        turnOff = turnOff
    };
    
    return export;
end

return diode;
