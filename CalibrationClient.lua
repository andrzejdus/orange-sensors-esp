local Config = require 'Config';
local HttpJsonClient = require 'HttpJsonClient';

local CalibrationClient = {}

CalibrationClient.getCalibrationData = function (onCalibrationDataReceived, onCalibrationFailed)
    HttpJsonClient.get(Config.BASE_URL, 'calibration', 200, function (code, jsonData)
        if (code == 200) then
            print('Calibration sucessfull');

            calibrationData = {
                splitDistance = jsonData.data.splitDistance,
                measurmentInterval = jsonData.data.measurmentInterval
            }

            onCalibrationDataReceived(calibrationData)
        else
            print('Calibration unsucessfull, returned HTTP code ', code);

            onCalibrationFailed();
        end
    end);
end

return CalibrationClient;
