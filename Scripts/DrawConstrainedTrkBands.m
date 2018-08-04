cd ~/Documents/MATLAB/Data/Scenarios/
load scenario.mat

config = '/Users/jtdavies/Documents/MATLAB/WellClear-master/DAIDALUS/Configurations/WC_SC_228_nom_b.txt';
messages = {messages_DA_62 messages_RWC_03 messages_RWC_06 messages_RWC_09 messages_RWC_12 messages_RWC_15 messages_RWC_18};

for i = 1:length(scenarioNames)
    [trafficStateCAT] = genScenarioLVC(messages{i});
    for j = 1:length(trafficStateCAT)
        trafficStateCAT(j).vz = 0;
    end
    genScenarioTrafficState(trafficStateCAT,'NASA870',0,inf,'.',[scenarioNames{i} '_vz.daa'])
end

for i = 1:length(scenarioNames)
    [TrkBands, ~, ~, ~, ~, ~, ~] = getDAIDBands(['./' scenarioNames{i} '_vz.daa'],config);
    [Alerts,~] = getDAIDAlerts(['./' scenarioNames{i} '_vz.daa'],config);
    [OSstate,~] = getTrafficStateDAA(['./' scenarioNames{i} '_vz.daa'],config);
    
    figure;
    ax = plotTrkBands(TrkBands,OSstate,Alerts,true);
    saveas(gcf,[scenarioNames{i}])
    saveas(gcf,[scenarioNames{i}],'png')
    close(gcf)
end