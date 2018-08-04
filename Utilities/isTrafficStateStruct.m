function [out]=isTrafficStateStruct(input,extended)

if ~exist('extended','var'), extended = false; end

if extended 
    trafficStateFields = {'Name'...
        'UID'...
        'lat'...
        'lon'...
        'alt'...
        'track'...
        'gs'...
        'vx'...
        'vy'...
        'vz'...
        'time'};
else
    trafficStateFields = {'Name'...
        'UID'...
        'lat'...
        'lon'...
        'alt'...
        'track'...
        'vx'...
        'vy'...
        'vz'...
        'time'};
end

if isstruct(input) && all(ismember(trafficStateFields,fieldnames(input)))
    out=true;
else
    out=false;
end