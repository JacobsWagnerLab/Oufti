function g = findEdges(img)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function g = findEdges(img)
%oufti.v0.2.9
%@author:  Oleksii Sliusarenko
%@modified by:  Ahmad J Paintdakhi
%@date:    March 05 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%g:  segmented image
%**********Input********:
%img:    a single image that need to be filtered
%=========================================================================
% PURPOSE:
% a combination of the 'valley detection' and 'LoG' algorithms
% 
% mode = 'none', 'log', 'valley', 'logvalley' or 0,1,2,3
% p.valleythresh2 is a 'hard' threshold, p.valleythresh1 - a 'soft' one,
%meaning that the
% pixel is only detected as a part of a valley if it's adjasent to a
% pixel above the hard threshold.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

global handles
mode = get(get(handles.SegEdgeMode,'SelectedObject'),'string');
 
if mode==0, mode='none';
elseif strcmpi(mode,'LOG'), mode='log'; % Laplacian of Gaussian (LoG) edge detection
elseif strcmpi(mode,'Valley'), mode='valley'; % Valley (ridge) detection
elseif mode==3, mode='logvalley'; % Both LoG and Valley detection
elseif strcmpi(mode,'Cross'), mode='clogvalley'; % Cross of LoG and Valley with common threshold
end
img = 1-im2single(img);
[m,n] = size(img);
  
if strcmp(mode,'log') || strcmp(mode,'logvalley') || strcmp(mode,'clogvalley')
    edgeSigmaL    = get(handles.SegEdgeSigmaL,'value');
    logThresh     = get(handles.SegLogThresh,'value');
      % LoG edge  detection
      fsize = ceil(edgeSigmaL*3)*2 + 1;  % choose an odd fsize > 6*edgeSigmaL;
      op = fspecial('log',fsize,edgeSigmaL); 
      op = op - sum(op(:))/numel(op); % make the op to sum to zero
      b = imfilter(img,op,'replicate');
      stdb = std(b(:));
      e = b>logThresh*stdb;
% % %       se = strel('arbitrary',ones(3));
% % %       e = imdilate(e&~bwmorph(e,'endpoints'),se)&e;
      e = conv2(single(e&~bwmorph(e,'endpoints')),ones(3,'single'),'same')&e;
end
if strcmp(mode,'valley') || strcmp(mode,'logvalley') || strcmp(mode,'clogvalley')
   valleyThresh1 = get(handles.SegValleyThresh1,'value');
   valleyThresh2 = get(handles.SegValleyThresh2,'value');
   edgeSigmaV    = get(handles.SegEdgeSigmaV,'value');

      % Valley detection
      se = strel('arbitrary',ones(3));
      rr = 2:m-1; 
      cc = 2:n-1;
      valleyThresh2 = max(valleyThresh2,0);
      valleyThresh1 = min(max(valleyThresh1,0),valleyThresh2);
      fsize = ceil(edgeSigmaV*3)*2 + 1;
      op = fspecial('gaussian',fsize,edgeSigmaV); 
      op = op/sum(sum(op));
      img = imfilter(img,op,'replicate');
% % %       op = fspecial('log',fsize,edgeSigmaV); 
% % %       f = imfilter(img,op,'replicate');
      f = zeros(m,n);
      f(rr,cc) = max(max(min(img(rr,cc-1)-img(rr,cc),img(rr,cc+1)-img(rr,cc)), ...
                         min(img(rr-1,cc)-img(rr,cc),img(rr+1,cc)-img(rr,cc))), ...
                     max(min(img(rr-1,cc-1)-img(rr,cc),img(rr+1,cc+1)-img(rr,cc)), ...
                         min(img(rr+1,cc-1)-img(rr,cc),img(rr-1,cc+1)-img(rr,cc))));
      fmean = mean(f(f>quantile2(f(f>0),0.99)));
      f1 = f>fmean*valleyThresh1;
      f2 = f>fmean*valleyThresh2;
% % %       for i=1:4, f2 = f1 & imdilate(f2,se); end
      for i=1:4, f2 = f1 & conv2(single(f2),ones(3,'single'),'same'); end
end

%update june 8 2012--------
if (strcmp(mode,'logvalley') || strcmp(mode,'clogvalley'))
    crossThresh = get(handles.SegCrossThresh,'value');
   c = b.*(f+fmean)>stdb*fmean*crossThresh;
else
   c = false;
end
  %-----------------------------
  if strcmp(mode,'log')
      g = e;
  elseif strcmp(mode,'valley')
      g = f2;
  elseif strcmp(mode,'logvalley')
      g = e | f2 | c;
  elseif strcmp(mode,'clogvalley')
      g = c;
  else
      g = false(m,n);
  end
  
end
  
  
  