function filteredImage = lowPassFilter(image,cutoffFreq)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function filteredImage = lowPassFilter(image,cutoffFreq)
%oufti.v0.0.1
%@author:  Ahmad J Paintdakhi
%@date:    October 17 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%filteredImage:  an image that is filtered after high components are
%blocked
%**********Input********:
%image:  input image
%cutoffFreq:  cutoff frequency for the filter.  This is the frequency
%beyond which signals are not passed.
%==========================================================================
hfft2d = vision.FFT;
hifft2d = vision.IFFT;
imageTemp = im2uint8(image);
%change image into its frequency domain equivalent
freqTransformImage = step(hfft2d,single(imageTemp));
[M N] = size(image);
u=0:(M-1);
v=0:(N-1);
idx=find(u>M/2);
u(idx)=u(idx)-M;
idy=find(v>N/2);
v(idy)=v(idy)-N;
[V,U]=meshgrid(v,u);

for i = 1:M
    for j = 1:N
        %apply 2nd order Butterworth filter 
        UVw = double((U(i,j)*U(i,j) + V(i,j)*V(i,j))/(cutoffFreq*cutoffFreq));
        H(i,j) = 1/(1+UVw*UVw);
    end
end
%apply fiter and do inverst of FFT to convert back to spatial coordinates.
G = H.*freqTransformImage;
filteredImage = im2uint16(step(hifft2d,G),'Indexed');
end


