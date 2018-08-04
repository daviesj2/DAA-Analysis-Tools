function plotDAAvsACAS (messages,scenario,config,outPath,startTime)
%Plot DAID and ACAS track bands side-by-side

trafficStateOS = getTrafficStateDAA(scenario,config);
Trkbands = getDAIDBands(scenario,config);

figure
ax1 = subplot(2,1,1);
ax2 = subplot(2,1,2);

scenarioName = regexp(scenario,'(\w+|\d+)\.(\w+|\d+)+$','match');
scenarioName = regexp(scenarioName{1},'^(\w)+|(\d)+','match');
scenarioName = scenarioName{1};

ax1=plotTrkBands(Trkbands,trafficStateOS,[],true,scenarioName,ax1);
ax2=plotTrkBandsACAS(messages,trafficStateOS,true,false,ax2);

ax1.Title.Interpreter = 'none';

linkaxes([ax1 ax2],'xy')
ylim([-180 180])

Ticks = ax1.XAxis.TickLabels;
for i = 1:length(Ticks)
Ticks(i) = {num2str(str2num(Ticks{i})-startTime(1))};
end
ax1.XAxis.TickLabels=Ticks;

Ticks = ax2.XAxis.TickLabels;
for i = 1:length(Ticks)
Ticks(i) = {num2str(str2num(Ticks{i})-startTime(1))};
end
ax2.XAxis.TickLabels=Ticks;
kids = get(ax2,'Children');
delete(kids(2));

legend(ax1,'off')
legend(ax2,'off')

saveas(gcf,fullfile(outPath,[scenarioName '_DAIDvACAS.fig']))

close(gcf)