function scn = EthoScreen(varargin)
% EthoScreen   Setup or inquire about the experiment display
% Usage:
%     EthoScreen
%     EthoScreen('param', value, ...)
%     scn = EthoScreen(...)
% If the experimental display screen has not yet been set up (with calls to
% Screen('OpenWindow'), sets up the display screen; otherwise has no effect
% on the display. In either case, returns a struct containing information
% about the display screen with the following fields:
%     scn.
%             win       The Screen handle for the display window
%             rect      The result of Screen('Rect', scn.win)
%             center    The [x y] point in the middle of the display
%             pix2deg   The conversion factor from pixels to degrees
%             deg2pix   The conversion factor from degrees to pixels
%             new       Did this call to EthoScreen open a new
%                       window? True or false.
% EthoScreen presently takes only a single parameter/value pair:
%     BackgroundColor: A three-element vector defining the color to fill
%                      the window with. This only has an effect if
%                      EthoScreen sets up a new window, and is
%                      ignored if the experimental display window already
%                      exists. Default is [0 0 0] (black).

if nargin
    p = inputParser;
    p.addParamValue('BackgroundColor', []);
    p.parse(varargin{:});
    bgColor = p.Results.BackgroundColor;
else
    bgColor = [];
end

physical = EthoPars_screen;

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
        showNewWindowMessage(physical);
        isNewWindow = true;
    case 1
        win = windowScreens(onExptScreen);
        if ~isempty(bgColor)
            Screen('FillRect', win, bgColor);
            Screen('Flip', win);
        end
        isNewWindow = false;
    otherwise
        error('EthoScreen:tooManyWindows', ...
            'Too many PTB windows on the experiment screen to autodetect.');
end

scn = struct;
scn.win = win;
scn.rect = Screen('Rect', win);
scn.center = ...
    round([mean(scn.rect([1 3])), mean(scn.rect([2 4]))]);
scn.distance = physical.distance;
scn.height = physical.height;
scn.width = physical.width;

% Compute horizontal angle subtended by the screen, in radians:
xAngle = 2 * atan(scn.width / (2*scn.distance));
% Compute conversion factor for pixels into visual degrees:
scn.pix2deg = xAngle * 180 / pi / diff(scn.rect([1 3]));
scn.deg2pix = 1 ./ scn.pix2deg;

scn.new = isNewWindow;

function showNewWindowMessage(physical)

message = EthoMakeMessenger();
message('Screen physical parameters are:');
message('  width x height = %.1f cm x %.1f cm', ...
    physical.width, physical.height);
message('  distance to subject = %.1f cm');
message('  PsychToolbox screen ID = %d', physical.screen);
message(['If any of these values are incorrect, use EthoProfile to select' ...
    'the correct profile, or EthoConfigure to update it.']);
