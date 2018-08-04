function kinematicOverview(scenario,config)
% Interactive overview of scenario kinematics and track guidance.
%
%   Name: kinematicOverview.m [Function]   
%
%   INPUT: 
%       scenario [char]: Full path to a scenario file (*.daa)
%       
%       config   [char](opt.): Full path to a DAIDALUS config file
%   OUTPUT:
%       NONE
%
%   NOTES:
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% October 6, 2017
% ___________________________________________________________
%|                                                           |
%| Requires Matlab java version (version '-java') be equal to|
%| DAIDALUS.jar. This can be set with EV MATLAB_JAVA before  |
%| launching Matlab                                          |
%|___________________________________________________________|

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('config','var')
    config = '';
end

data = struct('time',[],'timeLine',[],'Once',[],'Exist',[],'Play',[],'trafficStateOS',[],'trafficStateINT',[],'Bands',[],'Config',[],'Handles',[]);

%Options
data.Config.tailLength = 10; %Length of trail points
data.Config.windowSize = 0.25; %Square window size in degrees
data.Config.BandsDistance = data.Config.windowSize/10; %Track bands radius in window units (degrees)
data.Config.FrameRate = 5;

%Get relevent state and DAIDALUS data
[data.trafficStateOS, data.trafficStateINT] = getTrafficStateDAA(scenario);
[data.Bands.TrkBands, ~, ~, ~, ~, ~, data.Config.scenario] = getDAIDBands(scenario,config);
data.timeLine = [data.trafficStateOS.time];

%Draw and modify figure layout
fig = figure('Position',[700 462 670 480],'Name',scenario,'NumberTitle','off');
ax = axes(fig,'DeleteFcn',@stopAll,'Position',[0.062 0.216417910447761 0.9131 0.760582089552239]);

%Define shared variables
data.time = data.timeLine(1);
data.Play = false;
data.Exist = false;
data.Once = true;

%Embed data structure to axis
ax.UserData = data;

%Draw UI control objects
uicontrol('style','text','String','Current Time','Units','normalized','Position',[0.133582089552239 0.0906666666666667 0.2 0.04])
uicontrol('style','text','String','Ownship Info','Units','normalized','Position',[0.810929405472636 0.107212506420134 0.10935 0.05642],'FontWeight','bold');
uicontrol('style','text','String',{'Callsign:' 'Track:' 'Altitude:' 'Ground Speed:'},'Units','normalized','Position',[0.761380276119403 0.00542501284026708 0.10935 0.12342],'HorizontalAlignment','right');
uicontrol('style','text','String','Frame Rate','Units','normalized','Position',[0.347761194029852 0.0791666666666666 0.0791044776119404 0.0395833333333334],'HorizontalAlignment','right');


ax.UserData.Handles.startStop = uicontrol('CallBack',{@buttonFun, ax},'Units','normalized','Position',[0.0622820895522388 0.0310033333333333 0.0649400000000001 0.095],'String','Start');
ax.UserData.Handles.timeBox = uicontrol('Style','edit','CallBack',{@timeBoxFun, ax},'Units','normalized','Position',[0.138059701492537 0.0384166666666667 0.2 0.05],'String',num2str(ax.UserData.time));
ax.UserData.Handles.Info = uicontrol('Style','text','String','','Units','normalized','Position',[0.873170149253731 0.00467999999999999 0.0881989999999999 0.1235],'HorizontalAlignment','left');
ax.UserData.Handles.Slider = uicontrol('CallBack',{@sliderFun, ax},'Style','slider','String','Time','Value',ax.UserData.time,'Units','normalized','Position',[0.35 0.032 0.316 0.04],'Min',min(ax.UserData.timeLine),'Max',max(ax.UserData.timeLine));
ax.UserData.Handles.FrameRate = uicontrol('CallBack',{@frameRateFun, ax},'Style','edit','String',num2str(ax.UserData.Config.FrameRate),'Units','normalized','Position',[0.434328358208956 0.0833333333333333 0.0349424751243778 0.0395833333333334]);

%Draw the first frame
draw(ax)
end

%UI Callbacks
function buttonFun(UI, ~, ax)
    
    %Start main thread
    if ~ax.UserData.Exist
        ax.UserData.Exist = true;
        ax.UserData.Play = true;
        UI.String = 'Stop';
        mainThread(ax);
        return
    end
    
    %Toggle play status
    if ax.UserData.Play
        UI.String = 'Start';
        ax.UserData.Play = false;
        
    else
        UI.String = 'Stop';
        ax.UserData.Play = true;
        mainThread(ax);
    end
    
end
function timeBoxFun(UI, ~, ax)
    tempTime = str2double(UI.String);       %Get input time
    ax.UserData.time = near(tempTime,ax.UserData.timeLine);  %Pull out a timestamp near entered time
    ax.UserData.Play = false;
    ax.UserData.Once = true; %Don't start playing, just draw the frame
    ax.UserData.Handles.startStop.String = 'Start';
    draw(ax)
end
function sliderFun(UI,~,ax)
    tempTime = UI.Value;      %Get input time
    ax.UserData.time = near(tempTime,ax.UserData.timeLine);  %Pull out a timestamp near entered time
    ax.UserData.Play = false;
    ax.UserData.Once = true; %Don't start playing, just draw the frame
    ax.UserData.Handles.startStop.String = 'Start';
    draw(ax)
end
function frameRateFun(UI,~,ax)
ax.UserData.Config.FrameRate = str2double(UI.String);
end
function stopAll(~, ~)
data.Exist = false;
end

%Main thread
function draw(ax)


if ax.UserData.time<ax.UserData.timeLine(end) && (ax.UserData.Play || ax.UserData.Once)
    privateData = ax.UserData;
     
    %Define states for this timestep
    thisOwnshipState = privateData.trafficStateOS([privateData.trafficStateOS.time] == privateData.time);
    thisIntruderState = privateData.trafficStateINT([privateData.trafficStateINT.time] == thisOwnshipState.time);
    thisTrkBands = privateData.Bands.TrkBands([privateData.Bands.TrkBands.time] == thisOwnshipState.time);
    
    %Old states for drawing tails
    oldOwnshipState = privateData.trafficStateOS([privateData.trafficStateOS.time]<=thisOwnshipState.time & [privateData.trafficStateOS.time]>(thisOwnshipState.time-privateData.Config.tailLength)); 
    oldIntruderState = privateData.trafficStateINT([privateData.trafficStateINT.time]<=thisOwnshipState.time & [privateData.trafficStateINT.time]>(thisOwnshipState.time-privateData.Config.tailLength));
    
    %Draw frame
    [~,text]=drawKinematics(ax,thisOwnshipState,thisIntruderState,oldOwnshipState,oldIntruderState,ax.UserData.Config.BandsDistance,true,ax.UserData.Config.windowSize);
    ax.UserData.Handles.Info.String = text;
    drawBands(ax,thisTrkBands,thisOwnshipState)
    
    %Increment and update time info
    ax.UserData.time = privateData.timeLine(find(privateData.timeLine == privateData.time,1)+1);
    ax.UserData.Handles.timeBox.String = num2str(privateData.time);
    ax.UserData.Handles.Slider.Value = privateData.time;
else
    ax.UserData.Play = false;
end

if ax.UserData.Once
    ax.UserData.Once = false;
end

end
function mainThread(ax)
    while  isgraphics(ax) && ax.UserData.Exist
        if ax.UserData.Play            
            draw(ax)
            pause(1/ax.UserData.Config.FrameRate);
        else
            return
        end   
    end
end

%Render functions
function drawBands(AX, TrkBands, Ownship)
ASPECT = pbaspect(AX);
circle = 0:360;
privateData = AX.UserData;
%Band colors in vector format
NONE = [0 0 0];     %black
FAR  = [0 0 1];     %blue
MID  = [1 0.5 0];   %orange
NEAR = [1 0 0];     %red
RECOVERY = [0 1 0]; %green

%Draw each band around ownship
for i = 1:length(TrkBands.NONE)
    ticks = TrkBands.NONE{i};
    region = toHeading(circle(circle >= ticks(1) & circle <= ticks(2)));
    x = ((cosd(region)/ASPECT(1))*privateData.Config.BandsDistance)+Ownship.lon;
    y = ((sind(region)/ASPECT(2))*privateData.Config.BandsDistance)+Ownship.lat;
    z = ones(1,numel(x))*Ownship.alt;
    plot3(AX,x,y,z,'Color',NONE,'LineWidth',3)
end
for i = 1:length(TrkBands.FAR)
    ticks = TrkBands.FAR{i};
    region = toHeading(circle(circle >= ticks(1) & circle <= ticks(2)));
    x = ((cosd(region)/ASPECT(1))*privateData.Config.BandsDistance)+Ownship.lon;
    y = ((sind(region)/ASPECT(2))*privateData.Config.BandsDistance)+Ownship.lat;
    z = ones(1,numel(x))*Ownship.alt;
    plot3(AX,x,y,z,'Color',FAR,'LineWidth',3)
end
for i = 1:length(TrkBands.MID)
    ticks = TrkBands.MID{i};
    region = toHeading(circle(circle >= ticks(1) & circle <= ticks(2)));
    x = ((cosd(region)/ASPECT(1))*privateData.Config.BandsDistance)+Ownship.lon;
    y = ((sind(region)/ASPECT(2))*privateData.Config.BandsDistance)+Ownship.lat;
    z = ones(1,numel(x))*Ownship.alt;
    plot3(AX,x,y,z,'Color',MID,'LineWidth',3)
end
for i = 1:length(TrkBands.NEAR)
    ticks = TrkBands.NEAR{i};
    region = toHeading(circle(circle >= ticks(1) & circle <= ticks(2)));
    x = ((cosd(region)/ASPECT(1))*privateData.Config.BandsDistance)+Ownship.lon;
    y = ((sind(region)/ASPECT(2))*privateData.Config.BandsDistance)+Ownship.lat;
    z = ones(1,numel(x))*Ownship.alt;
    plot3(AX,x,y,z,'Color',NEAR,'LineWidth',3)
end
for i = 1:length(TrkBands.RECOVERY)
    ticks = TrkBands.RECOVERY{i};
    region = toHeading(circle(circle >= ticks(1) & circle <= ticks(2)));
    x = ((cosd(region)/ASPECT(1))*privateData.Config.BandsDistance)+Ownship.lon;
    y = ((sind(region)/ASPECT(2))*privateData.Config.BandsDistance)+Ownship.lat;
    z = ones(1,numel(x))*Ownship.alt;
    plot3(AX,x,y,z,'Color',RECOVERY,'LineWidth',3)
end
end

%Small utility functions
function [out] = toHeading(vect)
out = 90-(vect);
end
function [out, IDX]=near(val,vector)

[~,IDX] = min(abs(vector-val));
out = vector(IDX);

end