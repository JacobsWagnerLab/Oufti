function res = checkparam(p,varargin)
    % this function checks if at least one of the provided parameters is
    % missing
    res = false;
    if isempty(p)
        res = true;
    end
    for i=1:length(varargin)
        if ~isfield(p,varargin{i})
            res = true;
        end
    end
end