function [win] = GaussWin(dimensions,sigma,center_)
if nargin ~= 3
    center_ = (dimensions + 1)/2;
end
rs = center_(1) - repmat([1:dimensions(1)]',[1,dimensions(2)]);
cs = center_(2) - repmat([1:dimensions(2)],[dimensions(1), 1]);
dx = rs.^2 + cs.^2;
win = (exp(-dx/(2*sigma^2)));
win = win/sum(win(:));
end