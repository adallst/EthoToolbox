function EthoToolbox(varargin)

if ismember('setup', varargin)
    % Add EthoToolbox to the path
    this_dir = fileparts(mfilename('fullpath'));
    util_dir = fullfile(this_dir, 'util');
    cur_path = addpath(util_dir);

    message = EthoMakeMessenger;
    message('Adding EthoToolbox to the path and setting up local info.');

    etho_path = etho_genpath(this_dir);
    path(etho_path, cur_path);
    savepath;

    p = EthoPaths;
    mkdir(p.settings);
    mkdir(p.profiles);
    mkdir(p.profiles, 'default');

    message('Set up default screen info now?');
    if ask_yes_no(true)
        EthoConfigure('screen');
    end
    message('Set up default I/O hardware configuration now?');
    if ask_yes_no(true)
        EthoConfigure('io');
    end
end

function yn = ask_yes_no(default_yes)
if ~nargin
    default_yes = false;
end
if default_yes
    response = input('(Y / n)? ', 's');
    yn = ~strncmpi(response, 'n', 1);
else
    response = input('(y / N)? ', 's');
    yn = strncmpi(response, 'y', 1);
end
