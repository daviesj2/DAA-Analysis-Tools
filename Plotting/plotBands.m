function [ax]=plotBands(Bands,dimension,MinMax,trafficStateOS,relative,Alerts,scenario,ax)
%   Draws DAIDALUS track bands vs. Time
%
%   Name: drawDAIDTrkBands.m [Function]   
%
%   INPUT: 
%       Bands        [struct]: Bands structure generated from
%                              getDAAbandsDAIDALUS.m or DrawMultibands.m
%
%       trafficStateOS  [struct](opt.): Traffic state structure for ownship
%
%       relativeTrk     [logical](opt.): Draw bands relative to ownship
%                                            heading (requires trafficStateOS)
%
%       ax              [figure](opt.): Axes to draw plot.
%
%
%   OUTPUT:
%       ax: Axes containing plots
%
%   NOTES:
%       Assumes that trafficStateOS.time == TrkBands.time
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% DATE [Month Day, Year]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('ax','var') || ~isgraphics(ax)
    ax = gca;
end

if ~exist('relative','var')
    relative = false;
end

if ~exist('scenario','var')
    scenario='';
else
    scenario = [scenario ': '];
end

hold(ax,'on');

if exist('trafficStateOS','var') 
    drawOwnship = true;
else
    trafficStateOS=[];
    drawOwnship = false;
end

switch lower(dimension)
    case {'track' 'trk' 'heading' 'hdg'}
        
        dimension = 'Track';
        ylab = 'Track (°)';
        
    case {'alt' 'altitude' 'height'}
        
        dimension = 'Alt';
        
        ylab = 'Altitude';
        if exist('MinMax','var')
            unit = MinMax.(dimension);
            ylab = [ylab ' (' unit{2} ')'];
        end
        
    case {'gs' 'ground_speed' 'groundspeed' 'speed'}
        
        dimension = 'Gs';
       
        ylab = 'Ground Speed';
        if exist('MinMax','var')
            unit = MinMax.(dimension);
            ylab = [ylab ' (' unit{2} ')'];
        end
        
    case {'vs' 'vertical_rate' 'verticalrate' 'climb_rate' 'climbrate' 'climb'}
        
        dimension = 'Vs';
        
        ylab = 'Climb Rate';
        if exist('MinMax','var')
            unit = MinMax.(dimension);
            ylab = [ylab ' (' unit{2} ')'];
        end
        
    otherwise
        error('Unkown dimension ''%s''! Try ''trk'',''alt'',''gs'', or ''vs''',dimension)
end
        
if strcmp(dimension,'Track')
        [FARAX, MIDAX, NEARAX, RECAX ]=plotTrkBands(Bands,trafficStateOS,relative,ax);
        if relative
            ylims = [-180 180];
        else
            ylims = [0 360];
        end
else
        if exist('MinMax','var') && ~relative
            ylims = MinMax.(dimension);
            ylims = ylims{1};
            
        else
            ylims = 'auto';
        end
        
        [FARAX, MIDAX, NEARAX, RECAX ]=plotDAABands(Bands,dimension,trafficStateOS,relative,ax);
end

ylim(ylims)
 
OWNAX = line([],[]);

%Draw a scatter plot of ownship
if drawOwnship && ~relative
    OStime = [trafficStateOS(ismember([trafficStateOS.time],[Bands.time])).time];
    OSState = [trafficStateOS(ismember([trafficStateOS.time],[Bands.time])).(lower(dimension))];
    OWNAX = scatter(ax,OStime,OSState,'.k');
end

%Change title and limits if relative to ownship
if relative
    if strcmp(dimension,'Track'), set(ax,'YDir','reverse'); end
    clause = ', Relative to Ownship';
    xlims = xlim(ax);
    OWNAX = plot(ax,[-1*min(xlims)*10 max(xlims)*10],[0 0],':k','LineWidth',2);
    xlim(ax,xlims);
else
    clause = '';
end

%Label Axes and make title
ylabel(ax,ylab)
xlabel(ax,'Time (s)')
title(ax,[scenario 'DAIDALUS ' dimension ' Bands' clause])
ax.XAxis.Exponent = 0;
ax.XAxis.TickLabelFormat = '%.1f';

%Plot TWCV if alerting structure is provided

TWCV={}; %Cell to hold line handles
TWCVStrings = {}; %Cell for legend strings

if exist('Alerts','var') && ~isempty(Alerts)
    ax = subplot(2,1,1,ax);
    ax2 = subplot(2,1,2);
    pos1 = ax.Position;
    pos2 = ax2.Position;
    
    ax.Position = [pos1(1) 0.3 pos1(3) 0.6];
    ax2.Position = [pos2(1:3) 0.173333333333333];
    
    
    xlims = xlim(ax);
    intruders = unique({Alerts([Alerts.AlertLevel] ~= 0).Traffic});
    
    for i = 1:length(intruders)
        yyaxis(ax,'right');
        ax.YColor = [0 0.447 0.741];
        intruderAlerts = Alerts(strcmp({Alerts.Traffic},intruders(i)));
        TWCV = [TWCV {plot(ax,[intruderAlerts.Time], [intruderAlerts.WCVTime],'Color',[0 0.447 0.741])}];
        TWCVStrings = [TWCVStrings {[intruders{i} ' Time to WCV']}];
        ylim auto;

        TWCV = [TWCV {plot(ax2,[intruderAlerts.Time], [intruderAlerts.AlertLevel],'d ','Color',[0 0.447 0.741])}];
        TWCVStrings = [TWCVStrings {[intruders{i} ' Alert Level']}];
    end
    
    %Clear duplicate information
    ax.XLabel=[];
    ax.XAxis.TickLabels=[];
    
    ax2.YTick = [0 1 2 3];
    grid(ax2,'on')
    ylim(ax2,[-1 4])
    
    yyaxis(ax,'right')
    ylabel(ax,'Time to WCV (s)')
    linkaxes([ax ax2],'x')
    xlim(ax,xlims)
    ax.YGrid = 'on';
    
    ylabel(ax2,'Alert Level')
    xlabel(ax2,'Time (s)')
    
    ax2.XAxis.Exponent = 0;
    ax2.XAxis.TickLabelFormat = '%.1f';
end
   
%Sort out the legend
handles = [{FARAX MIDAX NEARAX RECAX OWNAX} TWCV];
strings = [{'FAR' 'MID' 'NEAR' 'RECOVERY' ['Ownship ' dimension]} TWCVStrings];
strings = strings(~cellfun(@isempty,handles));
handles = handles(~cellfun(@isempty,handles));

legend(ax,[handles{:}],strings,'Location','best')

function[FARAX, MIDAX, NEARAX, RECAX ]=plotTrkBands(TrkBands,trafficStateOS,relative,ax)

%Get some dummy line handles
[FARAX, MIDAX, NEARAX, RECAX] = deal(line([],[]));

FAR  = [0 0 1];     %blue
MID  = [1 0.5 0];   %orange
NEAR = [1 0 0];     %red
RECOVERY = [0 1 0]; %green


%Plot Bands
if relative
    for i = 1:length(TrkBands)
        
        offset = trafficStateOS([trafficStateOS.time] == TrkBands(i).time).track; %Find current heading
        %Calculate bands in two parts to allow for wrapping to 180
        for k = 1:length(TrkBands(i).FAR)
            
            bands = wrapTo180(TrkBands(i).FAR{k}-offset);
            
            %   Requires wrapping  || Is a fully saturated band
            if bands(2) < bands(1) || (TrkBands(i).FAR{k}(2) > TrkBands(i).FAR{k}(1) && bands(2)==bands(1)) 
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[bands(1) 180],FAR,'LineWidth',3)
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[-180 bands(2)],FAR,'LineWidth',3)
            else
                NEARAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], bands(1:2), 'Color',FAR,'LineWidth',3);
            end
            
        end
        for k = 1:length(TrkBands(i).MID)
            
            bands = wrapTo180(TrkBands(i).MID{k}-offset);
            if bands(2) < bands(1) || (TrkBands(i).MID{k}(2) > TrkBands(i).MID{k}(1) && bands(2)==bands(1))
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[bands(1) 180], 'Color',MID,'LineWidth',3)
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[-180 bands(2)], 'Color',MID,'LineWidth',3)
            else
            MIDAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], bands(1:2), 'Color',MID,'LineWidth',3);
            end
            
        end
        for k = 1:length(TrkBands(i).NEAR)
            
            bands = wrapTo180(TrkBands(i).NEAR{k}-offset);
            if bands(2) < bands(1) || (TrkBands(i).NEAR{k}(2) > TrkBands(i).NEAR{k}(1) && bands(2)==bands(1))
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[bands(1) 180], 'Color',NEAR,'LineWidth',3)
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[-180 bands(2)], 'Color',NEAR,'LineWidth',3)
            else
                NEARAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], bands(1:2), 'Color',NEAR,'LineWidth',3);
            end
            
        end
        for k = 1:length(TrkBands(i).RECOVERY)
 
            bands = wrapTo180(TrkBands(i).RECOVERY{k}-offset);
            if bands(2) < bands(1) || (TrkBands(i).RECOVERY{k}(2) > TrkBands(i).RECOVERY{k}(1) && bands(2)==bands(1))
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[bands(1) 180], 'Color',RECOVERY,'LineWidth',3)
                plot(ax,[TrkBands(i).time  TrkBands(i).time],[-180 bands(2)], 'Color',RECOVERY,'LineWidth',3)
            else
                RECAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], bands(1:2), 'Color',RECOVERY,'LineWidth',3);
            end
            
        end
    end
else
    for i = 1:length(TrkBands)
        for k = 1:length(TrkBands(i).FAR)
            FARAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], TrkBands(i).FAR{k}, 'Color',FAR,'LineWidth',3);
        end
        for k = 1:length(TrkBands(i).MID)
            MIDAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], TrkBands(i).MID{k}, 'Color',MID,'LineWidth',3);
        end
        for k = 1:length(TrkBands(i).NEAR)
            NEARAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], TrkBands(i).NEAR{k}, 'Color',NEAR,'LineWidth',3);
        end
        for k = 1:length(TrkBands(i).RECOVERY)
            RECAX = plot(ax,[TrkBands(i).time  TrkBands(i).time], TrkBands(i).RECOVERY{k}, 'Color',RECOVERY,'LineWidth',3);
        end
        
    end
end
function [FARAX, MIDAX, NEARAX, RECAX ]=plotDAABands(Bands,dimension,trafficStateOS,relative,ax)


%Get some dummy line handles
[FARAX, MIDAX, NEARAX, RECAX] = deal(line([],[]));

FAR  = [0 0 1];     %blue
MID  = [1 0.5 0];   %orange
NEAR = [1 0 0];     %red
RECOVERY = [0 1 0]; %green


if relative
    for i = 1:length(Bands)
        
        offset = trafficStateOS([trafficStateOS.time] == Bands(i).time).(lower(dimension)); %Find current state
        
        for k = 1:length(Bands(i).FAR)
            FARAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).FAR{k}-offset, 'Color',FAR,'LineWidth',3);
        end
        for k = 1:length(Bands(i).MID)
            MIDAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).MID{k}-offset, 'Color',MID,'LineWidth',3);
        end
        for k = 1:length(Bands(i).NEAR)
            NEARAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).NEAR{k}-offset, 'Color',NEAR,'LineWidth',3);
        end
        for k = 1:length(Bands(i).RECOVERY)
            RECAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).RECOVERY{k}-offset, 'Color',RECOVERY,'LineWidth',3);
            
        end
    end
else
    for i = 1:length(Bands)
            for k = 1:length(Bands(i).FAR)
                FARAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).FAR{k}, 'Color',FAR,'LineWidth',3);
            end
            for k = 1:length(Bands(i).MID)
                MIDAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).MID{k}, 'Color',MID,'LineWidth',3);
            end
            for k = 1:length(Bands(i).NEAR)
                NEARAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).NEAR{k}, 'Color',NEAR,'LineWidth',3);
            end
            for k = 1:length(Bands(i).RECOVERY)
                RECAX = plot(ax,[Bands(i).time  Bands(i).time], Bands(i).RECOVERY{k}, 'Color',RECOVERY,'LineWidth',3);
            end
    end
end