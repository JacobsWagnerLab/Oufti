function [y,x] = integinterp(xi,yi,n)
% Syntax:
% [y,x] = integinterp(xi,yi,n);
% 
% <xi>, <yi> - raw data, the values of intensity yi sampled at points xi.
%     Since the interpolation is only performed on [0 1] interval, it is
%     assumed that xi coordinates are relative to the cell length.
% n - number of interpolated points, corresponding to n segments of equal
%     length onto which the region [0 1] is brocken.
% <y>, <x> - the output data (integrals of the intensity on the intervals)
%     and centers of the integration intervals.
% 
% This function produces interpolation of the original data in n 
% equidistand points spanning the interval [0 1]. The interpolation methods
% is linear interpolation followed by integration on each interval.
% 
% Example 1: create a 5-point profile for cell 9 on frame 2
% 
% [p,x] = intprofile(cellList,2,9,'unitlength','nodisp');
% [y,xx] = integinterp(x,p,5);
% plot(x,p,'-b',xx,y,'.r')
% 
% Example 2: 5-point profile normalized by area
%
% frame=2;
% cell=9;
% lng = cellList.meshData{frame}{cell}.length;
% x = cellList.meshData{frame}{cell}.lengthvector/lng;
% a = cellList.meshData{frame}{cell}.steparea;
% s = cellList.meshData{frame}{cell}.signal1;
% y = integinterp(x,s,5);
% [r,xx] = integinterp(x,a,5);
% c = y./r;
% plot(x,s./a,'-',xx,c,'.')
    
    x = 1/2/n:1/n:1;
    y = zeros(1,n);
    for i=1:n
        a = (i-1)/n;
        b = i/n;
        y(i) = n*quadl(@integinterp2,a,b);
    end
    
    function res = integinterp2(x)
        res = interp1(xi,yi,x,'linear',0);
    end
end