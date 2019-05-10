function [out]= mmin(array)
    %
    % returns the min value of a N dimensional array
    %
    out=min(array);
    n=ndims(array);
    if n>1
        for i=2:n
            out=min(out);
        end
    end
end