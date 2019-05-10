function ctrlist = interpoutline(cCell,img2,p)

% LoG filter
if p.interpSigma(1)<0.01, p.interpSigma(1)=0.01; end
fsize = ceil(p.interpSigma(1)*3)*2 + 1;
op = fspecial('log',fsize,p.interpSigma(1)); 
op = op - sum(op(:))/numel(op);
img1 = imfilter(img2,op,'replicate');
img1 = -img1/2/std(img1(:));

% Smoothing the original image
if isfield(p,'interpSigma') && p.interpSigma(2)>0
    gradSmoothFilter = fspecial('gaussian',2*ceil(1.5*p.interpSigma(2))+1,p.interpSigma(2));
    img2 = imfilter(img2,gradSmoothFilter);
end

% Create the mask around original contour
interpoutlinestep = 7;
se = strel('disk',interpoutlinestep);
mask = poly2mask(cCell(:,2),cCell(:,1),size(img2,1),size(img2,2));
mask = imdilate(mask,se);
img2 = img2.*mask;
thr = graythresh(img2(mask))*p.thresFactorF*p.interpWeights(2);

% Combine the LoG-filtered and Gaussian-filtered images and get the contour
img2 = p.interpWeights(1)*img1.*mask + p.interpWeights(2)*img2;

% Get the new contour or contours
c = contourc(img2,[thr thr]);
ctrlist = {};

% Create a structure holding 
ind = 1;
[x1,y1] = poly2cw(cCell(:,1),cCell(:,2));
while ind<size(c,2)
    ctrtmp = fliplr(c(:,ind+1:ind+c(2,ind))');
    [x2 y2] = poly2cw(ctrtmp(:,1),ctrtmp(:,2));
    ind = ind+c(2,ind)+1;
    [x,y]=polybool('intersection',x1,y1,x2,y2);
    area2 = polyarea(x2,y2);
    x(isnan(x))=[];
    y(isnan(y))=[];
    area = polyarea(x,y);
    if area>=p.areaMin && area<p.areaMax && area>area2/2
        ctrlist = [ctrlist [x2 y2]];
    end
end