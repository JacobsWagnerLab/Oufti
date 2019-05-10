function setbar(varargin)
% This function sets new parameters for a bar group, referenced by the axes
% handles, including the 'gap' parameter, indicating the width of the gap
% between bar groups in the units of space allocated for individual bars.
%
% setbar(axes,property,property value,...)
%
% The properties are the same as for barseries, with 'gap' added
% (width of the gap between bar groups relative to the bar width)

hnd = varargin{1};
if length(hnd)~=1 || ~ishandle(hnd) || ~strcmp(get(hnd,'Type'),'axes')
    return
end
gap = [];
i=0;
imax = nargin-1;
while true
    i=i+1;
    if i>imax, break; end
    if ischar(varargin{i}) && strcmp(varargin{i},'gap') && i<nargin && strcmp(class(varargin{i+1}),'double')
        gap = varargin{i+1};
        varargin = varargin([1:i-1 i+2:end]);
        imax = imax-2;
    end
end
argline = '';
for i=2:length(varargin)
    argline = [argline 'varargin{' num2str(i) '}'];
    if i<length(varargin), argline = [argline ',']; end
end

h1 = get(hnd,'Children');
nbars = length(h1);
if nbars<2, return; end
for i=1:nbars
    if ~strcmp(get(h1(nbars-i+1),'Type'),'hggroup'), continue; end
    if ~isempty(argline), eval(['set(h1(i),' argline ')']); end
end
centers = get(h1(1),'XData');
if length(centers)<2, return; end
fwidth = get(h1(1),'BarWidth');
dcenters = min(centers(2:end)-centers(1:end-1));
dx = dcenters/(nbars+gap);
awidth = dx*fwidth;
agap = dx*gap;
for i=1:nbars
    if ~strcmp(get(h1(nbars-i+1),'Type'),'hggroup'), continue; end
    if ~isempty(gap)
        h2 = get(h1(nbars-i+1),'Children');
        x1 = centers-dcenters/2+agap/2+dx*(1-fwidth)/2+(i-1)*dx;
        x2 = x1+awidth;
        xdata = get(h2(1),'Xdata');
        xdata(1:2,:)=repmat(x1,2,1);
        xdata(3:4,:)=repmat(x2,2,1);
        ydata = get(h2(1),'Ydata');
        vertices = [reshape([centers;xdata],[],1) reshape([centers*0;ydata],[],1)];
        vertices = [vertices;vertices(end,:)];
        set(h2(1),'Vertices',vertices);
    end
end