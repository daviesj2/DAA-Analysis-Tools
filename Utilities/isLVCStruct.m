function [out]=isLVCStruct(input)

LVCfields = {'Name' 'Data' 'time' 'HumanTime'};

if isstruct(input) && all(ismember(fieldnames(input),LVCfields))
    out=true;
else
    out=false;
end