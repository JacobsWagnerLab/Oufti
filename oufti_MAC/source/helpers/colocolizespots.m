function varargout=colocolizespots(varargin)
% [<arr>,<cellList>]=colocolizespots(<cellList1>,<cellList2>,<output type>)
% OUTPUTS (all optional)
% <arr> - 2D table of spots positions with columns:
% frame | cell | spot1 | data (as many columns as spot2 length)
% <cellList> - standard format + .colocolize field for each cell
% INPUTS (all optional)
% <cellList1>,<cellList2> - data in cellList format for both colors
% <output type> - 'xls' to output as .xls file, 'list' for cellList format,
% 'both' for both, the program will request the file name in a dialog
if nargin>=1 && ischar(varargin{nargin}), input=varargin{nargin}; nrg=nargin-1; else input=''; nrg=nargin; end
global colocolizespotsMeshFile1 colocolizespotsMeshFile2
if nrg>=1
    if isempty(who('colocolizespotsMeshFile1')), colocolizespotsMeshFile1=''; end
    [FileName,PathName] = uigetfile('*.mat','Select file with signal 1 spots',colocolizespotsMeshFile1);
    if isempty(FileName)||isequal(FileName,0), return, end
    colocolizespotsMeshFile1 = [PathName '/' FileName];
    lst1 = load(colocolizespotsMeshFile1,'cellList');
else
    lst1.cellList = varargin{1};
end
if nrg>=2
    if isempty(who('colocolizespotsMeshFile2')), colocolizespotsMeshFile2=''; end
    [FileName,PathName] = uigetfile('*.mat','Select file with signal 2 spots',colocolizespotsMeshFile2);
    if isempty(FileName)||isequal(FileName,0), return, end
    colocolizespotsMeshFile2 = [PathName '/' FileName];
    lst2 = load(colocolizespotsMeshFile2,'cellList');
else
    lst2.cellList = varargin{2};
end
ind=0;
arr = [];
if isfield(lst1.cellList,'meshData'), lst1.cellList = lst1.cellList.meshData; end
if isfield(lst2.cellList,'meshData'), lst2.cellList = lst2.cellList.meshData; end
xarr = {'frame','cell','spot1 #','spot2 #','','','','','';'','','',1,2,3,4,5,6};
for frame=1:length(lst1.cellList)
    for cell=1:length(lst1.cellList{frame})
        if length(lst1.cellList{frame})>=cell && length(lst2.cellList{frame})>=cell ...
                && ~isempty(lst1.cellList{frame}{cell}) && ~isempty(lst2.cellList{frame}{cell}) ...
                && isfield(lst1.cellList{frame}{cell},'spots') && isfield(lst2.cellList{frame}{cell},'spots') ...
                && ~isempty(lst1.cellList{frame}{cell}.spots.positions) && ~isempty(lst2.cellList{frame}{cell}.spots.positions)
            spt1 = lst1.cellList{frame}{cell}.spots;
            spt2 = lst2.cellList{frame}{cell}.spots;
            tbl = sqrt((repmat(spt1.x',1,length(spt2.x))-repmat(spt2.x,length(spt1.x),1)).^2 ...
                +(repmat(spt1.y',1,length(spt2.x))-repmat(spt2.y,length(spt1.x),1)).^2);
            arr(ind+1:ind+size(tbl,1),4:3+size(tbl,2))=tbl;
            arr(ind+1:ind+size(tbl,1),1)=frame;
            arr(ind+1:ind+size(tbl,1),2)=cell;
            arr(ind+1:ind+size(tbl,1),3)=(1:size(tbl,1))';
            xarr{ind+3:ind+size(tbl,1)+2,4:3+size(tbl,2)} = num2cell(tbl);
            xarr{ind+3:ind+size(tbl,1)+2,1} = num2cell(repmat(frame,size(tbl,1),1));
            xarr{ind+3:ind+size(tbl,1)+2,2} = num2cell(repmat(cell,size(tbl,1),1));
            xarr{ind+3:ind+size(tbl,1)+2,3} = num2cell((1:size(tbl,1))');
            lst1.cellList{frame}{cell}.spots2 = lst2.cellList{frame}{cell}.spots;
            lst1.cellList{frame}{cell}.colocolize = tbl;
            ind = ind + size(tbl,1);
        end
    end
end
if nargout>=1, varargout{1}=arr; end
if nargout>=2, varargout{2}=lst1.cellList; end
if strcmp(input,'xls') || strcmp(input,'excel') || strcmp(input,'both')
    [FileName,PathName] = uiputfile('*.mat','Select file to write excel data to',colocolizespotsMeshFile1);
    if isempty(FileName)||isequal(FileName,0), return, end
    outfile = [PathName '/' FileName];
    xlswrite(outfile,xarr)
end
if strcmp(input,'cellList') || strcmp(input,'list') || strcmp(input,'both')
    [FileName,PathName] = uiputfile('*.mat','Select file to write cellList to',colocolizespotsMeshFile1);
    if isempty(FileName)||isequal(FileName,0), return, end
    outfile = [PathName '/' FileName];
    save(outfile,'-struct','lst1')
end