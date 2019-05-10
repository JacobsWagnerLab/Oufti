function [def_params] = defparameters(nparam)

%declare default parameters
def_params.ManualBGSel = 0.1; %image magnitude to be declared as background, if 0, other background subtraction algo will be used
def_params.BGFilterSize=8; %filter size for bandpass filtering, used in background subtraction
def_params.BGFilterThresh=.21; %threshold value for background subtraction, applied to output of otsu's method
def_params.LoG_sigma = 3; %sigma of laplacian of gaussian filter
def_params.magnitude = .1; %magnitude parameter of LoG filter
def_params.res = .1; %sampling rate...actually inverse, so .1 means to sample each px 10 times
def_params.zx = 0; %zero-crossing, LoG
def_params.cellpad = 10; %extra pixels to pad around the cell prior to filtering
def_params.incellpercent = .4; %the fraction of the nucleoid that must be within the cell mesh to save
def_params.min_nucleoid_area = 50; %obvious...
def_params.ReSampleOutline =1; %bool
def_params.BGMethod = 3; %sets the method...we can discuss/eliminate some of the BG methods
def_params.ModValue = 1; 

fni = fieldnames(nparam);
fnd = fieldnames(def_params);

for k = 1:length(fni)
    if isempty(nparam.(fni{k})), continue, end
    
    for t = 1:length(fnd)
        if (strcmpi(fni{k},fnd{t}))
            def_params.(fnd{t}) = nparam.(fni{k});
        end
    end
end