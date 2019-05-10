function res = spsmooth(x,y,p,xx)
    % A simple smoothing cubic spline routine. It takes original points y, 
    % their parameterization x, tolerance p, and the new parameterization xx.
    xi = reshape(x,[],1); % make x vertical
    yi = y'; % make y vertival
    n = size(xi,1);
    ny = size(yi,2);
    nn = ones(1,ny);
    dx = diff(xi);
    drv = diff(yi)./dx(:,nn);
    % adx = abs(dx);
    % w = max([adx;0],[0;adx])/mean(adx);
    w = ones(length(x),1);
    if n>2
       idx = 1./dx;
       R = spdiags([dx(2:n-1), 2*(dx(2:n-1)+dx(1:n-2)), dx(1:n-2)], -1:1, n-2, n-2);
       Qt = spdiags([idx(1:n-2), -(idx(2:n-1)+idx(1:n-2)), idx(2:n-1)], 0:2, n-2, n);
       W = spdiags(w,0,n,n);
       Qtw = Qt*spdiags(sqrt(w),0,n,n);
       u = ((6*(1-p))*(Qtw*Qtw.')+p*R)\diff(drv);
       yi = yi - (6*(1-p))*W*diff([zeros(1,ny); diff([zeros(1,ny);u;zeros(1,ny)])./dx(:,nn); zeros(1,ny)]);
       c3 = [zeros(1,ny);p*u;zeros(1,ny)];
       c2 = diff(yi)./dx(:,nn)-dx(:,nn).*(2*c3(1:n-1,:)+c3(2:n,:));
       coefs = reshape([(diff(c3)./dx(:,nn)).',3*c3(1:n-1,:).',c2.',yi(1:n-1,:).'],(n-1)*ny,4);
    else % straight line output
       coefs = [drv.' yi(1,:).'];
    end
    breaks = xi.';
    sizec = size(coefs);
    k = sizec(end);
    l = prod(sizec(1:end-1))/ny;
    [mx,nx] = size(xx);
    lx = mx*nx;
    xs = reshape(xx,1,lx);
    [tmp,index] = histc(xs,[-inf,breaks(2:end-1),inf]);
    NaNx = find(index==0);
    index = min(index,numel(breaks)-1);
    index(NaNx) = 1;
    xs = xs-breaks(index);
    xs = reshape(repmat(xs,ny,1),1,ny*lx);
    index = reshape(repmat(1+ny*index,ny,1)+repmat((-ny:-1).',1,lx), ny*lx, 1 );
    v = coefs(index,1).';
    for i=2:k
       v = xs.*v + coefs(index,i).';
    end
    if ~isempty(NaNx) && k==1 && l>1, v = reshape(v,ny,lx); v(:,NaNx) = NaN; end
    v = reshape(v,ny*mx,nx);
    
    res = reshape(v,[ny,length(xx)]);
end