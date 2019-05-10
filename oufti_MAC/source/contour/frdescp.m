function fourierTransformS = frdescp(signal)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function fourierTransformS = frdescp(signal)
%oufti.v0.3.0
%@author:  oleksii sliusarenko
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%fourierTransformS:  fourier transform of input signal
%**********Input********:
%signal:    signal or boundary points of a cell contour.
%=========================================================================
% PURPOSE:
%computes the Fourier descriptors of signal, which is an np-by-2
% sequence of image coordinates describing a boundary.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

[np, nc] = size(signal);
if nc ~=2, error('S must be of size np-by-2.'); end
if np/2 ~= round(np/2);
   signal(end+1,:) = signal(end, :);
   np = np + 1;
end
x = 0:(np-1);
m = ((-1).^x)';
signal(:,1) = m .* signal(:,1);
signal(:,2) = m .* signal(:,2);
signal = signal(:,1) + sqrt(-1)*signal(:,2);
fourierTransformS = fft(signal);
end