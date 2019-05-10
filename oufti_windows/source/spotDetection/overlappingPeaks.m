function [spot_x, spot_y, sigma, rmse] = overlappingPeaks(im,cellList,Frame,Cell,maxdx,blockR,sigmaCutoff,MinSpotPixels)
% maxdx = 3; %Maximum radius from a peak to consider for fitting
% blockR = 3; %Radius that other spots should be blocked from a spot currently being fitted
% SigmaCutoff = 1.5; %Any peak must be > mean(backgroundpixels) + SigmaCutoff*std(backgroundpixels)
% MinSpotPixels = 10; %Minimum number of pixels a spot must have in order to attempt fitting
%
%Brad Parry; November 2012
tic;
spot_x = [];
spot_y = [];
sigma = [];
rmse = [];

if MinSpotPixels < 4
    %Fitting includes four unknowns, need 4 pixels to produce 4 eq.
    MinSpotPixels = 4;
end

raw = imcrop(im,cellList{Frame}{Cell}.box);
[r,c] = size(raw);
co = cat(1,cellList{Frame}{Cell}.mesh(:,1:2),flipud(cellList{Frame}{Cell}.mesh(:,3:4))) + 1;
%subtract off box, one dimension at a time to avoid using repmat
co(:,1) = co(:,1) - cellList{Frame}{Cell}.box(1);
co(:,2) = co(:,2) - cellList{Frame}{Cell}.box(2);
cellmask = single(poly2mask(co(:,1),co(:,2),r,c));

%pad the cell mask with ones -- this method is WAY (~100x) faster than the
%built in f'n imdilate for this purpose
dilcellm = conv2(cellmask,ones(3),'same');
% the convolution will have summed a bunch of neighboors together, bring it
% back to 0's and 1's
dilcellm(dilcellm>0)=1;

[img,img1] = filterIM(raw,'sl',blockR*2+1,'fq',0.08,'ithresh',[0.30 0.5]);
%identify background pixels as pixels inside the convoloved (dilated) cell,
%masked out by bandpass filtering
backgroundpixels = logical(img1)+~dilcellm;
backgroundpixels = backgroundpixels(:) == 0;
bgpxvals = raw(backgroundpixels);

%find rough location of peaks, demand the peaks are inside the cell, by
%referencing convolved (dilated) cell mask
[pixvals, sortorder] = sort(raw(dilcellm>0),'descend');
%shift back to actual image indices since the previous line sorted an index of the image
dilcellmis1 = find(dilcellm(:) > 0);
sortorder = dilcellmis1(sortorder);

%ignore relatively dim pixels initially
% del = pixvals <= mean(pixvals(pixvals>0));
del = pixvals <= mean(bgpxvals) + .5*std(double(bgpxvals));
sortorder(del) = [];

% SHOULD NOT BE NECESSARY SINCE filterIM ALREDY HID EDGE PIXELS
% % ignore pixels adjacent to edge pixels
% del = 1:r:c*r;
% for k = [1:r, del, del + r-1, ((c-1)*r + 1):c*r]
%     sortorder(sortorder == k) = [];
% end
% END UNNECESSARY

%build matrix of neighbors to ignore the bright neighbors of brightest
%pixels
repeatedvals = repmat(img(sortorder),[1,8]);
neighbors = [img(sortorder - r - 1), img(sortorder - r),...
    img(sortorder - r + 1), img(sortorder + 1),...
    img(sortorder + r + 1), img(sortorder + r),...
    img(sortorder + r - 1), img(sortorder - 1)];
%set neighbors of locally brightest pixels to some value < 0
peaks = sortorder(min(repeatedvals - neighbors,[],2)>0);

minPeakVal = mean(bgpxvals) + sigmaCutoff*std(double(bgpxvals));
peaks(raw(peaks) < minPeakVal) = [];

[n, m] = meshgrid(1:c,1:r);
gauss2d = fittype(@(k,sigma,pxy1,pxy2,x,y) k*exp(-(x-pxy1).^2/(2*sigma^2)-(y-pxy2).^2/(2*sigma^2)),...
                    'independent', {'x', 'y'},'dependent', 'z');
for k = 1:length(peaks)
    indices2mask = setdiff(peaks,peaks(k));
    mask = ones(size(img));
    for ind = 1:length(indices2mask)
        rowlocation = (rem(indices2mask(ind)-1,r)+1);
        collocation = ceil(indices2mask(ind)./r);
        %dmask is a matrix of locations from bright pixels of a peak not
        %being considered in iteration k of the loop
        dmask = ((m-rowlocation).^2 + (n-collocation).^2).^(1/2);
        %binarize dmask based on blocking radius, blockR
        dmask(dmask <= blockR) = 0;
        dmask(dmask>0)=1;        
        mask = mask.*dmask;
    end
    %reverse the mask and set other spots to a distance greater than maxdx
    %to hide them from the current peak
    mask = ~mask*maxdx+1;
    
    %use g2d to get a position estimate
    rp = (rem(peaks(k)-1,r)+1);
    cp = ceil(peaks(k)./r);
    pxy = g2d(img(rp-1:rp+1,cp-1:cp+1)) + [cp-1,rp-1] -1;
    pxy1 = pxy(1);
    pxy2 = pxy(2);
    peakdxy = ((m - pxy2).^2 + (n - pxy1).^2).^(1/2);
    ix = find(peakdxy.*mask <= maxdx);
    
    rp = (rem(ix-1,r)+1);
    cp = ceil(ix./r);
    dxy = ((rp - pxy(2)).^2 + (cp - pxy(1)).^2).^(1/2);
    if length(ix) >= MinSpotPixels
        [sfit gof] = fit([cp,rp],double(raw(ix)),gauss2d,'StartPoint',[k, sigma, pxy1, pxy2]);
        spot_x(k) = sfit.pxy1;
        spot_y(k) = sfit.pxy2;
        sigma(k) = sfit.sigma;
        rmse(k) = gof.adjrsquare;
    end
end
toc;
% UNCOMMENT FOR VIS
isho = @(x) imshow(x,[min(x(:)) max(x(:))],'InitialMagnification','fit');
figure
isho(raw)
hold on
plot(spot_x,spot_y,'xr','LineWidth',2)
for k = 1:length(rmse)
    text(spot_x(k)+2,spot_y(k),num2str(rmse(k)),'Color','w')  
end
end

function [varargout] = filterIM(im, varargin)
%im should be an image to filter
%frequency is the upper limit of frequencies to pass
%spotlength is the length of the spot, set to zero to avoid boxcar
%convolution
%ithresh should be a value between 0 and 1 indicating the intensity level
%to threshold at. If set to 0, no thresholding will occur. If multiple
%thresholding values are passed (i.e., passing ithresh a vector of length n
%with values between 0 and 1)
%
%Example
%filteredimage = filterIM(someimagetofilter,'spotlength',7,'frequency',1,'ithresh',0)
%
%filtering is performed in the frequency domain on account of speed
%relative convolution in the space domian
%
%Brad Parry, November 2012

Fq = 1;
spotLength = 9;
ithresh = 0;

for q = 1:length(varargin)
    if strcmpi(varargin{q},'fq') || strcmpi(varargin{q},'frequency') || strcmpi(varargin{q},'freq')
        Fq = varargin{q+1};
    elseif strcmpi(varargin{q},'spotlength') || strcmpi(varargin{q},'sl')
        spotLength = varargin{q + 1};
    elseif strcmpi(varargin{q},'ithresh')
        ithresh = varargin{q + 1};
    end
end

im = im - mean(im(:)); im(im<0) = 0;
dr = 0; dc = 0;
if ~mod(size(im,1),2), im = cat(1, im(1,:), im); dr = 1; end
if ~mod(size(im,2),2), im = cat(2, im(:,1), im); dc = 1; end

b_im = conv2(double(im), ones(spotLength)/spotLength^2, 'same');
[r_ind c_ind] = size(im);
Fp = cat(1, im, zeros(r_ind, c_ind));
Fp = cat(2, Fp, zeros(size(Fp,1), c_ind));
Fuv = fft2(Fp);
Huv = GaussWin(size(im),Fq);
Hp = cat(1, Huv, zeros(r_ind, c_ind));
Hp = cat(2, Hp, zeros(size(Hp,1), c_ind));
fCHp = fft2(Hp);
G = real(ifft2(Fuv.*fCHp)); %Filter & return to spatial domain at once
indx(1:2) = [floor(r_ind/2) + 1 + dr, floor(r_ind/2) + size(im,1)];
indx(3:4) = [floor(c_ind/2) + 1 + dc, floor(c_ind/2) + size(im,2)];
GF = G(indx(1):indx(2),indx(3):indx(4));
ind = ceil(spotLength/2);
mask = zeros(size(GF));
mask(ind+1:end-ind-1,ind+1:end-ind-1) = 1;
filteredIM = mask.*(GF - b_im(1:end-dr,1:end-dc));

for k = 1:length(ithresh)
    varargout{k} = filteredIM;
    L = (ithresh(k))*(max(varargout{k}(:)) - min(varargout{k}(:)))*graythresh(varargout{k});
    varargout{k}(varargout{k} <= L) = 0;
end

end

function [win] = GaussWin(dimensions,sigma,center_)
if nargin ~= 3
    center_ = (dimensions + 1)/2;
end
rs = center_(1) - repmat([1:dimensions(1)]',[1,dimensions(2)]);
cs = center_(2) - repmat([1:dimensions(2)],[dimensions(1), 1]);
dx = rs.^2 + cs.^2;
win = (exp(-dx/(2*sigma^2)));
win = win/sum(win(:));
end

function [xy] = g2d(image)
image = double(image);
M0 = sum(image(:));
x = repmat(1:size(image,2),[size(image,1), 1]);
Mx = sum(sum(x.*image));
ay(:,1) = 1:size(image,1);
y = repmat(ay,[1,size(image,2)]);
My = sum(sum(y.*image));
xy = [Mx/M0, My/M0];
end