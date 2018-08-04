function [ trafficStateOS, trafficStateINT, relTrafficStateINT, Unit ] = getTrafficStateDAA( DAA, config )
%   Generate trafficState structures from scenario using DAIDALUS
%
%   Name: getTrafficStateDAA.m [Function]   
%
%   INPUT: 
%       DAA         [char]: Full path to scenario file
%       config      [char]: Full path to configuration file
%
%   OUTPUT:
%       trafficStateOS      [struct]: trafficState structure of Ownship
%       trafficStateINT     [struct]: trafficState structure of all
%                                     intruders
%       relTrafficStateINT  [struct]: Relative Euclidean projection of
%                                     intruder states
%       Unit                [struct]: Unit structure
%
%   NOTES:
%           
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% [October 16, 2017]
% ___________________________________________________________
%|                                                           |
%| Requires Matlab java version (version '-java') be equal to|
%| DAIDALUS.jar. This can be set with EV MATLAB_JAVA before  |
%| launching Matlab                                          |
%|___________________________________________________________|

import('gov.nasa.larcfm.ACCoRD.*')
import('gov.nasa.larcfm.IO.*')

trafficStateINT = struct('Name',[],'UID',[],'lat',[],'lon',[],'alt',[],'track',[],'gs',[],'vx',[],'vy',[],'vz',[],'time',[]);
relTrafficStateINT = struct('Name',[],'UID',[],'Position',[],'Velocity',[],'time',[]);

trafficStateINT(1) = [];
relTrafficStateINT(1)=[];

%Create Daidalus instance
daa = Daidalus;

%Apply a config file if provided
if exist('config','var')
    daa.parameters.loadFromFile(config);
end

%Start a new FileWalker
input = DaidalusFileWalker(DAA);

%If there are no states, something is wrong
if input.atBeginning && input.atEnd
    error('Invalid or empty scenario file');
end

lastIDX = input.indexOfTime(input.lastTime); %Zero indexed position of final state

Unit.lat = 'deg'; %Add units soon
Unit.lon = 'deg'; 
Unit.alt = daa.parameters.getUnits("alt_step").toCharArray';
Unit.gs = daa.parameters.getUnits("gs_step").toCharArray';
Unit.track = daa.parameters.getUnits("trk_step").toCharArray';
Unit.vx = daa.parameters.getUnits("gs_step").toCharArray';
Unit.vy = daa.parameters.getUnits("gs_step").toCharArray';
Unit.vz = daa.parameters.getUnits("gs_step").toCharArray';


Unit.s_x = 'nmi';
Unit.s_y = 'nmi';
Unit.s_z = 'ft';
Unit.v_x = 'knot';
Unit.v_y = 'knot';
Unit.v_z = 'fpm';

trafficStateOS(lastIDX+1) = struct('Name',[],'UID',[],'lat',[],'lon',[],'alt',[],'track',[],'gs',[],'vx',[],'vy',[],'vz',[],'time',[]);

for i = 1:lastIDX+1 
    %%%%%Read States into the Daidalus object%%%%%
    input.readState(daa)
    
    %%%%%Get Aircraft States%%%%%
    trafficStateOS(i) = MorphTrafficState(daa.getOwnshipState, Unit);
    
    %Preallocation helps speed a bit
    tempTrafficStateINT(1:daa.numberOfAircraft-1) = struct('Name',[],'UID',[],'lat',[],'lon',[],'alt',[],'track',[],'gs',[],'vx',[],'vy',[],'vz',[],'time',[]);
    tempRelTrafficStateINT(1:daa.numberOfAircraft-1) = struct('Name',[],'UID',[],'Position',[],'Velocity',[],'time',[]);
    
    %Get all Intruder traffic states for this timestep
    for j = 1:daa.numberOfAircraft-1 
       [tempTrafficStateINT(j), tempRelTrafficStateINT(j)] = MorphTrafficState(daa.getAircraftState(j), Unit);
    end
    
    trafficStateINT = [trafficStateINT tempTrafficStateINT];
    relTrafficStateINT = [relTrafficStateINT tempRelTrafficStateINT];
end

end

function[trafficStateStruct, relTrafficStateStruct] = MorphTrafficState(trafficState, Unit)

    import('gov.nasa.larcfm.Util.*')

    %Format trafficState object into a trafficState structre%
    
    trafficStateStruct.Name = trafficState.getId.toCharArray';
    trafficStateStruct.UID = str2double(strrep(num2str(int32(trafficStateStruct.Name)),' ','')); %Kind of an odd method but should produce a unique number for each aircraft

    trafficStateStruct.lat = Units.to(Unit.lat, trafficState.getPosition.lat);
    trafficStateStruct.lon = Units.to(Unit.lon, trafficState.getPosition.lon);
    trafficStateStruct.alt = Units.to(Unit.alt, trafficState.getPosition.alt);
    
    trafficStateStruct.track = Units.to(Unit.track,trafficState.getVelocity.trk);
    trafficStateStruct.gs = Units.to(Unit.gs,trafficState.getVelocity.gs);
    
    trafficStateStruct.vx = Units.to(Unit.vx,trafficState.getVelocity.x);
    trafficStateStruct.vy = Units.to(Unit.vy,trafficState.getVelocity.y);
    trafficStateStruct.vz = Units.to(Unit.vz,trafficState.getVelocity.z);

    trafficStateStruct.time = trafficState.getTime;
    
    relTrafficStateStruct.Name = trafficState.getId.toCharArray';
    relTrafficStateStruct.UID = str2double(strrep(num2str(int32(trafficStateStruct.Name)),' ',''));

    relTrafficStateStruct.Position = [Units.to(Unit.s_x, trafficState.get_s.x) Units.to(Unit.s_y, trafficState.get_s.y) Units.to(Unit.s_z, trafficState.get_s.z)];
    relTrafficStateStruct.Velocity = [Units.to(Unit.v_x, trafficState.get_v.x) Units.to(Unit.v_y, trafficState.get_v.y) Units.to(Unit.v_z, trafficState.get_v.z)];

    relTrafficStateStruct.time = trafficState.getTime;
 
end