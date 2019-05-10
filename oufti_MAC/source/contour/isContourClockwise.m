function tf = isContourClockwise(varargin)
% This function detects if a polygon is clockwise. A faster and simplified
% version of MATLAB's ispolycw function.

if isempty(varargin)
    tf = 0;
    return
else
    if length(varargin)>=2
        x = varargin{1};
        y = varargin{2};
    elseif length(varargin)==1
        if isempty(varargin{1})
            tf = 0;
            return
        else
            x = varargin{1}(:,1);
            y = varargin{1}(:,2);
        end
    end
end

if numel(x) <= 1
    tf = true;
    return;
end

is_closed = (x(1) == x(end)) && (y(1) == y(end));
if is_closed
    x(end) = [];
    y(end) = [];
end

[x, y] = removeDuplicates(x, y);
num_vertices = numel(x);
if num_vertices <= 2
    tf = true;
    return;
end

idx = findExtremeVertices(x, y);

if numel(idx) > 1
    % The same extreme vertex appears multiple, nonsuccessive times in
    % the vertex list.  Use signed area test.
    tf = signedArea(x, y) <= 0;
    return;
end

% Find the three vertices we are interested in: the left-most of the
% lowest vertices, as well as the ones immediately before and after it.
p = mod((idx - 1) + [-1, 0, 1], num_vertices) + 1;
xx = x(p);
yy = y(p);

if ~isfloat(xx)
    xx = double(xx);
end
if ~isfloat(yy)
    yy = double(yy);
end

ux = xx(2) - xx(1);
uy = yy(2) - yy(1);

vx = xx(3) - xx(2);
vy = yy(3) - yy(2);

a = ux*vy;
b = uy*vx;
if a == b
    % The left-most lowest vertex is the end-point of a kind of linear
    % "spur."  The contour doubles back on itself, such as in this case:
    % x = [0 1 1 0 0 -1 0];
    % y = [0 0 1 1 0 -1 0];
    % The left-most lowest vertex is (-1,-1), but we since this vertex
    % is the end-point of a spur, we can't tell the direction from it.
    % Use the signed polygon test.
    tf = signedArea(x, y) <= 0;
else
    tf = a < b;
end


%----------------------------------------------------------------------
function [xout, yout] = removeDuplicates(x, y)
num_vertices = numel(x);
k1 = [2:num_vertices 1];
k2 = 1:num_vertices;
dups = (x(k1) == x(k2)) & (y(k1) == y(k2));
xout = x;
yout = y;
xout(dups) = [];
yout(dups) = [];

%----------------------------------------------------------------------
function idx = findExtremeVertices(x, y)
% Return the indices of all the left-most lowest vertices in (x,y).

% Find the vertices with the minimum y.
idx = find(y == min(y));

x_subset = x(idx);
idx2 = find(x_subset == min(x_subset));

idx = idx(idx2);

%----------------------------------------------------------------------
function a = signedArea(x, y)
% a = signedArea(x,y) returns twice the signed area of the polygonal
% contour represented by vectors x and y.  Assumes (x,y) is NOT closed.

% Reference: 
% http://geometryalgorithms.com/Archive/algorithm_0101/algorithm_0101.htm

x = x - mean(x);
n = numel(x);
if n <= 2
    a = 0;
else
    i = [2:n 1];
    j = [3:n 1 2];
    k = [1:n];
    a = sum(x(i) .* (y(j) - y(k)));
end

