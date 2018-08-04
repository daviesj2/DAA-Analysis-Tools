function [ax]=plotHorzSeparation(trafficStateOS,trafficStateINT,limit,RWCV,NMAC,ax)
%   Plot of actual horizontal separation based on trafficState structs.
%
%   Name: plotHorzSeparation.m [Function]   
%
%   INPUT: 
%       Ownship     [struct]: trafficState structure of ownship states
%       Intruder    [struct]: trafficState structure of intruder(s) states
%       limit       [double](opt.): Lower limit of separation to plot in nmi
%       RWCV        [double](opt.): Remain Well-Clear volume radius in nmi
%       NMAC        [double](opt.): Near Mid-Air Collision volume radius nmi
%       ax          [axes]  (opt.): Axes to draw plot
%
%   OUTPUT:
%       ax [axes]: Axes of drawn plot
%
%   NOTES:
%       Assumes Ownship and Intruder structs occur over the same time
%       period, intruders are truncated to ownship timeline
%       
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% [September 20, 2017]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
METER2NMI = 0.000539957; %Conversion of meters to nmi

if ~exist('limit','var'), limit = 10; end
if ~exist('RWCV','var'), RWCV = 1; end
if ~exist('NMAC','var'), NMAC = 0.082289416846; end

IntruderNames = unique({trafficStateINT.Name});
Intruders=cell(1,length(IntruderNames));

[validIntruders] = ismember([trafficStateINT.time],[trafficStateOS.time]);
trafficStateINT=trafficStateINT(validIntruders);

for i =1:length(IntruderNames)
    Intruders(i) = {trafficStateINT(strcmp({trafficStateINT.Name},IntruderNames{i}))};
end

Intruders(cellfun(@isempty,Intruders))=[];

if ~exist('ax','var') || ~isgraphics(ax)
    ax = gca;
end


hold(ax,'on');
IntruderNames = {};
HorzSep = gobjects(0);

for i = 1:length(Intruders)
    
    
    [~, IdxOwn, IdxInt] = intersect([trafficStateOS.time],[Intruders{i}.time]);
    thisOwnship = trafficStateOS(IdxOwn);
    thisIntruders = Intruders{i}(IdxInt);
    
    thisIntruderPos = [vertcat(thisIntruders.lat) vertcat(thisIntruders.lon)];
    thisOwnshipPos = [vertcat(thisOwnship.lat) vertcat(thisOwnship.lon)];
    
    distance = haversine(thisOwnshipPos,thisIntruderPos)*METER2NMI;
    
    if ~any(distance <= limit)
        continue
    end
    IntruderNames = [IntruderNames {Intruders{i}(1).Name}];
    HorzSep = [HorzSep scatter(ax,[thisOwnship.time],distance,'.')];
end
plot(xlim,[RWCV RWCV],'--','Color',[1 0.5 0])
plot(xlim,[NMAC NMAC],'--','Color',[1 0 0])

legend(HorzSep,IntruderNames);