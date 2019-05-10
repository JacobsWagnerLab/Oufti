function rawS1Data=subtractbgr(rawPhaseData,rawS1Data,range)
% This finctions subtracts the background from a range of frames in a stack
if isempty(range), range = [1 10000]; end
if length(range)==1, range = [range range]; end
range=[max(1,range(1)) min(size(rawS1Data,3),size(rawPhaseData,3),range(2))];
if range(1)>range(2), range(1)=range(2); end
for i=range(1):range(2)
    imgP = rawPhaseData(:,:,i);
    if channels(g)==3, img = rawS1Data(:,:,i); end
    if channels(g)==4, img = rawS2Data(:,:,i); end
    thres = graythresh(imgP);
    mask = im2bw(imgP,thres);
    for k=1:p.bgrErodeNum, mask = imerode(mask,se); end
    bgr = mean(img(mask));
    img = uint16(max(0,int32(img)-bgr));
    if mod(i,5)==0, disp(['Subtracting backgroung from signal ' num2str(channels(g)-2) ', frame ' num2str(i)]); end
end