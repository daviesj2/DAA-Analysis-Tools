function [ messages ] = getLVC(CSVLog)
%   Packages messages from an LVC log into a standard message structure.
%
%   Name: getLVC.m [Function] 
% 
%   INPUT: 
%       CSVLog [char]: Fully qualified path to LVC log .csv file
%
%   OUTPUT:
%       messages [struct]: Structure containing all LVC messages
%       	.Name       [char]: Name of lvc message ex. 'MsgFlightPlan'
%       	.Data       [struct]: Structure of data with LVC field names
%                                 for fields
%       	.time       [double]: Time of record (or time of applicability if available) in seconds UTC
%   NOTES:
%           Can take advantage of parpool if available.
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 13, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%This changes your parallel pool settings to not auto-create a pool on a
%parfor call. This change is reverted at the end of the function. 
%Feel free to comment or remove these lines if you don't want to mess with
%your settings.
%%%
parSettings = parallel.Settings;
AutoCreateDefault = parSettings.Pool.AutoCreate;
parSettings.Pool.AutoCreate = false;
%%%

%Input checking
if ~exist('CSVLog','var') 
    [CSVLog, path] = uigetfile('*.csv','Select Message Log File: ');
    CSVLog = fullfile(path,CSVLog);
end

if ~exist('ignoreType','var')
    ignoreType = false;
end

%Build up message map from top of log file
messageMap = buildMessageMap(CSVLog); 

%
formatSpec = repmat('%s',1,119);
fileID = fopen(CSVLog,'r');
if fileID == -1, error('Log file does not exist!'); end

data = textscan(fileID, formatSpec,'HeaderLines',27,'Delimiter',',', 'TextType', 'char','ReturnOnError', false, 'EndOfLine', '\r\n');
fclose(fileID);

if all(cellfun(@isempty,data))
    messages = [];
    return
end

data = [data{1:end}]; %Scan it all in
messageNames = data(:,1); %Make one large cell matrix

messages(length(messageNames)) = struct('Name',[],'Fields',[],'Data',[],'time',[]); %Preallocate
reformedData = cell(1,length(data(:,1)));
times = zeros(1,length(data(:,1)));

messageMapNames = {messageMap.Name};
for i = 1:length(data(:,1))
    reformedData(i) = {data(i,3:end)};
    messages(i) = messageMap(strcmp(messageMapNames,messageNames(i))); %Fill in name and structure
    times(i) = sscanf(data{i,2},'%f');
end
data=reformedData;


%Populate Structures
for i = 1:length(data)    
    data{i}(find(~strcmp(data{i},''),1,'last')+1:end) = [];%Remove trailing empties
    
    switch messages(i).Name
        
        case 'AcasXu' %Pair up ACAS bands bits
            intruderID = data{i}(11:74); %Intruder ID field is a fixed length 1x64 integer

            merged = mergeCells(cellstr(repmat(',',64,1))',intruderID);
            intruderIDVector = sscanf([merged{:}],',%f')';

            data{i}(11) = {intruderIDVector};
            data{i}(12:74)=[];
            
            data{i}(15) = {strcmp(data{i}(15:34),'1')};
            data{i}(16) = {strcmp(data{i}(35:end),'1')};

            if any(data{i}{15} | data{i}{16})
                data{i}(17) = {true};
            else
                data{i}(17) = {false};
            end
            
            messages(i).Fields = [messages(i).Fields {'bands_drawn'}];
            data{i}(18:end)=[];
            
        case 'MsgFlightPlan'
            if ~any(strcmp(messages(i).Fields,'m_dlinkEquipped'))
                messages(i).Fields = [messages(i).Fields {'m_dlinkEquipped'}];
            end
    end
    messages(i).Data = data{i};

end 

%Cast
messages=fixTypes(messages);

for i = 1:numel(messages)
    mergedData = mergeCells(messages(i).Fields,messages(i).Data);
    messages(i).Data = struct(mergedData{:}); %Fill in data
    
    if all(strcmp('m_timeOfApplicability',messages(i).Fields))
        messages(i).time = sscanf(messages(i).Data.m_timeOfApplicability,'%f');
    else
        messages(i).time = times(i);%Fill in message time
    end
end
    


messages = rmfield(messages,'Fields');

%%% Reset default Parallel setting
parSettings.Pool.AutoCreate = AutoCreateDefault;
%%%

end

function [ messageMap ] = buildMessageMap(CSVLog)
%Build messageMap struct for importing logs later.

fileID = fopen(CSVLog,'r');
map = textscan(fileID, repmat('%s',1,400), 25, 'Delimiter', ',', 'TextType', 'char', 'ReturnOnError', false, 'EndOfLine', '\r\n');
map = [map{1:end}];

if isempty(map), error('Empty or incompatible CSV file!'); end

messageMap(length(map(:,1))) = struct('Name',[],'Fields',[],'Data',[],'time',[]);
for i = 1:length(map(:,1))
    
    messageMap(i) = struct('Name',map{i,1},'Fields',[],'Data',[],'time',[]);
    
    Fields = {map{i,3:end}};
    Fields(cellfun('isempty',Fields)) = [];
    
    idx=false(1,length(Fields));
    for j=1:length(Fields)
        if any(regexp(Fields{j},'[\[\]]'))
            idx(j)=true;
        else
            idx(j)=false;
        end
    end
    Fields(idx) =[];
    
    messageMap(i).Fields = Fields;
end

fclose(fileID);
end

function [messages] = fixTypes(messages)
if isempty(gcp('nocreate'))
    for i = 1:length(messages)
        if strcmp(messages(i).Name,'AcasXu'),continue;end
        for j = 1:length(messages(i).Data)
            temp = sscanf(messages(i).Data{j},'%f');
            if ~isempty(temp)
                messages(i).Data{j} = temp;
            end
        end
    end
else
    for i = 1:length(messages)
        if strcmp(messages(i).Name,'AcasXu'),continue;end
        for j = 1:length(messages(i).Data)
            temp = sscanf(messages(i).Data{j},'%f');
            if ~isempty(temp)
                messages(i).Data{j} = temp;
            end
            
        end
    end
end
end

function [merged] = mergeCells(Fields,Data)
merged = cell(1,numel(Fields)*2);
IDX = 1:numel(merged);

modVal = (mod(IDX,2)==0) ;

merged(IDX(~modVal)) = Fields;
merged(IDX(modVal)) = Data;
end

