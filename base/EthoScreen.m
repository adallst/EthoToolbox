function scnDat = ExperimentScreenGKA(varargin)
% ExperimentScreenGKA   Setup or inquire about the experiment display
% Usage:
%     ExperimentScreenGKA
%     ExperimentScreenGKA('param', value, ...)
%     scnData = ExperimentScreenGKA(...)
% If the experimental display screen has not yet been set up (with calls to
% Screen('OpenWindow'), sets up the display screen; otherwise has no effect
% on the display. In either case, returns a struct containing information
% about the display screen with the following fields:
%     scnData.
%             win       The Screen handle for the display window
%             rect      The result of Screen('Rect', scnData.win)
%             center    The [x y] point in the middle of the display
%             pix2deg   The conversion factor from pixels to degrees
%             deg2pix   The conversion factor from degrees to pixels
%             new       Did this call to ExperimentScreenGKA open a new
%                       window? True or false.
% ExperimentScreenGKA presently takes only a single parameter/value pair:
%     BackgroundColor: A three-element vector defining the color to fill
%                      the window with. This only has an effect if
%                      ExperimentScreenGKA sets up a new window, and is
%                      ignored if the experimental display window already
%                      exists. Default is [0 0 0] (black).

persistent physical
if isempty(physical)
    if ~exist('screenPhysicalParams.m','file')
        error('ExperimentScreenGKA:noPhysicalParams', ...
            ['No "screenPhysicalParams.m" found on the MATLAB path. ' ...
            'ExperimentScreenGKA requires this function to return a ' ...
            'struct with fields "screen", "distance", "width", and ' ...
            '"height", with measurements in cm.']);
    end
    physical = screenPhysicalParams;
    if ~all(isfield(physical, {'screen', 'distance', 'width', 'height'}))
        error('ExperimentScreenGKA:missingPhysicalParams', ...
            ['"screenPhysicalParams.m" must return a struct with ' ...
            'fields "screen", "distance", "width", and "height", with ' ...
            'measurements in cm.']);
    end
    fprintf('%s: Screen physical parameters are:\n', mfilename);
    fprintf('%s: height = %.1f cm\n', mfilename, physical.height);
    fprintf('%s: width = %.1f cm\n', mfilename, physical.width);
    fprintf('%s: distance = %.1f cm\n', mfilename, physical.distance);
    fprintf('%s: PTB id = %i\n', mfilename, physical.screen);
    fprintf(['%s: If any of these values are incorrect, you should ' ...
        '<a href="matlab:edit(''%s'');clear %s">edit the parameter ' ...
        'file</a>.\n'], ...
        mfilename, which('screenPhysicalParams'), mfilename);
end

if nargin>0
    isColor = @(v)(isnumeric(v) && numel(v)==3 && all(v>=0 & v<=255));
    p = inputParser;
    p.addParamValue('BackgroundColor', [0 0 0], isColor);
    p.parse(varargin{:});
    bgColor = p.Results.BackgroundColor;
else
    bgColor = [0 0 0];
end

allWindows = Screen('Windows');
onScreen = Screen(allWindows, 'WindowKind') == 1;
windowScreens = zeros(size(allWindows));
for k=1:numel(allWindows)
    windowScreens(k) = Screen('WindowScreenNumber', allWindows(k));
end
if isempty(windowScreens)
    onExptScreen = [];
else
    onExptScreen = (windowScreens == physical.screen) && onScreen;
end
switch sum(onExptScreen)
    case 0
        win = Screen('OpenWindow', physical.screen, bgColor, [], 32);
        Screen('Flip', win);
        isNewWindow = true;
    case 1
        win = windowScreens(onExptScreen);
        isNewWindow = false;
    otherwise
        error('ExperimentScreenGKA:tooManyWindows', ...
            'Too many PTB windows on the experiment screen to autodetect.');
end

scnDat = struct;
scnDat.win = win;
scnDat.rect = Screen('Rect', win);
scnDat.center = ...
    round([mean(scnDat.rect([1 3])), mean(scnDat.rect([2 4]))]);
scnDat.distance = physical.distance;
scnDat.height = physical.height;
scnDat.width = physical.width;

% Compute horizontal angle subtended by the screen, in radians:
xAngle = 2 * atan(scnDat.width / (2*scnDat.distance));
% Compute conversion factor for pixels into visual degrees:
scnDat.pix2deg = xAngle * 180 / pi / diff(scnDat.rect([1 3]));
scnDat.deg2pix = 1 ./ scnDat.pix2deg;

scnDat.new = isNewWindow;
