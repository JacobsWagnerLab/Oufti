function [xForce,yForce] = getrigidityforces(xImage,yImage,weightVector)
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
xForce = - 2*sum(weightVector)*xImage;
yForce = - 2*sum(weightVector)*yImage;
for i=1:length(weightVector)
    xForce = xForce + weightVector(i)*(circShiftNew(xImage,i)+circShiftNew(xImage,-i));
    yForce = yForce + weightVector(i)*(circShiftNew(yImage,i)+circShiftNew(yImage,-i));
end

end