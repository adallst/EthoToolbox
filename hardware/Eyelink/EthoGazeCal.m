function EthoGazeCal(varargin)
% EthoGazeCal   Generic calibration routine for Eyelink
% Usage:
%     EthoGazeCal('Param',value,...)
%     EthoGazeCal(pars)
% EthoGazeCal runs through Eyelink calibration in a relatively quick and
% painless way. EthoGazeCal automatically informs Eyelink of the proper
% screen resolution, and requests the appropriate target positions from
% Eyelink. The complete calibration routine can be completed from the
% MATLAB console without directly using the Eyelink computer (although
% monitoring the Eyelink console for proper fixation is still necessary).
% The drawing of targets, awarding of juice, and acceptance of fixation can
% be coordinated with a single key press (space), making the proper
% behavioral conditioning much simpler. The behavior of EthoGazeCal can
% also be easily customized with parameters. Valid parameters are:
%     BgColor:  A 3 element RGB vector defining the background color during
%         calibration. For best results, the brightness of the background
%         during calibration should be similar to the average brightness
%         of the screen during the task, so that the subject's pupil is
%         similarly dilated. Default is [127 127 127] (neutral grey).
%     TargColor:  A 3 element RGB vec tor defining the color the calibration
%         targets. Default is [255 0 25] (red).
%     TargDiamDeg:  The target diameter, in visual degrees. Default is 0.5.
%     Type:  The type of calibration to perform, either 'grid' (default)
%         for a 9 point calibration or 'cross' for a 5 point calibration.
%     RwdAmt:  The juice reward for successfully maintaining fixation.
%         Default is 100.
%     FlickerRate:  The frequency to flicker the target, in Hz. Default is
%         0 (no flickering).
% Parameters can be supplied as either 'parameter',value pairs or in a
% struct such that s.parameter = value.
% Examples:
%     EthoGazeCal('BgColor',[0 0 0],'Type','cross')
%         Perform a 5 point calibration with a black background.
%     EthoGazeCal(myCalParams)
%         If "myCalParams.m" is an m-file function that returns a struct,
%         it can conveniently define a standard parameter set for a given
%         task and/or subject.

color = EthoColors;
message = EthoMakeMessenger('CAL');

p = inputParser;
p.addParamValue('BgColor', color.WebGray);
p.addParamValue('TargColor', color.Red);
p.addParamValue('TargDiamDeg', .5);
p.addParamValue('Type', 'grid', @(s)ismember(s,{'cross','grid'}));
p.addParamValue('RwdAmt', 100);
p.addParamValue('FlickerRate', 0);
p.addParamValue('RandOrder', false);
p.addParamValue('Averaging', 1);
p.addParamValue('FlashColor', color.White);
p.addParamValue('FlashTime', 0.5);
% p.addParamValue('PupilMode', 'ellipse', ...
%     @(s)ismember(s,{'ellipse','centroid'}));
p.parse(varargin{:});
pars = p.Results;

isFlickered = pars.FlickerRate ~= 0;

% Set up experiment screen
scrn = EthoScreen('BackgroundColor', pars.BgColor);

targDiamPix = pars.TargDiamDeg * scrn.deg2pix;

% Connect to Eyelink if not already connected
if Eyelink('IsConnected')
    hangupWhenDone = false;
else
    Eyelink('Initialize');
    hangupWhenDone = true;
end
%DigOutGKA.Initialize; % Initialize digital output for juicer
digIO = EthoIO();
EthoKeyboard('Start'); % Set up KbQueue* for key presses

% Inform the user of the current paramters
message('Performing %s calibration', pars.Type);
message('Reward for fixating is %d', pars.RwdAmt);
message('Background color is [%d %d %d]', pars.BgColor);
message('Target color is [%d %d %d] and diameter is %.1f visual degrees', ...
    pars.TargColor, pars.TargDiamDeg);
if isFlickered
    message('Target flickers at %.1f Hz', pars.FlickerRate);
else
    message('Target flickering is off');
end

message('Calibration requires experimenter interaction.');
message('Press any of the following keys during calibration:');

keys = {
    'cancel', 'ESCAPE',    'Cancel calibration and quit the task';
    'next',   'space',     'Draw the current calibration target, or accept it, clear it, and give reward';
    'accept', 'Return',    'Accept the calibration set after all points are acquired, or accept a single point';
    'reward', 'r',         'Deliver an immediate reward';
    'draw',   'd',         'Draw the current calibration target';
    'clear',  'DELETE',    'Clear the screen';
    'prev',   'LeftArrow', 'Clear the screen and reject the previously accepted target';
    'flash',  'f',         'Flash the error screen, then return to a clear background';
    };
keys = cell2struct(keys, {'action', 'name', 'description'}, 2);

for i=1:numel(keys)
    keys(i).code = KbName(keys(i).name);
    message('  %-12s %s', keys(i).name, keys(i).description);
end

cancelKey = keys(strcmp('cancel', {keys.action})).code;

% Define the basic rectangle the target is inscribed within, without
% offsets
targShape = [-.5 -.5 .5 .5] * pars.TargDiamDeg * scrn.deg2pix;

% Define the function that scales the target diameter for flickering:
flickerFun = @(t)(abs(cos(2*pi*pars.FlickerRate/2*t)));

% Tell Eyelink what the screen resolution is:
Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', ...
    scrn.rect(1), scrn.rect(2), scrn.rect(3), scrn.rect(4));
Eyelink('Command', sprintf('screen_phys_coords = %g %g %g %g', ...
    -scrn.width/2, scrn.height/2, scrn.width/2, -scrn.height/2));
Eyelink('Command', sprintf('screen_distance = %g', scrn.distance));

% Configure the calibration type
switch pars.Type
    case 'cross'
        Eyelink('Command', 'calibration_type = HV5');
    case 'grid'
        Eyelink('Command', 'calibration_type = HV9');
end
if p.Results.RandOrder
    Eyelink('Command', 'randomize_calibration_order = YES');
else
    Eyelink('Command', 'randomize_calibration_order = NO');
end

Eyelink('StartSetup');
% Wait until Eyelink has actually entered Setup mode before proceeding
eyelinkOK = awaitEyelinkMode(2, cancelKey);
if eyelinkOK
    % Magic words: send the keypress 'c' to put Eyelink in calibration mode
    Eyelink('SendKeyButton', double('c'), 0, 10);
    eyelinkOK = awaitEyelinkMode(10, cancelKey);
end
if ~eyelinkOK
    message('User aborted while waiting for Eyelink')
end

[~, targX, targY] = Eyelink('TargetCheck');

%targetIsOn = false;
isTargetOn = false;
shouldShowTarget = false;

% Main event loop:
while eyelinkOK && Eyelink('CurrentMode') == 10 % calibration mode

    screenHasBeenUpdated = false;
    if shouldShowTarget && ~isTargetOn
        % I need to draw the target
        if isFlickered
            drawTarget(scrn, targX, targY, ...
                targDiamPix, pars.TargColor);
        else
            drawTarget(scrn, targX, targY, ...
                targDiamPix*flickerFun(GetSecs), pars.TargColor);
        end
        isTargetOn = true;
        screenHasBeenUpdated = true;
    elseif targetIsOn && ~shouldShowTarget
        % I need to clear the target
        clearScreen(scrn, pars.BgColor);
        isTargetOn = false;
        screenHasBeenUpdated = true;
    elseif targetIsOn && isFlickered
        % I need to update the flickering target
        drawTarget(scrn, targX, targY, ...
            targDiamPix*flickerFun(GetSecs), pars.TargColor);
        screenHasBeenUpdated = true;
    end

    % Check for key presses
    [isKey, keyPress] = KbQueueCheck;
    if ~isKey && ~screenHasBeenUpdated
        % Sleep for a moment to keep from spamming the CPU
        WaitSecs(.005);
    end

    for key = keys
        if any(keyPress(key.code))
            switch key.action
            case 'cancel'
                Eyelink('SendKeyButton', 27, 0, 10); % 27 = ESCAPE
            case 'next'
                if isTargetOn
                    % Accept fixation on the current target
                    Eyelink('SendKeyButton',13,0,10); % 13 = Return
                    % Reward the subject
                    digIO.Reward(pars.RwdAmt);
                    % Remove the target at next loop
                    shouldShowTarget = false;
                else
                    % No target is on, so draw one
                    % Ask Eyelink where it wants the target:
                    [dummy, targX, targY] = Eyelink('TargetCheck');
                    shouldShowTarget = true;
                end
            case 'accept'
                % Accept fixation, with no other consequences
                % OR, if all targets have been accepted, accept calibration
                Eyelink('SendKeyButton',13,0,10); % 13 = Return
            case 'reward'
                digIO.Reward(pars.RwdAmt);
            case 'draw'
                [~, targX, targY] = Eyelink('TargetCheck');
                shouldShowTarget = true;
            case 'clear'
                shouldShowTarget = false;
            case 'prev'
                Eyelink('SendKeyButton',8,0,10); % 8 = Backspace
                shouldShowTarget = false;
            case 'flash'
                clearScreen(scrn, pars.FlashColor);
                WaitSecs(pars.FlashTime);
                clearScreen(scrn, pars.BgColor);
                isTargetOn = false;
                shouldShowTarget = false;
            end
        end
    end
end

EthoKeyboard('Stop');
if hangupWhenDone
    % We created the Eyelink connection, so let's clean up after ourselves
    Eyelink('Shutdown');
end
if scrn.new
    % We created the experimental display, so clean it up
    Screen('Close', scrn.win);
end

function when = drawTarget(scrn, x, y, diamPix, color)
targRect = [x y x y] + diamPix.*[-.5 -.5 .5 .5];
Screen('FillOval', scrn.win, color, targRect);
when = Screen('Flip', scrn.win);

function when = clearScreen(scrn, color)
Screen('FillRect', scrn.win, color);
when = Screen('Flip', scrn.win);

function isGood = awaitEyelinkMode(mode, abortKey)
isGood = true;
while isGood && Eyelink('CurrentMode') ~= mode
    WaitSecs(.01);
    % Let the user abort with ESCAPE
    [isKey, keyPress] = KbQueueCheck;
    if isKey && keyPress(abortKey)
        isGood = false;
    end
end
