local delay = 5000;

print('---------------------------');
print(string.format('Waiting %s ms before running app.lua (you can delete it now)', delay));
tmr.alarm(0, delay, 0, function()
    print('Starting app.lua');
    dofile('app.lua')
end);
