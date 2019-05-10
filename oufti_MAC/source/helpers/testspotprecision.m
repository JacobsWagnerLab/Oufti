function testspotprecision(cellList,varargin)
% Syntax:
% testspotprecision(cellList)
% testspotprecision(cellList,field)
% 
% This function test the precision of SpotFinderZ and indicates whether 
% subpixel resolution was actually achieved. The function displays the 
% distribution of spot position within pixel boundaries, plotting the
% global coordinates of the spots by modulus one. An approximately uniform
% distribution indicates that there was no tendency to pixel celters, a
% cluster in the middle inducates that there is such tendency and if 
% subpixel resolution is desired, the "Shift limit" parameter of 
% SpotFinderZ should be reduced.
% 
% <cellList> - input cell list (the other possible input, which can be used 
%     instead of the curvlist). If neither curvlist nor cellList is 
%     supplied, the program will request to open a file with the cellList.
% <field> - field with the spots. Default: 'spots'.

if ~isempty(varargin) && ischar(varargin{1})
    field = varargin{1};
else
    field = 'spots';
end

mode = 0; % mode=1 - spotFinderZ's cellList, mode=2 - spotFinderF's spotList
if ~isfield(cellList,'meshData')
for frame=1:length(cellList)
    if iscell(cellList{frame})
        for i=1:length(cellList{frame})
            if ~isempty(cellList{frame}{i}) && isstruct(cellList{frame}{i})
                if isfield(cellList{frame}{i},'mesh')
                    mode=1;
                elseif isfield(cellList{frame}{i},'x')
                    mode=2;
                end
                break
            end
        end
    end
end
if mode==0, disp('No data in this list or wrong format'); return; end

x = [];
y = [];
for frame=1:length(cellList)
    for cell=1:length(cellList{frame})
        if ~isempty(cellList{frame}{cell})
            if mode==1 && isfield(cellList{frame}{cell},field)
                x = [x cellList{frame}{cell}.(field).x];
                y = [y cellList{frame}{cell}.(field).y];
            elseif mode==2
                x = [x cellList{frame}{cell}.x];
                y = [y cellList{frame}{cell}.y];
            end
        end
    end
end

else
    for frame=1:length(cellList.meshData)
        for i=1:length(cellList.meshData{frame})
            if ~isempty(cellList{frame}{i}) && isstruct(cellList{frame}{i})
                if isfield(cellList{frame}{i},'mesh')
                    mode=1;
                elseif isfield(cellList{frame}{i},'x')
                    mode=2;
                end
                break
            end
        end
    end
    if mode==0, disp('No data in this list or wrong format'); return; end

    x = [];
    y = [];
    for frame=1:length(cellList.meshData)
        for cell=1:length(cellList.meshData{frame})
            if mode==1 && isfield(cellList{frame}{cell},field)
                x = [x cellList{frame}{cell}.(field).x];
                y = [y cellList{frame}{cell}.(field).y];
            elseif mode==2
                x = [x cellList{frame}{cell}.x];
                y = [y cellList{frame}{cell}.y];
            end
        end
    
    end
end

if isempty(x)
    disp('No spots found')
    return
end

fig = figure;
pos = get(fig,'pos');
set(fig,'pos',[pos(1) pos(2)+pos(4)-pos(3) pos(3) pos(3)])
plot(mod(x+0.5,1),mod(y+0.5,1),'.')
xlim([0 1])
ylim([0 1])
xlabel('x coordinate','FontSize',16)
ylabel('y coordinate','FontSize',16)
set(gca,'FontSize',14)