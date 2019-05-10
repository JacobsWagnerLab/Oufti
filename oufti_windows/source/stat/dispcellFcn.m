function dispcellFcn
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function 
%PURPOSE:
%@author:  
%@date:    
%@copyright 2012-2015 Yale University
%==========================================================================
%**********output********:
%out1
%.
%.
%outN
%**********Input********:
%in1
%.
%.
%inN
%=========================================================================
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%pragma function needed to include files for deployment
%#function [dispcell loadimagestack]
global cellList rawS1Data
if isempty(rawS1Data)
    input = inputdlg({'path to images','frame','cell'});
    if isempty(input),return;end
else
    imageChoice = questdlg('Use current data set?','Image set','Yes','No','Yes');
    switch imageChoice
        case 'Yes'
            data = rawS1Data;
            input = inputdlg({'frame','cell'});
            if isempty(input),return;end
            if sum(cellfun(@numel,cellList.meshData)) == 0,disp('First load cell meshes'),return;end
            figure('name','cell display','NumberTitle','off');
            try
                dispcell(cellList,data,str2double(input{1}),str2double(input{2}));
            catch
            end

        case 'No'
                try
                    dataChoice = questdlg('stack?','data type','Yes','No','Yes');
                    switch dataChoice
                        case 'Yes'
                            [fileName,pathName] = uigetfile('*.tif');
                            [~,data] = loadimagestack(3,[pathName '\' fileName],1,0);
                        case 'No'
                            pathName = uigetdir('*.tif');
                            [data, ~, ~] = loadimageseries(pathName);
                    end
            
                catch
                end
                input = inputdlg({'frame','cell'});
                if isempty(input),return;end
                if sum(cellfun(@numel,cellList.meshData)) == 0,warndlg('First load cell meshes'),return;end
                figure('name','cell display','NumberTitle','off');
                try
                    dispcell(cellList,data,str2double(input{1}),str2double(input{2}));
                catch
                end

        otherwise
            return;
    end
end


end