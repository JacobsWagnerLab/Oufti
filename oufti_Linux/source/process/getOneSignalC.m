function outputSignal = getOneSignalC(mesh,meshBox,img,rsz)
%------------------------------------------------------------------------
%------------------------------------------------------------------------
%function outputSignal = getOneSignalC(mesh,meshBox,img,rsz)
%oufti.v0.2.6
%@author:  Oleksii Sliusarenko
%@date:    December 3, 2012
%@copyright 2012-2013 Yale University
%====================================================================
%**********output********:
%outputSignal:  signal profile.
%**********Input********:
%mesh:  A four-by-n matrix outlining the contour of a cell.
%meshBox:   Box coordinate of the mesh with respect to the image.
%img:   input image.
%rsz:   if resize is required.
%====================================================================
% This function integrates signal confined within each segment of the
% mesh. Two versions are provided. This one is a slower but more
% precise C-based function (requires 'aip' function to run).
%------------------------------------------------------------------------
%------------------------------------------------------------------------

outputSignal = zeros(size(mesh,1)-1,1);
if length(mesh)>4
   img2 = imcrop(img,meshBox);
   if rsz>1
   img2 = imresize(img2,rsz);
   end
   c = repmat(1:size(img2,2),size(img2,1),1);
   r = repmat((1:size(img2,1))',1,size(img2,2));
   icw = isContourClockwise([mesh(:,1);flipud(mesh(2:end-1,3))],[mesh(:,2);flipud(mesh(2:end-1,4))]);
   maxi = size(mesh,1)-1;
   for i=1:maxi
       plgx = rsz*([mesh(i,[1 3]) mesh(i+1,[3 1])]-meshBox(1)+1)';
       plgy = rsz*([mesh(i,[2 4]) mesh(i+1,[4 2])]-meshBox(2)+1)';
       if icw, plgx = flipud(plgx); plgy = flipud(plgy); end % making contours clockwise
       [plgx2,plgy2] = expandpoly(plgx,plgy,1.42,1);
       %if sum(isnan(plgx2))>0, sgn=[]; return; end
       mask = poly2mask(double(plgx2),double(plgy2),size(img2,1),size(img2,2));
       f = find(mask);
       int = 0;
       if ~isempty(f)
          for px = f'
               int = int+img2(px)*aip(plgx,plgy,c(px),r(px));
          end
       end
          outputSignal(i) = sum(int);
   end
end
end