function [cimage,cimageF,cimage0] = convertimages(frame,preFilter,params,se,images)

try
cimage0 = im2double(images(:,:,frame));
cimage0 = imresize(cimage0,params.resize);
cimageF = filterImage(cimage0,params,se);
if params.minprefilterh>0,cimageF = cimageF.*(cimageF>params.minprefilterh); end
cimage  = imfilter(cimage0,preFilter,'replicate');
cimage0 = LOG_filter(cimage0);
catch err
      disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
 
end
end