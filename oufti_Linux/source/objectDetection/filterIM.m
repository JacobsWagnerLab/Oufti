function [varargout] = filterIM(im, varargin)
% author:     Bradley R Parry
% date:       2011
% copyright:  Yale University
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% filterIM performs bandpass Gaussian filtering on an input image. The
% input image is convolved with a boxcar kernel (see below to avoid boxcar
% convolution), and subtracted from a convolution of the input image with a
% Gaussian window. The input image is convolved with a Gaussian in the
% frequency space and obtained with an inverse Fourier transform. Pixels 
% ceil(spotLength/2) from the image edge are masked out.
%
%   INPUT ARGUMENTS
% im is an image to filter
% optional input arguements include:
%     frequency: is the upper limit of frequencies to pass
%         filteredIM = filterIM(im,'frequency',0.95)
%     spotlength: length of the spot, set to zero to avoid boxcar
%     convolution. spotlength should be an integer value.
%         filteredIM = filterIM(im,'spotlength',9)
%     ithresh: a value between 0 and 1 indicating the intensity level
%     to threshold at. If set to 0, no thresholding will occur
%         filteredIM = filterIM(im,'ithresh',.2)
% 
%   OUTPUT ARGUMENT
% filteredIM: the filtered result of input image, im
% if no output is requested, filterIM will display, as an image (scaled 
% from min to max), the result of filtering. 

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

function [win] = GaussWin(dimensions,sigma)
% author:     Bradley R Parry
% date:       2011
% copyright:  Yale University
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% constructs a Gassian window of size specified by dimensions and the
% standard deviation of the Gaussian function specified by sigma
% if dimensions has 2 components, output win will be of size
% (dimensions(1), dimensions(2)).
% the output window will be centered on dimensions and normalized to 1
% 
% EXAMPLE - to construct a 5 by 5 Gaussian surface with standard deviation
% 1:
%     GaussSurf = GaussWin([5, 5], 1);
% 
%     GaussSurf = 
%         0.0030    0.0133    0.0219    0.0133    0.0030
%         0.0133    0.0596    0.0983    0.0596    0.0133
%         0.0219    0.0983    0.1621    0.0983    0.0219
%         0.0133    0.0596    0.0983    0.0596    0.0133
%         0.0030    0.0133    0.0219    0.0133    0.0030

if nargin ~= 3
    center_ = (dimensions + 1)/2;
end
rs = center_(1) - repmat([1:dimensions(1)]',[1,dimensions(2)]);
cs = center_(2) - repmat([1:dimensions(2)],[dimensions(1), 1]);
dx = rs.^2 + cs.^2;
win = (exp(-dx/(2*sigma^2)));
win = win/sum(win(:));
end