function [spotlist,mask] = getspots(plgx,plgy,imgF,imgR,s2,dmax,dmapmsk,intensityIndex)
    mask = imdilate(poly2mask(double(plgx),double(plgy),size(imgF,1),size(imgF,2)),s2);
    if ~isempty(dmapmsk)
        mask = mask.*dmapmsk;
    end
    [row,col] = find(imgF.*mask);
    Y = col;
    X = row;
    Ly = length(row);
    spotlist = zeros(Ly,7);
    msk = zeros(dmax*2-1);
    msk(dmax,dmax)=1;
    msk = imdilate(msk,strel('disk',dmax));
    D2 = repmat(reshape((-dmax+1):(dmax-1),1,[]),2*dmax-1,1).^2 +...
         repmat(reshape((-dmax+1):(dmax-1),[],1),1,2*dmax-1).^2;

    % 1st fit - fixed positions, individual spots
    for sp = 1:Ly
        % Prepare matrices for minimization
        box1(1:2) = max([Y(sp) X(sp)]-dmax+1,1);
        box1(3:4) = min([Y(sp) X(sp)]+dmax-1,[size(imgR,2) size(imgR,1)])-box1(1:2);
        box2(1:2) = max(0,dmax-[Y(sp) X(sp)])+1;
        box2(3:4) = box1(3:4);
        img2 = imcrop(imgR,box1);
% % %         img2 = (img2-(intensityIndex*0.064)/1000);
        msk2 = imcrop(msk,box2).*imcrop(mask,box1);
        mskp = bwperim(imcrop(msk,box2));
        dst2 = imcrop(D2,box2);
%         dst2 = dst2.*(dst2<intensityIndex*100);
        % Assign data
        dat = [mean(mean(img2)) dmax max(0,img2(dmax-max(0,dmax-X(sp)),dmax-max(0,dmax-Y(sp)))-mean(mean(img2)))];
        % Do minimization
        options = optimset('Display','off','MaxIter',300);
        [dat,fval,exitflag] = fminsearch(@gfit,dat,options);
        % Save for later
        spotlist(sp,1) = dat(1); % background
        spotlist(sp,2) = dat(2); % squared width of the spots
        spotlist(sp,3) = dat(3); % hight
        spotlist(sp,4) = gfit(dat)/(dat(3)^2); % rel. sq. error
        spotlist(sp,5) = var(imgR(mskp))/(dat(3)^2); % perimeter variance
        spotlist(sp,6) = imgF(X(sp),Y(sp))/dat(3); % filtered/fitted ratio
        spotlist(sp,7) = exitflag; % exit -1 / 0 / 1
        spotlist(sp,8) = X(sp);
        spotlist(sp,9) = Y(sp);
        
    end
    function res = gfit(in)
        % also uses:
        % ls (list of spots to fit)
        % wf - squared width of the spots, only those for ~ls are used
        % hf - hight of the spots
        % in = [b wv(1:n) hv(1:n)]
        b = in(1);
        wv = in(2);
        hv = in(3);
        M = b + exp(-dst2/wv)*hv;
        R = (msk2.*(M - img2)).^2;
        res = sum(sum(R));
        if b<0, res=res+(b/hv)^2; end
    end
end