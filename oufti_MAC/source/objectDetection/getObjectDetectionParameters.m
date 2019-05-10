function params = getObjectDetectionParameters(handles1)


%declare default parameters
params.ManualBGSel      = 0.1; %image magnitude to be declared as background, if 0, other background subtraction algo will be used
params.BGFilterSize     = 8; %filter size for bandpass filtering, used in background subtraction
params.BGFilterThresh   = 0.1; %threshold value for background subtraction, applied to output of otsu's method
params.logSigma         = 3; %sigma of laplacian of gaussian filter
params.magnitudeLog     = 0.1; %magnitude parameter of LoG filter
params.subPixelRes      = 0.1; %sampling rate...actually inverse, so .1 means to sample each px 10 times
params.psfSigma         = 1.62; %extra pixels to pad around the cell prior to filtering
params.inCellPercent    = 0.4; %the fraction of the nucleoid that must be within the cell mesh to save
params.minObjectArea    = 50; %obvious...
params.reSampleOutline  = 1; %bool
params.BGMethod         = 3; %sets the method...we can discuss/eliminate some of the BG methods
params.ModValue         = 1; 


try
    if  isstruct(handles1.objectDetection) 
        params.ManualBGSel      = str2double(get(handles1.objectDetection.ManualBGSel,'string'));
        params.BGFilterSize     = str2double(get(handles1.objectDetection.BGFilterSize,'string'));
        params.BGFilterThresh   = str2double(get(handles1.objectDetection.BGThreshold,'string'));
        params.logSigma         = str2double(get(handles1.objectDetection.logSigma,'string'));
        params.magnitudeLog     = str2double(get(handles1.objectDetection.magnitudeLog,'string'));
        params.subPixelRes      = params.subPixelRes;
        params.psfSigma         = str2double(get(handles1.objectDetection.psfSigma,'string'));
        params.inCellPercent    = str2double(get(handles1.objectDetection.inCellPercent,'string'));
        params.minObjectArea    = str2double(get(handles1.objectDetection.minObjectArea,'string'));
        params.BGMethod         = str2double(get(handles1.objectDetection.BGMethod,'string'));
        params.reSampleOutline  = 1;
    end

 catch err
       disp(err.message);
       return;
end


end %getObjectDetectionParameters