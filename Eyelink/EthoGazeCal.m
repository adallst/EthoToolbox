function CalibrateGKA(varargin)
% CalibrateGKA   Generic calibration routine for Eyelink
% Usage:
%     CalibrateGKA('Param',value,...)
%     CalibrateGKA(pars)
% CalibrateGKA runs through Eyelink calibration in a relatively quick and
% painless way. CalibrateGKA automatically informs Eyelink of the proper
% screen resolution, and requests the appropriate target positions from
% Eyelink. The complete calibration routine can be completed from the
% MATLAB console without directly using the Eyelink computer (although
% monitoring the Eyelink console for proper fixation is still necessary).
% The drawing of targets, awarding of juice, and acceptance of fixation can
% be coordinated with a single key press (space), making the proper
% behavioral conditioning much simpler. The behavior of CalibrateGKA can
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
%         Default is 50.
%     Flicker:  Whether to flicker the target diameter or not. Default is
%         false.
%     FlickerFreq:  The frequency to flicker the target, if Flicker is
%         true.  Default is 5 (Hz).
% Parameters can be supplied as either 'parameter',value pairs or in a
% struct such that s.parameter = value.
% Examples:
%     CalibrateGKA('BgColor',[0 0 0],'Type','cross')
%         Perform a 5 point calibration with a black background.
%     CalibrateGKA(myCalParams)
%         If "myCalParams.m" is an m-file function that returns a struct,
%         it can conveniently define a standard parameter set for a given
%         task and/or subject.
%
% CalibrateGKA depends on KbControlGKA, ExperimentScreenGKA, and
% screenPhysicalParams

% Parse parameters:
p = inputParser;
p.addParamValue('BgColor', [127 127 127]);
p.addParamValue('TargColor', [255 0 0]);
p.addParamValue('TargDiamDeg', .5); 
p.addParamValue('Type', 'grid', @(s)ismember(s,{'cross','grid'}));
p.addParamValue('RwdAmt', 100);
p.addParamValue('Flicker', false);
p.addParamValue('FlickerFreq', 6);
p.addParamValue('RandOrder', false);
p.addParamValue('Averaging', 1);
p.addParamValue('FlashColor', [255 255 255]);
p.addParamValue('FlashTime', 0.5);
% p.addParamValue('PupilMode', 'ellipse', ...
%     @(s)ismember(s,{'ellipse','centroid'}));
p.parse(varargin{:});
pars = p.Results;

% Set up experiment screen
scrn = ExperimentScreenGKA('BackgroundColor', pars.BgColor);

% Connect to Eyelink if not already connected
if Eyelink('IsConnected')
    hangupWhenDone = false;
else
    Eyelink('Initialize');
    hangupWhenDone = true;
end
%DigOutGKA.Initialize; % Initialize digital output for juicer
digIO = SchedIO('/dev/ttyACM0');
KbControlGKA('Start'); % Set up KbQueue* for key presses

% Inform the user of the current paramters
fprintf('\n    ***  %s  ***\n\n', mfilename);
fprintf('CAL: Performing %s calibration\n', pars.Type);
fprintf('CAL: Target diameter is %.1f visual degrees\n', pars.TargDiamDeg);
fprintf('CAL: Reward for fixating is %i ms of juice\n', pars.RwdAmt);
fprintf('CAL: Background color is [%d %d %d]\n', pars.BgColor);
fprintf('CAL: Target color is [%d %d %d]\n', pars.TargColor);
if pars.Flicker
    fprintf('CAL: Target flickers at %.1f Hz\n', pars.FlickerFreq);
end

% Key definitions
keyCancel = KbName('ESCAPE'); % To cancel calibration and quit
keyJuice  = KbName('j');      % For immediate juice reward
keyDraw   = KbName('d');      % To draw or clear calibration target
keyNext   = KbName('space');  % To draw or accept fixation on this target
keyAccept = KbName('Return'); % To send an accept command
keyClear  = KbName('DELETE'); % To clear the screen
keyBack   = KbName('LeftArrow'); % To return to the previous target
keyFlash  = KbName('f'); % Flash the screen background

% Inform the user how to control calibration
infoStr = sprintf([...
'CAL: %s relies on experimenter feedback for control.\n'...
'CAL: Press any of the following keys during the experiment:\n'...
'CAL:    j          Deliver an immediate juice reward\n'...
'CAL:    d          Toggle the visibility of the calibration target\n'...
'CAL:    space      If the calibration target is not visible, draw it.\n'...
'CAL:               Otherwise, accept fixation for this target, reward,\n'...
'CAL:               and clear the screen\n'...
'CAL:    Return     Accept fixation for this target without rewarding or\n'...
'CAL:               clearing the screen. Or, once all targets have been\n'...
'CAL:               accepted, accept the whole calibration\n'...
'CAL:    LeftArrow  Clear the screen and return to the previous target\n'...
'CAL:    DELETE     Clear the screen\n'...
'CAL:    ESCAPE     Reset all targets, or cancel calibration and quit\n'...
], mfilename);
disp(infoStr);

% Define the basic rectangle the target is inscribed within, without
% offsets
targShape = [-.5 -.5 .5 .5] * pars.TargDiamDeg * scrn.deg2pix;

% Define the function that scales the target diameter for flickering:
flickerFun = @(t)(abs(sin(2*pi*pars.FlickerFreq/2*t)));

% Tell Eyelink what the screen resolution is:
Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', ...
    scrn.rect(1), scrn.rect(2), scrn.rect(3), scrn.rect(4));
Eyelink('Command', sprintf('screen_phys_coords = %g %g %g %g', ...
    -scrn.width/2, scrn.height/2, ...
    scrn.width/2, -scrn.height/2));
Eyelink('Command', sprintf('screen_distance = %g', scrn.distance));

% Get the calibration type code string that Eyelink expects
switch pars.Type
    case 'cross'
        calString = 'HV5';
        %numTargs = 5;
    case 'grid'
        calString = 'HV9';
        %numTargs = 9;
end
% Tell Eyelink the calibration type to use
Eyelink('Command', 'calibration_type = %s', calString);
if p.Results.RandOrder
    Eyelink('Command', 'randomize_calibration_order = YES');
else
    Eyelink('Command', 'randomize_calibration_order = NO');
end
% if strcmp(p.Results.PupilMode, 'ellipse')
%     Eyelink('Command', 'use_ellipse_fitter = YES');
% else
%     Eyelink('Command', 'use_ellipse_fitter = NO');
% end
%Eyelink('Command', 'calibration_average = YES');
%Eyelink('Command', 'calibration_samples = %d', ...
%    p.Results.Averaging*numTargs);
%Eyelink('Command', 'calibration_sequence =%s', ...
%    sprintf(' %d', repmat(0:numTargs-1, 1, p.Results.Averaging)));
%Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', ...
%    scrn.rect(1), scrn.rect(2), scrn.rect(3), scrn.rect(4));
%Eyelink('Command', 'generate_default_targets = YES');
% Put Eyelink in setup mode
Eyelink('StartSetup');
% Wait until Eyelink actually enters Setup mode (otherwise the
% SendKeyButton command below can happen too quickly and won't actually put
% us in calibration mode):
trackerResp = true;
while trackerResp && Eyelink('CurrentMode')~=2 % Mode 2 is setup mode
    % Let the user abort with ESCAPE
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('ESCAPE'))
        disp('Aborted while waiting for Eyelink!');
        trackerResp = false;
    end
end
% Magic words: Send the keypress 'c' to select "Calibrate" and put Eyelink
% in calibration mode
Eyelink('SendKeyButton',double('c'),0,10);
% Wait again for the mode to change:
while trackerResp && Eyelink('CurrentMode')~=10 % Mode 10 is calibration mode
    % Let the user abort with ESCAPE
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('ESCAPE'))
        disp('Aborted while waiting for Eyelink!');
        trackerResp = false;
    end
end

targX = scrn.center(1);
targY = scrn.center(2);

targetIsOn = false;
% Main event loop:
while trackerResp % If we already aborted with ESCAPE, skip this
    if Eyelink('CurrentMode') ~= 10 % Mode 10 is calibration mode
        % Calibration is finished, so quit
        break;
    end
    % Check for key presses
    [isKey, keyPress] = KbQueueCheck;
    if ~isKey
        if pars.Flicker && targetIsOn
            % Draw the flickering stimulus
            Screen('FillOval', scrn.win, pars.TargColor, ...
                [targX targY targX targY] + flickerFun(GetSecs)*targShape);
            Screen('Flip', scrn.win);
        else
            % No key press, sleep for 50 ms before checking again
            WaitSecs(0.05);
            continue;
        end
    end
    if keyPress(keyCancel)
        % Cancel calibration
        Eyelink('SendKeyButton',27,0,10); % 27 = ESCAPE
    elseif keyPress(keyJuice)
        % Immediate juice reward with no other consequences
        %DigOutGKA.Juice(pars.RwdAmt);
        digIO.PulsePin(2,1,pars.RwdAmt);
    elseif keyPress(keyDraw)
        % Toggle display of the target, with no other consequences
        if targetIsOn
            % The target is on, so clear the screen
            Screen('FillRect', scrn.win, pars.BgColor);
            Screen('Flip', scrn.win);
            targetIsOn = false;
        else
            % No target is on, so draw one
            % Ask Eyelink where it wants the target:
            [dummy, targX, targY] = Eyelink('TargetCheck');
            % Draw the target:
            if pars.Flicker
                % Draw a flickering target
                targRect = [targX targY targX targY] + ...
                    targShape * flickerFun(GetSecs);
            else
                % Draw a steady target
                targRect = [targX targY targX targY] + targShape;
            end
            Screen('FillOval', scrn.win, pars.TargColor, targRect);
            Screen('Flip', scrn.win);
            targetIsOn = true;
        end
    elseif keyPress(keyClear)
        % Blank the screen
        Screen('FillRect', scrn.win, pars.BgColor);
        Screen('Flip', scrn.win);
        targetIsOn = false;
    elseif keyPress(keyNext)
        % Move forward through the targets
        if targetIsOn
            % Accept fixation on the current target
            Eyelink('SendKeyButton',13,0,10); % 13 = Return
            % Reward the subject
            %DigOutGKA.Juice(pars.RwdAmt);
            digIO.PulsePin(2,1,pars.RwdAmt);
            % Clear the screen
            Screen('FillRect', scrn.win, pars.BgColor);
            Screen('Flip', scrn.win);
            targetIsOn = false;
        else
            % No target is on, so draw one
            % Ask Eyelink where it wants the target:
            [dummy, targX, targY] = Eyelink('TargetCheck');
            % Draw it:
            if pars.Flicker
                % Draw a flickering target
                targRect = [targX targY targX targY] + ...
                    targShape * flickerFun(GetSecs);
            else
                % Draw a steady target
                targRect = [targX targY targX targY] + targShape;
            end
            Screen('FillOval', scrn.win, pars.TargColor, targRect);
            Screen('Flip', scrn.win);
            targetIsOn = true;
        end
    elseif any(keyPress(keyAccept))
        % Accept fixation, with no other consequences
        % OR, if all targets have been accepted, accept calibration
        Eyelink('SendKeyButton',13,0,10); % 13 = Return
    elseif keyPress(keyBack)
        % Undo the previous target
        Eyelink('SendKeyButton',8,0,10); % 8 = Backspace
        % Blank the screen
        Screen('FillRect', scrn.win, pars.BgColor);
        Screen('Flip', scrn.win);
        targetIsOn = false;
    elseif keyPress(keyFlash)
        Screen('FillRect', scrn.win, pars.FlashColor);
        Screen('Flip', scrn.win);
        targetIsOn = false;
        WaitSecs(pars.FlashTime);
        Screen('FillRect', scrn.win, pars.BgColor);
        Screen('Flip', scrn.win);
    end
end

KbControlGKA('Stop'); %Stop listening for key presses
if hangupWhenDone
    % We created the Eyelink connection, so let's clean up after ourselves
    Eyelink('Shutdown');
end
if scrn.new
    % We created the experimental display, so clean it up
    Screen('Close', scrn.win);
end
