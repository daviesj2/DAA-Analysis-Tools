myPath = pwd;

buffer = 30; %Seconds preceding and following scenario to include

load /Users/jtdavies/Documents/MATLAB/Data/Scenarios/scenarioTimes.mat
cd /Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-18-2017/GatewayLogger

scenarioNames = {'DA_62' 'RWC_03' 'RWC_06' 'RWC_09' 'RWC_12' 'RWC_15' 'RWC_18'};

messages_RWC_03 = getLVC('./MPI_gateway4__LOGGER_07182017_083545AM.csv');
messages_RWC_06 = getLVC('./MPI_gateway4__LOGGER_07182017_062437AM.csv');
messages_RWC_09 = getLVC('./MPI_gateway4__LOGGER_07182017_074112AM.csv');

messages_RWC_12 = getLVC('./MPI_gateway4__LOGGER_07182017_090027AM.csv');
messages_RWC_15 =[getLVC('./MPI_gateway4__LOGGER_07182017_071524AM.csv') getLVC('./MPI_gateway4__LOGGER_07182017_065928AM.csv')];
messages_RWC_18 = getLVC('./MPI_gateway4__LOGGER_07182017_080709AM.csv');

messages_DA_62 = getLVC('/Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-27-2017/GatewayLogger/MPI_gateway4__LOGGER_07272017_085229AM.csv');


messages_RWC_03 = messages_RWC_03([messages_RWC_03.time] >= RWC_03(1)-buffer & [messages_RWC_03.time] <= RWC_03(2)+buffer);
messages_RWC_06 = messages_RWC_06([messages_RWC_06.time] >= RWC_06(1)-buffer & [messages_RWC_06.time] <= RWC_06(2)+buffer);
messages_RWC_09 = messages_RWC_09([messages_RWC_09.time] >= RWC_09(1)-buffer & [messages_RWC_09.time] <= RWC_09(2)+buffer);

messages_RWC_12 = messages_RWC_12([messages_RWC_12.time] >= RWC_12(1)-buffer & [messages_RWC_12.time] <= RWC_12(2)+buffer);
messages_RWC_15 = messages_RWC_15([messages_RWC_15.time] >= RWC_15(1)-buffer & [messages_RWC_15.time] <= RWC_15(2)+buffer);
messages_RWC_18 = messages_RWC_18([messages_RWC_18.time] >= RWC_18(1)-buffer & [messages_RWC_18.time] <= RWC_18(2)+buffer);

messages_DA_62 = messages_DA_62([messages_DA_62.time] >= DA_62(1)-buffer & [messages_DA_62.time] <= DA_62(2)+buffer);

cd(myPath);

vars = {'messages_RWC_03' 'messages_RWC_06' 'messages_RWC_09' 'messages_RWC_12'...
        'messages_RWC_15' 'messages_RWC_18' 'messages_DA_62' 'scenarioNames'};
    
save('~/Documents/MATLAB/Data/Scenarios/scenario.mat',vars{:})

genScenarioLVC(messages_RWC_03,'~/Documents/MATLAB/Data/Scenarios','RWC_03.daa');
genScenarioLVC(messages_RWC_06,'~/Documents/MATLAB/Data/Scenarios','RWC_06.daa');
genScenarioLVC(messages_RWC_09,'~/Documents/MATLAB/Data/Scenarios','RWC_09.daa');

genScenarioLVC(messages_RWC_12,'~/Documents/MATLAB/Data/Scenarios','RWC_12.daa');
genScenarioLVC(messages_RWC_15,'~/Documents/MATLAB/Data/Scenarios','RWC_15.daa');
genScenarioLVC(messages_RWC_18,'~/Documents/MATLAB/Data/Scenarios','RWC_18.daa');

genScenarioLVC(messages_DA_62,'~/Documents/MATLAB/Data/Scenarios','DA_62.daa');

bufferScenarioTimes = {[RWC_03(1)-buffer RWC_03(2)+buffer] ...
                       [RWC_06(1)-buffer RWC_06(2)+buffer] ...
                       [RWC_09(1)-buffer RWC_09(2)+buffer] ...
                       [RWC_12(1)-buffer RWC_12(2)+buffer] ...
                       [RWC_15(1)-buffer RWC_15(2)+buffer] ...
                       [RWC_18(1)-buffer RWC_18(2)+buffer]};
                   

clear ans buffer myPath vars