function g = logedge(img,thresh,sigma,mode)

  % mode = 1 (log), 2 (valley), 3 (both)

  img = im2single(img);
  [m,n] = size(img);
  rr = 2:m-1; 
  cc = 2:n-1;
  if length(thresh)>1, thresh = thresh(rr,cc); end
  
  fsize = ceil(sigma*3) * 2 + 1;  % choose an odd fsize > 6*sigma;
  op = fspecial('log',fsize,sigma); 
  
  op = op - sum(op(:))/numel(op); % make the op to sum to zero
  b = imfilter(img,op,'replicate');
  
  if isempty(thresh)
    thresh = .75*mean2(abs(b));
  end
  
  if mode==1 || mode==3
      e = false(m,n);

      % Look for the zero crossings:  +-, -+ and their transposes 
      % We arbitrarily choose the edge to be the negative point
      [rx,cx] = find( b(rr,cc) < 0 & b(rr,cc+1) > 0 ...
                      & abs( b(rr,cc)-b(rr,cc+1) ) > thresh );   % [- +]
      e((rx+1) + cx*m) = 1;
      [rx,cx] = find( b(rr,cc-1) > 0 & b(rr,cc) < 0 ...
                      & abs( b(rr,cc-1)-b(rr,cc) ) > thresh );   % [+ -]
      e((rx+1) + cx*m) = 1;
      [rx,cx] = find( b(rr,cc) < 0 & b(rr+1,cc) > 0 ...
                      & abs( b(rr,cc)-b(rr+1,cc) ) > thresh);   % [- +]'
      e((rx+1) + cx*m) = 1;
      [rx,cx] = find( b(rr-1,cc) > 0 & b(rr,cc) < 0 ...
                      & abs( b(rr-1,cc)-b(rr,cc) ) > thresh);   % [+ -]'
      e((rx+1) + cx*m) = 1;

      % Most likely this covers all of the cases.   Just check to see if there
      % are any points where the LoG was precisely zero:
      [rz,cz] = find( b(rr,cc)==0 );
      if ~isempty(rz)
        % Look for the zero crossings: +0-, -0+ and their transposes
        % The edge lies on the Zero point
        zero = (rz+1) + cz*m;   % Linear index for zero points
        zz = find(b(zero-1) < 0 & b(zero+1) > 0 ...
                  & abs( b(zero-1)-b(zero+1) ) > 2*thresh);     % [- 0 +]'
        e(zero(zz)) = 1;
        zz = find(b(zero-1) > 0 & b(zero+1) < 0 ...
                  & abs( b(zero-1)-b(zero+1) ) > 2*thresh);     % [+ 0 -]'
        e(zero(zz)) = 1;
        zz = find(b(zero-m) < 0 & b(zero+m) > 0 ...
                  & abs( b(zero-m)-b(zero+m) ) > 2*thresh);     % [- 0 +]
        e(zero(zz)) = 1;
        zz = find(b(zero-m) > 0 & b(zero+m) < 0 ...
                  & abs( b(zero-m)-b(zero+m) ) > 2*thresh);     % [+ 0 -]
        e(zero(zz)) = 1;
      end
  elseif mode==2 || mode==3
      f = false(m,n);
%       [rx,cx] = find(min(b(rr,cc-1)-b(rr,cc),b(rr,cc+1)-b(rr,cc))>thresh);
%       f((rx+1) + cx*m) = 1;
%       [rx,cx] = find(min(b(rr-1,cc)-b(rr,cc),b(rr+1,cc)-b(rr,cc))>thresh);
%       f((rx+1) + cx*m) = 1;
%       [rx,cx] = find(min(b(rr-1,cc-1)-b(rr,cc),b(rr+1,cc+1)-b(rr,cc))>thresh);
%       f((rx+1) + cx*m) = 1;
%       [rx,cx] = find(min(b(rr+1,cc-1)-b(rr,cc),b(rr-1,cc+1)-b(rr,cc))>thresh);
%       f((rx+1) + cx*m) = 1;
      
      f(rr,cc) = (min(b(rr,cc-1)-b(rr,cc),b(rr,cc+1)-b(rr,cc))>thresh & max(img(rr,cc-1)-img(rr,cc),img(rr,cc+1)-img(rr,cc))<0) | ...
          (min(b(rr-1,cc)-b(rr,cc),b(rr+1,cc)-b(rr,cc))>thresh & max(img(rr-1,cc)-img(rr,cc),img(rr+1,cc)-img(rr,cc))<0) | ...
          (min(b(rr-1,cc-1)-b(rr,cc),b(rr+1,cc+1)-b(rr,cc))>thresh & max(img(rr-1,cc-1)-img(rr,cc),img(rr+1,cc+1)-img(rr,cc))<0) | ...
          (min(b(rr+1,cc-1)-b(rr,cc),b(rr-1,cc+1)-b(rr,cc))>thresh & max(img(rr+1,cc-1)-img(rr,cc),img(rr-1,cc+1)-img(rr,cc))<0);
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