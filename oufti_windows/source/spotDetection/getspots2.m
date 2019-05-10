function spotlist2 = getspots2(spotlist,imgR,mask,wmax,dmax,shiftlim)
    if isempty(spotlist); spotlist2 = []; return; end
    X = spotlist(:,8);
    Y = spotlist(:,9);
    m = size(imgR,1);
    n = size(imgR,2);
    Ly = size(spotlist,1);
    Xm = repmat(reshape(X,[1 1 Ly]),m,n);
    Ym = repmat(reshape(Y,[1 1 Ly]),m,n);
    Ix2 = repmat((1:m)',[1 n]);
    Iy2 = repmat(1:n,[m 1]);
    wf = spotlist(:,2);
    hf = spotlist(:,3);
    bf = spotlist(:,1);
    % bf = mean(b);
    Ix3 = repmat((1:m)',[1 n Ly-1]);
    Iy3 = repmat(1:n,[m 1 Ly-1]);
    spotlist2 = zeros(size(spotlist));
    msk = zeros(dmax*2-1);
    msk(dmax,dmax)=1;
    msk = imdilate(msk,strel('disk',dmax));
    D2 = repmat(reshape((-dmax+1):(dmax-1),1,[]),2*dmax-1,1).^2 +...
         repmat(reshape((-dmax+1):(dmax-1),[],1),1,2*dmax-1).^2;
    % 2nd fit - flexible positions
    for q = 1:2
        for sp = 1:Ly
            % Assign variable data
            box1(1:2) = max([Y(sp) X(sp)]-dmax+1,1);
            box1(3:4) = min([Y(sp) X(sp)]+dmax-1,[size(imgR,2) size(imgR,1)])-box1(1:2);
            box2(1:2) = max(0,dmax-[Y(sp) X(sp)])+1;
            box2(3:4) = box1(3:4);
            img2 = imcrop(imgR,box1);
            msk2 = imcrop(msk,box2).*imcrop(mask,box1);
            dst2 = imcrop(D2,box2);
            dat = [bf(sp) wf(sp) hf(sp) X(sp) Y(sp)];
            % Assign fixed data
            ls = true(1,Ly);
            ls(sp) = false;
            W = repmat(reshape(wf(ls),[1 1 Ly-1]),m,n);
            H = repmat(reshape(hf(ls),[1 1 Ly-1]),m,n);
            Xm3 = repmat(reshape(X(ls),[1 1 Ly-1]),m,n);
            Ym3 = repmat(reshape(Y(ls),[1 1 Ly-1]),m,n);
            D3 = (Xm3-Ix3).^2 + (Ym3-Iy3).^2;
            M0 = sum(exp(-D3./W).*H,3);
            % Do minimization
            options = optimset('Display','off','MaxIter',300);
            [dat,fval,exitflag] = fminsearch(@gfitpos,dat,options);
            bf(sp) = dat(1);
            wf(sp) = dat(2);
            hf(sp) = dat(3);
            X(sp) = dat(4);
            Y(sp) = dat(5);

            spotlist2(sp,1) = dat(1); % background
            spotlist2(sp,2) = dat(2); % spot width
            spotlist2(sp,3) = dat(3); % hight
            spotlist2(sp,4) = gfit(dat)/(dat(3)^2); % rel. sq. error
            % fields 5 & 6 are not filled in second pass
            spotlist2(sp,7) = exitflag; % exit -1 / 0 / 1
            spotlist2(sp,8) = dat(4);
            spotlist2(sp,9) = dat(5);
        end %
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
        x0 = spotlist(sp,8);
        y0 = spotlist(sp,9);
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