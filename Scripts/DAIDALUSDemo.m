%%Example workflow for generating DAIDALUS band visulations from LVC data
OwnshipName = 'NASA870';
IntruderName = 'N3GC';

start = 1501171080; %Encounter POSIX start/stop
stop = 1501171200;

LVCLog = '/Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-27-2017/GatewayLogger/MPI_gateway4__LOGGER_07272017_085229AM.csv';

scenarioFile = 'ScenarioFile.daa';
videoFile = 'OverviewVideo.avi';



MATLABPath = '~/Documents/MATLAB/';
WellClearPath = '~/Documents/MATLAB/WellClear-master/DAIDALUS/Java/';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use GPS Data
%
% IkhanaGPSPath = '/Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-18-2017/Ikhana_dGPS';
% IkhanaGPSFile = 'ACAS_Xu_20170718_17.07.18_1333_KinematicReport.txt';
% 
% N3GCGPSPath = '/Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-18-2017/N3GC_dGPS';
% N3GCGPSFile = 'N3GC_20170718.txt';
%
% trafficStateOwnship = getTrafficStateIkhana(fullfile(IkhanaGPSPath,IkhanaGPSFile),OwnshipName);
% trafficStateIntruder = getTrafficStateN3GC(fullfile(N3GCGPSPath,N3GCGPSFile),IntruderName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

messages = getLVC(LVCLog);
messages = messages([messages.time] > start & [messages.time] < stop);
[trafficStateCAT] = genScenarioLVC(messages,'.',scenarioFile);
trafficStateOwnship = trafficStateCAT(strcmp({trafficStateCAT.Name},OwnshipName));
trafficStateIntruder = trafficStateCAT(~strcmp({trafficStateCAT.Name},OwnshipName));

fprintf('\nGetting Bands...');
[TrkBands, GsBands, VsBands, AltBands, MinMax, ownship, scenario] = getDAIDBands(['./' scenarioFile]);
Alerts = getDAIDAlerts(['./' scenarioFile]);
fprintf('Done. ');

fprintf('\nDrawing Bands...');
tic;
cdata = drawBandsDAIDALUS(TrkBands, GsBands, VsBands, AltBands, Alerts, MinMax,trafficStateOwnship, trafficStateIntruder, ownship, scenario, false);
toc
fprintf('Done. ');

fprintf('\nProcessing frames...')
video = VideoWriter(videoFile);
video.FrameRate = 2;
video.Quality = 100;
open(video)

for i = 1:length(cdata)
    video.writeVideo(cdata(i))
end
close(video)
