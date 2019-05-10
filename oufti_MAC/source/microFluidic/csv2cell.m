function [data,paramString] = csv2cell(fname,delimiter,comment,quotes,options,frameNumber)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%oufti
%@author:  Ahmad Paintdakhi
%@date:    December 19, 2012
%@modified: January 21, 2014
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%data:  cellList structure with cell array of frames and cell array of
%cells.  If the text data containts "cellId" field name then the
%structure will contain two field names: 1. meshData and 2. cellId.  The
%meshData field containts a cell array of frames and cell array of cells
%while the cellId contains the ids for each cell in a given frame.  The
%cellId element is needed as empty cells were deleted from the cells
%array to conserve space and memory.
%If no elements2id field is found in the text file then the output will
%simply be a cell array of frames containing cell array of cells for each
%frame.
%**********Input********:
%fname:     the file to be read.
%delimiter: (default: ',') any string. May be a regexp, but this is a bit
%           slow on large files. 
%comment:   (default: '') zero or one character. Anything after 
%           (and including) this character, until the end of the 
%           line, will be ignored.
%quotes:    (default: '') zero, one (opening quote equals closing), or two
%characters (opening and closing quote) to be treated as paired braces. 
%           Everything between the quotes will be treated as one item. 
%           The quotes will remain. Quotes may be nested.
% 
% options:  (default: '') may contain (concatenate combined options): 
%           - 'textual': no numeric conversion ('data' is a cell array of 
%               strings only), 
%           - 'numeric': everything is converted to a number or NaN 
%               ('data' is a numeric array, empty items 
%           are converted to NaNs unless 'empty2zero' is given), 
%           - 'empty2zero': an empty field is saved as zero, and 
%           - 'empty2NaN': an empty field is saved as NaN. 
%           - 'usewaitbar': call waitbar to report progress. 
%           If you find the wait bar annoying, get 'waitbar 
% [cellList,paramString] = csv2cell(filename, ',', '#', '"','textual-usewaitbar');
%==========================================================================

% Read (or set to default) the input arguments.
if((nargin < 1) || ~ischar(fname) || isempty(fname))% Is there a file name?
	error('First argument must be a file name!'); 
end
if(nargin < 2), delimiter=	',';				end	% Default delimiter value.
if(nargin < 3), comment=	'';					end	% Default comment value.
if(nargin < 4), quotes=		'';					end	% Default quotes value.
if(nargin < 5), options=	[];					end	% Default options value.
	
options=		lower(options);
op_waitbar=		~isempty(strfind(options, 'usewaitbar'));% Do waitbar calls. 
op_numeric=		~isempty(strfind(options, 'numeric'));	% Read as numerical. 
op_textual=		~isempty(strfind(options, 'textual')) && ~op_numeric;% Read as textual. 
op_empty=		[];% Ignore empties, ...
if(~isempty(strfind(options, 'empty2zero')))
	op_empty=		0;% ... or replace by zero ...
elseif(op_numeric || ~isempty(strfind(options, 'empty2nan')))
		op_empty=		NaN;% ... or replace by NaN.
end
if(op_textual), op_empty= num2str(op_empty);	end	% Textual 'empty'.
if(~ischar(comment) || (length(comment) > 1))
	error('Argument ''comment'' must be a string of maximum one character.');
end
if(~ischar(quotes) || (length(quotes) > 2))
	error('Argument ''quotes'' must be a string of maximum two characters.');
end
	
% Set the default return values.
result.min=		Inf;
result.max=		0;
result.quote=	0;
	
% Read the file.
[fid, errmess]=	fopen(fname, 'r');% Open the file.
closeFile = onCleanup(@()fclose(fid));
if(fid < 0), error(['Trying to open ' fname ': ' errmess]); end
text=			fread(fid, 'uchar=>char')';	% Read the file.
if ~isempty(frameNumber)
    frameValue = ['#' num2str(frameNumber) ','];
    fileLocation = strfind(text,frameValue); 
    try
        text = text(fileLocation(1)-1:fileLocation(end)-1);
    catch err
       try
           if strcmpi(err.identifier,'MATLAB:badsubscript')
               disp(['Data being loaded does not contain frame number ' num2str(frameNumber)])
           end
       catch err
           disp(err.message);
           data = [];
           paramString = [];
        return;
       end
       data = [];
       paramString = [];
       return;
    end
end
    
    
delete(closeFile);	% Close the file.
%if(op_waitbar)
%	th= waitbar(0, '(readtext) Initialising...');% Show waitbar.
%	thch=			findall(th, '-property', 'Interpreter');
%	set(thch, 'Interpreter', 'none');% No (La)TeX) formatting. 
%end	
% Clean up the text.
eol=			char(10);
% % % 	text=			strrep(text, [char(13) char(10)], eol);% Replace Windows-style eol.
% % % 	text=			strrep(text, char(13), eol);% Replace MacClassic-style eol.
if(~isempty(comment))	% Remove comments.
% % % 		text=	regexprep(text, ['^' comment ], '');% Remove commented lines. 
% % % 		text=	regexprep(text, [comment '[^\n]*'], '');% Remove commented line endings.
    text = strrep(text,comment,''); % remove comment from all lines.
end
if(text(end) ~= eol), text= [text eol];	end	% End string with eol, if none.
	
% Find column and row dividers.
delimiter=		strrep(delimiter, '\t', char( 9));% Convert to one char, quicker?
delimiter=		strrep(delimiter, '\n', char(10));
delimiter=		strrep(delimiter, '\r', char(10));
delimiter=		strrep(delimiter, '\f', char(12));
if(1 == length(delimiter))	% Find column dividers quickly.
	delimS=		find((text == delimiter) | (text == eol));
	delimE=		delimS;
elseif(isempty(regexp(delimiter, '[\+\*\?\|\[^$<>]', 'once')))% Find them rather quickly.
	delimS=		strfind(text, delimiter);
	eols=		find(text == eol);
	delimE=		union(eols, delimS + length(delimiter) - 1);
	delimS=		union(eols, delimS);
else	% Find them with regexp.
	[delimS, delimE]=	regexp(text, [delimiter '|' eol]);
end
divRow=			[0, find(text == eol), length(text)];% Find row dividers+last.
	
% Keep quoted text together.
if(~isempty(quotes))% Should we look for quotes?
	if((length(quotes) == 1) || (quotes(1) == quotes(2)))% Opening char == ending.
		exclE=			find(text == quotes(1));
		exclS=			exclE(1:2:end);
		exclE=			exclE(2:2:end);
	else	% Opening char ~= closing.
		exclS=			find(text == quotes(1));
		exclE=			find(text == quotes(2));
    end
    if((length(exclS) ~= length(exclE)) || (sum(exclS > exclE) > 0))
		%if(op_waitbar), close(th); 	end	% Close waitbar or it'll linger.
		error('Opening and closing quotes don''t match in file %s.', fname); 
	end
	if(~isempty(exclS))	% We do have quoted text.
		%if(op_waitbar), waitbar(0, th, '(readtext) Doing quotes...'); end	% Inform user.
			r=		1;
			rEnd=	length(exclS);
			n=		1;
			nEnd=	length(delimS);
			result.quote=	rEnd;
			while((n < nEnd) && (r < rEnd)) % "Remove" delimiters and newlines within quyotes.
				while((r <= rEnd) && (delimS(n) > exclE(r))), r= r+1;	end
				while((n <= nEnd) && (delimS(n) < exclS(r))), n= n+1;	end
				while((n <= nEnd) && (delimS(n) >= exclS(r)) && (delimS(n) <= exclE(r)))
					delimS(n)=	0;
					n=			n+1;
				end
				if((bitand(n, 255) == 0) && op_waitbar), waitbar(n/nEnd); end	% Update waitbar.
			end
			%if(op_waitbar), waitbar(1);	end;
			delimE=	delimE(delimS > 0);
			delimS=	delimS(delimS > 0);
	end
end
delimS=		delimS-1;	% Last char before delimiter.
delimE=		[1 delimE(1:end-1)+1];	% First char after delimiter.
	
% Do the stuff: convert text to cell (and maybe numeric) array.
%if(op_waitbar), waitbar(0, th, sprintf('(readtext) Reading ''%s''...', fname));	end
r=				1;
c=				1;	% Presize data to optimise speed.
data=			cell(length(divRow), ceil(length(delimS)/(length(divRow)-1)));
nums=			zeros(size(data));	% Presize nums to optimise speed.
nEnd=			length(delimS);		% Prepare for a waitbar.
dividerWaitbar=10^(floor(log10(nEnd))-1);% update waitbar every 10 counts
for n=1:nEnd
	temp=			text(delimE(n):delimS(n));
	data{r, c}= 	temp;	% Textual item.
	if(~op_textual), nums(r, c)= str2double(temp);	end% Quicker(!) AND better waitbar.
	if(text(delimS(n)+1) == eol)% Next row.
		result.min=		min(result.min, c);% Find shortest row.
		result.max=		max(result.max, c);	% Find longest row.
		r=				r+1;
		c=				0;
	end
	c=				c+1;
	%if((bitand(n, 255) == 0) && op_waitbar)
     %  if (round(n/dividerWaitbar)==n/dividerWaitbar)    
     %      waitbar(n/nEnd);	
      %  end
    %end% Update waitbar.
end
%if(op_waitbar), waitbar(1);	end
	
% Clean up the conversion and do the result statistics.
%if(op_waitbar), waitbar(0, th, '(readtext) Cleaning up...');	end	% Inform user.
data=				data(1:(r-1), 1:result.max);% In case we started off to big.
if(~op_textual), nums= nums(1:(r-1), 1:result.max);	end	% In case we started off to big.
if(exist('strtrim', 'builtin')), data= strtrim(data);% Not in Matlab 6.5...
else							 data= deblank(data);		
end
while(all(cellfun('isempty', data(end, :))))% Remove empty last lines. 
	data=	data(1:end-1, :); 
	nums=	nums(1:end-1, :); 
	r=		r-1;
end 
while(all(cellfun('isempty', data(:, end))))% Remove empty last columns. 
	data=	data(:, 1:end-1); 
	nums=	nums(:, 1:end-1); 
	c=		c-1;
end 
result.rows=		r-1;
empties=			cellfun('isempty', data);% Find empty items.
result.emptyMask=	empties;
if(op_textual)
	result.numberMask=	repmat(false, size(data));% No numbers, all strings.
	result.stringMask=	~empties;% No numbers, all strings.
	data(empties)=		{op_empty};	% Set correct empty value.
else
	result.numberMask=	~(isnan(nums) & ~strcmp(data, 'NaN'));% What converted well.
	if(op_numeric)
		nums(empties)=		op_empty;% Set correct empty value.
		data=				nums;	% Return the numeric array.
		result.stringMask=	~(empties | result.numberMask);	% Didn't convert well: so strs.
	else
		data(result.numberMask)= num2cell(nums(result.numberMask));	% Copy back numerics.
		data(empties)=		{op_empty};	% Set correct empty value.
		result.stringMask=	cellfun('isclass', data, 'char');% Well, the strings.
	end
end
sizeOfData = size(data);
clearvars -except data th frameNumber sizeOfData
cellIdArray = [];
tempStruct = struct('ancestors',   [],...
                    'birthframe',   [],...
                    'box',          [],...
                    'descendants',  [],...
                    'divisions',    [],...
                    'mesh',         [],...
                    'length',       [],...
                    'area',         [],...
                    'polarity',     [],...
                    'signal0',      []);
                
if ~isempty(frameNumber)
    firstFrameNumberLocation = 1;
else
    indexFrameNumber = strcmp('frameNumber',data(1:400));
    firstFrameNumberLocation = find(indexFrameNumber);
end

numRows = size(data,1) - firstFrameNumberLocation;
dataArray = cell(numRows,12);
cellIdLocation = find(strcmp('$ cellId',data));
if isempty(cellIdLocation), cellIdLocation = find(strcmp('$ element2id',data)); end
if ~isempty(cellIdLocation)
    dataArrayAll = cellfun(@str2num,data(firstFrameNumberLocation+1:end,:),'UniformOutput',0);
    dataArray = dataArrayAll(1:(cellIdLocation-(firstFrameNumberLocation+1)),:);
    cellIdArray = dataArrayAll((cellIdLocation-firstFrameNumberLocation)+1:end,1);
else
    dataArray(:,1)   = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,1),'UniformOutput',0),'UniformOutput',0);
    dataArray(:,2)   = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,2),'UniformOutput',0),'UniformOutput',0);
    dataArray(:,3)   = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,3),'UniformOutput',0),'UniformOutput',0);
    dataArray(:,4:7) = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,4:7),'UniformOutput',0),'UniformOutput',0);
    dataArray(:,8:10) = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,8:10),'UniformOutput',0),'UniformOutput',0);
    dataArray(:,11)  = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,11),'UniformOutput',0),'UniformOutput',0);
    if sizeOfData(2) == 12
        dataArray(:,12)  = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,12),'UniformOutput',0),'UniformOutput',0);
    elseif sizeOfData(2) == 14
        dataArray(:,12)  = cellfun(@single,cellfun(@str2num,data(firstFrameNumberLocation+1:end,14),'UniformOutput',0),'UniformOutput',0);
    end
        
end
clear dataArrayAll    
dataArray(:,4:7) = cellfun(@recip,dataArray(:,4:7),'UniformOutput',0);
dataArray(:,10) = cellfun(@recip,dataArray(:,10),'UniformOutput',0);
frameNum = cat(1,dataArray{:,1});
uniqueFrameNum = unique(frameNum);
uniqueFrameNumLength = numel(uniqueFrameNum);
tempCellList = cell(1,uniqueFrameNumLength);
fieldsTempStruct = fieldnames(tempStruct);
if size(dataArray,2) == 12
    for ii = 1:uniqueFrameNumLength
        indexCells = find(frameNum == uniqueFrameNum(ii));
        minIndexCells = min(indexCells);
        maxIndexCells = max(indexCells);
        tempCellList{ii} = cell2struct(dataArray(minIndexCells:maxIndexCells,2:11),fieldsTempStruct,2)';
        cellIdArray{ii}  = cat(2,dataArray{minIndexCells:maxIndexCells,12}); %#ok<AGROW>
    end
else
    for ii = 1:uniqueFrameNumLength
        indexCells = find(frameNum == uniqueFrameNum(ii));
        minIndexCells = min(indexCells);
        maxIndexCells = max(indexCells);
        tempCellList{ii} = cell2struct(dataArray(minIndexCells:maxIndexCells,2:11),fieldsTempStruct,2)';
    end
end
tempCellList1 = cell(size(tempCellList));
for jj = 1:length(tempCellList1)
    tempCellList1{jj} = cell(1,length(tempCellList{jj}));
    for ii = 1:length(tempCellList{jj})
        tempCellList1{jj}{ii} = tempCellList{jj}(ii);
    end
end

indexParamStartPosition = strcmp('algorithm = 4',data(1:200));
firstParamLocation = find(indexParamStartPosition);
paramString = data(firstParamLocation:firstFrameNumberLocation - 2,1);

if ~isempty(cellIdLocation) || ~isempty(cellIdArray)
    data = [];
    data.meshData = tempCellList1;
    data.cellId = cellIdArray;
else
    data = tempCellList1;
end

%---------------------------------------------------------
%this function takes the recipricol of any cell values.
function y = recip(x)
y = x';
end
%---------------------------------------------------------

%if(op_waitbar), close(th);	end	% Removing the waitbar. 

end
