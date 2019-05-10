function str2 = reorient(cellStructure)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cellList = removeorientationall(cellList,cellId)
%oufti.v0.2.8
%@author:  oleksii Sliusarenko
%@update:  Ahmad J. Paintdakhi
%@date:    March 27, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%cellList:    updated cellList changes to the polarity field in all data in
%             cellList
%**********Input********:
%cellList:    A structure containing two fields meshData and cellId
%cellId:    cellId is the cell # where field changes will occur.
%==========================================================================
%The function reorients fields in a given cellStructure.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------

names = fieldnames(cellStructure);
% flip the orientation of the data arrays (of every vertical array)
for i=1:length(names)
    t=['str2.' names{i} '=flipud(cellStructure.' names{i} ');'];
    eval(t);
end
% if mesh is flipped, preserve the clockwise orientation of the outline
if ismember('mesh',names) && numel(str2.mesh)>1
   str2.mesh = str2.mesh(:,[3 4 1 2]);
end
% change the models for particular algorithms
if ismember('model',names) && ismember('algorithm',names)
   if ismember(cellStructure.algorithm,[1 2])
      str2.model(1) = mod(cellStructure.model(1) + pi,2*pi);
   elseif ismember(cellStructure.algorithm,3)
      str2.model(3) = mod(cellStructure.model(3) + pi,2*pi);
   elseif ismember(cellStructure.algorithm,4)
      s = size(cellStructure.model,1);
      s2 = floor(s/2);
      if s>1
         str2.model = [cellStructure.model(s2+1:s,:);cellStructure.model(1:s2,:)];
      end
   end
end
% reorient spots data (assuming the spots structure name starts with
% 'spots' and all spots sub-arrays are horizontal)
for i=1:length(names)
    if length(names{i})>=5 && strcmp('spots',names{i}(1:5))
       names2 = {};
       eval(['names2 = fieldnames(cellStructure.' names{i} ');'])
       if ismember('positions',names2)
          eval(['str2.' names{i} '.l = cellStructure.length-cellStructure.' names{i} '.l;'])
          eval(['str2.' names{i} '.positions = size(cellStructure.mesh,1)+1-cellStructure.' names{i} '.positions;'])
          eval(['names2 = fieldnames(cellStructure.' names{i} ');'])
          for j=1:length(names2)
              t=['str2.' names{i} '.' names2{j} '=fliplr(str2.' names{i} '.' names2{j} ');'];
              eval(t);
          end
       end
    end
end
% reorient lengthvector (the only aray for which flip is insufficient)
if ismember('lengthvector',names) && ismember('length',names)
   str2.lengthvector = str2.length-str2.lengthvector;
end
end