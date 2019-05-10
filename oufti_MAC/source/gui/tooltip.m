function tooltip(hObject, message, displayTime, varargin)
% TOOLTIP temporarily displays a message below a uicontrol
% tooltip(hObject, message, displayTime, property name/value pairs)
% generates a text message underneath the supplied uicontrol.  If the font
% is changed, then the width of the text box will probably be wrong.

% NOTE: This currently uses characters for the position - this is defined
% by the default system font.  Due to the way MATLAB won't autofit text
% into textboxes (unless you use TEXT in a set of axes - which you can't
% animate), then the positions will not be correct if you change the font
% name or size.  The function begins with characters, but is then converted
% over to pixels later.

% Improvements:
% 1. Text wrapping, or cut off using an ellipsis (options).

% checks the number of arguments
error(nargchk(2, Inf, nargin))

% error checking
if ~isscalar(hObject) || ~strcmp(get(hObject, 'Type'), 'uicontrol')
    % handle object must be a single uicontrol
    error('Handle graphics object must be a single uicontrol.')
    
elseif isempty(message)
    % message cannot be empty
    error('Message cannot be empty.')
    
elseif ~ischar(message) && (ischar(message) && size(message, 1) ~= 1) && ~iscellstr(message)
    % the message must be a character string, or a cell array of strings
    error('The message must be a string, or a cell array of strings.')
    
elseif iscellstr(message) && size(message, 2) > 1
    % can only accept column vector cell arrays
    error('Cell arrays of strings must be vectors.')
    
elseif nargin >= 3 && ~isempty(displayTime) && (~isnumeric(displayTime) || ~isreal(displayTime) || ~isscalar(displayTime) || isnan(displayTime) || displayTime <= 0 || isinf(displayTime))
    % if supplied, the display time must be a real number greater than 0
    % (and not infinite)
    error('Display time must be a real number greater than 0.')
    
elseif nargin >= 4 && ~ispv(varargin{:})
    % if property/value arguments supplied, they must be in pairs
    error('Property/value arguments must be in pairs.')
end

% all units are in characters

% start with an offset for either end
extraWidth = 0.4;

% lookup table for letters (ASCII 32 to 126 - printable characters only) -
% assume character width of 0 for less than 33 and 127, and 1 for anything
% larger)
characterWidth = {  char(9), 0.58;...
                    ' ', 0.58;...
                    '!', 0.38;...
                    '"', 0.8;...
                    '#', 1.22;...
                    '$', 1.22;...
                    '%', 2.06;...
                    '&', 1.42;...
                    '''', 0.38;...
                    '(', 0.8;...
                    ')', 0.8;...
                    '*', 0.8;...
                    '+', 1.22;...
                    ',', 0.58;...
                    '-', 0.8;...
                    '.', 0.58;...
                    '/', 0.58;...
                    '0', 1.22;...
                    '1', 1.22;...
                    '2', 1.22;...
                    '3', 1.22;...
                    '4', 1.22;...
                    '5', 1.22;...
                    '6', 1.22;...
                    '7', 1.22;...
                    '8', 1.22;...
                    '9', 1.22;...
                    ':', 0.58;...
                    ';', 0.58;...
                    '<', 1.22;...
                    '=', 1.22;...
                    '>', 1.22;...
                    '?', 1.22;...
                    '@', 2.26;...
                    'A', 1.64;...
                    'B', 1.42;...
                    'C', 1.42;...
                    'D', 1.42;...
                    'E', 1.22;...
                    'F', 1.22;...
                    'G', 1.64;...
                    'H', 1.42;...
                    'I', 0.38;...
                    'J', 1;...
                    'K', 1.42;...
                    'L', 1.22;...
                    'M', 1.64;...
                    'N', 1.42;...
                    'O', 1.64;...
                    'P', 1.22;...
                    'Q', 1.64;...
                    'R', 1.42;...
                    'S', 1.42;...
                    'T', 1.22;...
                    'U', 1.42;...
                    'V', 1.64;...
                    'W', 2.06;...
                    'X', 1.42;...
                    'Y', 1.64;...
                    'Z', 1.42;...
                    '[', 0.58;...
                    '\', 0.58;...
                    ']', 0.58;...
                    '^', 1;...
                    '_', 1.22;...
                    '`', 0.8;...
                    'a', 1.22;...
                    'b', 1.22;...
                    'c', 1.22;...
                    'd', 1.22;...
                    'e', 1.22;...
                    'f', 0.8;...
                    'g', 1.22;...
                    'h', 1.22;...
                    'i', 0.38;...
                    'j', 0.38;...
                    'k', 1;...
                    'l', 0.38;...
                    'm', 1.64;...
                    'n', 1.22;...
                    'o', 1.22;...
                    'p', 1.22;...
                    'q', 1.22;...
                    'r', 0.8;...
                    's', 1.22;...
                    't', 0.58;...
                    'u', 1.22;...
                    'v', 1.22;...
                    'w', 2.06;...
                    'x', 1.22;...
                    'y', 1.22;...
                    'z', 1.22;...
                    '{', 0.8;...
                    '|', 0.38;...
                    '}', 0.8;...
                    '~', 1.22;...
                    '�', 0.8};

% converts the numbers for convenience
charIndex = double(cell2mat(characterWidth(:, 1)));
charSize = cell2mat(characterWidth(:, 2));

% transform the char into a cell array if necessary
if ischar(message)
    % transform (and unpack if a char array)
    message = {message(:)'};
end

% defines the height (and pre-allocates the array for finding the maximum
% linewidth
height = size(message, 1) + 0.154;
length = ones(size(message, 1), 1);

% gets the maximum length of the message
for m = 1:size(message, 1)
    % defines the line for checking
    newLine = double(message{m});
    
    % the ones which are listed...
    isListed = ismember(newLine, cell2mat(characterWidth(:, 1)));
    
    % and gets a list and number of each character
    listNum = histc(newLine(isListed), charIndex)';
    
    % the length is the number of each character multiplied by their size
    length(m) = sum(listNum .* charSize);
    
    % defines the unlisted ones
    notListed = newLine(~isListed);
    
    % but we also need to add on an estimated amount for the characters
    % which aren't listed - assume a character width of 1.22
    length(m) = length(m) + (sum(notListed <= 33 | notListed == 127) * 1.22);
end

% adds on the extra round the edges, to the longest possible length
length = max(length) + extraWidth;

% gets the parent
parent = get(hObject, 'Parent');

% gets the position - we want to know when the figure ends,
% and clip the test if necessary (this could be a figure or a uipanel)
%figurePosition = getposition(parent, 'characters');

% if the display time wasn't supplied, use a default
if nargin < 3 || (nargin >= 3 && isempty(displayTime))
    % defines the display time
    displayTime = 4;
end

% get the size and position of the supplied uicontrol in characters
position = getposition(hObject, 'characters');

% calculates the positions (in characters)
toolTipPositionCharacters = [position(1:2), length, height];

% generates a static text item with the same units below the uicontrol
% (actually this is top of the uicontrol on the bottom left)
toolTipHandle = uicontrol(  'Style', 'text',...
                            'HorizontalAlignment', 'left',...
                            'Parent', parent,...
                            'Units', 'characters',...
                            'String', message,...
                            'Position', toolTipPositionCharacters,...
                            'UserData', hObject,...
                            'Visible', 'off');
                
% if varargin was supplied
if nargin >= 4
    % don't know how to test for valid arguments so this is try-catched to
    % delete it then rethrow the error
    try
        % applies any custom properties
        set(toolTipHandle, varargin{:})
        
    catch
        % deletes the axes
        delete(toolTipHandle)

        % re-errors
        rethrow(lasterror)
    end
end
                
% NOW get the size in pixels and creates a new position that is 1 pixel
% larger (it'll be a border)
set(toolTipHandle, 'Units', 'pixels')
toolTipPositionPixels = get(toolTipHandle, 'Position');

% shifts it down 1 pixel (to allow for the border)
toolTipPositionPixels(2) = toolTipPositionPixels(2) - 1;

% shifts it forward a pixel and shrinks it not sure why this is necessary)
toolTipPositionPixels(1) = toolTipPositionPixels(1) + 1;

% creates the background
toolTipBorderPosition = [toolTipPositionPixels(1:2) - 1, toolTipPositionPixels(3:4) + 2];
                            
% generates a static text item with the same units below the uicontrol
% (actually this is top of the uicontrol on the bottom left)
toolTipHandle(2) = uicontrol(   'Style', 'text',...
                                'BackgroundColor', 'black',...
                                'Parent', parent,...
                                'Units', 'pixels',...
                                'Position', toolTipBorderPosition,...
                                'UserData', hObject,...
                                'Visible', 'off');
                
% need to change it so that the background goes behind the thing
children = get(parent, 'Children');

% switch them round (done this way in case this gets interrupted) - the
% uicontrols are stacked from the last item in the list upwards
toolTipIndex = children == toolTipHandle(1) | children == toolTipHandle(2);
children(toolTipIndex) = toolTipHandle(1:2);
set(parent, 'Children', children)

% animation parts
animationSteps = size(message, 1) * 6;
animationTime = 0.04;
animationStepTime = animationTime / animationSteps;

% defines the height (a little redundant, but good for pedagogic purposes)
heightPixels = toolTipPositionPixels(4);

% loops to animate it
for m = 1:animationSteps
    % short pause if its not the first one
    if m ~= 1
        % short pause
        pause(animationStepTime)
    end
    
    % generates a new position
    newToolTipPosition = [  toolTipPositionPixels(1),...
                            toolTipPositionPixels(2) - (heightPixels * (m / animationSteps)),...
                            toolTipPositionPixels(3),...
                            heightPixels * (m / animationSteps)];

    % change the position of the text
    set(toolTipHandle(1), 'Position', newToolTipPosition)
    
    % and the border too
    set(toolTipHandle(2), 'Position', [ newToolTipPosition(1:2) - 1,...
                                        newToolTipPosition(3:4) + 2])

    % if its the first one, make them visible too
    if m == 1
        % make it visible
        set(toolTipHandle, 'Visible', 'on')
    end
end

% generates a timer to delete the object - if the timer is stopped
% prematurely, then the tooltip will also get deleted
removeTimer = timer('TimerFcn', {@deleteToolTip, toolTipHandle, animationSteps, animationStepTime, heightPixels},...
                    'StopFcn', {@deleteToolTip, toolTipHandle, animationSteps, animationStepTime, heightPixels},...
                    'StartDelay', displayTime);
    
% starts the timer
start(removeTimer)


function deleteToolTip(timerObject, eventdata, toolTipHandle, animationSteps, animationStepTime, heightPixels)
% callback to delete the text object

% checks the uicontrol is OK before it goes ahead with it - makes sure that
% it does not error if the GUI has been closed in between triggering the
% tooltip and it needing to be deleted
if ishandle(toolTipHandle)
    % gets the position (of the main thing)
    toolTipPosition = get(toolTipHandle(1), 'Position');

    % loops to animate it (don't need to do the first one, since we
    % just did it when we initialised the uicontrol)
    for m = 1:animationSteps - 1
        % short pause if its not the first one
        if m ~= 1
            % short pause
            pause(animationStepTime)
        end
        
        % defines the new position
        newToolTipPosition =  [ toolTipPosition(1),...
                                toolTipPosition(2) + (heightPixels * (m / animationSteps)),...
                                toolTipPosition(3),...
                                toolTipPosition(4) - toolTipPosition(4) * (m / animationSteps)];

        % change the position
        set(toolTipHandle(1), 'Position', newToolTipPosition)
        set(toolTipHandle(2), 'Position', [ newToolTipPosition(1:2) - 1,...
                                            newToolTipPosition(3:4) + 1])
    end
    
    % deletes it
    delete(toolTipHandle)
end