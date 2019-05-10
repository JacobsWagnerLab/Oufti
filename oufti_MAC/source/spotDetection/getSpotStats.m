function spotlist2 = getSpotStats(spotlist,imgR,mask,wmax,dmax,shiftlim,bf)
    spotlist = double(spotlist);
    if isempty(spotlist); spotlist2 = []; return; end
    X = round(spotlist(:,1));
    Y = round(spotlist(:,2));
    m = size(imgR,1);
    % % % %Fitting includes four unknowns, need 4 pixels to produce 4 eq.
% % %     msize = 0.25; % Prefilter range, must be >0
% % %     x = repmat(1:ceil(msize)*2+1,ceil(msize)*2+1,1);
% % %     y = repmat((1:ceil(msize)*2+1)',1,ceil(msize)*2+1);
% % %     prefilter = exp(-((ceil(msize)+1-x).^2 + (ceil(msize)+1-y).^2) / msize^2);
% % %     prefilter = prefilter/sum(sum(prefilter));
% % %     imgR = imfilter(imgR,prefilter,'replicate');
    imgR = im2double(imgR);
    n = size(imgR,2);
    Ly = size(spotlist,1);
    Xm = repmat(X,m,n);
    Ym = repmat(Y,m,n);
    Ix2 = repmat((1:m)',[1 n]);
    Iy2 = repmat(1:n,[m 1]);
    wf = spotlist(:,3);
    hf = spotlist(:,4);
    % bf = mean(b);
    Ix3 = repmat((1:m)',[1 n Ly]);
    Iy3 = repmat(1:n,[m 1 Ly]);
    spotlist2 = zeros(size(spotlist));
    msk = zeros(dmax*2-1);
    msk(dmax,dmax)=1;
    msk = imdilate(msk,strel('disk',dmax));
    D2 = repmat(reshape((-dmax+1):(dmax-1),1,[]),2*dmax-1,1).^2 +...
         repmat(reshape((-dmax+1):(dmax-1),[],1),1,2*dmax-1).^2;
    % 2nd fit - flexible positions
    for q = 1:3
            % Assign variable data
            msk2 = msk;
            dst2 = D2;
            dat = [bf wf hf X Y];
            % Assign fixed data
            ls = true(1,Ly);
            ls = false;
            W = repmat(reshape(wf,[1 1 1]),m,n);
            H = repmat(reshape(hf,[1 1 1]),m,n);
            Xm3 = repmat(reshape(X,[1 1 1]),m,n);
            Ym3 = repmat(reshape(Y,[1 1 1]),m,n);
            D3 = (Xm3-Ix3).^2 + (Ym3-Iy3).^2;
            M0 = sum(exp(-D3./W).*H,3);
            % Do minimization
            options = optimset('Display','off','MaxIter',300);
            [dat,fval,exitflag] = fminsearch(@gfitpos,dat,options);
            bf = dat(1);
            wf = dat(2);
            hf = dat(3);
            X = dat(4);
            Y = dat(5);

            spotlist2(1) = dat(1); % background
            spotlist2(2) = dat(2); % spot width
            spotlist2(3) = dat(3); % hight
% % %             spotlist2(4) = gfit(dat)/(dat(3)^2); % rel. sq. error
            % fields 5 & 6 are not filled in second pass
% % %             spotlist2(7) = exitflag; % exit -1 / 0 / 1
            spotlist2(4) = dat(4);
            spotlist2(5) = dat(5);
    end
    function res = gfit(in)
        b = in(1);
        wv = in(2);
        hv = in(3);
        M = b + exp(-dst2/wv)*hv;
        R = (msk2.*(M - img2)).^2;
        res = sum(sum(R));
    end
    function res = gfitpos(in)
        % also uses:
        % ls (indicates the spot to fit)
        % wf - width of the spot
        % hf - hight of the spot
        % in = [b wv(1:n) hv(1:n)]
        b = in(1);
        wv = in(2);
        hv = in(3);
        xv = in(4);
        yv = in(5);
        x0 = spotlist(1);
        y0 = spotlist(2);
        Xm = repmat(xv,m,n);
        Ym = repmat(yv,m,n);
        D2a = (Xm-Ix2).^2 + (Ym-Iy2).^2;
        M = M0 + b + exp(-D2a/wv)*hv;
        R = (mask.*(M - imgR)).^2;
        if isempty(shiftlim)||shiftlim<0, shiftlim = 0.01; end
        res = sum(sum(R))*(1+shiftlim*((x0-xv)^2+(y0-yv)^2))*(1+max(0,wv/wmax-1)^2)*(1+min(0,hv/mean(hf))^2);
        if b<0, res=res+(b/hv)^2; end
    end
end