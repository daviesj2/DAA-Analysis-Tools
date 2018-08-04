function [ ax ] = plotAlertTimes( Alerts, offset, ax )

if ~exist('offset','var')
    offset = 0;
end

level0=[];
level1=[];
level2=[];
level3=[];
level4=[];

ZERO  = [0 0 0];     %blue
ONE  = [0.25 0.25 0.75];   %orange
TWO = [1 0.5 0];     %orange
THREE = [1 0 0]; %red
FOUR = [0 1 0]; %green

for i = 1:length(Alerts)
    
    switch Alerts(i).AlertLevel
        case 0
            %level0(i,1) = Alerts(i).AlertLevel;
            level0 = [level0 Alerts(i).Time];
        case 1
            %level1(i,1) = Alerts(i).AlertLevel;
            level1 = [level1 Alerts(i).Time];
        case 2
            %level2(i,1) = Alerts(i).AlertLevel;
            level2 = [level2 Alerts(i).Time];
        case 3
            %level3(i,1) = Alerts(i).AlertLevel;
            level3 = [level3 Alerts(i).Time];
        case 4
            %level3(i,1) = Alerts(i).AlertLevel;
            level4 = [level4 Alerts(i).Time];
    end 
end
ax0 = scatter(level0,ones(1,length(level0))*offset,'MarkerFaceColor',ZERO,'MarkerEdgeColor',ZERO,'Marker','s','SizeData',50);
hold on;
ax1 = scatter(level1,ones(1,length(level1))*offset,'MarkerFaceColor',ONE,'MarkerEdgeColor',ONE,'Marker','s','SizeData',50);
ax2 = scatter(level2,ones(1,length(level2))*offset,'MarkerFaceColor',TWO,'MarkerEdgeColor',TWO,'Marker','s','SizeData',50);
ax3 = scatter(level3,ones(1,length(level3))*offset,'MarkerFaceColor',THREE,'MarkerEdgeColor',THREE,'Marker','s','SizeData',50);
ax4 = scatter(level4,ones(1,length(level4))*offset,'MarkerFaceColor',FOUR,'MarkerEdgeColor',FOUR,'Marker','s','SizeData',50);

if ~exist('ax','var')
    title('Alert Level vs. Time')
    legend([ax0 ax1 ax2 ax3 ax4],{'0' '1' '2' '3' '4'})
end