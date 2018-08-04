function[figures]=drawBandsDAIDALUS(varargin)
%   Draws DAIDALUS DAA bands as figures or video frames.
%
%   Name: drawDAAbandsDAIDALUS.m [Function]   
%
%   Visualizes DAA multibands from DAIDALUS. Can take inputs directly from
%   getDAAbandsDAIDALUS.m 
%
%   INPUT: 
%       varargin[1]:
%           daaPath    [char]: Fully qualified path to .draw file to be
%                               used as input to getDAAbandsDAIDALUS.m
%       varargin[2]:
%           varargin{1} [char]: Path containing .draw file.
%           varargin{2} [char]: File to be used as input to 
%                               getDAAbandsDAIDALUS.m
%
%       varargin[8]:
%           {1} TrkBands    [struct]: DAAbands structure for track guidance
%                                     (described in getDAAbandsDAIDALUS.m)
%           {2} GsBands     [struct]: DAAbands structure for ground speed 
%           {3} VsBands     [struct]: DAAbands structure for climb rate
%           {4} AltBands    [struct]: DAAbands structure for altitude
% 
%           {5} Alerts      [struct]: Structure containing alert information             
%                   .Callsign   [char]: Callsign on of intruder
%                   .Times      [double]: 1xN vector of times of applicability of alerts
%                   .Levels     [int]:  1xN vector of alert levels
% 
%           {6} MinMax      [struct]: Struct of performance limit information
%                                {1}: [hi-bound lo-bound] {2}: 'unit'
%                   .Gs         [cell]: Ground speed limit
%                   .Vs         [cell]: Climb rate limit
%                   .Alt        [cell]: Altitude limit
% 
%           {7} ownship     [char]
%           {8} scenario    [char]
%           {9} relativeTrk [logical]
%
%       varargin[11]
%           varargin{1:8}
%           +
%           OwnshipState [struct]: State structure for ownship 
%                                  (from getTrafficState*.m)
%           IntruderState[struct]: State structure for intruder(s)
%           relativeTrk [logical]: Plot track information relative to ownship heading
%           
%   OUTPUT:
%           figures [cData/figure]: Color data or figure handles generated 
%                                   from data.
%   NOTES:
%           If the number of requested is > 5 video frames will be
%           extracted from each figure and each figure will be closed after
%           generation to keep MATLAB from crashing. These frames can be
%           turned into video files using a VideoWriter object.
%
%           Various plot parameters can be specified in %%%%OPTIONS%%%%%
%           section following input handling.
%
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% DATE [September 19, 2017]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch length(varargin) %Input handling
    case 1
        daaPath = varargin{1};
        [TrkBands, GsBands, VsBands, AltBands, MinMax, ownship, scenario] = getDAIDBands(daaPath);
        Alerts = getDAIDAlerts(daaPath);
        [OwnshipState, IntruderState] = getTrafficStateDAA(daaPath);
        relativeTrk = true;
    case 2
        daaPath = fullfile(varargin{1},varargin{2});
        Alerts = getDAIDAlerts(daaPath);
        [TrkBands, GsBands, VsBands, AltBands, MinMax, ownship, scenario] = getDAIDBands(daaPath);
        relativeTrk = true;
        [OwnshipState, IntruderState] = getTrafficStateDAA(daaPath);
    case 9
        [TrkBands, GsBands, VsBands, AltBands, Alerts, MinMax, ownship, scenario, relativeTrk]=varargin{:};
    case 11
        [TrkBands, GsBands, VsBands, AltBands, Alerts, MinMax,OwnshipState, IntruderState, ownship, scenario, relativeTrk]=varargin{:};
    otherwise
        error('1,2,9,11 inputs required, %d provided!',nargin)
        
end

if ~all(length(TrkBands) == [length(GsBands) length(VsBands) length(AltBands)])
    throw(MException('tools:drawDAAbandsDAIDALUS:bandDataException','Band data is not all the same length'));
end

if ~exist('relativeTrk','var')
    relativeTrk = false;
end

%%%%%%%%OPTIONS%%%%%%%%
tailLength = 50;

%Band colors in vector format
NONE = [0 0 0];     %black
FAR  = [0 0 1];     %blue
MID  = [1 0.5 0];   %orange
NEAR = [1 0 0];     %red
RECOVERY = [0 1 0]; %green

%Alerting Bands Options
bandWeight = 6;             %Weight of alert bands
bandResolution = 1;    %Track Bands minimum segment (degree)
bandsRadius = 0.8;          %TrkBands distance from ownship
GsResolution=1;             %Ground speed stepsize (knots)
AltResolution = 100;        %Altitude Stepsize (ft)
VsResolution = 1;           %Climb rate stepsize (fpm)

if length(TrkBands) > 5, writeVideo = true; Visible='off'; else, writeVideo = false; Visible='on'; end

if exist('OwnshipState','var') && exist('IntruderState','var')
    drawOwnship = true; 
    OwnshipTimes = [OwnshipState.time];
    IntruderTimes = [IntruderState.time];
    bandsTime = [TrkBands.time];
    
    ownIDX = false(1,length(OwnshipTimes));
    intruderIDX = false(1,length(IntruderTimes));
    
    for i = 1:length(OwnshipTimes)
        if ~any(OwnshipTimes(i) == bandsTime), ownIDX(i)=true; end
    end
    
    for i = 1:length(IntruderTimes)
        if ~any(IntruderTimes(i) == bandsTime), intruderIDX(i)=true; end
    end
    
    OwnshipState(ownIDX) = [];
    IntruderState(intruderIDX) = [];
    
    try
        [~, idx]=unique([OwnshipState.time]);
        OwnshipState=OwnshipState(idx);
        if ~all(ismember([TrkBands.time],[OwnshipState.time])) || ~all(ismember([IntruderState.time],[TrkBands.time]))
            warning('Warning: Ignoring state data');
            drawOwnship=false;
        end
    catch
        warning('Warning: Ignoring state data');
        drawOwnship=false;
    end
else
    drawOwnship = false;
end

if relativeTrk
    for i = 1:length(TrkBands)
        for j = 1:length(TrkBands(i).NONE)
            TrkBands(i).NONE{j} = TrkBands(i).NONE{j} - OwnshipState(i).track;
        end
        for j = 1:length(TrkBands(i).FAR)
            TrkBands(i).FAR{j} = TrkBands(i).FAR{j} - OwnshipState(i).track;
        end
        for j = 1:length(TrkBands(i).MID)
            TrkBands(i).MID{j} = TrkBands(i).MID{j} - OwnshipState(i).track;
        end
        for j = 1:length(TrkBands(i).NEAR)
            TrkBands(i).NEAR{j} = TrkBands(i).NEAR{j} - OwnshipState(i).track;
        end
        for j = 1:length(TrkBands(i).RECOVERY)
            TrkBands(i).RECOVERY{j} = TrkBands(i).RECOVERY{j} - OwnshipState(i).track;
        end
    end
end

fig = gobjects(1,length(TrkBands));
for i = 1:105
    fig(i)=figure('Visible','off');
end

for i = 1:length(TrkBands)
    [~,PolAx, GsAx, VsAx, AltAx]=drawDAIDAxes(Visible,fig(i));
    %Plot NONE bands-----------------------------------------------------------
    cla(PolAx)
    polarscatter(PolAx,0,0,200,'^k','MarkerFaceColor','k')
    for j = 1:length(TrkBands(i).NONE)
        ticks = TrkBands(i).NONE{j};
        
        h=polarplot(PolAx,...
            (ticks(1):bandResolution:ticks(2))*(pi/180),...
            repmat(bandsRadius,1,length(ticks(1):bandResolution:ticks(2))),...
            'LineWidth',bandWeight);
        
        h.Color = NONE;
        h.DisplayName = 'NONE';
        hold('on');
    end
    
    %Plot FAR bands------------------------------------------------------------
    for j = 1:length(TrkBands(i).FAR)
        ticks = TrkBands(i).FAR{j};
        
        h=polarplot(PolAx,...
            (ticks(1):bandResolution:ticks(2))*(pi/180),...
            repmat(bandsRadius,1,length(ticks(1):bandResolution:ticks(2))),...
            'LineWidth',bandWeight);
        
        h.Color = FAR;
        h.DisplayName = 'FAR';
        hold('on');
    end
    
    %Plot MID bands------------------------------------------------------------
    for j = 1:length(TrkBands(i).MID)
        ticks = TrkBands(i).MID{j};
        
        h=polarplot(PolAx,...
            (ticks(1):bandResolution:ticks(2))*(pi/180),...
            repmat(bandsRadius,1,length(ticks(1):bandResolution:ticks(2))),...
            'LineWidth',bandWeight);
        
        h.Color = MID;
        h.DisplayName = 'MID';
        hold('on');
    end
    
    %Plot NEAR bands-----------------------------------------------------------
    for j = 1:length(TrkBands(i).NEAR)
        ticks = TrkBands(i).NEAR{j};
        
        h=polarplot(PolAx,...
            (ticks(1):bandResolution:ticks(2))*(pi/180),...
            repmat(bandsRadius,1,length(ticks(1):bandResolution:ticks(2))),...
            'LineWidth',bandWeight);
        
        h.Color = NEAR;
        h.DisplayName = 'NEAR';
        hold('on');
    end
    
    %Plot RECOVERY bands-------------------------------------------------------
    for j = 1:length(TrkBands(i).RECOVERY)
        ticks = TrkBands(i).RECOVERY{j};
        
        h=polarplot(PolAx,...
            (ticks(1):bandResolution:ticks(2))*(pi/180),...
            repmat(bandsRadius,1,length(ticks(1):bandResolution:ticks(2))),...
            'LineWidth',bandWeight);
        
        h.Color = RECOVERY;
        h.DisplayName = 'RECOVERY';
        hold('on');
    end
    
    if drawOwnship
        if relativeTrk 
            polarscatter(PolAx,0,bandsRadius,50,'bo','filled','Linewidth',1); 
        else
            thisOwnshipState = OwnshipState([OwnshipState.time] == TrkBands(i).time);
            polarscatter(PolAx,thisOwnshipState.track*(pi/180),bandsRadius,50,'bo','filled','Linewidth',1);
        end
    end    
    title(PolAx,['DIADALUS DAA: ' scenario]);
    
    %%Plot Gs alerts-----------------------------------------------------------
    scale = MinMax.Gs{1}(1):GsResolution:MinMax.Gs{1}(2);
    cla(GsAx)
    
    for j = 1:length(GsBands(i).NONE)
        bounds = GsBands(i).NONE{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
        
        h=plot(GsAx,...
            scale(IDX),0.5*ones(1,sum(IDX)),...
            'LineWidth',bandWeight);
        
        h.Color = NONE;
        h.DisplayName = 'NONE';
        hold('on');
    end
    
    %%GsFar-------------------------
    for j = 1:length(GsBands(i).FAR)
        bounds = GsBands(i).FAR{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
        
        h=plot(GsAx,...
            scale(IDX),0.5*ones(1,sum(IDX)),...
            'LineWidth',bandWeight);
        
        h.Color = FAR;
        h.DisplayName = 'FAR';
        hold('on');
    end
    
    %%GsMID-------------------------
    for j = 1:length(GsBands(i).MID)
        bounds = GsBands(i).MID{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(GsAx,...
            scale(IDX),0.5*ones(1,sum(IDX)),...
            'LineWidth',bandWeight);
        
        h.Color = MID;
        h.DisplayName = 'MID';
        hold('on');
    end

    %%GsNear-------------------------
    for j = 1:length(GsBands(i).NEAR)
        bounds = GsBands(i).NEAR{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(GsAx,...
            scale(IDX),0.5*ones(1,sum(IDX)),...
            'LineWidth',bandWeight);
        
        h.Color = NEAR;
        h.DisplayName = 'NEAR';
        hold('on');
    end

    
    %%GsRecovery-------------------------
    for j = 1:length(GsBands(i).RECOVERY)
        bounds = GsBands(i).RECOVERY{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(GsAx,...
            scale(IDX),0.5*ones(1,sum(IDX)),...
            'LineWidth',bandWeight);
        
        h.Color = RECOVERY;
        h.DisplayName = 'RECOVERY';
        hold('on');
    end
    
    scatter(GsAx,norm([OwnshipState(i).vx OwnshipState(i).vy]),0.60,'vk','MarkerFaceColor','b')
    
    ylim(GsAx,[0 1]);
    xlim(GsAx,[MinMax.Gs{1}(1) MinMax.Gs{1}(2)]);
    
    
    %%Plot Alt alerts-----------------------------------------------------------
    scale = MinMax.Alt{1}(1):AltResolution:MinMax.Alt{1}(2);
    cla(AltAx)
    
    for j = 1:length(AltBands(i).NONE)
        bounds = AltBands(i).NONE{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
        
        h=plot(AltAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = NONE;
        h.DisplayName = 'NONE';
        hold('on');
    end
    
    %%AltFar-------------------------
    for j = 1:length(AltBands(i).FAR)
        bounds = AltBands(i).FAR{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(AltAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = FAR;
        h.DisplayName = 'FAR';
        hold('on');
    end
    
    %%AltFar-------------------------
    for j = 1:length(AltBands(i).MID)
        bounds = AltBands(i).MID{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(AltAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = MID;
        h.DisplayName = 'MID';
        hold('on');
    end
    
    %%AltNear-------------------------
    for j = 1:length(AltBands(i).NEAR)
        bounds = AltBands(i).NEAR{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(AltAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = NEAR;
        h.DisplayName = 'NEAR';
        hold('on');
    end
    
    %%AltRecovery-------------------------
    for j = 1:length(AltBands(i).RECOVERY)
        bounds = AltBands(i).RECOVERY{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(AltAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = RECOVERY;
        h.DisplayName = 'RECOVERY';
        hold('on');
    end
    scatter(AltAx,0.40,OwnshipState(i).alt,'>k','MarkerFaceColor','b')
    xlim(AltAx,[0 1]);
    ylim(AltAx,[MinMax.Alt{1}(1) MinMax.Alt{1}(2)]);
    
    %%Plot Vs alerts-----------------------------------------------------------
    scale = MinMax.Vs{1}(1):VsResolution:MinMax.Vs{1}(2);
    cla(VsAx)
    
    for j = 1:length(VsBands(i).NONE)
        bounds = VsBands(i).NONE{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
        
        h=plot(VsAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = NONE;
        h.DisplayName = 'NONE';
        hold('on');
    end
    
    %%VsNONE-------------------------
    for j = 1:length(VsBands(i).FAR)
        bounds = VsBands(i).FAR{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(VsAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = FAR;
        h.DisplayName = 'FAR';
        hold('on');
    end
    
    %%VsFar-------------------------
    for j = 1:length(VsBands(i).MID)
        bounds = VsBands(i).MID{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(VsAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = MID;
        h.DisplayName = 'MID';
        hold('on');
    end    
    
    %%VsNear-------------------------
    for j = 1:length(VsBands(i).NEAR)
        bounds = VsBands(i).NEAR{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(VsAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = NEAR;
        h.DisplayName = 'NEAR';
        hold('on');
    end
    
    %%VsRecovery-------------------------
    for j = 1:length(VsBands(i).RECOVERY)
        bounds = VsBands(i).RECOVERY{j};
        IDX = scale>=bounds(1) & scale<=bounds(2);
                
        h=plot(VsAx,...
            0.5*ones(1,sum(IDX)),scale(IDX),...
            'LineWidth',bandWeight);
        
        h.Color = RECOVERY;
        h.DisplayName = 'RECOVERY';
        hold('on');
    end
    scatter(VsAx,0.40,OwnshipState(i).vz,'>k','MarkerFaceColor','b')
    
    xlim(VsAx,[0 1]);
    ylim(VsAx,[MinMax.Vs{1}(1) MinMax.Vs{1}(2)]);
        
    thisAlert = Alerts([Alerts.Time]==TrkBands(i).time & ([Alerts.AlertLevel] > 0));
    text(PolAx,pi,0.1,ownship,'HorizontalAlignment','center')
    if ~isempty(thisAlert)
        for j = 1:length(thisAlert)
        text(PolAx,pi,0.125+0.05*j,sprintf('%s %d',thisAlert(j).Traffic,thisAlert(j).AlertLevel),'HorizontalAlignment','center')
        end
    end
    text(PolAx,180*(pi/180),1.145,['Time: ' num2str(TrkBands(i).time) ' UTC'],'HorizontalAlignment','center')
    
%     StartStop = uicontrol('Position',[350 410 40 30],'String','Start');
%     Time = uicontrol('Position',[400 415 100 20],'String','Time','Style','edit');
    if drawOwnship 
        pos = fig(i).Position;
        newPos = [pos(1:3) pos(4)*1.85];
        fig(i).Position = newPos;
        
        XYax = axes(fig(i),'Units','pixels','Position',[50 pos(4)+80 pos(3)-80 newPos(4)-pos(4)-100]);
        set(fig(i).Children,'Units','normalized')
        
        thisOwnshipState = OwnshipState([OwnshipState.time] == TrkBands(i).time);
        thisIntruderState = IntruderState([IntruderState.time] == thisOwnshipState.time);
        
        oldOwnshipState = OwnshipState([OwnshipState.time]<=thisOwnshipState.time & [OwnshipState.time]>(thisOwnshipState.time-tailLength));
        oldIntruderState = IntruderState([IntruderState.time]<=thisOwnshipState.time & [IntruderState.time]>(thisOwnshipState.time-tailLength));
        
        drawKinematics(XYax,thisOwnshipState,thisIntruderState,oldOwnshipState,oldIntruderState);
    end
end

if writeVideo
    frames(length(fig)) = struct('cdata',[],'colormap',[]);
    for i = 1:length(fig)
        frames(i) = getframe(fig(i));
        close(fig(i));
    end
    figures=frames;    
end

end


function [fig,PolAx, GsAx, VsAx, AltAx]=drawDAIDAxes(Visible,fig)
    
    if ~exist('fig','var')
        fig = figure('Visible',Visible); %Create a new figure if none is passed
    else
        set(0, 'currentfigure', fig);
    end
    
    GsAx=subplot(2,3,4); %Create each subplot
    AltAx=subplot(2,3,[2 5]);
    VsAx=subplot(2,3,[3 6]);
    PolAx=matlab.graphics.internal.prepareCoordinateSystem('polar',subplot(2,3,1));
  
    
    %Formatting
    PolAx.RTick=[];
    PolAx.ThetaZeroLocation='top';
    PolAx.ThetaDir='clockwise';
    
    GsAx.Position =[0.10 0.11 0.51 0.075];
    AltAx.Position = [0.69 0.11 0.075 0.8];
    VsAx.Position = [0.84 0.11 0.075 0.8];
    VsAx.YAxisLocation = 'right';
    PolAx.Position = [0.035 0.25 0.6 0.7];
    
    GsAx.Units = 'pixels';
    AltAx.Units = 'pixels';
    VsAx.Units = 'pixels';
    PolAx.Units = 'pixels';
    
    xlabel(AltAx,'Altitude (ft)');
    xlabel(VsAx,'Climb Rate (fpm)');
    xlabel(GsAx,'Speed (knots)')
    
    rlim(PolAx,[0 1])
    
    hold(GsAx,'on')
    hold(AltAx,'on')
    hold(VsAx,'on')
    hold(PolAx,'on')
end

