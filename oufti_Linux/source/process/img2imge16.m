function im2 = img2imge16(im,nm,se)
% erodes image "im" by "nm" pixels
%global se
im2 = im;
for i=1:nm, im2 = imerode(im2,se);end
end