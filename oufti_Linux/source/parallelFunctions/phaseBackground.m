%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Function phaseBackground needed
%by processCell Function.  Ahmad.P May 11 2012
function bgr = phaseBackground(img,thres,se,bgrErodeNum)
    mask = ~im2bw(img,thres);
    for k=1:bgrErodeNum, mask = imerode(mask,se); end
    bgr = mean(img(mask));
end

