function startup()
    if file.open('init.lua') == nil then
        print('init.lua deleted')
    else
        print('init.lua ok - running')
        
        file.close('init.lua')

        dofile('app.lua')
    end
end

tmr.alarm(0, 2500, 0, startup)
