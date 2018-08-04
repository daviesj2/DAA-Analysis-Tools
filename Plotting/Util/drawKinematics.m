function [AX,OStext]=drawKinematics(AX,OwnshipState,IntruderState,oldOwnshipState,oldIntruderState,bandsSpace,ownshipText,windowSize)
% Draws ownship and intruder position and velocity on an lat/lon map.
% 
%   Name: drawKinematics.m [Function]   
%
%   INPUT: 
%       AX                 [axes]:   LVC message structure from getLVC().m
%
%       OwnshipState       [struct]: 1x1 trafficState struct of ownship
%                                    this is the time reference and figure center
%
%       IntruderState      [struct]: 1xN of N intruders' trafficStates at
%                                    OwnshipState's timestamp
%
%       oldOwnshipState    [struct](opt.): Ownship states preceding current
%                                          state, used to draw tails
%
%       oldIntruderState   [struct](opt.): Intruders' states preceding current
%                                          state, used to draw tails
%
%       bandsSpace         [double](opt.):  Add extra space between ownship icon
%                                           and callouts to allow for track guidance 
%                                           bands to be drawn. In window
%                                           units
%
%       ownshipText        [logical](opt.): Return ownship text instead of
%                                           drawing it beneath icon
%
%       windowSize         [double](opt.): set window size to 
%                                          (windowSize x windowSize)
%                                          in degrees
%
%   OUTPUT:
%       AX [axes]: Axes handle of drawn plots
%
%   NOTES:
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 13, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%Option Defaults: Specifying these programmatically seems unnessecary
ownshipMarkerSize = 25;
%%%%%

%Input checking defaults
if ~exist('bandsSpace','var')
    bandsSpace = 0;
end

if ~exist('windowSize','var')
    windowSize = 0.25;
end

if ~exist('ownshipText','var')
    ownshipText=false;
end

if ~(isTrafficStateStruct(OwnshipState,true) && isTrafficStateStruct(OwnshipState,true))
    error('Inputs 1 & 2 are not trafficStates!')
end

ownship = OwnshipState.Name;
IntruderState([IntruderState.lat]>OwnshipState.lat+windowSize | [IntruderState.lat]<OwnshipState.lat-windowSize) = [];
IntruderState([IntruderState.lon]>OwnshipState.lon+windowSize | [IntruderState.lon]<OwnshipState.lon-windowSize) = [];

cla(AX)
hold(AX,'on');

if exist('oldOwnshipState','var') && exist('oldIntruderState','var') && ~isempty(oldOwnshipState) && ~isempty(oldIntruderState)
    %Plot tails
    plot3(AX,[oldOwnshipState.lon],[oldOwnshipState.lat],[oldOwnshipState.alt],'.k','MarkerSize',5)
    plot3(AX,[oldIntruderState.lon],[oldIntruderState.lat],[oldIntruderState.alt],'.b','MarkerSize',5)
end


%Draw heading arrows
aspect = pbaspect(AX);
if bandsSpace > 0
    VectorLength = bandsSpace;
else
    VectorLength=0.12*windowSize;
end
VY = (sind(90-OwnshipState.track)/aspect(2))*VectorLength;
VX = (cosd(90-OwnshipState.track)/aspect(1))*VectorLength;

line([OwnshipState.lon OwnshipState.lon+VX],[OwnshipState.lat OwnshipState.lat+VY],[OwnshipState.alt OwnshipState.alt],'LineWidth',2,'Color','k')

for i = 1:length(IntruderState)
    VectorLength=norm([IntruderState(i).vx IntruderState(i).vy])/10000;
    VY = (sind(90-IntruderState(i).track)/aspect(2))*VectorLength;
    VX = (cosd(90-IntruderState(i).track)/aspect(1))*VectorLength;

    line([IntruderState(i).lon IntruderState(i).lon+VX],[IntruderState(i).lat IntruderState(i).lat+VY],[IntruderState(i).alt IntruderState(i).alt],'LineWidth',2,'Color','k')
end

%Plot ownship and intruders
plot3(AX,OwnshipState.lon,OwnshipState.lat,OwnshipState.alt,'o','MarkerSize',ownshipMarkerSize*0.5,'MarkerEdgeColor','k','MarkerFaceColor',[0.4 0.9 0.4]);
plot3(AX,[IntruderState.lon],[IntruderState.lat],[IntruderState.alt],'o','MarkerSize',ownshipMarkerSize*0.5,'MarkerEdgeColor','k','MarkerFaceColor',[0.25 0.4 1]);

xlim(AX,[OwnshipState.lon-windowSize OwnshipState.lon+windowSize]); %Window size X
ylim(AX,[OwnshipState.lat-windowSize OwnshipState.lat+windowSize]); %Window size Y

grid(AX,'on');

%Axis labels
% xlabel(AX,'Longitude (deg)')
% ylabel(AX,'Latitude (deg)')

%Annotate Ownship
if ownshipText
    OStext = sprintf('%s\n%.1f°\n%.1f ft\n%.1f knot',ownship,OwnshipState.track,OwnshipState.alt,OwnshipState.gs);
else
    if bandsSpace > 0
        text(OwnshipState.lon,OwnshipState.lat -bandsSpace,OwnshipState.alt-bandsSpace,sprintf('%s\n%.1f°\n%.1f ft\n%.1f knot',ownship,OwnshipState.track,OwnshipState.alt,OwnshipState.gs),'HorizontalAlignment','Center','VerticalAlignment','cap');
    else
        text(OwnshipState.lon,OwnshipState.lat -0.05*windowSize,OwnshipState.alt-0.05*windowSize,sprintf('%s\n%.1f°\n%.1f ft\n%.1f knot',ownship,OwnshipState.track,OwnshipState.alt,OwnshipState.gs),'HorizontalAlignment','Center','VerticalAlignment','cap');
    end
    OStext='';
end


%Annontate Intruder(s)
INTstring = cell(1,length(IntruderState));
for i = 1:length(IntruderState)
    INTstring(i) = {sprintf('%s\n%.1f°\n%.1f ft\n%.1f knot',IntruderState(i).Name,IntruderState(i).track,IntruderState(i).alt,IntruderState(i).gs)};
end
text([IntruderState.lon],[IntruderState.lat]-0.05*windowSize,[IntruderState.alt]-0.05*windowSize,INTstring,'HorizontalAlignment','Center','Clipping','on','VerticalAlignment','cap')
end
