function [trafficStateCAT, trafficStateOS, trafficStateINT]=genScenarioLVC(messages,outputPath,fileName)
%   Produces a DAIDALUS scenario file (.daa) from LVC DAA Aircraft Track State data structures (MsgAcTrackState) messages.
%   
%   Name: genScenarioLVC.m [Function]   
%
%   INPUT: 
%       messages    [struct]: LVC message structure from getLVC.m
%       outputPath  [char]: Path to place generated scenario file
%       fileName    [char]: Name of generated scenario file
%
%   OUTPUT:
%       trafficStateCAT [struct]: Interpolated trafficState structure of 
%                                 MsgFlighState messages for all traffic.
%                                    
%           .Name [char]:   Aircraft's callsign
%           .lat  [double]: latitude            (degrees)(N+,S-)
%           .lon  [double]: longitude           (degrees)(E+,W-)
%           .alt  [double]: Altitude            (ft) 
%           .vx   [double]: latitude velocity   (knot) 
%           .vy   [double]: longitude velocity  (knot)
%           .vz   [double]: climb rate          (fpm)
%           .time [double]: time UTC            (seconds)
%
%       trafficStateOS [struct]: TrafficState structure for Ownship
%
%       trafficStateINT [struct]: Uninterpolated trafficState 
%                                structure for all intruders
%
%   NOTES:
%           Intruder states are linearly interpolated to the next ownship
%           state in time. States with invalid (-999999) velocities are
%           assumed to be static ie, vx/y/z = 0, for interpolation.
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 13, 2017
%
% Assumes:  1deg of lat = 60.11 nmi
%           1deg long = cos(lat)*60.11  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('outputPath','var'), outputPath=''; end
if ~exist('fileName','var'), fileName='Scenario.daa'; end

[trafficStateOS, trafficStateINT]=getTrafficState(messages);

trafficStateCAT = interpStates(trafficStateOS,trafficStateINT,messages);

%Write scenario file
if ~isempty(outputPath)
    writeScenarioFile(trafficStateCAT,outputPath,fileName);
end

end

function trafficStateCAT = interpStates(trafficStateOS,trafficStateINT,messages)

SEC2HOUR = (1/60^2);
LENGTHLAT = 60.11; %nmi

%Scenario time
OStimes = [trafficStateOS.time];

%Tracks can be explicitly deleted via DeleteAC LVC messages
DeleteCalls = messages(strcmp({messages.Name},'DeleteAC'));

%Initialize traffic and trafficStateCAT structures
traffic = trafficStateOS(1);
traffic(1)=[];
trafficStateCAT=traffic;

OStimesCol = [[-inf OStimes(1:end-1)]' [OStimes(2:end) inf]']; %Col vectors of [ start stop ] for each interpolation block

INTblockIndex = [trafficStateINT.time] >= OStimesCol(:,1) & [trafficStateINT.time] < OStimesCol(:,2);   %start <= intruder time < stop 
INTnextIndex = [trafficStateINT.time] >= OStimesCol(:,1);                                               %intruder time >= start
DeleteBlockIndex = [DeleteCalls.time] >= OStimesCol(:,1) & [DeleteCalls.time] < OStimesCol(:,2);        %start <= Delete time < stop
uniqueIDs = unique([trafficStateINT.UID]);

finalTimes = zeros(1,length(uniqueIDs));
for i = 1:length(uniqueIDs)
    finalTimes(i) = trafficStateINT(find([trafficStateINT.UID]' == uniqueIDs(:,i),1,'last')).time;
end

for i = 1:length(OStimes)
       
    IntBlock = trafficStateINT(INTblockIndex(i,:));
    Delete = DeleteCalls(DeleteBlockIndex(i,:));
        
    trafficID = [traffic.UID];
    INTID = [IntBlock.UID];
                                    %Not currently in Intruder Block
    IntBlock = [IntBlock traffic(~ismember(trafficID,INTID)) ]; %Add missing traffic updates to the block
    
    [~, IDX] = unique([IntBlock.UID]); %If there are multiple states of the same intruder, use the first one
    IntBlock = IntBlock(IDX);          %Maybe averaging them might be better? 
    
    INTdt = OStimes(i)-[IntBlock.time];
    
    for j = 1:length(IntBlock) %Linearly project traffic states forward to ownship time.
        
        %vx/vy are in knots, vz in fpm. Convert from linear distance to
        %approx. coordinate change
        
        IntBlock(j).lat = IntBlock(j).lat + (IntBlock(j).vy * INTdt(j)*SEC2HOUR)/LENGTHLAT;
        IntBlock(j).lon = IntBlock(j).lon + (IntBlock(j).vx * INTdt(j)*SEC2HOUR)/(cosd(IntBlock(j).lat)*LENGTHLAT);
        
        %IntBlock(j).alt = IntBlock(j).alt + IntBlock(j).vz * INTdt(j)*SEC2MIN;
        
        %Altitude data is very coarse (~100 ft), trying to project
        %alititde from climbrate for short (~1s) states doesn't make a lot
        %of sense
        
        IntBlock(j).time = OStimes(i);
    
    end
    
    IDX = false(1,length(IntBlock));
    for j = 1:length(Delete)
        IDX = IDX | strcmp(deblank(Delete(j).Data.m_acid),{IntBlock.Name});
    end
    
    for j = 1:length(IntBlock)
        if OStimes(i) >= finalTimes(IntBlock(j).UID==uniqueIDs)
            IDX(j) = true;
        end
    end
       
    IntBlock(IDX) = [];
    traffic=IntBlock;

    trafficStateCAT = [trafficStateCAT trafficStateOS(i) IntBlock];
        
end

end

function writeScenarioFile(trafficState,outputPath,fileName)

    fid = fopen(fullfile(outputPath,fileName),'w+');
    
    %Write header
    fprintf(fid,'NAME,     lat,     lon,     alt,     vx,     vy,     vz,     time\n unitless,   [deg],    [deg],   [ft],    [knot],   [knot],   [fpm],  [s] '); %Print Header
    
    %Write entries
    for i = 1:length(trafficState)
        fprintf(fid, '\n%s, %.15f, %.15f, %.15f, %.15f, %.15f, %.15f, %.15f',...
                trafficState(i).Name,...
                trafficState(i).lat,...
                trafficState(i).lon,...
                trafficState(i).alt,...
                trafficState(i).vx,...
                trafficState(i).vy,...
                trafficState(i).vz,...
                trafficState(i).time);
    end
    
    fclose(fid);

end

function [trafficStateOS, trafficStateINT]=getTrafficState(messages)

INTtrackState = messages(strcmp({messages.Name},'MsgAcTrackState'));
OStrackState= messages(strcmp({messages.Name},'MsgAcTrackStateOS'));

tempTOA = [INTtrackState.Data];
tempTOA = [tempTOA.m_timeOfApplicability];
for i = 1:length(tempTOA)
    INTtrackState(i).time = tempTOA(i);
end

tempTOA = [OStrackState.Data];
tempTOA = [tempTOA.m_timeOfApplicability];
for i = 1:length(tempTOA)
    OStrackState(i).time = tempTOA(i);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trafficStateINT(length(INTtrackState)) = struct('Name',[],'UID',[],'lat',[],'lon',[],'alt',[],'track',[],'gs',[],'vx',[],'vy',[],'vz',[],'time',[]);
trafficStateOS(length(OStrackState)) = struct('Name',[],'UID',[],'lat',[],'lon',[],'alt',[],'track',[],'gs',[],'vx',[],'vy',[],'vz',[],'time',[]);

for i = 1:length(OStrackState)
    
        trafficStateOS(i).Name  = num2str(OStrackState(i).Data.m_callsign);
        trafficStateOS(i).UID   = OStrackState(i).Data.m_uid;
        trafficStateOS(i).lat   = OStrackState(i).Data.m_Latitude;
        trafficStateOS(i).lon   = OStrackState(i).Data.m_Longitude;
        trafficStateOS(i).alt   = OStrackState(i).Data.m_geometricAltitude;

        if OStrackState(i).Data.m_horizontalVelocity1 == -999999 || OStrackState(i).Data.m_horizontalVelocity1 == -999999
                trafficStateOS(i).vx    = 0; %invalid velocities should be ignored
                trafficStateOS(i).vy    = 0;
                trafficStateOS(i).gs = norm([trafficStateOS(i).vx trafficStateOS(i).vy]);
        else
            if OStrackState(i).Data.m_horizontalVelocityType == 1 %Type 1 is +N/-S & +E/-W velcity vector components
                trafficStateOS(i).vx    = OStrackState(i).Data.m_horizontalVelocity2; %E velocity
                trafficStateOS(i).vy    = OStrackState(i).Data.m_horizontalVelocity1; %N Velocity
            elseif OStrackState(i).Data.m_horizontalVelocityType == 2 %Type 2 is ground speed and true track angle
                trafficStateOS(i).vx    = OStrackState(i).Data.m_horizontalVelocity1*cosd(90-OStrackState(i).Data.m_horizontalVelocity2); %Calculate E velocity
                trafficStateOS(i).vy    = OStrackState(i).Data.m_horizontalVelocity1*sind(90-OStrackState(i).Data.m_horizontalVelocity2); %Calculate N velocity
            else
                error('m_horizontalVelocityType is unknown value of %d in track state %d',OStrackState(i).Data.m_horizontalVelocityType,i)
            end
            trafficStateOS(i).gs = norm([trafficStateOS(i).vx trafficStateOS(i).vy]);
        end
        trafficStateOS(i).track = wrapTo360(OStrackState(i).Data.m_trueHeading);
        trafficStateOS(i).vz    = OStrackState(i).Data.m_verticalVelocity;
        trafficStateOS(i).time  = OStrackState(i).time;
end

for i = 1:length(INTtrackState)
 
        trafficStateINT(i).Name  = num2str(INTtrackState(i).Data.m_callsign);
        trafficStateINT(i).UID   = INTtrackState(i).Data.m_uid;
        
        switch INTtrackState(i).Data.m_coordinateType
            case 1 %Relative lat/lon
                error('Relative Lat/Lon for intruders is not implemented yet.')
            case 2
                error('Range and bearing for intruder position is not implemented yet.')
            case 3
                trafficStateINT(i).lat   = INTtrackState(i).Data.m_horizontalPosition1;
                trafficStateINT(i).lon   = INTtrackState(i).Data.m_horizontalPosition2;
        end
        
        trafficStateINT(i).alt   = INTtrackState(i).Data.m_Altitude;

        if INTtrackState(i).Data.m_horizontalVelocity1 == -999999 || INTtrackState(i).Data.m_horizontalVelocity1 == -999999
                trafficStateINT(i).vx    = 0; %invalid velocities should be ignored
                trafficStateINT(i).vy    = 0;
                trafficStateINT(i).gs = norm([trafficStateINT(i).vx trafficStateINT(i).vy]);
        else
            if INTtrackState(i).Data.m_horizontalVelocityType == 1 %Type 1 is +N/-S & +E/-W velcity vector components
                trafficStateINT(i).vx    = INTtrackState(i).Data.m_horizontalVelocity2; %E velocity
                trafficStateINT(i).vy    = INTtrackState(i).Data.m_horizontalVelocity1; %N Velocity
            elseif INTtrackState(i).Data.m_horizontalVelocityType == 2 %Type 2 is ground speed and true track angle
                trafficStateINT(i).vx    = INTtrackState(i).Data.m_horizontalVelocity1*cosd(90-INTtrackState(i).Data.m_horizontalVelocity2); %Calculate E velocity
                trafficStateINT(i).vy    = INTtrackState(i).Data.m_horizontalVelocity1*sind(90-INTtrackState(i).Data.m_horizontalVelocity2); %Calculate N velocity
                trafficStateINT(i).track = wrapTo360(INTtrackState(i).Data.m_horizontalVelocity2);
            else %Otherwise there's something wrong
                error('m_horizontalVelocityType is unknown value of %d in track state %d',INTtrackState(i).Data.m_horizontalVelocityType,i)
            end
            trafficStateINT(i).gs = norm([trafficStateINT(i).vx trafficStateINT(i).vy]);
        end

        if isempty(trafficStateINT(i).track) %If we didn't record heading from horz vel, calculate it
            trafficStateINT(i).track = 90-atan2d(trafficStateINT(i).vx,trafficStateINT(i).vy);
        end
        
        if INTtrackState(i).Data.m_verticalSpeedType == 1 %Vertical speed type
            trafficStateINT(i).vz    = INTtrackState(i).Data.m_verticalSpeed;
        else
            error('Relative Speeds not implemented yet!');
        end
        trafficStateINT(i).time  = INTtrackState(i).time;
end
 
%Sort by ToA
[~,I] = sort([trafficStateINT.time]);
trafficStateINT=trafficStateINT(I);

[~,I] = sort([trafficStateOS.time]);
trafficStateOS=trafficStateOS(I);

end
