function get(baseUrl, urlPath, finishedCallback)
    local url = string.format('%s/%s', baseUrl, urlPath);
    local headers = 'Content-Type: application/json\n';
    
    print(string.format('Getting data from %s', url));
    http.get(url, nil, function(code, data)
        local decodedData = nil;
        if (code ~= 200) then
            print(string.format('HTTP request failed, status %s', code));
        else
            decodedData = sjson.decode(data);
        end
        print('Response', data);

        finishedCallback(code, decodedData);
    end);
end

function post(baseUrl, urlPath, body, finishedCallback)
    local url = string.format('%s/%s', baseUrl, urlPath);
    local headers = 'Content-Type: application/json\n';
    
    print(string.format('Sending data to %s', url));
    local body = sjson.encode(body);
    print('Body', body);

--    if (false) then
    http.post(url, headers, body, function(code, data)
        local decodedData = nil;
        if (code ~= 200) then
            print(string.format('HTTP request failed, status %s', code));
        else
            decodedData = sjson.decode(data);
        end
        print('Response', data);

        finishedCallback(code, decodedData);
    end);
--    end
end

return {
    get = get,
    post = post
};
