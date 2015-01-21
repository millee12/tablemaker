function [fluid] = quirks(fluid,str,n)
%Fixes quirks in data tables such as:
%1. Quality tables often contain 999 and -999, because the lookup is meant to
%produce values only in the saturated l-v region
%2. Where refprop is unable to return values, NaN has been used as a
%placeholder.  This symbol is inadmissable in simulink, and must be
%replaced with a finite, real number.  In this case:
%2. tables that are majority Nan are deleted
%3. NaN is replaced with the value of the nearest neighbor in usable tables.

%1. Check Quality Tables
if strcmp(str(1),'Q')
    fluid.(str)(fluid.(str) > 1)=1;
    fluid.(str)(fluid.(str) < 0)=0;
end

%2. Remove unuseable tables
if sum(sum(isnan(fluid.(str)))) >= .5*n^2
    fluid=rmfield(fluid,str);
    return
end

%3. Replace NaN with nearest neighbor
    k=0;
while sum(sum(isnan(fluid.(str)))) > 0
    [r,c]=find(isnan(fluid.(str)),1);
    v=NaN;
    %Try Neighboring Row
    if isnan(v)
        try
            v=fluid.(str)(r+k,c);
        catch
        end
    end
    %Try Neighboring Column
    if isnan(v)
        try
            v=fluid.(str)(r,c+k);
        catch
        end
    end
    %Try Neighboring Diagonal
    if isnan(v)
        try
            v=fluid.(str)(r+k,c+k);
        catch
        end
    end
    % Change Counter
    if isnan(v)
        if k <= 0
            k=-k+1;
        else
            k=-k;
        end
        if abs(k) > n
            error('unable to remove NaN' )
        end
    else
        fluid.(str)(r,c)=v;
        k=0;
    end
end
end

