function sgn = getOneSignalContourM(contour,mbox,img,rsz)
    % This function integrates signal confined within the contour (which is 
    % not segmented in the way the mesh is). This is a faster but less
    % precise MATLAB-based version.
    % 
    sgn = [];
    if length(contour)>1
        img2 = imcrop(img,mbox);
        if rsz>1
            img2 = imresize(img2,rsz);
        end
        plgx = rsz*(contour(:,1)-mbox(1)+1);
        plgy = rsz*(contour(:,2)-mbox(2)+1);
        mask = poly2mask(plgx,plgy,size(img2,1),size(img2,2));
        sgn = sum(sum(mask));
        if sgn>0, sgn=(rsz^(-2))*sum(sum(mask.*img2))*polyarea(plgx,plgy)/sgn; end
    end
end