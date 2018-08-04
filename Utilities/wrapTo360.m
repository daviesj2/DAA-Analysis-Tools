function[out] = wrapTo360(in)
%   Wraps input to 360
%      
%   Input/Output is (N x M x ...)   
%
%   0 < out < 360
%   trigd(out) == trigd(n)
%%%%
out = in; %Copy structure and preallocate
for i = 1:numel(in)
    out(i) = mod(in(i),360);
end