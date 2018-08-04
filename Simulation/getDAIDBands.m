function [TrkBands, GsBands, VsBands, AltBands, MinMax, ownship, scenario] = getDAIDBands( scenario, config )
%  Gets alerting suggestive guidance bands from scenario using Daidalus java object
%
%   Name: DrawMultibands.m [Function]   
%
%   INPUT: 
%       scenario    [char]: Fully qualified path to scenario file (*.daa)
%       config      [char]: (optional) Fully qualified path to configuration file
%
%   OUTPUT:
%       TrkBands [struct]: DAIDALUS bands structure for horizontal guidance
%
%               .time           [double]  Time that bands occur
%               .NONE           [double]  NONE alert level bands
%               .FAR            [double]  FAR alert level bands
%               .MID            [double]  MID alert level bands
%               .NEAR           [double]  NEAR alert level bands
%               .RECOVERY       [double]  RECOVERY alert level bands
%               .bands_drawn    [logical] Indicates if alert level
%                                         excedes NONE
%       GsBands  [struct]: DAIDALUS bands structure for ground speed 
%       VsBands  [struct]: DAIDALUS bands structure for vertical speed 
%       AltBands [struct]: DAIDALUS bands structure for altitude
%
%       MinMax   [struct]: Aircraft performance structure
%               
%               {[Minimum, Maximum] 'unit'}
%               .Gs     [cell] Ground speed 
%               .Vs     [cell] Climb rate
%               .Alt    [cell] Altitude
%
%       ownship  [char]: Ownship callsign
%       scenario [char]: Scenario name
%
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% [October 9, 2017]
% ___________________________________________________________
%|                                                           |
%| Requires Matlab java version (version '-java') be equal to|
%| DAIDALUS.jar. This can be set with EV MATLAB_JAVA before  |
%| launching Matlab                                          |
%|___________________________________________________________|

%%%%

import('gov.nasa.larcfm.ACCoRD.*')
import('gov.nasa.larcfm.Util.*')
import('gov.nasa.larcfm.IO.*')

TrkBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false,'timeToRecovery',[]);
GsBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false,'timeToRecovery',[]);
VsBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false,'timeToRecovery',[]);
AltBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false,'timeToRecovery',[]);
MinMax = struct('Gs',[],'Vs',[],'Alt',[]);

%Create Daidalus instance
daa = Daidalus;

%Apply a config file if provided
if exist('config','var') && ~isempty(config)
    daa.parameters.loadFromFile(config);
else
    daa.set_Buffered_WC_SC_228_MOPS(true); %Use nominal_b as default config
end

%Start a new FileWalker
input = DaidalusFileWalker(scenario);

%Cut out scenario name
scenario(max(regexp(scenario,'\.')):end)=[];
scenario = split(scenario,'/');
scenario = scenario{end};

%If there are no states, something is wrong
if input.atBeginning && input.atEnd
    error('Invalid or empty scenario file');
end

lastIDX = input.indexOfTime(input.lastTime); %Zero indexed position of final state
GsUnit = char(daa.parameters.getUnits('gs_step'));
VsUnit = char(daa.parameters.getUnits('vs_step'));
AltUnit = char(daa.parameters.getUnits('alt_step'));

for i = 1:lastIDX+1
    
    %%%%%Read States into the Daidalus object%%%%%
    input.readState(daa)
        
    %%%%%Get bands%%%%%
    kb = daa.getKinematicMultiBands;
    
    NONE={};
    FAR={};
    MID={};
    NEAR={};
    RECOVERY={};
    
    %Track/Heading Bands%
    for j = 1:kb.trackLength
        
        switch char(kb.trackRegion(j-1).toString)
            case 'NONE'
                NONEstr = char(kb.track(j-1,'deg').toString);
                NONEstr(regexp(NONEstr,'([^\d-,.])')) = [];
                NONEstr = str2double(split(NONEstr,','));
                temp={};
                for k = getOdd(1:length(NONEstr))
                    temp = [temp {[NONEstr(k) NONEstr(k+1)]}];
                end
                
                NONE = [NONE temp];
            case 'FAR'
                FARstr = char(kb.track(j-1,'deg').toString);
                FARstr(regexp(FARstr,'([^\d-,.])')) = [];
                FARstr = str2double(split(FARstr,','));
                temp={};
                for k = getOdd(1:length(FARstr))
                    temp = [temp {[FARstr(k) FARstr(k+1)]}];
                end
                
                FAR = [FAR temp];
            case 'MID'
                MIDstr = char(kb.track(j-1,'deg').toString);
                MIDstr(regexp(MIDstr,'([^\d-,.])')) = [];
                MIDstr = str2double(split(MIDstr,','));
                temp={};
                for k = getOdd(1:length(MIDstr))
                    temp = [temp {[MIDstr(k) MIDstr(k+1)]}];
                end
                
                MID = [MID temp];
            case 'NEAR'
                NEARstr = char(kb.track(j-1,'deg').toString);
                NEARstr(regexp(NEARstr,'([^\d-,.])')) = [];
                NEARstr = str2double(split(NEARstr,','));
                temp={};
                for k = getOdd(1:length(NEARstr))
                    temp = [temp {[NEARstr(k) NEARstr(k+1)]}];
                end
                
                NEAR = [NEAR temp];
            case 'RECOVERY'
                RECOVERYstr = char(kb.track(j-1,'deg').toString);
                RECOVERYstr(regexp(RECOVERYstr,'([^\d-,.])')) = [];
                RECOVERYstr = str2double(split(RECOVERYstr,','));
                temp={};
                for k = getOdd(1:length(RECOVERYstr))
                    temp = [temp {[RECOVERYstr(k) RECOVERYstr(k+1)]}];
                end
                
                RECOVERY = [RECOVERY temp];
            otherwise
                warning('Somethings wrong')
        end  
    end
    
    TrkBands(i).time = daa.getCurrentTime;
    TrkBands(i).NONE = NONE;
    TrkBands(i).FAR = FAR;
    TrkBands(i).MID = MID;
    TrkBands(i).NEAR = NEAR;
    TrkBands(i).RECOVERY = RECOVERY;
    TrkBands(i).bands_drawn = ~isempty([FAR MID NEAR RECOVERY]);
    
    TrkBands(i).timeToRecovery = kb.timeToTrackRecovery;
    if isnan(TrkBands(i).timeToRecovery), TrkBands(i).timeToRecovery = inf; end
    
    NONE={};
    FAR={};
    MID={};
    NEAR={};
    RECOVERY={};
    
    %Ground Speed Bands%
    for j = 1:kb.groundSpeedLength
        
        switch char(kb.groundSpeedRegion(j-1).toString)
            case 'NONE'
                NONEstr = char(kb.groundSpeed(j-1,GsUnit).toString);
                NONEstr(regexp(NONEstr,'([^\d-,.])')) = [];
                NONEstr = str2double(split(NONEstr,','));
                temp={};
                for k = getOdd(1:length(NONEstr))
                    temp = [temp {[NONEstr(k) NONEstr(k+1)]}];
                end
                
                NONE = [NONE temp];
            case 'FAR'
                FARstr = char(kb.groundSpeed(j-1,GsUnit).toString);
                FARstr(regexp(FARstr,'([^\d-,.])')) = [];
                FARstr = str2double(split(FARstr,','));
                temp={};
                for k = getOdd(1:length(FARstr))
                    temp = [temp {[FARstr(k) FARstr(k+1)]}];
                end
                
                FAR = [FAR temp];
            case 'MID'
                MIDstr = char(kb.groundSpeed(j-1,GsUnit).toString);
                MIDstr(regexp(MIDstr,'([^\d-,.])')) = [];
                MIDstr = str2double(split(MIDstr,','));
                temp={};
                for k = getOdd(1:length(MIDstr))
                    temp = [temp {[MIDstr(k) MIDstr(k+1)]}];
                end
                
                MID = [MID temp];
            case 'NEAR'
                NEARstr = char(kb.groundSpeed(j-1,GsUnit).toString);
                NEARstr(regexp(NEARstr,'([^\d-,.])')) = [];
                NEARstr = str2double(split(NEARstr,','));
                temp={};
                for k = getOdd(1:length(NEARstr))
                    temp = [temp {[NEARstr(k) NEARstr(k+1)]}];
                end
                
                NEAR = [NEAR temp];
            case 'RECOVERY'
                RECOVERYstr = char(kb.groundSpeed(j-1,GsUnit).toString);
                RECOVERYstr(regexp(RECOVERYstr,'([^\d-,.])')) = [];
                RECOVERYstr = str2double(split(RECOVERYstr,','));
                temp={};
                for k = getOdd(1:length(RECOVERYstr))
                    temp = [temp {[RECOVERYstr(k) RECOVERYstr(k+1)]}];
                end
                
                RECOVERY = [RECOVERY temp];
        end
    end
    
    GsBands(i).time = daa.getCurrentTime;
    GsBands(i).NONE = NONE;
    GsBands(i).FAR = FAR;
    GsBands(i).MID = MID;
    GsBands(i).NEAR = NEAR;
    GsBands(i).RECOVERY = RECOVERY;
    GsBands(i).bands_drawn = ~isempty([FAR MID NEAR RECOVERY]);
    GsBands(i).timeToRecovery = kb.timeToGroundSpeedRecovery;
    
    NONE={};
    FAR={};
    MID={};
    NEAR={};
    RECOVERY={};
    
    %Vertical Speed Bands%
    for j = 1:kb.verticalSpeedLength
        
        switch char(kb.verticalSpeedRegion(j-1).toString)
            case 'NONE'
                NONEstr = char(kb.verticalSpeed(j-1,VsUnit).toString);
                NONEstr(regexp(NONEstr,'([^\d-,.])')) = [];
                NONEstr = str2double(split(NONEstr,','));
                temp={};
                for k = getOdd(1:length(NONEstr))
                    temp = [temp {[NONEstr(k) NONEstr(k+1)]}];
                end
                
                NONE = [NONE temp];
            case 'FAR'
                FARstr = char(kb.verticalSpeed(j-1,VsUnit).toString);
                FARstr(regexp(FARstr,'([^\d-,.])')) = [];
                FARstr = str2double(split(FARstr,','));
                temp={};
                for k = getOdd(1:length(FARstr))
                    temp = [temp {[FARstr(k) FARstr(k+1)]}];
                end
                
                FAR = [FAR temp];
            case 'MID'
                MIDstr = char(kb.verticalSpeed(j-1,VsUnit).toString);
                MIDstr(regexp(MIDstr,'([^\d-,.])')) = [];
                MIDstr = str2double(split(MIDstr,','));
                temp={};
                for k = getOdd(1:length(MIDstr))
                    temp = [temp {[MIDstr(k) MIDstr(k+1)]}];
                end
                
                MID = [MID temp];
            case 'NEAR'
                NEARstr = char(kb.verticalSpeed(j-1,VsUnit).toString);
                NEARstr(regexp(NEARstr,'([^\d-,.])')) = [];
                NEARstr = str2double(split(NEARstr,','));
                temp={};
                for k = getOdd(1:length(NEARstr))
                    temp = [temp {[NEARstr(k) NEARstr(k+1)]}];
                end
                
                NEAR = [NEAR temp];
            case 'RECOVERY'
                RECOVERYstr = char(kb.verticalSpeed(j-1,VsUnit).toString);
                RECOVERYstr(regexp(RECOVERYstr,'([^\d-,.])')) = [];
                RECOVERYstr = str2double(split(RECOVERYstr,','));
                temp={};
                for k = getOdd(1:length(RECOVERYstr))
                    temp = [temp {[RECOVERYstr(k) RECOVERYstr(k+1)]}];
                end
                
                RECOVERY = [RECOVERY temp];
        end
    end
    
    VsBands(i).time = daa.getCurrentTime;
    VsBands(i).NONE = NONE;
    VsBands(i).FAR = FAR;
    VsBands(i).MID = MID;
    VsBands(i).NEAR = NEAR;
    VsBands(i).RECOVERY = RECOVERY;
    VsBands(i).bands_drawn = ~isempty([FAR MID NEAR RECOVERY]);
    VsBands(i).timeToRecovery = kb.timeToVerticalSpeedRecovery;
    
    NONE={};
    FAR={};
    MID={};
    NEAR={};
    RECOVERY={};
    
    %Altitude Bands%
    for j = 1:kb.altitudeLength
        
        switch char(kb.altitudeRegion(j-1).toString)
            case 'NONE'
                NONEstr = char(kb.altitude(j-1,AltUnit).toString);
                NONEstr(regexp(NONEstr,'([^\d-,.])')) = [];
                NONEstr = str2double(split(NONEstr,','));
                temp={};
                for k = getOdd(1:length(NONEstr))
                    temp = [temp {[NONEstr(k) NONEstr(k+1)]}];
                end
                
                NONE = [NONE temp];
            case 'FAR'
                FARstr = char(kb.altitude(j-1,AltUnit).toString);
                FARstr(regexp(FARstr,'([^\d-,.])')) = [];
                FARstr = str2double(split(FARstr,','));
                temp={};
                for k = getOdd(1:length(FARstr))
                    temp = [temp {[FARstr(k) FARstr(k+1)]}];
                end
                
                FAR = [FAR temp];
            case 'MID'
                MIDstr = char(kb.altitude(j-1,AltUnit).toString);
                MIDstr(regexp(MIDstr,'([^\d-,.])')) = [];
                MIDstr = str2double(split(MIDstr,','));
                temp={};
                for k = getOdd(1:length(MIDstr))
                    temp = [temp {[MIDstr(k) MIDstr(k+1)]}];
                end
                
                MID = [MID temp];
            case 'NEAR'
                NEARstr = char(kb.altitude(j-1,AltUnit).toString);
                NEARstr(regexp(NEARstr,'([^\d-,.])')) = [];
                NEARstr = str2double(split(NEARstr,','));
                temp={};
                for k = getOdd(1:length(NEARstr))
                    temp = [temp {[NEARstr(k) NEARstr(k+1)]}];
                end
                
                NEAR = [NEAR temp];
            case 'RECOVERY'
                RECOVERYstr = char(kb.altitude(j-1,AltUnit).toString);
                RECOVERYstr(regexp(RECOVERYstr,'([^\d-,.])')) = [];
                RECOVERYstr = str2double(split(RECOVERYstr,','));
                temp={};
                for k = getOdd(1:length(RECOVERYstr))
                    temp = [temp {[RECOVERYstr(k) RECOVERYstr(k+1)]}];
                end
                RECOVERY = [RECOVERY temp];
        end
    end
    
    AltBands(i).time = daa.getCurrentTime;
    AltBands(i).NONE = NONE;
    AltBands(i).FAR = FAR;
    AltBands(i).MID = MID;
    AltBands(i).NEAR = NEAR;
    AltBands(i).RECOVERY = RECOVERY;
    AltBands(i).bands_drawn = ~isempty([FAR MID NEAR RECOVERY]);
    AltBands(i).timeToRecovery = kb.timeToAltitudeRecovery;
    %Get Ownship Performance Limits%
    
    MinMax.Gs = {[daa.parameters.getMinGroundSpeed(GsUnit) daa.parameters.getMaxGroundSpeed(GsUnit)] GsUnit};
    MinMax.Vs = {[daa.parameters.getMinVerticalSpeed(VsUnit) daa.parameters.getMaxVerticalSpeed(VsUnit)] GsUnit};
	MinMax.Alt = {[daa.parameters.getMinAltitude(AltUnit)  daa.parameters.getMaxAltitude(AltUnit)] AltUnit};
    
end

ownship = char(daa.getOwnshipState.getId);
end

function[odd] = getOdd(vect)
    
    odd = vect((mod(vect,2)==1));
    
end