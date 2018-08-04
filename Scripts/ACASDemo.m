%%Example workflow for generating ACAS-Xu alerting visulations from LVC messaging and GPS data
OwnshipName = 'NASA870';
IntruderName = 'N3GC';

LVCLog = '/Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-18-2017/GatewayLogger/MPI_gateway4__LOGGER_07182017_074112AM.csv';

IkhanaGPSPath = '/Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-18-2017/Ikhana_dGPS';
IkhanaGPSFile = 'ACAS_Xu_20170718_17.07.18_1333_KinematicReport.txt';

N3GCGPSPath = '/Users/jtdavies/Documents/Data/ACAS-Xu_Flight-Test/07-18-2017/N3GC_dGPS';
N3GCGPSFile = 'N3GC_20170718.txt';

videoFile = 'ACAS.avi';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

messages = getLVC(LVCLog);

[trafficStateCAT] = genScenarioLVC(messages,'','');
trafficStateOS = trafficStateCAT(strcmp({trafficStateCAT.Name},OwnshipName));
trafficStateINT = trafficStateCAT(~strcmp({trafficStateCAT.Name},OwnshipName));

[figs, cData] = drawBandsACASXu(messages,true,trafficStateOS,trafficStateINT);

video = VideoWriter(videoFile);
video.FrameRate = 1;
video.Quality = 100;
open(video)
for i = 1:length(cData)
    video.writeVideo(cData(i))
end
close(video)