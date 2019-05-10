function [extDx,extDy,imageForce]=getExtForces(im,im16,maskdx,maskdy,p,imageForce)
% computes the image forces from the image im using parameters
% p.forceWeights, p.dmapThres, p.dmapPower, and p.gradSmoothArea
% "im" - original phase image, "im16" - eroded image, outpits energy mast -
% same size as the microscope images.
%global p maskdx maskdy  
    % Edge forces
    extDx = [];
    extDy = [];
   if isempty(imageForce.forceX)
      [fex,fey] = edgeforce(im16,p.edgeSigmaL);
      imageForce.forceX = fex;
      imageForce.forceY = fey;
   else
      fex = imageForce.forceX;
      fey = imageForce.forceY;
   end
  %Edge Forces Generalized gradient vector flow (ggvf)
% % %     [fex,fey] = imgradient(double(im16),'Sobel');
% % %     fex = sign(fex);
% % %     fey = sign(fey);
    % Gradient forces
    gradSmoothFilter = fspecial('gaussian',2*ceil(1.5*p.gradSmoothArea)+1,p.gradSmoothArea);
    gradSmoothImage = imfilter(im,gradSmoothFilter); % this filtered image is going to be used in ther sections
    gradThres = mean(mean(gradSmoothImage(gradSmoothImage>mean(mean(gradSmoothImage)))));
    gradEnergy = imfilter(im,maskdx).^2 + imfilter(im,maskdy).^2;
% % %     gradEnergyGreaterThanZero = gradEnergy>0;
% % %     gradEnergyLessThanZero    = gradEnergy<0;
% % %     gradEnergyEqualZero       = gradEnergy==0;
% % %     gradEnergy(gradEnergyGreaterThanZero) = 1;
% % %     gradEnergy(gradEnergyLessThanZero )   = -1;
% % %     gradEnergy(gradEnergyEqualZero)       = 0;
% % %     gradEnergy = gradEnergy./(gradEnergy + gradThres^2);
% % %     
    
    
    gradEnergy = - gradEnergy./(gradEnergy + gradThres^2);
    gradDx = imfilter(gradEnergy,maskdx);
    gradDy = imfilter(gradEnergy,maskdy);
    gradDxyMax = max(max(max(abs(gradDx))),max(max(abs(gradDy))));
    gradEnergy = gradEnergy/gradDxyMax; % normalize to make the max force equal to 1

    % Threshold forces
    thresLevel = p.thresFactorF*graythreshreg(gradSmoothImage,p.threshminlevel); % Use the same filtering as in gradient section
    thresEnergy = (gradSmoothImage-thresLevel).^2;
% % %     thresEnergyGreaterThanZero = thresEnergy>0;
% % %     thresEnergyLessThanZero    = thresEnergy<0;
% % %     thresEnergyEqualZero       = thresEnergy==0;
% % %     thresEnergy(thresEnergyGreaterThanZero) = 1;
% % %     thresEnergy(thresEnergyLessThanZero )   = -1;
% % %     thresEnergy(thresEnergyEqualZero)       = 0;
    thresDx = imfilter(thresEnergy,maskdx);
    thresDy = imfilter(thresEnergy,maskdy);
    thresDxyMax = max(max(max(abs(thresDx))),max(max(abs(thresDy))));
    thresEnergy = thresEnergy/thresDxyMax; % normalize to make the max force equal to 1

    % Combined force
    extEnergy = gradEnergy*p.forceWeights(2) ...
              + thresEnergy*p.forceWeights(3);
    extDx = imfilter(extEnergy,maskdx)+fex*p.forceWeights(1);
    extDy = imfilter(extEnergy,maskdy)+fey*p.forceWeights(1);

end
 
