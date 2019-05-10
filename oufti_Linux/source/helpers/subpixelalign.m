function [images2,clist2,shiftframes]=subpixelalign(images,varargin)
% [images2,cellList2,shiftframes]=subpixelalign(images,cellList,depth)
%
% This function aligns images with subpixel resulution. It outputs the
% shifted stack of images (which may include interpolated images) and a
% shifted cellList (in MicrobeTracker format), produced from an input
% cellList, assumed to be obtained by replication of the first frame.
% 
% images - input stack of images, either obtained by loadimageseries 
%     command or the internal one of Microbetracker (accessable if you type
%     "global rawPhaseData"/"global rawS1Data"/"global rawS2Data" while
%     MicrobeTracker is loaded).
% cellList - input cellList, typically obtained by replication of the first 
%     frame.
% depth - number of frames to be taken into accoun while aligning. Default:
%     100; increase if little growth, noise; decrease otherwise.
% images2 - output stack, could be interpolated, which reduces quality
% cellList2 - output cellList, shifted original one to match the drift.
% shiftframes - structure with x and y fields containing shift coordinates.

if ~isempty(varargin)
    clist = varargin{1};
else
    clist = [];
end
if length(varargin)>=2
    depth = varargin{2};
else
    depth = 100;
end
[shiftY,shiftX]=alignframes(images,depth);
images2 = shiftimages(images,shiftX,shiftY);
if ~isempty(clist)
    clist2 = shiftclist(clist,shiftX,shiftY);
else
    clist2 = [];
end
shiftframes.x = shiftX;
shiftframes.y = shiftY;
end

 
function [shiftX,shiftY]=alignframes(A,depth)
    
    mrg = round(min(size(A,1),size(A,2))*0.05);
    % fld = [size(A,1)-2*mrg size(A,2)-2*mrg];
    time1 = clock;
    x0=[0 1 1 0 -1 -1 -1 0 1];
    y0=[0 0 1 1 1 0 -1 -1 -1];
    nframes = size(A,3);
    memory = double(A(:,:,1));
    score = zeros(1,9);
    shiftX = zeros(1,nframes);
    shiftY = zeros(1,nframes);
    for frame=2:nframes
        imtimage = getintimage(double(A(:,:,frame-1)),shiftX(frame-1),shiftY(frame-1));
        memory = memory*(1-1/depth) + double(imtimage)/depth;
        cframe = double(A(:,:,frame));
        [xF,yF] = alignoneframeI(cframe,memory,shiftX(frame-1),shiftY(frame-1),mrg,8);
        [xF,yF] = alignoneframeI(cframe,memory,xF,yF,mrg,4);
        [xF,yF] = alignoneframeI(cframe,memory,xF,yF,mrg,2);
        [xF,yF] = alignoneframeI(cframe,memory,xF,yF,mrg,1);
        [xF,yF] = alignoneframeI(cframe,memory,xF,yF,mrg,0.5);
        [xF,yF] = alignoneframeI(cframe,memory,xF,yF,mrg,0.25);
        [xF,yF] = alignoneframeI(cframe,memory,xF,yF,mrg,0.125);
        [xF,yF] = alignoneframeI(cframe,memory,xF,yF,mrg,0.0625);
        shiftX(frame) = xF;
        shiftY(frame) = yF;
        disp(['frame = ' num2str(frame) ', shift ' num2str(xF) ',' num2str(yF) ' pixels'])
    end
    time2 = clock;
    disp(['Finised, elapsed time ' num2str(etime(time2,time1)) ' s']);  
    
    function res = getintimage(img,x,y)
        sz1 = size(img,2);
        sz2 = size(img,1);
        sz1v = 1:sz1;
        sz2v = 1:sz2;
        sz1o = sz1*ones(1,sz1);
        sz2o = sz2*ones(1,sz2);
        [sz1m,sz2m] = meshgrid(sz1v,sz2v);
        [sz1n,sz2n] = meshgrid(mod(sz1v+x-1,sz1o)+1,mod(sz2v+y-1,sz2o)+1);
        res = interp2(sz1m,sz2m,img,sz1n,sz2n);
    end

    function [x,y] = alignoneframeI(cframe,memory,x,y,margin,factor)
        cframetmp = cframe(margin+1:end-margin,margin+1:end-margin);
        memorytmp = memory(margin+1:end-margin,margin+1:end-margin);
        field = [size(cframe,2)-2*margin size(cframe,1)-2*margin];
        % k=0;
        % while true
            dmax = ceil(max(abs(x),abs(y))+abs(factor));
            px = mod([x-factor x x+factor],1); px = min(px,1-px); pxmax = max(px);
            py = mod([y-factor y y+factor],1); py = min(py,1-py); pymax = max(py);
            for j=1:9
                dx = x + x0(j)*factor;
                dy = y + y0(j)*factor;
                fieldX1 = 1+dmax:field(1)-dmax;
                fieldY1 = 1+dmax:field(2)-dmax;
                fieldX2 = fieldX1+dx;
                fieldY2 = fieldY1+dy;
                [fieldXm ,fieldYm ] = meshgrid(1:field(1),1:field(2));
                [fieldX2m,fieldY2m] = meshgrid(fieldX2,fieldY2);
                memorytmp2 = memorytmp(fieldY1,fieldX1);
                cfieldtmp2 = interp2(fieldXm,fieldYm,cframetmp,fieldX2m,fieldY2m);
                
                px1 = mod(dx,1);
                px1 = min(px1,1-px1);
                px = (pxmax-px1)/(1-2*px1);
                cfieldtmp2 = (1-px)*cfieldtmp2 + (px/2)*(cfieldtmp2([2:end end],:)+cfieldtmp2([1 1:end-1],:));
                
                py1 = mod(dy,1);
                py1 = min(py1,1-py1);
                py = (pymax-py1)/(1-2*py1);
                cfieldtmp2 = (1-py)*cfieldtmp2 + (py/2)*(cfieldtmp2(:,[2:end end])+cfieldtmp2(:,[1 1:end-1]));
                
                score(j) = corel(memorytmp2,cfieldtmp2);
                % figure;imshow(cfieldtmp2,[]);set(gca,'pos',[0 0 1 1]);set(gcf,'pos',[1200 100 500 500])
            end
            % figure;imshow(memorytmp2,[]);set(gca,'pos',[0 0 1 1]);set(gcf,'pos',[1200 100 500 500])
            % score
            [scmax,ind] = max(score);
            % k=k+1;
            % if ind==1, break; end
            x = x + x0(ind)*factor;
            y = y + y0(ind)*factor;
        % end
    end
end

function B = shiftimages(A,shiftX,shiftY)
    B = ones(size(A),class(A));
    for frame = 1:size(A,3)
        xJ = shiftY(frame);
        yJ = shiftX(frame);
        field = [size(A,2) size(A,1)];
        fieldX1 = 1:field(1);
        fieldY1 = 1:field(2);
        fieldX2 = fieldX1+xJ;
        fieldY2 = fieldY1+yJ;
        [fieldXm ,fieldYm ] = meshgrid(1:field(1),1:field(2));
        [fieldX2m,fieldY2m] = meshgrid(fieldX2,fieldY2);
        A1 = double(A(:,:,frame));
        B(:,:,frame) = uint16(interp2(fieldXm,fieldYm,A1,fieldX2m,fieldY2m,'linear',mean(mean(A1))));
    end
end

function B = shiftclist(A,shiftX,shiftY)
    B = A;
    for frame = 1:min([length(A) length(shiftX) length(shiftY)])
        xJ = shiftX(frame);
        yJ = shiftY(frame);
        if length(A)>=frame && ~isempty(A{frame})
            for cell=1:length(A{frame})
                if ~isempty(A{frame}{cell}) && isfield(A{frame}{cell},'mesh') && length(A{frame}{cell}.mesh)>1
                    B{frame}{cell}.mesh(:,[1 3]) = A{frame}{cell}.mesh(:,[1 3])+yJ;
                    B{frame}{cell}.mesh(:,[2 4]) = A{frame}{cell}.mesh(:,[2 4])+xJ;
                end
            end
        end
    end
end

function y=corel(X,Y)
y = mean(mean((X-mean(mean(X))).*(Y-mean(mean(Y)))));
end