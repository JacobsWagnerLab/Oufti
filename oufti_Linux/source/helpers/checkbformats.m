function res = checkbformats(varargin)
% res = checkbformats
% res = checkbformats(loadcheck)
% 
% This function checks if BioFormats is loaded and loads it if gets a
% parameter <loadcheck> equal to 1 (ir is the paremter is missing). Just
% checks if the parameter is zero.

a = javaclasspath('-all');
b = strfind(a,'loci_tools.jar');
res = false;
for i = 1:length(a)
    res = res || ~isempty(b{i});
end
if length(varargin)>=1 && varargin{1}==1
    if ~res
        currentdir = fileparts(mfilename('fullpath'));
        bformatspath = fullfile(currentdir,'loci_tools.jar');
        if ~isempty(dir(bformatspath))
            javaaddpath(bformatspath);
            res = true;
        end
    end
end