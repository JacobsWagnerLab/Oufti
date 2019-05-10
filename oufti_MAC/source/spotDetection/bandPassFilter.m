function filteredImage = bandPassFilter(inputImage,lowNoise,lengthObject,threshold)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function filteredImage = bandPassFilter(inputImage,lowNoise,lengthObject,threshold)
%oufti.v0.2.9
%@author:  Ahmad J Paintdakhi
%@date:    March 05 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%filteredImage:  filtered image.
%**********Input********:
%inputImage:    a single image that need to be filtered
%lowNoise:      Characteristic lengthscale of noise in pixels.
%               Additive noise averaged over this length should
%               vanish. May assume any positive floating value.
%               May be set to 0 or false, in which case only the
%               highpass "background subtraction" operation is 
%               performed.
%lengthObject:  (optional) Integer length in pixels somewhat 
%               larger than a typical object. Can also be set to 
%               0 or false, in which case only the lowpass 
%               "blurring" operation defined by lowNoise is done,
%               without the background subtraction defined by
%               lengthObject.  Defaults to false.
%threshold:     (optional) By default, after the convolution,
%               any negative pixels are reset to 0.  Threshold
%               changes the threshhold for setting pixels to
%               0.  Positive values may be useful for removing
%               stray noise or small particles.  Alternatively, can
%               be set to -Inf so that no threshholding is
%               performed at all.
%=========================================================================
% PURPOSE:
%               Implements a real-space bandpass filter that suppresses 
%               pixel noise and long-wavelength image variations while 
%               retaining information of a characteristic size of a airy-dsik.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

if nargin < 3, lengthObject = false; end
if nargin < 4, threshold = 0; end

normalize = @(x) x/sum(x);

inputImage = double(inputImage);

if lowNoise == 0
  gaussian_kernel = 1;
else     

  gaussian_kernel = normalize(...
    exp(-((-ceil((lengthObject/2)^2):ceil((lengthObject/2)^2))/(4*lowNoise^2)).^2));
end

if lengthObject  
  boxcar_kernel = normalize(...
      ones(1,length(-round(lengthObject):round(lengthObject))));
end

%It turns out that convolving with a column vector is faster than
% convolving with a row vector, so instead of transposing the kernel, the
% image is transposed twice.

gconv = conv2(inputImage',gaussian_kernel','same');
gconv = conv2(gconv',gaussian_kernel','same');
%%%gconv = imfilter(inputImage,gaussian_kernel);
if lengthObject
  bconv = conv2(inputImage',boxcar_kernel','same');
  bconv = conv2(bconv',boxcar_kernel','same');
% % %     bconv = imfilter(inputImage,boxcar_kernel);
  filtered = gconv - bconv;
else
  filtered = gconv;
end

% Zero out the values on the edges to signal that they're not useful.     
 lzero = max(lengthObject,ceil((lengthObject/2)^2));

filtered(1:(round(lzero)),:) = 0;
filtered((end - lzero + 1):end,:) = 0;
filtered(:,1:(round(lzero))) = 0;
filtered(:,(end - lzero + 1):end) = 0;
filteredTemp = mat2gray(filtered);
indexArray = filteredTemp<threshold;
filtered(indexArray) = 0;
filteredImage = filtered;

end