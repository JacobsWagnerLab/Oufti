function outStackImages = LOG_filter(stackImages)
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function outStackImages = LOG_filter(stackImages)
%oufti.v1.0.5
%@author:  Ahmad J Paintdakhi
%@date:    September 6 2012
%update:   Septmeber 11 2012
%@copyright 2012-2013 Yale University

%=================================================================================
%**********output********:
%outStackImages -- images that are filtered using a Laplacian of Gaussian
%filter

%**********Input********:
%stackImages -- images that need to go through a filter.
%The image could be a stack or individual image.
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------

% This generates the LOG filter itself.
% The bandwidth (here 1.5) may need to be changed depending
% on the pixel size of your camera and your microscope's
% optical characteristics.
stackImages = im2double(stackImages);
H = -fspecial('log',15,1.5);

% Here, we amplify the signal by making the filter "3-D"
H = 1/3*cat(3,H,H,H);

% Apply the filter
outStackImages = imfilter(stackImages,H,'circular','same');

% Set all negative values to zero
outStackImages(logical(outStackImages<0)) = 0;
