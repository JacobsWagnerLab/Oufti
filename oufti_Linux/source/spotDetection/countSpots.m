%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function intensityIndex = countSpots(ims)
%oufti.v1.0.5
%@author:  Ahmad J Paintdakhi
%@date:    September 6 2012
%update:   Septmeber 11 2012
%@copyright 2012-2013 Yale University

%=================================================================================
%**********output********:
%intensityIndex -- pixel cutoff threshold used for acquriring sptos.

%**********Input********:
%ims -- filtered image/images where spots are counted.
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
function intensityIndex = countSpots(ims)

% The images are now contained in the variable "ims"

% Convert to double.
% ims = im2double(ims);

% Now run the data through a linear filter to enhance particles
%ims2 = LOG_filter(ims);

% Normalize ims2
ims2 = ims/max(ims(:));

% This function call will find the number of mRNAs for all thresholds
thresholdfn = multiThreshStack(ims2);

% These are the thresholds
thresholds = (1:100)/100;

% Let's plot the threshold as a function of the number of mRNAs
figure(1)
plot(thresholds, thresholdfn);
xlabel('Threshold');
ylabel('Number of spots counted');
% Zoom in on important area
ylim([0 2000]);

% In this case, the appropriate threshold is around 0.23 or so.

% This code helps extract the number of mRNA from the graph

title('Click at appropriate x/threshold value and hit return')

[x,y] = getpts;
line([x x],[0 2000]);
intensityIndex = x;
%intensityIndex = round(x*100); % 100 is the number of thresholds
end
%number_of_mrna = thresholdfn(x)




