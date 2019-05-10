function [lsq, e] = linfitfn(x,y)
A = [ones(length(x),1),x];
ws = warning('off','all'); 
lsq = (A'*A)^(-1)*A'*y;
warning(ws);
e = sum(abs(y - A*lsq));
end