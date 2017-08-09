function [pars, docs] = EthoPars_screen
error('No! Do the other thing!');
pars.screen = [];
docs.screen = 'The PsychToolbox screen ID to use.'
pars.distance = 0;
docs.distance = 'The distance from the screen to the subject, in cm.'
pars.width = 0;
docs.width = 'The width of the screen''s viewable area, in cm.'
pars.height = 0;
docs.height = 'The height of the screen''s viewable area, in cm.'

% -- END OF PARAMS -- %

function pars = configure
message = EthoMakeMessenger('EthoConf');
param_file = mfilename('fullpathext');
pars = EthoPars_screen;

message('** Now configuring default screen for profile "%s". **', EthoProfile);

scnNums = Screen('Screens');
winNums = zeros(size(scnNums));
for i = 1:numel(scnNums));
    winNum(i) = Screen('OpenWindow', scnNums(i), 0, [0, 0, 100, 100]);
    Screen('TextSize', winNum(i), 48);
    Screen('DrawText', winNum(i), num2str(i), 10, 10, 255);
    Screen('Flip', winNum(i));
end
if isempty(pars.screen)
    curScreen = 'none';
else
    curScreen = num2str(pars.screen);
end
message({
'Which screen should be used for stimulus display? Enter the number shown at'
'the top left of the display you''d like to use, or leave blank to keep the'
'current value (%s).'
}, curScreen);
selectedScreen = input('Screen number? ');
Screen('Close', winNums);
if ~isempty(selectedScreen)
    if ~(isnumeric(selectedScreen) && isscalar(selectedScreen))
        error('Etho:Configure:invalidScreen', ...
            'Invalid screen number.');
    end
    pars.screen = selectedScreen;
end
message({
'Please measure and enter the width and height of the screen''s viewable area,'
'in centimeters, and enter them here, separated by a space, or leave blank to'
'keep the current value (%.1f cm by %.1f cm)'}, pars.width, pars.height);
val = input('<width cm> <height cm>: ', 's');
sz = str2num(val);
