function parseparameters(str)
    % takes parameters string (loaded or modified by the user) and updates
    % the global variable "p" - parameters structure
    global p handles
    names = {};
    values = {};
    if length(str)==1, str = str{1}; end
    for i=1:length(str)
        res = textscan([char(str{i}) ' '], '%s%s', 'commentstyle', '%','delimiter','=');
        if ~isempty(res{1})
            names = [names res{1}];
            values = [values res{2}];
        end
    end
    try
        if isfield(handles, 'segmentationRun')
            if handles.segmentationRun == 0, p = []; end
        end
        for i=1:length(names)
            try
                if ~isempty(str2num( values{i}))
                    eval(['p.' names{i} '=[' values{i} '];']);
                else
                    eval(['p.' names{i} '=[' char(39) strtrim(values{i}) char(39) '];']);
                end
            catch
                continue;
            end
        end
        % Temporarily added for new parameters
        if ~isfield(p,'aligndepth'), p.aligndepth = 1; end
        if isfield(p,'algorithm')
            if strcmpi(p.algorithm,'pixel'), p.algorithm = 1;
            elseif strcmpi(p.algorithm,'subpixel'),p.algorithm = 4;
            end
        end
        if ~isfield(p,'getmesh'), p.getmesh = true; end
        if ~isfield(p,'meshStep'), p.meshStep = 1; end
        if ~isfield(p,'fmeshstep'), p.fmeshstep = p.meshStep; end
        if ~isfield(p,'scaleFactor'), p.scaleFactor = 1; end
        if ~isfield(p,'meshTolerance'), p.meshTolerance = 0.01; end
        if ~isfield(p,'meshWidth') && ~isfield(p,'cellwidth'), p.meshWidth = 12; end
        if ~isfield(p,'meshWidth') && isfield(p,'cellwidth'), p.meshWidth = p.cellwidth*1.5; end % !!!
        if ~isfield(p,'neighRepA'), p.neighRepA = 0; end
        if ~isfield(p,'useExtraData'), p.useExtraData = false; end
        if ~isfield(p,'invertimage'), p.invertimage = 0; end
        if ~isfield(p,'maxRegNumber'), p.maxRegNumber = 1000000; end
        if ~isfield(p,'joindilate'), p.joindilate = 1; end
        if ~isfield(p,'fitConvLevel1'), p.fitConvLevel1 = 0.0001;end
%             if isfield(p,'edgedetection') && ~p.edgedetection, p.edgemode = 'none'; end
        if ~isfield(p,'edgeSigmaL'), p.edgeSigmaL = 1; end
%         if ~isfield(p,'edgeSigmaV'), p.edgeSigmaV = 0.5; end
%         if ~isfield(p,'valleythresh1'), if isfield(p,'valleythres1'), p.valleythresh1 = p.valleythres1*300; else p.valleythresh1 = 0; end; end
%         if ~isfield(p,'valleythresh2'), if isfield(p,'valleythres2'), p.valleythresh2 = p.valleythres2*300; else p.valleythresh2 = 1; end; end
        if ~isfield(p,'fitDisplay'), p.fitDisplay = false; end
        if ~isfield(p,'fitDisplay1'), p.fitDisplay1 = false; end
        if get(handles.aligntest,'Value'), p.fitDisplay=1; p.fitDisplay1=1; end
        if ~isfield(p,'opennum'), p.opennum = 0; end
        if ~isfield(p,'threshminlevel'), p.threshminlevel = 0; end
        if ~isfield(p,'approxSignal'), p.approxSignal = 0; end
        if ~isfield(p,'forceindframes'), p.forceindframes = 0; end
        if ~isfield(p,'runSerial'), p.runSerial = 0;end
        if ~isfield(p,'maxWorkers'),p.maxWorkers = 12;end
        if ~isfield(p,'wShedNum'),p.wShedNum = 3200;end
        if ~isfield(p,'displayW'),p.displayW = 0; end
        if ~isfield(p,'outCsvFormat'),p.outCsvFormat = 0;end
        if ~isfield(p,'stopButton'),p.stopButton = 0;end
        if ~isfield(p,'pauseButton'),p.pauseButton = 0;end
        if ~isfield(p,'bgrErodeNum'),p.bgrErodeNum = 5;end
        if ~isfield(p,'gradSmoothArea'),p.gradSmoothArea = 0.5;end
        if ~isfield(p,'forceWeights'),p.forceWeights = [0.25 0.5 0.25];end
        if ~isfield(p,'maxCellNumber'),p.maxCellNumber = 10000000;end
        if ~isfield(p,'maxmesh'),p.maxmesh = 1000000;end
        if ~isfield(p,'rigidityRange'),p.rigidityRange = 2.5;end
        if ~isfield(p,'rigidityRangeB'),p.rigidityRangeB = 8;end
        if ~isfield(p,'horalign'),p.horalign = 0.2;end
        if ~isfield(p,'eqaldist'),p.eqaldist = 2.5;end
        if ~isfield(p,'dmapThres'),p.dmapThres = 2;end
        if ~isfield(p,'dmapPower'),p.dmapPower = 2;end
        if ~isfield(p,'maxRegNumber'),p.maxRegNumber = 10000;end
        if ~isfield(p,'sgnResize'),p.sgnResize = 1;end
        if ~isfield(p,'aligndepth'),p.aligndepth = 1;end
        if ~isfield(p,'joinWhenReuse'),p.joinWhenReuse = 0;end
        if ~isfield(p,'split1'),p.split1 = 1;end
        if ~isfield(p,'attrRegion'),p.attrRegion = 1;end
        if ~isfield(p,'attrPower'),p.attrPower = 6;end
        if ~isfield(p,'repArea'),p.repArea = 0.9;end
        if ~isfield(p,'fitqualitymax'),p.fitqualitymax = 0.65;end
        if ~isfield(p,'fitCondition'),p.fitCondition = 0.0;end
      
  


    catch
        errordlg('The format of one or more parameters is incorrect or parameters missing');
        return;
    end
end