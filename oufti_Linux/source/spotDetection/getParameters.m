function params = getParameters(handles1,params)
try
if ishandle(handles1.postProcessButton) && isfield(handles1,'postMinWidth') && ishandle(handles1.postMinWidth)
   params.postMinWidth  = str2double(get(handles1.postMinWidth,'string'));
   params.postMaxWidth  = str2double(get(handles1.postMaxWidth,'string'));
   params.postMinHeight = str2double(get(handles1.postMinHeight,'string'));
   params.postError     = str2double(get(handles1.postError,'string'));
end
 if get(handles1.filtWin,'value') == 1 
     params.filtWin = get(handles1.filtWin,'value');
 else
     params.filtWin = 0;
 end
% % %    params.intensityThresh   = str2num(get(handles1.intensityThresh,'string'));
% % %    params.sigmaPsf          = str2double(get(handles1.sigmaPsf,'string'));
% % %    params.minArea           = str2double(get(handles1.minArea,'string'));
% % %    params.maxArea           = str2double(get(handles1.maxArea,'string'));
% % %    params.COM               = 1;
% % % else
   params.intensityThresh  = 0;
   params.spotRadius       = 0;
   params.minArea          = 0;
   params.maxArea          = 120;
   params.lowPass          = 2;
% % %    params.COM              = 0;
% % % end
% % % if get(handles1.GAU,'value') == 1
% % %     params.GAU = 1;
% % % else
% % %     params.GAU = 0;
% % % end
params.scale             = str2double(get(handles1.scale,'string'));
params.lowPass           = str2double(get(handles1.lowPass,'string'));
params.spotRadius          = str2double(get(handles1.spotRadius,'string'));
params.minRegionSize     = str2double(get(handles1.minRegionSize,'string'));
params.int_threshold         = str2double(get(handles1.int_threshold,'string'));
params.fitRadius         = str2double(get(handles1.fitRadius,'string'));
params.multGauss         = get(handles1.multGauss,'value');
catch err
    disp(err.message);
    return;
end
end