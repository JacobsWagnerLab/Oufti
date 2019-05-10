function [a,b] = expandpoly(x,y,d,varargin)
% [a,b] = expandpoly(x,y,d,chk)
% 
% This function expands a closed polygon by shifting each edge outwards by
% a set distance. Duplicated x,y pairs are removed.
% 
% <x>,<y> - x and y coordinates of the original polygon vertices.
% <d> - distance to move the edges (positive - outwards).
% <chk> (optional) - do not check for clockwise orientation (if 1, it must 
%     be clockwise already).
% <a>,<b> - x,y coordinates of the resulting polygon.

% define basic variables
if isempty(varargin) || ~varargin{1}
    d = d*(2*isContourClockwise(x,y)-1);
end
if size(x,1)==1, h=true; else h=false; end
x = x(:);
y = y(:);
dx1 = x-circshift(x,1);
dy1 = y-circshift(y,1);

% remove duplicates
ind = (abs(dx1)<1E-10 & abs(dy1)<1E-10);
while true
    if sum(ind)>0
        x = x(~ind);
        y = y(~ind);
        dx1 = dx1(~ind);
        dy1 = dy1(~ind);
        ind = (abs(dx1)<1E-10 & abs(dy1)<1E-10);
    else
        break
    end
end

% compute the new contour
dx2 = circshift(dx1,-1);
dy2 = circshift(dy1,-1);
normf = dx1.*dy2-dy1.*dx2;
n = sqrt(dx1.^2+dy1.^2);
g1 = y.*dx1-x.*dy1+n*d;
g2 = circshift(g1,-1);
a = (g1.*dx2-g2.*dx1)./normf;
b = (g1.*dy2-g2.*dy1)./normf;

% correct straight lines
ind = abs(normf)<1E-10;
if sum(ind)>0
    a(ind) = x(ind) - d*dy1(ind)./n(ind);
    b(ind) = y(ind) + d*dx1(ind)./n(ind);
end

% make a,b shape similar to x,y
if h, a=a'; b=b'; end