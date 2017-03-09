function EthoConfigure(config)

message = EthoMakeMessenger('EthoConf');

profile = EthoProfile;
if isempty(profile)
    allProfiles = EthoProfile('-list');
    if isempty(allProfiles)
        message(['No profiles have yet been created. I can create one now ' ...
            'if you provide a name, or leave it blank to cancel.']);
        profile = input('Profile name? ', 's');
        if isempty(profile)
            message('Canceled. Bye!');
            return;
        end
        EthoProfile('-create', profile);
    else
        message(['No profile is currently active. You can activate one of ' ...
            'the following, or create a new one.']);
        allProfiles = EthoProfile('-list');
        prettprint_columns(allProfiles);
        profile = input('Profile name? ', 's');
        if isempty(profile)
            message('Canceled. Bye!');
            return;
        elseif ismember(profile, allProfiles)
            EthoProfile(profile);
        else
            message('Confirm creation of profile "%s"?', profile);
            confirm = input('[y / N]: ');
            if strcmpi(confirm, 'y')
                EthoProfile('-create', profile);
            else
                message('Canceled. Bye!');
            end
        end
    end
else
    message(['Active profile is "%s". If this isn''t the profile you want ' ...
        'to configure, press Ctrl-C to cancel and use EthoProfile to ' ...
        'select another.'], profile);
end

switch lower(config)
    case 'screen'
        param_path = fullfile(EthoPaths('current_profile'), ...
            'EthoPars_screen.m');
        if ~exist(param_path, 'file')
            copyfile(which('EthoPars_screen'), param_path);
        end
        message('Interactive screen configuration isn''t yet implemented.');
        message('Opening the EthoPars_screen.m file for editing instead.');
        edit(param_path);
    case 'io'
        param_path = fullfile(EthoPaths('current_profile'), ...
            'EthoPars_io.m');
        if ~exist(param_path, 'file')
            copyfile(which('EthoPars_io'), param_path);
        end
        message('Interactive I/O configuration isn''t yet implemented.');
        message('Opening the EthoPars_io.m file for editing instead.');
        edit(param_path);
    otherwise
        message('No configuration set for that found! Bye.');
end

function updateParameter(param_file, param, value)
if isempty(EthoProfile())
    error('No profile currently active.');
end

filetext = fileread(param_file);
value_str = etho_repr(value);

param_str = strcat('pars\.', regexptranslate('escape', param));
pattern = sprintf('(?m)(?-s)(pars.%s *= *)(.+)(; *(%%.*)?)$', param_str);
replace = sprintf('$1%s$3', value_str);

filetext = regexprep(filetext, pattern, value_str);
param_path = fullfile(EthoPaths('current_profile'), [param_file '.m']);

fid = fopen(param_path, 'w');
fwrite(fid, filetext);
fclose(fid);
