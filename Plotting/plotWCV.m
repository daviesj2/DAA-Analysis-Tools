function [ ax ] = plotWCV( Alerts, Traffic, Unit)
%   Plot relevent metrics for detection and analysis of Well-Clear violations
%   
%   Name: plotWCV.m [Function]   
%
%   INPUT: 
%       Alerts      [struct]: DAIDALUS Alerts structure
%       Traffic     [char]: Callsign of aircraft of interest
%       Unit        [struct](opt.): Unit structure compliment to Alerts
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

PREV  = [0 0 1];     %blue
CORR  = [1 0.5 0];   %orange
WARN = [1 0 0];     %red

PrevWCV = 60.000000;
CorWCV = 60.000000;
WarnWCV = 30.000000;

PrevHMD = 1.000000;
CorHMD = 1.000000;
WarnHMD = 1.000000;

PrevVMD = 750;
CorVMD = 450;
WarnVMD = 450;

trafficAlerts = cell(1,length(Traffic));
for i = 1:length(Traffic)
    trafficAlerts{i} = Alerts(strcmp({Alerts.Traffic},Traffic{i}));
end

ax1 = subplot(2,2,1,'align');
ax2 = subplot(2,2,2,'align');
ax3 = subplot(2,2,3,'align');
ax4 = subplot(2,2,4,'align');

hold(ax1, 'on')
hold(ax2, 'on')
hold(ax3, 'on')
hold(ax4, 'on')

grid(ax1, 'on')
grid(ax2, 'on')
grid(ax3, 'on')
grid(ax4, 'on')

for i = 1:length(trafficAlerts)
    plot(ax1,[trafficAlerts{i}.Time],[trafficAlerts{i}.AlertLevel])
    plot(ax2,[trafficAlerts{i}.Time],[trafficAlerts{i}.WCVTime])
    plot(ax3,[trafficAlerts{i}.Time],[trafficAlerts{i}.ProjectedHMD])
    plot(ax4,[trafficAlerts{i}.Time],[trafficAlerts{i}.ProjectedVMD])
end

xlim1 = xlim(ax1);

plot(ax2,xlim1,[1 1] * PrevWCV,':','Color',PREV)
plot(ax2,xlim1,[1 1] * CorWCV,':','Color',CORR)
plot(ax2,xlim1,[1 1] * WarnWCV,':','Color',WARN)

plot(ax3,xlim1,[1 1] * PrevHMD,':','Color',PREV)
plot(ax3,xlim1,[1 1] * CorHMD,':','Color',CORR)
plot(ax3,xlim1,[1 1] * WarnHMD,':','Color',WARN)

plot(ax4,xlim1,[1 1] * PrevVMD,':','Color',PREV)
plot(ax4,xlim1,[1 1] * CorVMD,':','Color',CORR)
plot(ax4,xlim1,[1 1] * WarnVMD,':','Color',WARN)

ax1.XAxis.Exponent = 0;
ax1.XAxis.TickLabelFormat = '%.1f';
ax2.XAxis.Exponent = 0;
ax2.XAxis.TickLabelFormat = '%.1f';
ax3.XAxis.Exponent = 0;
ax3.XAxis.TickLabelFormat = '%.1f';
ax4.XAxis.Exponent = 0;
ax4.XAxis.TickLabelFormat = '%.1f';

AlertLevelString = Traffic;
WCVTString = Traffic;
HMDString = Traffic;
VMDString = Traffic;

if exist('Unit','var')
    AlertLevelString = [AlertLevelString];
%     WCVTString = [WCVTString ' (' Unit.WCVTime ')' ];
%     HMDString = [HMDString ' (' Unit.ProjectedHMD ')' ];
%     VMDString = [VMDString ' (' Unit.ProjectedVMD ')' ];
    
    ylabel(ax1,'Alert Level')
    ylabel(ax2,['Time To WCV ' '(' Unit.WCVTime ')'])
    ylabel(ax3,['HMD ' '(' Unit.ProjectedHMD ')'])
    ylabel(ax4,['VMD ' '(' Unit.ProjectedVMD ')'])
else
    ylabel(ax1,'Alert Level')
    ylabel(ax2,'Time To WCV ')
    ylabel(ax3,'HMD')
    ylabel(ax4,'VMD')
end

xlabel(ax1,'Time (s)')
xlabel(ax2,'Time (s)')
xlabel(ax3,'Time (s)')
xlabel(ax4,'Time (s)')

legend(ax1, AlertLevelString)
legend(ax2, AlertLevelString)
legend(ax3, AlertLevelString)
legend(ax4, AlertLevelString)

title(ax1,'Alert Level')
title(ax2,'Time To Violation')
title(ax3,'Projected HMD')
title(ax4,'Projected VMD')

linkaxes([ax1 ax2 ax3 ax4],'x')
xlim(xlim1);
ax = [ax1 ax2 ax3 ax4];
end

