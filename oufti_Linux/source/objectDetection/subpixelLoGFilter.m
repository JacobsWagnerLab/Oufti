function [threshim, lg, Zi]= subpixelLoGFilter(image, sigma, ZX, Magnitude, res)

% Get a LoG window
% Determine LoG window size, choose size to capture >= 99.7% of the volume under a 
% Gaussian surface.
N = ceil(sigma*3) * 2 + 1;
w = LoGWin([N,N],sigma);
tb = false(N-1,size(image,2));
image = cat(1,tb,image,tb);
lr = false(size(image,1),N-1);
image = cat(2,lr,image,lr);
lg=conv2(double(image),w,'same');
lg = lg(N:end-N+1,N:end-N+1); 

threshim = false((size(lg)-1)/res + 1);

X = repmat((1:size(lg,2)),[size(lg,1),1]);
Y = repmat((1:size(lg,1))',[1,size(lg,2)]);
Xi = repmat((1:res:size(lg,2)),[(size(X,1)-1)/res + 1,1]);
Yi = repmat((1:res:size(lg,1))',[1,(size(X,2)-1)/res + 1]);
Zi = interp2(X,Y,lg,Xi,Yi,'spline');

r_lim = 2:size(Zi,1)-1;
c_lim = 2:size(Zi,2)-1;
sz1 = size(Zi,1);

[nr,nc] = find(Zi(r_lim-1,c_lim) > ZX & Zi(r_lim,c_lim) < ZX & abs(Zi(r_lim-1,c_lim) - Zi(r_lim,c_lim)) > Magnitude);
threshim((nr+1)+nc*sz1) = 1;
[nr, nc] = find(Zi(r_lim,c_lim) < ZX & Zi(r_lim,c_lim+1) > ZX & abs(Zi(r_lim,c_lim) - Zi(r_lim,c_lim+1)) > Magnitude);
threshim((nr+1)+nc*sz1) = 1;
[nr,nc] = find(Zi(r_lim,c_lim-1) > ZX & Zi(r_lim,c_lim) < ZX & abs(Zi(r_lim,c_lim-1) - Zi(r_lim,c_lim)) > Magnitude);
threshim((nr+1)+nc*sz1) = 1;
[nr,nc] = find(Zi(r_lim,c_lim) < ZX & Zi(r_lim+1,c_lim) > ZX & abs(Zi(r_lim,c_lim) - Zi(r_lim+1,c_lim)) > Magnitude);
threshim((nr+1)+nc*sz1) = 1;

block = ceil(N/2)*1/res;
threshim(1:block,:) = 0;
threshim(end-block+1:end,:) = 0;
threshim(:,1:block) = 0;
threshim(:,end-block+1) = 0;
end

function [Win] = LoGWin(dimensions,sigma)
% Mak a Laplacian of Gaussian filter with dimensions [rows columns] and
% standard deviation, sigma. Resulting filter, Win, sums to zero
center = (dimensions + 1)/2;
% Distance in Y from center
rs = center(1) - repmat([1:dimensions(1)]',[1,dimensions(2)]); 
% Distance in X from center
cs = center(2) - repmat([1:dimensions(2)],[dimensions(1), 1]); 
num = rs.^2 + cs.^2 - 2*sigma^2;
den = sigma^4;
k = exp(-(rs.^2 + cs.^2)./(2*sigma^2));
Win = (num./den).*k;
%Sum to zero so convolution of homogneous regions is zero
Win = Win - sum(Win(:))/prod(dimensions); 
end