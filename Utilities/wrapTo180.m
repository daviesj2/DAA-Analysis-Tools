function[n180]=wrapTo180(n)
%   Wraps input to +/- 180
%
%   -180 < n180 < 180
%   trigd(n180) == trigd(n)
%%%%

n180 = n; %Copy structure and preallocate
for i = 1:numel(n180)
    n180(i)=mod(n180(i),360);
    if n180(i) > 180
        n180(i) = n180(i)-360;
    end
end