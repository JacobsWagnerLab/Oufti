function [out]= mmax(array)
    %
    % returns the max value of a N dimensional array
    %
    out=max(array);
    n=ndims(array);
    if n>1
        for i=2:n
            out=max(out);
        end
    end
end