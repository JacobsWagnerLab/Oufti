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

Fq = 0.5;
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

% % % im = im - mean(im(:)); im(im<0) = 0;
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