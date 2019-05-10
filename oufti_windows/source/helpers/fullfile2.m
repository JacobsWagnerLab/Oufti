function res = fullfile2(varargin)
    % This function replaces standard fullfile function in order to correct
    % a MATLAB bug that appears under Mac OS X
    % It produces results identical to fullfile under any other OS
    arg = '';
    for i=1:length(varargin)
        if ~strcmp(varargin{i},'\') && ~strcmp(varargin{i},'/')
            if i>1, arg = [arg ',']; end
            arg = [arg '''' varargin{i} ''''];
        end
    end
    eval(['res = fullfile(' arg ');']);
end