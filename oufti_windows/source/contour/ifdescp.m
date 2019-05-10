function s = ifdescp(inverseSignal, fsmoothValue)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function s = ifdescp(inverseSignal, fsmoothValue)
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
% S = IFDESCP(Z, ND) computes the inverse Fourier descriptors of Z, which
% is a sequence of Fourier descriptors arrived at by using FDESCP.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

signalPoints = length(inverseSignal);
if nargin==1 || fsmoothValue>signalPoints, fsmoothValue = signalPoints; end
x = 0:(signalPoints-1);
m = ((-1).^x)';
d = round((signalPoints - fsmoothValue)/2);
inverseSignal(1:d) = 0;
inverseSignal(signalPoints-d+1:signalPoints) = 0;
zz = ifft(inverseSignal);
s(:,1) = real(zz);
s(:,2) = imag(zz);
s(:,1) = m.*s(:,1);
s(:,2) = m.*s(:,2);
end