function contrastSlider(hObject,~)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function contrastSlider(hObject,eventdata)
%This function modifies the pixel intensity of an image to better visualize
%spots that are low in intensity compare to the rest of the image.  The
%slider helps user chose between different pixel intenisty and back to
%original image by pushing the slider to its initial position of 0.
%oufti.v0.2.4
%@author:  Ahmad J Paintdakhi
%@date:    Nov 8-9 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%no output but the global variables handles1 and imageHandle are updated.
%**********Input********:
%no input -- global variables being used
%==========================================================================
global handles1 imageHandle
try
    if (hObject == handles1.contrastSlider) && ishandle(imageHandle.himage)
        imageData = imageHandle.hImageHistory;
        maxContrastValue = max(max(imageData));
        contrastValue = get(handles1.contrastSlider,'Value');
        newImageData = imadjust(imageData,[contrastValue maxContrastValue],...
                       [contrastValue maxContrastValue  ],0.5);
        set(imageHandle.himage,'CData',newImageData);
        if (contrastValue == get(handles1.contrastSlider,'min'))
            set(imageHandle.himage,'CData',imageHandle.hImageHistory);
        end
    end
catch
    return;
end
end