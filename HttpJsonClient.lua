local HttpJsonClient = {};

function HttpJsonClient.get(baseUrl, urlPath, expectedStatus, finishedCallback)
    local url = string.format('%s/%s', baseUrl, urlPath);

    print(string.format('Getting data from %s', url));
    http.get(url, nil, getResponseHandler(expectedStatus, finishedCallback));
end

function HttpJsonClient.post(baseUrl, urlPath, body, expectedStatus, finishedCallback)
    local url = string.format('%s/%s', baseUrl, urlPath);
    local headers = 'Content-Type: application/json\n';
    
    print(string.format('Sending data to %s', url));
    local body = sjson.encode(body);
    print('Body', body);

    http.post(url, headers, body, getResponseHandler(expectedStatus, finishedCallback));
end


function getResponseHandler(expectedStatus, finishedCallback)
    return function(code, body, headers)
        local decodedBody = nil;
        if (code ~= expectedStatus) then
            print(string.format('HTTP request failed, status %s', code));
        else
            decodedBody = sjson.decode(body);
        end

        print('Response headers', headers and sjson.encode(headers) or 'headers empty');
        print('Response body', body);

        finishedCallback(code, decodedBody);
    end
end

return HttpJsonClient;
