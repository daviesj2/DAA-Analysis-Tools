function [TrkBands, GsBands, VsBands, AltBands, Alerts, MinMax, CalculatedState, ownship, scenario]=getDAIDBandsDRAW(varargin)
%   Parses through a log file produced by DrawMultiBands example (.draw)
% 
%   Name: getDAAbandsDAIDALUS.m [Function]   
%
%   INPUT: 
%       varargin[1]
%           varargin{1} [char]: Fully qualified path to .draw file
%       
%       varargin[2]
%           varargin{1} [char]: Path containing .draw file
%           varargin{2} [char]: Name of .draw file
%
%   OUTPUT:
%       TrkBands [struct]: DAIDALUS bands structure for horizontal guidance  
%                          with units of degrees 
%
%               .time           [double]  Time that bands occur
%               .NONE           [double]  NONE alert level bands
%               .FAR            [double]  FAR alert level bands
%               .MID            [double]  MID alert level bands
%               .NEAR           [double]  NEAR alert level bands
%               .RECOVERY       [double]  RECOVERY alert level bands
%               .bands_drawn    [logical] Indicates if alert level
%                                         excedes NONE

%       GsBands  [struct]: DAIDALUS bands structure for ground speed with
%                          units of knots
%       VsBands  [struct]: DAIDALUS bands structure for vertical speed with
%                          units of feet per minute
%       AltBands [struct]: DAIDALUS bands structure for altitude with
%                          units of feet
%
%       Alerts   [struct]: DAIDALUS DAA alerts structure
%
%               .Callsign   [char]      Callsign of associated alerts
%               .Times      [double]    Times of alerts
%               .Levels     [double]    alert levels
%
%       MinMax   [struct]: Aircraft performance structure
%               
%               {[Minimum, Maximum] 'unit'}
%               .Gs     [cell] Ground speed 
%               .Vs     [cell] Climb rate
%               .Alt    [cell] Altitude
%
%       CalculatedState [struct]: State information calculated by DAIDALUS
%           
%               .OwnTrk: Ownship heading        (deg)
%               .OwnGs:  Ownship groundspeed    (knot)
%               .OwnVs:  Ownship vertical speed (fpm)
%               .OwnAlt: Ownship altitude       (feet)
%
%       ownship  [char]: Ownship callsign
%       scenario [char]: Scenario name
%
%   NOTES:
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 26, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DrawMultiBands from: https://github.com/nasa/WellClear/tree/master/DAIDALUS

if length(varargin) == 1
    daaPath = varargin{1};
elseif length(varargin) == 2
    daaPath = fullfile(varargin{1},varargin{2});
else
    throw(MException('tools:getDAAbandsDAIDALUS:argumentsException','Incorrect number of input arguments. Expected 1,2 got %d.',length(varargin)));
end

fid = fopen(daaPath,'r');
if fid==-1 
    throw(MException('tools:getDAAbandsDAIDALUS:fileNotFound','I can''t find file: %s',daaPath)); 
end

%Initialize data cell structure and index
data = {};
i=1;

%Loop over file
while ~feof(fid)
    data{i,1} = {fgetl(fid)};
    i=i+1;
end

fclose(fid);

%Get scenario name
scenario = split(data{2},':');
scenario = scenario{2};

%Get ownship callsign
ownship = split(data{3},':');
ownship = ownship{2};

%Get alert bands enumeration (lazy)
alert_NONE = 0;
alert_FAR = 1;
alert_MID = 2;
alert_NEAR = 3;
alert_RECOVERY = 4;

%Get performance limits {[low hi], 'unit'}
MinMaxGs = split(data{10},':');
MinMaxGs = {str2num(MinMaxGs{2}) MinMaxGs{3}}; %Ignore warning, str2num knows '1 2' = [1 2]. 
MinMaxVs = split(data{11},':');                %str2double thinks '1 2' = NaN.
MinMaxVs = {str2num(MinMaxVs{2}) MinMaxVs{3}};
MinMaxAlt = split(data{12},':');
MinMaxAlt = {str2num(MinMaxAlt{2}) MinMaxAlt{3}};

TrkBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false);
GsBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false);
VsBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false);
AltBands = struct('time',[],'NONE',[],'FAR',[],'MID',[],'NEAR',[],'RECOVERY',[],'bands_drawn',false);

TrkLength = 1;
GsLength  = 1;
VsLength  = 1;
AltLength  = 1;

for i=1:length(data) %iterate over bands
    if any(strfind(data{i+12}{1},'MostSevereAlertLevel')),break;end %Stop if you've come to the end (This doesn't seem like the cleanest way to do this but it works, -5 style points)
    
    %Break out Type (Trk Vs Gs Alt) and Time
    band = split(data{i+12},':');
    bandType = band{1};
    bandTime = str2double(band{2});
    bandData = split(band{3});
    
    for j = 1:length(bandData) %Clear out some control characters
        bandData{j}(regexp(bandData{j},'[,\[\]]'))=[];
        if isempty(bandData{j}), bandData(j) = []; break; end
    end

    locIdx=1; %Each band statement has 3 parts [lo hi alrt] locIdx keeps track of where it is within the band line
    bandDeg={};
    bandAlrt=[];
    
    %Assemble Data
    for j = 1:length(bandData)

       switch locIdx
           case 1
               lo = str2double(bandData{j});
           case 2
               hi = str2double(bandData{j});
           case 3
               alrt = str2double(bandData{j});
       end
       if locIdx >= 3 
           bandDeg = [bandDeg {[lo hi]}];
           bandAlrt = [bandAlrt alrt];
           locIdx=1; 
       else 
           locIdx = locIdx+1;
       end
    end
    
    
    %Populate alert band structures
    switch bandType
        case 'TrkBands'
            TrkBands(TrkLength).time = bandTime;
            TrkBands(TrkLength).NONE = bandDeg(bandAlrt == alert_NONE);
            TrkBands(TrkLength).FAR = bandDeg(bandAlrt == alert_FAR);
            TrkBands(TrkLength).MID = bandDeg(bandAlrt == alert_MID);
            TrkBands(TrkLength).NEAR = bandDeg(bandAlrt == alert_NEAR);
            TrkBands(TrkLength).RECOVERY = bandDeg(bandAlrt == alert_RECOVERY);
            
            if ~length(TrkBands(TrkLength).NONE) == 1 || ~all(TrkBands(TrkLength).NONE{1} == [0 360])
                TrkBands(TrkLength).bands_drawn=true;
            else
                TrkBands(TrkLength).bands_drawn=false;
            end
            
            TrkLength = TrkLength+1;
        case 'GsBands'
            GsBands(GsLength).time = bandTime;
            GsBands(GsLength).NONE = bandDeg(bandAlrt == alert_NONE);
            GsBands(GsLength).FAR = bandDeg(bandAlrt == alert_FAR);
            GsBands(GsLength).MID = bandDeg(bandAlrt == alert_MID);
            GsBands(GsLength).NEAR = bandDeg(bandAlrt == alert_NEAR);
            GsBands(GsLength).RECOVERY = bandDeg(bandAlrt == alert_RECOVERY);
            
            if ~length(GsBands(GsLength).NONE) == 1 || ~all(GsBands(GsLength).NONE{1} == MinMaxGs{1})
                GsBands(GsLength).bands_drawn=true;
            else
                GsBands(GsLength).bands_drawn=false;
            end
            
            GsLength = GsLength+1;
        case 'VsBands'
            VsBands(VsLength).time = bandTime;
            VsBands(VsLength).NONE = bandDeg(bandAlrt == alert_NONE);
            VsBands(VsLength).FAR = bandDeg(bandAlrt == alert_FAR);
            VsBands(VsLength).MID = bandDeg(bandAlrt == alert_MID);
            VsBands(VsLength).NEAR = bandDeg(bandAlrt == alert_NEAR);
            VsBands(VsLength).RECOVERY = bandDeg(bandAlrt == alert_RECOVERY);
            
            if ~length(VsBands(VsLength).NONE) == 1 || ~all(VsBands(VsLength).NONE{1} == MinMaxVs{1})
                VsBands(VsLength).bands_drawn=true;
            else
                VsBands(VsLength).bands_drawn=false;
            end
            
            VsLength = VsLength+1;
        case 'AltBands'
            AltBands(AltLength).time = bandTime;
            AltBands(AltLength).NONE = bandDeg(bandAlrt == alert_NONE);
            AltBands(AltLength).FAR = bandDeg(bandAlrt == alert_FAR);
            AltBands(AltLength).MID = bandDeg(bandAlrt == alert_MID);
            AltBands(AltLength).NEAR = bandDeg(bandAlrt == alert_NEAR);
            AltBands(AltLength).RECOVERY = bandDeg(bandAlrt == alert_RECOVERY);
            
            if ~length(AltBands(AltLength).NONE) == 1 || ~all(AltBands(AltLength).NONE{1} == MinMaxAlt{1})
                AltBands(AltLength).bands_drawn=true;
            else
                AltBands(AltLength).bands_drawn=false;
            end
            
            AltLength = AltLength+1;
        otherwise
            break
    end
            
end

eoBands=i+12;
MaxAlert = split(data{eoBands},':');
MaxAlert = str2double(MaxAlert(2));

Alerts = struct('Callsign',[],'Times',[],'Levels',[]);
CalculatedState = struct('OwnTrk',[],'OwnGs',[],'OwnVs',[],'OwnAlt',[]);
for i = 1:length(data(eoBands+1:end))
    
    AlertData = split(data{eoBands+i},':');
    
    switch AlertData{1}
    
        case 'AlertingTimes' %There is more data after AlertingTimes (Ownship Gs,alt,etc.) but we dont need it.
    
            Alerts(i).Callsign = AlertData{2};
            AlertData = split(AlertData{3},' ');

            for j=1:length(AlertData)-1 %-1, line terminates at with an empty string. 
                    if mod(j,2) == 0,Alerts(i).Levels = [Alerts(i).Levels str2double(AlertData{j})]; %Comes in pairs. Odds times, even levels
                    else, Alerts(i).Times = [Alerts(i).Times str2double(AlertData{j})];  end
            end
        
        case 'OwnTrk'
            
            owntrk = split(AlertData{2});
            for j = 1:length(owntrk)-1
                CalculatedState(j).OwnTrk = str2double(owntrk{j});
            end
            
            
        case 'OwnGs'
            
            owngs = split(AlertData{2});
            for j = 1:length(owngs)-1
                CalculatedState(j).OwnGs = str2double(owngs{j});
            end
        
        case 'OwnVs'
            
            ownvs = split(AlertData{2});
            for j = 1:length(ownvs)-1
                CalculatedState(j).OwnVs = str2double(ownvs{j});
            end
        
        case 'OwnAlt'
            
            ownalt = split(AlertData{2});
            for j = 1:length(ownalt)-1
                CalculatedState(j).OwnAlt = str2double(ownalt{j});
            end
    end
                
end

MinMax.Gs = MinMaxGs;
MinMax.Vs = MinMaxVs;
MinMax.Alt = MinMaxAlt;

%Reformat to new Alerts structure.
Alerts = reformAlerts(Alerts, ownship);

end

function Alerts = reformAlerts (OldAlerts, Ownship)
Alerts = struct('Time',[],'Ownship',[],'Traffic',[],'AlertLevel',[]);
Alerts(1)=[];

for i = 1:length(OldAlerts)
    tempAlerts(length(OldAlerts(i).Times)) = struct('Time',[],'Ownship',[],'Traffic',[],'AlertLevel',[]);
    for j = 1:length(OldAlerts(i).Times)
        tempAlerts(j).Time = OldAlerts(i).Times(j);
        tempAlerts(j).Ownship = Ownship;
        tempAlerts(j).Traffic = OldAlerts(i).Callsign;
        tempAlerts(j).AlertLevel = OldAlerts(i).Levels(j);
    end
    Alerts = [Alerts tempAlerts];
    tempAlerts = [];
end

[~, IDX] = sort([Alerts.Time]);
Alerts = Alerts(IDX);
end
    


