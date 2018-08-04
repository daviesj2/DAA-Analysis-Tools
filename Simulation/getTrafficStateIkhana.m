function [trafficState] = getTrafficStateIkhana(path,file,callsign)
%   Generate trafficState structures from Ikhana GPS logs
%
%   Name: getTrafficStateIkhana.m [Function]   
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
%   No   ,   Rover    ,         UTC time          ,SVs ,    Latitude    ,    Longitude    ,Height, foot ,   sX   ,   sY   ,   sZ   , RMS, m ,Fixed ,   Heading,°   ,    Pitch,°   
% --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%      1 ,log0718a_01 ,18/07/2017 12:08:20.000 PM ,  9 ,N 34.921505414° ,W 117.881846603° ,   2200.2114 , 0.3769 , 1.3210 , 1.8922 , 2.3383 ,No    ,356.238171341° ,0.031025070°  
%      2 ,log0718a_01 ,18/07/2017 12:08:21.000 PM ,  9 ,N 34.921500076° ,W 117.881819012° ,   2199.2644 , 0.2673 , 0.9343 , 1.3385 , 1.6541 ,No    ,356.196016323° ,0.026099048°  
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
headers = 17; %Number of header lines
mps2knot = 1.94384; %m/s to knot conversion

data = {};
i=1;
fid = fopen(log);
while ~feof(fid) %Loop over the file and get all the data out
    data{i,1} = fgetl(fid);
    i=i+1;
end
fclose(fid);
for i = 1:length(data(:,1))
    data{i,1}(strfind(data{i,1},cast(0,'char')))=[]; %Weird null characters in these logs, remove them.
end

data = deblank(data); %clean up a bit
data(cellfun('isempty',data))=[];%Remove empties
data = split(data(headers:end),',');

trafficState(length(data(:,1))) = struct('Name',[],'lat',[],'lon',[],'alt',[],'track',[],'vx',[],'vy',[],'vz',[],'time',[]);

for i = 1:length(data(:,1))
    trafficState(i).Name = callsign;
    
    %Get latitude
    lat = data{i,5};
    lat(strfind(lat,'°'))=[];
    lat = split(deblank(lat));
    
    if any(strfind(lat{1},'N'))
        lat = str2double(lat{2});
    elseif any(strfind(lat{1},'S'))
        lat = str2double(lat{2})*-1;
    else
        error('Improper coordinate spec.');
    end        
    trafficState(i).lat = lat;
    
    %Get longitude
    lon = data{i,6};
    lon(strfind(lon,'°'))=[];
    lon = split(deblank(lon));
    
    if any(strfind(lon{1},'E'))
        lon = str2double(lon{2});
    elseif any(strfind(lon{1},'W'))
        lon = str2double(lon{2})*-1;
    else
        error('Improper coordinate spec.');
    end
    trafficState(i).lon = lon;
    
    %Get altitude
    trafficState(i).alt = str2double(strip(data{i,7}));
    
    %Get time
    trafficState(i).time = posixtime(datetime(data{i,3},'InputFormat','dd/MM/yyyy hh:mm:ss.SSS a'));
    
%     %Record heading
%     tempHead = data{i,13};
%     tempHead(strfind(tempHead,'°'))=[];
%     heading(i) = str2double(strip(tempHead));
%     trafficState(i).track = heading(i);
%
% Heading appears incorrect in GPS logs, we will calculate
% It ourselves later.
end
    locs = [vertcat(trafficState.lat) vertcat(trafficState.lon)];
    posA = locs(1:end-1,:);
    posB = locs(2:end,:);
    distance = haversine(posA,posB);
    displacement = posB-posA;
    heading = 90-atan2d(displacement(:,1),displacement(:,2));
    heading = mod(heading+360,360);
    
    dTime = diff(vertcat(trafficState.time));
    
    speed = distance./dTime;
    xyCart = 90-heading(:); %Convert heading to xy-Carteseian angle
    
    vx = (speed.*cosd(xyCart))*mps2knot;
    vy = (speed.*sind(xyCart))*mps2knot;
    
    
    dAlt = diff([trafficState.alt]);
    vz = (dAlt./dTime)*60; %Already in ft/s, convert to fpm
    
    trafficState(end).vx=0;
    trafficState(end).vy=0;
    trafficState(end).vz=0;
    
    for i = 1:length(trafficState)-1
        trafficState(i).vx = vx(i);
        trafficState(i).vy = vy(i);
        trafficState(i).vz = vz(i);
        trafficState(i).gs = norm([vx(i) vy(i)]);
        trafficState(i).track = heading(i);
    end
    
%%% Reset default Parallel setting
parSettings.Pool.AutoCreate = AutoCreateDefault;
%%%

end
