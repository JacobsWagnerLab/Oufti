function nbins = binNbFreedmanDiaconi(X,varargin)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function nbins = binNbFreedmanDiaconi(X,varargin)
%@author:  Manuel Campos
%@date:    August 17, 2015
%@copyright 2014-2015 Yale University
%==========================================================================
%**********output********:
%nbins:     estimate of the number of bins to use to construct a histogram
%           for X 
%**********Input********:
%X:         Vector of real numbers
%varargin:  lowbnd and uprbnd provide a mean to artificially limit the
%           output value to the specified range [lowbnd,uprbnd].
%==========================================================================
%PURPOSE:   Generate automatically a generally good first guess for the
%           number of bins to use to construct the histogram of vector X.
%
%USE:       X = randn(1000,1);
%           nbins = binNbFreedmanDiaconi(X)
%           Or, to limit the number of bins from 10 to 15
%           nbins = binNbFreedmanDiaconi(X,10,15)
%
% See the following web page for a descrition of the formula and
% potentially other similar/complementary approaches (e.g. Sturges' or
% Scott's formulas)
% https://en.wikipedia.org/w/index.php?title=Histogram&oldid=232222820#Number_of_bins_and_width
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 

h = iqr(X); %inter-quartile range
% If the iqr is null, try to rescue the approach by using the mad
if h == 0
    h = 2*mad(X,1); %twice median absolute deviation
end
% Use Freedman-Diaconi's formula to compute nbins
if h > 0
    nbins = ceil((max(X)-min(X))/(2*h*length(X)^(-1/3)));
else
    nbins = 1;
end

if nargin==3
    lowbnd = varargin{1};
    uprbnd = varargin{2};
    nbins = ceil(max(nbins,lowbnd));
    nbins = floor(min(nbins,uprbnd));
end 

end