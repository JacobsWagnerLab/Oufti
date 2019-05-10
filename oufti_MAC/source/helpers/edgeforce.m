function [forceX,forceY] = edgeforce(imageData,sigmaL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function [forceX,forceY] = edgeforce(imageData,sigmaL)
%oufti.v0.3.2
%@author:  oleksii sliusarenko
%modified: August 5, 2013  --- Ahmad J. Paintdakhi
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%forceX: image force in the x-direction.
%forceY: image force in the y-direction.
%**********Input********:
%imageData:   current image that is used for force extraction
%sigmaL:    length of sigma for LOG-based edge method.
%=========================================================================
% PURPOSE:
% a spin-off of edgevalley/logvalley function that gets the edge forces
% based on the LoG-based edge proximity
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

% masks for computing x & y derivatives
maskdx = fliplr(fspecial('sobel')'); %[-1 0 1; -2 0 2; -1 0 1]/2; 
maskdy = fspecial('sobel');%[1 2 1; 0 0 0; -1 -2 -1]/2;

imageData = 1-im2double(imageData);
[m,n] = size(imageData);
rr = 2:m-1; 
cc = 2:n-1;

if true
  % LoG edge  detection (so far only this mode in the function)
  if sigmaL<0.01, sigmaL=0.01; end
  fsize = ceil(sigmaL*3)*2 + 1;  % choose an odd fsize > 6*sigmaL;
  op = fspecial('log',fsize,sigmaL); 
  op = op - sum(op(:))/numel(op); % make the op to sum to zero
  b = imfilter(imageData,op,'replicate');
  % get positive side of the edge
  e1 = false(m,n);
  threshL = 0;
  [rx,cx] = find( b(rr,cc) > 0 & b(rr,cc+1) < 0 & abs( b(rr,cc)-b(rr,cc+1) ) > threshL );
  e1((rx+1) + cx*m) = 1;
  [rx,cx] = find( b(rr,cc-1) < 0 & b(rr,cc) > 0 & abs( b(rr,cc-1)-b(rr,cc) ) > threshL );
  e1((rx+1) + cx*m) = 1;
  [rx,cx] = find( b(rr,cc) > 0 & b(rr+1,cc) < 0 & abs( b(rr,cc)-b(rr+1,cc) ) > threshL);
  e1((rx+1) + cx*m) = 1;
  [rx,cx] = find( b(rr-1,cc) < 0 & b(rr,cc) > 0 & abs( b(rr-1,cc)-b(rr,cc) ) > threshL);
  e1((rx+1) + cx*m) = 1;
  [rz,cz] = find( b(rr,cc)==0 );
  if ~isempty(rz)
    zero = (rz+1) + cz*m;
    ind = b(zero-1) < 0 & b(zero+1) > 0 & abs( b(zero-1)-b(zero+1) ) > 2*threshL;
    e1(zero(ind)) = 1;
    ind = b(zero-1) > 0 & b(zero+1) < 0 & abs( b(zero-1)-b(zero+1) ) > 2*threshL;
    e1(zero(ind)) = 1;
    ind = b(zero-m) < 0 & b(zero+m) > 0 & abs( b(zero-m)-b(zero+m) ) > 2*threshL;
    e1(zero(ind)) = 1;
    ind = b(zero-m) > 0 & b(zero+m) < 0 & abs( b(zero-m)-b(zero+m) ) > 2*threshL;
    e1(zero(ind)) = 1;
  end
  % get negative side of the edge
  e2 = false(m,n);
  threshL = 0;
  [rx,cx] = find( b(rr,cc) < 0 & b(rr,cc+1) > 0 & abs( b(rr,cc)-b(rr,cc+1) ) > threshL );
  e2((rx+1) + cx*m) = 1;
  [rx,cx] = find( b(rr,cc-1) > 0 & b(rr,cc) < 0 & abs( b(rr,cc-1)-b(rr,cc) ) > threshL );
  e2((rx+1) + cx*m) = 1;
  [rx,cx] = find( b(rr,cc) < 0 & b(rr+1,cc) > 0 & abs( b(rr,cc)-b(rr+1,cc) ) > threshL);
  e2((rx+1) + cx*m) = 1;
  [rx,cx] = find( b(rr-1,cc) > 0 & b(rr,cc) < 0 & abs( b(rr-1,cc)-b(rr,cc) ) > threshL);
  e2((rx+1) + cx*m) = 1;
  [rz,cz] = find( b(rr,cc)==0 );
  if ~isempty(rz)
    zero = (rz+1) + cz*m;
    ind = b(zero-1) > 0 & b(zero+1) < 0 & abs( b(zero-1)-b(zero+1) ) > 2*threshL;
    e2(zero(ind)) = 1;
    ind = b(zero-1) < 0 & b(zero+1) > 0 & abs( b(zero-1)-b(zero+1) ) > 2*threshL;
    e2(zero(ind)) = 1;
    ind = b(zero-m) > 0 & b(zero+m) < 0 & abs( b(zero-m)-b(zero+m) ) > 2*threshL;
    e2(zero(ind)) = 1;
    ind = b(zero-m) < 0 & b(zero+m) > 0 & abs( b(zero-m)-b(zero+m) ) > 2*threshL;
    e2(zero(ind)) = 1;
  end

% % %   se = strel('arbitrary',ones(3));
% % %   e1 = imdilate(e1&~bwmorph(e1,'endpoints'),se)&e1;
% % %   e1a = imdilate(e1,se)&(b>0)&~e1;
% % %   e2a = imdilate(e2,se)&~e2&(b<0);
  e1 = conv2(single(e1&~bwmorph(e1,'endpoints')),ones(3,'single'),'same')&e1;
  e1a = conv2(single(e1),ones(3,'single'),'same')&(b>0)&~e1;
  e2a = conv2(single(e2),ones(3,'single'),'same')&~e2&(b<0);
  fex = - b.*(imfilter(e2+0,maskdx).*e1-imfilter(e1+0,maskdx).*e2 + (imfilter(e1+0,maskdx).*e1a-imfilter(e2+0,maskdx).*e2a)/2);
  fey = - b.*(imfilter(e2+0,maskdy).*e1-imfilter(e1+0,maskdy).*e2 + (imfilter(e1+0,maskdy).*e1a-imfilter(e2+0,maskdy).*e2a)/2);
  feall = [abs(fex(:));abs(fey(:))];
  nrm = mean(feall(feall>quantile2(feall,0.99)))*2;
  forceX = fex./nrm;
  forceY = fey./nrm;

end
  
end


