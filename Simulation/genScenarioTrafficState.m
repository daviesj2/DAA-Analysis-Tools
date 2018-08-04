function [] = genScenarioTrafficState( trafficState,ownship,start,stop,outputPath,fileName)
%   Generates scenario file (.daa) from trafficState structures.
%
%   Name: genScenarioTrafficState.m [Function]   
%
%   INPUT: 
%       trafficState    [struct]:   Combination of ownship and intruder states
%                                   in a trafficState structure
%       ownship         [char]:     Callsign of Ownship  
%       start           [double]:   Scenario start time (POSIX time seconds)
%       stop            [double]:   Scenario stop time  (POSIX time seconds)
%       outputPath      [char]:     Output path
%       fileName        [char]:     Output file name
%
%   OUTPUT:
%       NONE
%
%   NOTES:
%       If more than one intruder state update occurs between each ownship update
%       These states will be averaged.
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% [September 20, 2017]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if stop<=start
    error('Stop time is earlier than start time!')
end

%Sort by time created
[~,I] = sort([trafficState.time]);
trafficState=trafficState(I);

IDX = [trafficState.time]>=start&[trafficState.time]<=stop; %trim to start/stop bounds.
trafficState=trafficState(IDX);

%The first state must be ownship
trafficState(1:find(strcmp({trafficState.Name},ownship),1)-1)=[]; %trim beginning states

ownshipIDX = find(strcmp({trafficState.Name},ownship)); %Synchronize states relative to ownship time
for i=1:length(ownshipIDX)
    
    if i==length(ownshipIDX) %If we've reached the last ownship state
        for j = ownshipIDX(i):length(trafficState)
            trafficState(j).time = trafficState(ownshipIDX(i)).time;
        end
        break; 
    end
    
    for j = ownshipIDX(i):ownshipIDX(i+1)-1 %Between first ownship instance and one before the next...
        trafficState(j).time = trafficState(ownshipIDX(i)).time;
    end
    
end
trafficState = removeDupes(trafficState,ownship);

%Write scenario file
if ~isempty(outputPath)
    fid = fopen(fullfile(outputPath,fileName),'w+');
    fprintf(fid,'NAME,     lat,     lon,     alt,     vx,     vy,     vz,     time\n unitless,   [deg],    [deg],   [ft],    [knot],   [knot],   [fpm],  [s] '); %Print Header
    for i = 1:length(trafficState)
        fprintf(fid, '\n%s, %.15f, %.15f, %.15f, %.15f, %.15f, %.15f, %.15f', trafficState(i).Name,...
                                                trafficState(i).lat,...
                                                trafficState(i).lon,...
                                                trafficState(i).alt,...
                                                trafficState(i).vx,...
                                                trafficState(i).vy,...
                                                trafficState(i).vz,...
                                                trafficState(i).time);
    end
    fclose(fid);
end

end

function [truthOut] = removeDupes(truth,ownship) %Remove duplicate entries by replacing with average.

truthOut=truth(1);
truthOut(1)=[];
ownshipBlocks = sum(strcmp({truth.Name},ownship));

for i = 1:ownshipBlocks
    idx = find(strcmp({truth.Name},ownship));
    if (i==ownshipBlocks)
        dupes = truth(idx(i):end);
    else
        dupes = truth(idx(i):idx(i+1)-1);
    end
    names = unique({dupes.Name});
    for j=1:length(names)
        numDupes = sum(strcmp({dupes.Name},names(j)));
        if numDupes >1
            dupesIdx = find(strcmp({dupes.Name},names(j)));
            average=dupes(dupesIdx(1)); %Lazily get structure format
            average.lat = mean([dupes(dupesIdx).lat]); %Get the average of each duplicate
            average.lon = mean([dupes(dupesIdx).lon]);
            average.alt = mean([dupes(dupesIdx).alt]);
            average.vx = mean([dupes(dupesIdx).vx]);
            average.vy = mean([dupes(dupesIdx).vy]);
            average.vz = mean([dupes(dupesIdx).vz]);
            dupes(dupesIdx(1)) = average;
            dupes(dupesIdx(2:end)) = [];
        end
    end
    truthOut = [truthOut dupes];
end
end
