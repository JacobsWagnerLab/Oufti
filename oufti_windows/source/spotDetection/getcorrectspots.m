function lst = getcorrectspots(spotlist,params,intensityIndex)
    global paramsHistoryVector
    scalefactor=params.scalefactor;
    if isempty(paramsHistoryVector.wmax) 
        wmax = params.wmax*scalefactor; % max width in pixels
        wmin = params.wmin*scalefactor;
        hmin = params.hmin; % min height
        ef2max = params.ef2max; % max relative squared error
        vmax = params.vmax; % max ratio of the variance to squared spot height
        fmin = params.fmin; % min ratio of the filtered to fitted spot (takes into account size and shape)
    else
        wmax   = max(paramsHistoryVector.wmax)*scalefactor;
        wmin   = min(paramsHistoryVector.wmin)*scalefactor;
        hmin   = min(paramsHistoryVector.goodArray.hmin);
        ef2max = max(paramsHistoryVector.ef2max);
        vmax   = max(paramsHistoryVector.vmax);
        fmin   = min(paramsHistoryVector.fmin);
    end
    lst = ...%spotlist(:,1)<((intensityIndex*0.064)/1000) & ...
          spotlist(:,2)<wmax & spotlist(:,2)>wmin & spotlist(:,3)>hmin ...
        & spotlist(:,4)<ef2max ...
        & (spotlist(:,5)<vmax | spotlist(:,5)==0) ... % OK if zero
        & spotlist(:,6)>fmin ...
        & spotlist(:,7)==1;

end