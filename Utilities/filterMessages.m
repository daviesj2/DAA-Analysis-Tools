function [messagesOut] = filterMessages(messages,field,match)
%   Filters LVC message structure by matching data within a specified field. 
%
%   Name: filterMessages.m [Function]   
%
%   INPUT: 
%       messages  [struct]: LVC message structure from getLVC().m
%       filter [double/char]: Message type or timespan of interest
%
%   OUTPUT:
%       messagesOut [struct]: LVC message structre that 
%                             contains matching data.
%
%   NOTES:
%       Example:
%           messagesOut = filterMessages(messages,'m_acid','NASA870');
%       
%             struct with fields:
% 
%             Name: 'MsgFlightPlan'
%           Fields: {1×34 cell}
%             Data: {1×34 cell}
%         UTC_Time: 1.500385866290933e+09
%
%   ToDo:
%
%       -Allow ranges of values using [hi lo] in match
%       -Indexing by Time and Name
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 13, 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~iscell(field), field={field}; end
if ~iscell(match), match={match}; end

messagesOut=messages;

for runs = 1:length(field)
    idx = false(1,length(messagesOut));

    for i = 1:length(messagesOut)
        fieldnum = find(strcmp(messagesOut(i).Fields,field{runs}));
        if ~isempty(fieldnum)
            if ischar(match{runs}) 
                if any(any(regexp(messagesOut(i).Data{fieldnum},match{runs})))
                    idx(i)=true;
                else
                    idx(i)=false;
                end
            end
            if isnumeric(match{runs}) 
                if (messagesOut(i).Data{fieldnum} == match{runs})
                    idx(i)=true;
                else
                    idx(i)=false;
                end
            end
        end
    end
    messagesOut=messagesOut(idx);
end