function [ ax ] = plotAlertTimesACAS( ACAS, offset, ax )

if ~exist('offset','var')
    offset = 0;
end

ACAS = ACAS(strcmp({ACAS.Name},'AcasXu'));
Time = [ACAS.time];
ACAS = [ACAS.Data];

level0=[];
level1=[];
level2=[];
level3=[];

ZERO  = [0 0 0];            %black
ONE  = [0 0.75 1];          %light blue
TWO = [1 0.5 0];            %orange
THREE = [1 0 0];            %red

for i = 1:length(ACAS)
    
    if ACAS(i).m_enumCombinedControl == 0
            level0 = [level0 Time(i)];
            
    elseif ACAS(i).m_enumCombinedControl == 1
            level1 = [level1 Time(i)];
            
    elseif any(ACAS(i).m_preventiveCABands) || ismember(ACAS(i).m_enumCombinedControl,[4 5])
            level3 = [level3 Time(i)];
     
    elseif any(ACAS(i).m_preventiveRWCBands) || ismember(ACAS(i).m_enumCombinedControl,[6 7])
            level2 = [level2 Time(i)];
    end
    
end


ax0 = scatter(level0,ones(1,length(level0))*offset,'MarkerFaceColor',ZERO,'MarkerEdgeColor',ZERO,'Marker','s','SizeData',50);
hold on;
ax1 = scatter(level1,ones(1,length(level1))*offset,'MarkerFaceColor',ONE,'MarkerEdgeColor',ONE,'Marker','s','SizeData',50);
ax2 = scatter(level2,ones(1,length(level2))*offset,'MarkerFaceColor',TWO,'MarkerEdgeColor',TWO,'Marker','s','SizeData',50);
ax3 = scatter(level3,ones(1,length(level3))*offset,'MarkerFaceColor',THREE,'MarkerEdgeColor',THREE,'Marker','s','SizeData',50);
if ~exist('ax','var')
    title('Alert Level vs. Time')
    legend([ax0 ax1 ax2 ax3],{'No Advisory' 'Resolved' 'RWC' 'CA'})
end
