function EthoConfigure(paramset)

message = EthoMakeMessenger('EthoConf');

profile = EthoProfile;
message(['Active profile is "%s". If this isn''t the profile you want ' ...
    'to configure, press Ctrl-C to cancel and use EthoProfile to ' ...
    'select another.'], profile);

configurable_psets = {
    'screen', @configure_screen;
    'io',     @configure_io;
    };

if strcmp(paramset, 'all')
    pset_ind = 1:size(configurable_psets, 1);
else
    [has_config, pset_ind] = ismember(paramset, configurable_psets(:,1));
    if ~has_config
        message({
            'Sorry, there is no interactive configuration for paramset "%s".'
            }, paramset);
        return;
    end
end

for i = pset_ind
    paramset = configurable_psets{i,1};
    config_fun = configurable_psets{i,2};
    message('** Now configuring paramset "%s" for profile "%s". **', ...
        paramset, profile);

    pars = EthoParameters(paramset, [], 'Verbosity', 1, 'Messenger', message);
    confirm = '';
    while ~ismember(confirm, {'y','c'});
        pars = config_fun(pars, message);
        message({
            'Okay, I''ve got it. Please confirm that these values are correct'
            'for paramset "%s":'
            }, paramset);
        disp(pars);
        message({
            '[y]es, these are correct / [N]o, I want to change them, /'
            'no, I want to [c]ancel.'
            });
        confirm = input('[y / N / c]? ', 's');
        if ~isempty(confirm)
            confirm = lower(confirm(1));
        end
    end
    if strcmp(confirm, 'y')
        EthoSetParameters(paramset, pars, [], ...
            'Verbosity', 1, 'Messenger', message);
    elseif strcmp(confirm, 'c');
        message('Interactive configuration canceled!');
        break;
    end
end

message('Interactive configuration finished. Bye!');

function [pars, confirm] = configure_screen(pars, message)

screen_ids = Screen('Screens');
window_ids = zeros(size(screen_ids));
for i = 1:numel(screen_ids));
    window_ids(i) = Screen('OpenWindow', screen_ids(i), 0, [0, 0, 100, 100]);
    Screen('TextSize', window_ids(i), 48);
    Screen('DrawText', window_ids(i), num2str(i), 10, 10, 255);
    Screen('Flip', window_ids(i));
end
if isempty(pars.screen) || isnan(pars.screen)
    screen_text = 'none';
else
    screen_text = num2str(pars.screen);
end
message({
    'Screen ID:\n'
    'Which screen should be used for stimulus display? Enter the number shown'
    'at the top left of the display you''d like to use, or leave blank to keep'
    'the current value (%s).'
    }, screen_text);
new_screen = input('Screen number? ');
Screen('Close', window_ids);
if ~isempty(new_screen)
    if ~(isnumeric(new_screen) && isscalar(new_screen))
        error('Etho:Configure:invalidScreen', ...
            'Invalid screen number.');
    end
    pars.screen = selectedScreen;
end

res = Screen('Resolution', pars.screen);
window_ids = zeros(1,4);

message({
    'Screen size:\n'
    'Please measure and enter the width and height of the screen''s viewable'
    'area, in centimeters, and enter them here, separated by a space, or leave'
    'blank to keep the current value (%.1f cm by %.1f cm).'
    }, pars.width, pars.height);
screen_size = input('<width cm> <height cm>: ', 's');
if ~isempty(screen_size)
    screen_size = str2num(screen_size);
    pars.width = screen_size(1);
    pars.height = screen_size(2);
end

message({
    'Subject distance:\n'
    'Please measure and enter the distance from the subject''s face to the'
    'screen, in cm. This value will be used to calculate distances in degrees'
    'of visual arc (DVA). Leave blank to keep the current value (%.1f cm).'
    }, pars.distance);

screen_distance = input('<distance cm>: ');
if ~isempty(screen_distance)
    pars.distance = screen_distance;
end


function pars = configure_io(pars, message)

if ispc
    port_example = 'COM1';
elseif ismac
    port_example = '/dev/cu.usbmodemXXXX';
elseif isunix
    port_example = '/dev/ttyACM0';
else
    port_example = '(Actually, I don''t know for this system.)';
end

message({
    'Device port identifier:\n'
    'Please enter the port identifier for the Arduino I/O device. On this'
    'system, it should look something like "%s". Or, leave blank to keep the'
    'current value ("%s").'
    }, port_example, pars.port_name);
port_name = input('Port identifier? ', 's');
if ~isempty(port_name)
    pars.port_name = port_name;
end

message({
    'Reward pin number:\n'
    'Please enter the number of the digital output pin wired up to your reward'
    'device, or leave blank to keep the current value (%d).'
    }, pars.reward_pin);
reward_pin = input('Reward pin? ');
if ~isempty(reward_pin)
    pars.reward_pin = reward_pin;
end
