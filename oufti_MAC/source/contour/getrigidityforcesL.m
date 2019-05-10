function [xForce,yForce] = getrigidityforcesL(xImage,yImage,weightVector)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function [xForce,yForce] = getrigidityforcesL(xImage,yImage,weightVector)
%oufti v0.3.1
%@author:  Oleksii Sliusarenko
%@modified:    July 19 2013(ap)
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********
%xForce:    forces in the x-direction
%yForce:    forces inthe y-direction
%**********Input********
%xImage:        image values in the x-axis
%yImage:        image values in the y-axis
%weightVector:  weight values to calculate image forces.
%**********Purpose******
%The function computes image forces from given image values using provided
%weight vector.
%==========================================================================

xForce = zeros(size(xImage,1),1);
yForce = zeros(size(yImage,1),1);
%     l = length(x);
%     D = sqrt((x([1 2 l-2 l-1])-x([2 3 l-1 l])).^2+(y([1 2 l-2 l-1])-y([2 3 l-1 l])).^2);
%     x(1) = x(2) + (x(1)-x(2))*D(2)/D(1);
%     y(1) = y(2) + (y(1)-y(2))*D(2)/D(1);
%     x(end) = x(end-1) + (x(end)-x(end-1))*D(3)/D(4);
%     y(end) = y(end-1) + (y(end)-y(end-1))*D(3)/D(4);
for i = 1:length(weightVector)
    fxt = weightVector(i)*(xImage(1:end-2*i)/2+xImage(2*i+1:end)/2-xImage(i+1:end-i));
    fyt = weightVector(i)*(yImage(1:end-2*i)/2+yImage(2*i+1:end)/2-yImage(i+1:end-i));
    xForce(i+1:end-i) = xForce(i+1:end-i) + fxt;
    yForce(i+1:end-i) = yForce(i+1:end-i) + fyt;
    xForce(1:end-2*i) = xForce(1:end-2*i) - fxt/2;
    yForce(1:end-2*i) = yForce(1:end-2*i) - fyt/2;
    xForce(2*i+1:end) = xForce(2*i+1:end) - fxt/2;
    yForce(2*i+1:end) = yForce(2*i+1:end) - fyt/2;
end

end