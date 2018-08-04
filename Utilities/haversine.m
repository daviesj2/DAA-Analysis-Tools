function [distance]=haversine(posA,posB)
%   Finds distance in meters between two coordinates on Earth. 
%
%   Name: haversine.m [Function]   
%
%   INPUT: 
%       posA [double]: First position in degrees. [lat lon]
%       posB [double]: Second position in degrees. [lat lon]
%   OUTPUT:
%       VAR [distance]: Distance between locations (meters)
%
%   NOTES: Can take 1x2 vectors, equal length nx2 vectors, or trafficStates.
%          
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 15, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R = 6371008; %Earth's radius in meters
deg2rad = pi/180;%Radian conversion

%Convert trafficStates to [lat lon] 
if isTrafficStateStruct(posA) && isTrafficStateStruct(posB)
    posA = [vertcat(posA.lat) vertcat(posA.lon)];
    posB = [vertcat(posB.lat) vertcat(posB.lon)];
end

if length(posA(1,:)) ~= 2 || length(posB(1,:)) ~= 2, error('Inputs must be 2 columns!'); end
if length(posA(:,1)) ~= length(posB(:,1)), error('Inputs must be the same length!'); end

lat1 = posA(:,1).*deg2rad;
lon1 = posA(:,2).*deg2rad;

lat2 = posB(:,1).*deg2rad;
lon2 = posB(:,2).*deg2rad;

distance = 2.*R.*(asin(sqrt(hav(lat2-lat1)+cos(lat1).*cos(lat2).*hav(lon2-lon1))));

end

function [out] = hav(theta)
out = (1-cos(theta))/2;
end