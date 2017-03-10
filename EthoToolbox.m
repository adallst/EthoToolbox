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
    
end
