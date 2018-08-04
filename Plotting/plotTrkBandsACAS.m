function [ax]=plotTrkBandsACAS(messages,trafficStateOS,relTrack,plotAlerts,ax)
%   Draws ACAS RWC and CA bands, alerts, and target heading vs time.
%
%   Name: drawACASTrkBands.m [Function]   
%
%   INPUT: 
%       messages [struct]:  ACAS LVC messages or unfiltered LVC messages in LVC
%                           messages structure.
%
%       trafficStateOS [struct](opt.): Ownship trafficState structure
%                                      required to plot target headings or if relTrack==false
%                                            
%       relTrack    [logical](opt.): Plot relative to ownship heading?
%
%       ax          [Axes](opt.): Axis to put plots
%
%   OUTPUT:
%       ax [Axes]: Axes handle of generated plots
%
%   NOTES:
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% October 4, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Input handling
if ~exist('relTrack','var')
    relTrack = true;
end

if ~relTrack && ~exist('trafficStateOS','var')
    error('Ownship trafficState required for absolute track!');
end

if ~exist('ax','var') || ~isgraphics(ax)
    ax = gca;
end

if ~exist('plotAlerts','var')
    plotAlerts = false;
end
hold(ax,'on');

%Colors%
RWC = [1 0.5 0];
CA = [1 0 0];

[RWCH, CAH, TARGETH, OWNSHIPH] = deal([]);

%Ensure we are working with ACAS messages only
ACAS = messages(strcmp({messages.Name},'AcasXu'));
ACASData = [ACAS.Data];

%Ensure we are working in ToA
for i = 1:length(ACAS)
    ACAS(i).time = ACASData(i).m_timeOfApplicability;
end

if exist('trafficStateOS','var') %Ensure ACAS.time == trafficStateOS.time
    trafficTimes = [trafficStateOS.time];
    [~,IDXACAS] = ismember(trafficTimes,[ACAS.time]);
    ACAS = ACAS(IDXACAS);
end

time = [ACAS.time];
ACASData = [ACAS.Data];

%Preallocation
theta = [ -80:10:80 ];
RWCBands=[];
RWCEdges=[];
CABands=[];
CAEdges=[];
RWCTimes=[];
CATimes=[];
AlertText = cell(1,length(ACAS));

for i = 1:length(ACAS)
    %Get alerting string
    if ACASData(i).m_enumCombinedControl == 0
        AlertText(i) = {''};
    else
        AlertText(i) = {num2str(ACASData(i).m_enumCombinedControl)};
    end
    
    %Calculate offset
    if ~relTrack
        offset = trafficStateOS(i).track;
    else
        offset = 0;
    end
    
    %Gather bands info with offset for later plotting
    RWCBands = [RWCBands theta(ACASData(i).m_preventiveRWCBands(2:18))+offset];
    RWCEdges = [RWCEdges;ACASData(i).m_preventiveRWCBands([1 19])];
    CABands =  [CABands  theta(ACASData(i).m_preventiveCABands(2:18))+offset];
    RWCTimes = [RWCTimes repmat(time(i),1,length(theta(ACASData(i).m_preventiveRWCBands(2:18))))];
    CAEdges =  [CAEdges;ACASData(i).m_preventiveCABands([1 19])];
    CATimes =  [CATimes  repmat(time(i),1,length(theta(ACASData(i).m_preventiveCABands(2:18))))];
end

%Plot bands
RWCH = scatter(ax,RWCTimes,RWCBands,'o','MarkerFaceColor',RWC,'MarkerEdgeColor',RWC,'SizeData',10);
CAH = scatter(ax,CATimes,CABands,'o','MarkerFaceColor',CA,'MarkerEdgeColor',CA,'SizeData',10);
for i = 1:length(time)
    if RWCEdges(i,1)
        line(ax,[1 1]*time(i) ,[-85 -180]+offset,'Color',RWC,'LineWidth',3)
    end
    if RWCEdges(i,2)
        line(ax,[1 1]*time(i) ,[85 180]+offset,'Color',RWC,'LineWidth',3)
    end
end

for i = 1:length(time)
    if CAEdges(i,1)
        line(ax,[1 1]*time(i) ,[-85 -180]+offset,'Color',CA,'LineWidth',3)
    end
    if CAEdges(i,2)
        line(ax,[1 1]*time(i) ,[85 180]+offset,'Color',CA,'LineWidth',3)
    end
end

%Plot Alerts
if plotAlerts
    Alerts = [ACASData.m_enumCombinedControl];
    IDX = Alerts == 0;
    Alerts(IDX) = [];
    AlertTimes = time(~IDX);

    if ~isempty(AlertTimes)
        ylims = ylim;
        text(AlertTimes,repmat(ylims(2),1,length(AlertTimes)),strip(split(num2str(Alerts))),'HorizontalAlignment','center')
        text(AlertTimes(1),ylims(2),'Alerts:    ','HorizontalAlignment','right')
        ylim([ylims(1) ylims(2)+5])
    end
end

%Add in target heading
targetHeading = [ACASData.m_advisoryHeading];
IDX = targetHeading == 0;
targetHeading(IDX) = [];
targetHeadingTimes = time(~IDX);

if relTrack && exist('trafficStateOS','var')
    targetHeading = wrapTo180(targetHeading-[trafficStateOS(ismember([trafficStateOS.time],time(~IDX))).track]);
end

if ~isempty(targetHeading)
    TARGETH=scatter(ax,targetHeadingTimes,targetHeading,'dg','MarkerFaceColor',[ 0 1 0 ]);
end

%Sort out title string
if relTrack
    clause = ', Relative to Ownship';
    xlims = xlim(ax);
    OWNSHIPH = plot(ax,[-1*min(xlims)*10 max(xlims)*10],[0 0],':k');
    xlim(ax,xlims);
    ax.YDir = 'reverse';
else
    OWNSHIPH = plot(time,[trafficStateOS.track],':k','LineWidth',2);
    clause = '';
end

%Annontate
title(['ACAS-Xu RWC and CA Bands' clause])
legendStrings = {'RWC','CA','Target Heading','Ownship Heading'};
legend([RWCH CAH TARGETH OWNSHIPH],legendStrings(~cellfun(@isempty,{RWCH CAH TARGETH OWNSHIPH})),'AutoUpdate','off')
xlabel('Time (s)')
ylabel('Heading')
ax.XAxis.Exponent = 0;
ax.XAxis.TickLabelFormat = '%.1f';