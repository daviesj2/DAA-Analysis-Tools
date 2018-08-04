function [trafficStateOwnship, trafficStateIntruder] = splitTrafficStates(states,Ownship)
%   Splits combined trafficState strucutres into ownship and intruder(s)
%
%   Name: splitTrafficStates.m [Function]   
%
%   INPUT: 
%       states [struct]: Combined Ownship and Intruder trafficState struct
%       Ownship [char]:  Ownship Callsign
%   OUTPUT:
%       trafficStateOwnship [struct]:  trafficState structure of Ownship
%       trafficStateIntruder [struct]: trafficState structure of
%                                      Intruder(s)
%
%   NOTES: 
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 20, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isLVCStruct(states)
    [states]=genScenarioLVC(messages,Ownship,'','',1);
end
   
if isTrafficStateStruct(states)
    trafficStateOwnship = states(strcmp({states.Name},Ownship));
    trafficStateIntruder = states(~strcmp({states.Name},Ownship));
end