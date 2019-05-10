function g = edgevalley(img,mode,sigmaL,sigmaV,thresh1,thresh2,thres0,slope)
% a combination of the 'valley detection' and 'LoG' algorithms
% 
% mode = 1 (log), 2 (valley), 3 (both)
% thres2 is a 'hard' threshold, thres - a 'soft' one, meaning that the
% pixel is only detected as a part of a valley if it's adjasent to a
% pixel above the hard threshold.

  img = 1-im2single(img);
  [m,n] = size(img);
  rr = 2:m-1; 
  cc = 2:n-1;
  
  if mode==1 || mode==3
      if sigmaL<0.01, sigmaL=0.01; end
      fsize = ceil(sigmaL*3) * 2 + 1;  % choose an odd fsize > 6*sigmaL;
      op = fspecial('log',fsize,sigmaL); 
      op = op - sum(op(:))/numel(op); % make the op to sum to zero
      b = imfilter(img,op,'replicate');
      if isempty(thresh1), thresh1 = .75*mean2(abs(b)); end
  else
      if isempty(thresh1), thresh1 = 0; end
  end
  
  if length(thresh1)>1, thresh1 = thresh1(rr,cc); end
  if isempty(thresh2), thresh2 = 0; end
  
  if mode==1 || mode==3
      % LoG edge  detection
      e = false(m,n);
      threshL = 0;
      [rx,cx] = find( b(rr,cc) > 0 & b(rr,cc+1) < 0 & abs( b(rr,cc)-b(rr,cc+1) ) > threshL );
      e((rx+1) + cx*m) = 1;
      [rx,cx] = find( b(rr,cc-1) < 0 & b(rr,cc) > 0 & abs( b(rr,cc-1)-b(rr,cc) ) > threshL );
      e((rx+1) + cx*m) = 1;
      [rx,cx] = find( b(rr,cc) > 0 & b(rr+1,cc) < 0 & abs( b(rr,cc)-b(rr+1,cc) ) > threshL);
      e((rx+1) + cx*m) = 1;
      [rx,cx] = find( b(rr-1,cc) < 0 & b(rr,cc) > 0 & abs( b(rr-1,cc)-b(rr,cc) ) > threshL);
      e((rx+1) + cx*m) = 1;
      [rz,cz] = find( b(rr,cc)==0 );
      if ~isempty(rz)
        zero = (rz+1) + cz*m;
        ind = b(zero-1) < 0 & b(zero+1) > 0 & abs( b(zero-1)-b(zero+1) ) > 2*threshL;
        e(zero(ind)) = 1;
        ind = b(zero-1) > 0 & b(zero+1) < 0 & abs( b(zero-1)-b(zero+1) ) > 2*threshL;
        e(zero(ind)) = 1;
        ind = b(zero-m) < 0 & b(zero+m) > 0 & abs( b(zero-m)-b(zero+m) ) > 2*threshL;
        e(zero(ind)) = 1;
        ind = b(zero-m) > 0 & b(zero+m) < 0 & abs( b(zero-m)-b(zero+m) ) > 2*threshL;
        e(zero(ind)) = 1;
      end
  end
  if mode==2 || mode==3
      % Normalization of parameters (needs to be tested)
      thresh2 = max(thresh2,0);
      thresh1 = min(max(thresh1,0),thresh2);
        % meangrad = sqrt(mean(mean((img(:,2:end)-img(:,1:end-1)).^2))+mean(mean((img(2:end,:)-img(1:end-1,:)).^2)));
        % thresh1 = thresh1*meangrad;
        % thresh2 = thresh2*meangrad;
      % Valley detection
      if sigmaV>0
          fsize = ceil(sigmaV*3) * 2 + 1;
          op = fspecial('gaussian',fsize,sigmaV); 
          op = op/sum(sum(op)); % make the op to sum to 1
          img = imfilter(img,op,'replicate');
      end
      if ~isempty(thres0) && thres0>0 && ~isempty(slope) && slope>0
          thresh1 = thresh1*(img(rr,cc)/thres0).^slope;
          thresh2 = thresh2*(img(rr,cc)/thres0).^slope;
      end
      f = false(m,n);
      f(rr,cc) = min(img(rr,cc-1)-img(rr,cc),img(rr,cc+1)-img(rr,cc))>thresh1 | ...
                 min(img(rr-1,cc)-img(rr,cc),img(rr+1,cc)-img(rr,cc))>thresh1 | ...
                 min(img(rr-1,cc-1)-img(rr,cc),img(rr+1,cc+1)-img(rr,cc))>thresh1 | ...
                 min(img(rr+1,cc-1)-img(rr,cc),img(rr-1,cc+1)-img(rr,cc))>thresh1;
      f2 = false(m,n);
      f2(rr,cc)= min(img(rr,cc-1)-img(rr,cc),img(rr,cc+1)-img(rr,cc))>thresh2 | ...
                 min(img(rr-1,cc)-img(rr,cc),img(rr+1,cc)-img(rr,cc))>thresh2 | ...
                 min(img(rr-1,cc-1)-img(rr,cc),img(rr+1,cc+1)-img(rr,cc))>thresh2 | ...
                 min(img(rr+1,cc-1)-img(rr,cc),img(rr-1,cc+1)-img(rr,cc))>thresh2;
      se = strel('arbitrary',ones(3));
      f = f & imdilate(f2,se);
  end
  if mode==1
      g = e;
  elseif mode==2
      g = f;
  elseif mode==3
      g = e | f;
  else
      g = false(m,n);
  end