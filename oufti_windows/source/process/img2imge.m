function im2 = img2imge(im,nm,se)
% erodes image "im" by "nm" pixels and normalizes it, outputs double
%global se
im2 = im;
for i=1:nm, im2 = imerode(im2,se);end
im2 = double(im2);
mn=mmin(im2);
mx=mmax(im2);
im2=1-(im2-mn)/double(mx-mn);
end