function corners = harrisMinEigen_(inputImage,cmesh,bgr,varargin)

inputImage = im2double(inputImage);
xmesh2a=cmesh(:,1);
xmesh2b=cmesh(:,3);
ymesh2a=cmesh(:,2);
ymesh2b=cmesh(:,4);
[~,~,theta]=cell_coord(cmesh);
[szuy,szux]=size(inputImage);
xb1= xmesh2a(ceil(length(xmesh2a)/2));
yb1= ymesh2a(ceil(length(ymesh2a)/2));
xb2= xmesh2b(ceil(length(xmesh2b)/2));
yb2= ymesh2b(ceil(length(ymesh2b)/2));
xbmax=max([xb1 xb2]);
xbmin=min([xb1 xb2]);
ybmax=max([yb1 yb2]);
ybmin=min([yb1 yb2]);
% % % xb1 = ceil(cmesh(:,2)/2);
% % % yb1 = ceil(cmesh(:,1)/2);
% % % xbmax = max(cmesh(:,2));
% % % xbmin = min(cmesh(:,2));
% % % ybmax = max(cmesh(:,1));
% % % ybmin = min(cmesh(:,2));
dxb=xbmax-xbmin;
dyb=ybmax-ybmin;

pstep=20;
proflinex=xbmin:dxb/(pstep-1):xbmax;
profliney=ybmin:dyb/(pstep-1):ybmax;
if isempty(proflinex)
    proflinex = ones(1,pstep)*xbmin;
end
if isempty(profliney)
    profliney = ones(1,pstep)*ybmin;
end

if xbmax==xb1,proflinex=fliplr(proflinex);end
if ybmax==yb1,profliney=fliplr(profliney);end

improf=interp2(1:szux,1:szuy,im2double(inputImage),proflinex,profliney,'linear');
% The weirdest thing happened here. The logical below found two minima
xcn=proflinex(improf==min(improf(3:pstep-3)));
ycn=profliney(improf==min(improf(3:pstep-3)));

[X,Y]=meshgrid(-15:1:15,-15:1:15);
Xr=X*cosd(theta)-Y*sind(theta);
Yr=X*sind(theta)+Y*cosd(theta);
Xrt=Xr+xcn(1);
Yrt=Yr+ycn(1);
inputImage = fliplr(interp2(1:szux,1:szuy,im2double(inputImage),Xrt,Yrt)');

checkImage(inputImage);
imageSize = size(inputImage);
% % % inputImage = im2single(inputImage);

% Check and parse other inputs.
params = parseInputs(imageSize, varargin{:});

if ~isempty(params.ROI)
    % If an ROI has been defined, we expand it so corners will be detected
    % on valid pixels instead of padded pixels. We then crop the image
    % within the expanded region.
    expandSize = floor(params.FilterSize / 2);
    expandedROI = vision.internal.detector.expandROI(imageSize, ...
        params.ROI, expandSize);
    inputImage = imcrop(inputImage, expandedROI);
end

% Create a 2-D Gaussian filter.
filter2D = createFilter(params.FilterSize);
% Compute the corner metric matrix.
metricMatrix = cornerMetric(inputImage, filter2D);
% Find peaks, i.e., corners, in the corner metric matrix.
locations = vision.internal.findPeaks(metricMatrix, params.MinQuality);
locations = subPixelLocation(metricMatrix, locations);

% Compute corner metric values at the corner locations.
metricValues = computeMetric(metricMatrix, locations);

if ~isempty(params.ROI)
    % Because the ROI was expanded earlier, we need to exclude corners
    % which locate outside the original ROI.
    [locations, metricValues] = ...
        vision.internal.detector.excludePointsOutsideROI(...
        params.ROI, expandedROI, locations, metricValues);
end

% Pack the output to a cornerPoints object.
corners = cornerPoints(locations, 'Metric', metricValues);

%==========================================================================
% Compute corner metric value at the sub-pixel locations by using
% bilinear interpolation
function values = computeMetric(metric, loc)
num = size(loc, 1);
values = zeros([num, 1]);
for idx = 1: num
    x = loc(idx, 1);
    y = loc(idx, 2);
    x1 = floor(x);
    y1 = floor(y);
    x2 = x1 + 1;
    y2 = y1 + 1;
    
    values(idx) = metric(y1,x1) * (x2-x) * (y2-y) ...
                + metric(y1,x2) * (x-x1) * (y2-y) ...
                + metric(y2,x1) * (x2-x) * (y-y1) ...
                + metric(y2,x2) * (x-x1) * (y-y1);
end

%==========================================================================
% Compute corner metric matrix
function metric = cornerMetric(I, filter2D)
% Compute gradients
A = imfilter(I,[-1 0 1] ,'replicate','same','conv');
B = imfilter(I,[-1 0 1]','replicate','same','conv');

% Crop the valid gradients
A = A(2:end-1,2:end-1);
B = B(2:end-1,2:end-1);

% Compute A, B, and C, which will be used to compute corner metric.
C = A .* B;
A = A .* A;
B = B .* B;

% Filter A, B, and C.
A = imfilter(A,filter2D,'replicate','full','conv');
B = imfilter(B,filter2D,'replicate','full','conv');
C = imfilter(C,filter2D,'replicate','full','conv');

% Clip to image size
removed = max(0, (size(filter2D,1)-1) / 2 - 1);
A = A(removed+1:end-removed,removed+1:end-removed);
B = B(removed+1:end-removed,removed+1:end-removed);
C = C(removed+1:end-removed,removed+1:end-removed);
% The parameter k which was defined in the Harris method is set to 0.04
k = 0.04; 
metric = (A .* B) - (C .^ 2) - k * ( A + B ) .^ 2;


%==========================================================================
% Compute sub-pixel locations
function loc = subPixelLocation(metric, loc)
for id = 1: size(loc,1)
    loc(id,:) = subPixelLocationImpl(metric, loc(id,:));
end

%==========================================================================
% Compute sub-pixel locations using bi-variate quadratic function fitting.
% Reference: http://en.wikipedia.org/wiki/Quadratic_function
function subPixelLoc = subPixelLocationImpl(metric, loc)

patch = metric(loc(2)-1:loc(2)+1, loc(1)-1:loc(1)+1);

dx2 = ( patch(1,1) - 2*patch(1,2) +   patch(1,3) ...
    + 2*patch(2,1) - 4*patch(2,2) + 2*patch(2,3) ...
    +   patch(3,1) - 2*patch(3,2) +   patch(3,3) ) / 8;

dy2 = ( ( patch(1,1) + 2*patch(1,2) + patch(1,3) )...
    - 2*( patch(2,1) + 2*patch(2,2) + patch(2,3) )...
    +   ( patch(3,1) + 2*patch(3,2) + patch(3,3) )) / 8;

dxy = ( + patch(1,1) - patch(1,3) ...
        - patch(3,1) + patch(3,3) ) / 4;

dx = ( - patch(1,1) - 2*patch(2,1) - patch(3,1)...
       + patch(1,3) + 2*patch(2,3) + patch(3,3) ) / 8;

dy = ( - patch(1,1) - 2*patch(1,2) - patch(1,3) ...
       + patch(3,1) + 2*patch(3,2) + patch(3,3) ) / 8;

detinv = 1 / (dx2*dy2 - 0.25*dxy*dxy);

% Calculate peak position and value
x = -0.5 * (dy2*dx - 0.5*dxy*dy) * detinv; % X-Offset of quadratic peak
y = -0.5 * (dx2*dy - 0.5*dxy*dx) * detinv; % Y-Offset of quadratic peak

% If both offsets are less than 1 pixel, the sub-pixel location is
% considered valid.
if abs(x) < 1 && abs(y) < 1
    subPixelLoc = [x, y] + loc;
else
    subPixelLoc = loc;
end

%==========================================================================
% Create a Gaussian filter
function f = createFilter(filterSize)
sigma = filterSize / 3;
f = fspecial('gaussian', filterSize, sigma);

%==========================================================================
function params = parseInputs(imageSize, varargin)
% Instantiate an input parser
parser = inputParser;
parser.FunctionName = mfilename;
parser.CaseSensitive = true;

% Parse and check the optional parameters
parser.addParamValue('MinQuality', 0.01, @checkMinQuality);
parser.addParamValue('FilterSize', 5, @(x)(checkFilterSize(x,imageSize)));
parser.addParamValue('ROI', [], @(x)(vision.internal.detector.checkROI(...
    x, imageSize)));
parser.parse(varargin{:});
params = parser.Results;

%==========================================================================
function r = checkImage(I)
validateattributes(I, ...
  {'logical', 'uint8', 'int16', 'uint16', 'single', 'double'}, ...
  {'2d', 'nonempty', 'nonsparse', 'real'},...
  mfilename, 'I', 1);
r = true;

%==========================================================================
function tf = checkMinQuality(x)
validateattributes(x,{'numeric'},...
    {'nonempty', 'nonnan', 'nonsparse', 'real', 'scalar', '>=', 0, '<=', 1},...
    mfilename,'QualityLevel');
tf = true;

%==========================================================================
function tf = checkFilterSize(x,imageSize)
maxSize = min(imageSize);
validateattributes(x,{'numeric'},...
    {'nonempty', 'nonnan', 'nonsparse', 'real', 'scalar', 'odd',...
    '>=', 3, '<=', maxSize}, mfilename,'FilterSize');
tf = true;
