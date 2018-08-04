function [ Alerts, Unit ] = getDAIDAlerts( scenario, config )
%   Gets alerting data from scenario file using Daidalus java object
%
%   Name: getDAIDAlerts.m [Function]   
%
%   INPUT: 
%       scenario    [struct]: Path to scenario file (*.daa)
%       config      [char]:   Path to DAIDALUS configuration file
%
%   OUTPUT:
%       Alerts      [struct]: DAA alerting structure with fields
%
%           .Time               [double]     Time of applicability
%           .Ownship            [char]       Ownship callsign
%           .Traffic            [char]       Intruder callsign
%           .AlertLevel         [double]     Current Alert level of intruder
%           .TimeToVol          [1xN double] Time to invasion of volume
%                                              for a given alert level (1:N)
%           .HorizontalSep      [double]     Current horizontal separation 
%           .VerticalSep        [double]     Current vertical separation                                       
%           .HorizontalClosure  [double]     Horizontal closure rate
%           .VerticalClosure    [double]     Vertical closure rate
%           .ProjectedHMD       [double]     Projected Horizontal
%                                              miss distance at WCV
%           .ProjectedVMD       [double]     Projected Vertical
%                                              miss distance at WCV
%           .ProjectedTCPA      [double]     Time to closest approach
%           .ProjectedDCPA      [double]     Distance at closest
%                                              approach
%           .ProjectedTCOA      [double]     Time to co-altitude
%
%       Unit        [struct]: Physical units of alerts, shares fieldnames
%                             of alerts
%
%   NOTES:
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% [October 9, 2017]
% ___________________________________________________________
%|                                                           |
%| Requires Matlab java version (version '-java') be equal to|
%| DAIDALUS.jar. This can be set with EV MATLAB_JAVA before  |
%| launching Matlab                                          |
%|___________________________________________________________|

import('gov.nasa.larcfm.ACCoRD.*')
import('gov.nasa.larcfm.Util.*')
import('gov.nasa.larcfm.IO.*')

%Create Daidalus instance
daa = Daidalus;

%Apply a config file if provided
if exist('config','var')
    daa.parameters.loadFromFile(config);
else
    daa.set_Buffered_WC_SC_228_MOPS(true);
end

%Start a new FileWalker
input = DaidalusFileWalker(scenario);

%If there are no states, something is wrong
if input.atBeginning && input.atEnd
    error('Invalid or empty scenario file');
end

lastIDX = input.indexOfTime(input.lastTime); %Zero indexed position of final state
input.goToBeginning

%Initalize Alerts structure
Alerts = struct('Time',[],'Ownship',[],'Traffic',[],'AlertLevel',[],'WCVTime',[],'TimeToVol',[],'TimeOutVol',[],'HorizontalSep',[],...
                'VerticalSep',[],'HorizontalClosure',[],'VerticalClosure',[],'ProjectedHMD',[],...
                'ProjectedVMD',[],'ProjectedTCPA',[],'ProjectedDCPA',[],'ProjectedTCOA',[]);
Unit = Alerts;
AlertStruct = Alerts;
Alerts(1) = [];

Unit.Time = 'sec';
Unit.Ownship = 'Callsign';
Unit.Traffic = 'Callsign';
Unit.AlertLevel = 'enum';
Unit.TimeToVol = 'sec';
Unit.TimeOutVol = 'sec';
Unit.WCVTime = 'sec';
Unit.HorizontalSep = daa.parameters.getUnits("min_horizontal_recovery").toCharArray';
Unit.VerticalSep = daa.parameters.getUnits("min_vertical_recovery").toCharArray';
Unit.HorizontalClosure = daa.parameters.getUnits("gs_step").toCharArray';
Unit.VerticalClosure = daa.parameters.getUnits("vs_step").toCharArray';
Unit.ProjectedHMD = daa.parameters.getUnits("min_horizontal_recovery").toCharArray';
Unit.ProjectedVMD = daa.parameters.getUnits("min_vertical_recovery").toCharArray';
Unit.ProjectedTCPA = 'sec';
Unit.ProjectedDCPA = daa.parameters.getUnits("min_horizontal_recovery").toCharArray';
Unit.ProjectedTCOA = 'sec';

totalAlerts=0;
for i = 1:lastIDX
    input.readState(daa);
    totalAlerts = totalAlerts+daa.lastTrafficIndex;
end
input.goToBeginning();
daa.reset();

Alerts(totalAlerts)=AlertStruct;

for i = 1:lastIDX
    input.readState(daa);
    if daa.lastTrafficIndex == 0, continue; end
    tempAlerts = AlertStruct; %Clear tempAlerts
    tempAlerts(daa.lastTrafficIndex) = AlertStruct; %Preallocate to end of TrafficIndex
    
    for j = 1:daa.lastTrafficIndex
        tempAlerts(j).Time = daa.getCurrentTime();
        
        tempAlerts(j).Ownship = daa.getOwnshipState().getId(); %javaString.toCharArray is ~2x faster than char(javaString)
        tempAlerts(j).Ownship = tempAlerts(j).Ownship.toCharArray';
        tempAlerts(j).Traffic = daa.getAircraftState(j).getId();
        tempAlerts(j).Traffic = tempAlerts(j).Traffic.toCharArray';
        
        tempAlerts(j).AlertLevel = daa.alerting(j);
        tempAlerts(j).WCVTime = daa.timeToViolation(j);
        
        for k = 1:daa.parameters.alertor.mostSevereAlertLevel()
            det = daa.detection(j,k);
            tempAlerts(j).TimeToVol = [tempAlerts(j).TimeToVol det.getTimeIn()];
            tempAlerts(j).TimeOutVol = [tempAlerts(j).TimeOutVol det.getTimeOut()];
        end
        
        tempAlerts(j).HorizontalSep =       Units.to(Unit.HorizontalSep,    det.get_s().norm2D());
        tempAlerts(j).VerticalSep =         Units.to(Unit.VerticalSep,      det.get_s().z);
        tempAlerts(j).HorizontalClosure =   Units.to(Unit.HorizontalClosure,det.get_v().norm2D());
        tempAlerts(j).VerticalClosure =     Units.to(Unit.VerticalClosure,  det.get_v().z);
        tempAlerts(j).ProjectedHMD =        Units.to(Unit.ProjectedHMD,     det.HMD(daa.parameters.getLookaheadTime()));
        tempAlerts(j).ProjectedVMD =        Units.to(Unit.ProjectedVMD,     det.VMD(daa.parameters.getLookaheadTime()));
        tempAlerts(j).ProjectedTCPA =       Horizontal.tcpa(det.get_s().vect2(),det.get_v().vect2());
        tempAlerts(j).ProjectedDCPA =       Horizontal.dcpa(det.get_s().vect2(),det.get_v().vect2());
        tempAlerts(j).ProjectedTCOA =       Vertical.time_coalt(det.get_s().z,det.get_v().z);
        
    end
    lastIdx = find(~cellfun(@isempty,{Alerts.Time}),1,'last');
    if isempty(lastIdx), lastIdx=0; end
    Alerts(lastIdx+1:lastIdx+length(tempAlerts)) = tempAlerts;
    
end


end

