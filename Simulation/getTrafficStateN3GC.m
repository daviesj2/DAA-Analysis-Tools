function [trafficState,heading] = getTrafficStateN3GC(path,file,callsign)
%   Generate trafficState structures from N3GC GPS logs
%
%   Name: getTrafficStateN3GC.m [Function]   
%
%   INPUT: 
%       path        [char]: Path containing log file
%       file        [char]: Log file name (.txt/csv)
%       callsign    [char]: Callsign to assign
%
%   OUTPUT:
%       trafficState [struct]: generated trafficState struct
%
%   NOTES:
%       
%       Can take advantage of parpool if available.
%           
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% [September 21, 2017]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example head()
%
% SITE MM/DD/YY HH:MM:SS         SVs PDOP     LATITUDE       LONGITUDE        HI        RMS   FLAG   V_EAST  V_NORTH     V_UP
% 9-K  07/18/17 12:55:38.000000   8   1.9  N 35.05837394  W -118.1426084   803.7687     0.037   2     0.008   -0.006   -0.020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%This changes your parallel pool settings to not auto-create a pool on a
%parfor call. This change is reverted at the end of the function. 
%Feel free to comment or remove these lines if you don't want to mess with
%your settings.
%%%
parSettings = parallel.Settings;
AutoCreateDefault = parSettings.Pool.AutoCreate;
parSettings.Pool.AutoCreate = false;
%%%


log = fullfile(path,file);
headers = 5; %Number of header lines
mps2knot = 1.94384; %m/s to knot conversion
mps2fpm = 196.85; %m/s to fpm
m2ft = 3.28084; %m to ft

data = {};
i=1;
fid = fopen(log);
while ~feof(fid) %Loop over the file and get all the data out
    data{i,1} = fgetl(fid);
    i=i+1;
end
fclose(fid);
data(1:headers) = []; %Remove header info

tempData(length(data),:) = split(data(1));
for i = 1:length(data) %Split out fields
    tempData(i,:) = split(data(i));
end
data=tempData;

trafficState(length(data(:,1))) = struct('Name',[],'lat',[],'lon',[],'alt',[],'track',[],'gs',[],'vx',[],'vy',[],'vz',[],'time',[]);

for i = 1:length(data(:,1))
    trafficState(i).Name = callsign;
    
    %Get latitude    
    trafficState(i).lat = str2double(data{i,7});
    
    %Get longitude
    trafficState(i).lon = str2double(data{i,9});

    %Get altitude
    trafficState(i).alt = str2double(data{i,10})*m2ft;
    
    %Get time
    trafficState(i).time = posixtime(datetime([data{i,2} ' ' data{i,3}],'InputFormat','MM/dd/yy HH:mm:ss.SSS'));
    
    trafficState(i).vx = str2double(data{i,13})*mps2knot;
    trafficState(i).vy = str2double(data{i,14})*mps2knot;
    trafficState(i).vz = str2double(data{i,15})*mps2fpm;
    trafficState(i).gs = norm([trafficState(i).vx trafficState(i).vy]);
    
end

locs = [vertcat(trafficState.lat) vertcat(trafficState.lon)];
posA = locs(1:end-1,:);
posB = locs(2:end,:);
displacement = posB-posA;
heading = 90-atan2d(displacement(:,1),displacement(:,2));
heading = vertcat(heading, heading(end));
heading = mod(heading+360,360);

parfor i = 1:length(trafficState)
    trafficState(i).track = heading(i);
end

%%% Reset default Parallel setting
parSettings.Pool.AutoCreate = AutoCreateDefault;
%%%

end