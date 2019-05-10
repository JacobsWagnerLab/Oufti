function bgr = phasebgr(img,thres,se,bgrErodeNum)
    %global se p
    mask = ~im2bw(img,thres);
    for k=1:bgrErodeNum, mask = imerode(mask,se); end
    bgr = mean(img(mask));
end