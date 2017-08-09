function output = EthoProfile(varargin)
% Set or retrieve the EthoToolbox profile
% Usage:
%     profile = EthoProfile()
%     prevProfile = EthoProfile(newProfile);
%     EthoProfile('-create', newProfile)
%     EthoProfile [-create] newProfile
%     EthoProfile -list
%
% Rationale:
%   When running multiple experiments from the same behavioral rig, it can be
%   helpful to use different default settings for different experiments. Storing
%   those default settings in a selectable profile reduces the chance of
%   inadvertently changing something important for one experiment while setting
%   up the configuration for another.
%
% Approach:
%   EthoToolbox creates a directory "$HOME/.EthoToolbox/profiles/" (where $HOME
%   is the user's home directory). Creating a profile adds a new subdirectory in
%   this tree. Activating a profile adds its directory to the Matlab path, and
%   removes the previously active profile directory (if any) from the path.
%   This allows configuration settings to be stored in Matlab files which will
%   be searched before the default settings.
%
% Examples:
%   Create a new profile "my-experiment":
%     >> EthoProfile -create my-experiment

persistent curProfile;
if isempty(curProfile)
    curProfile = 'default';
end

message = EthoMakeMessenger();

if nargin
    profilesDir = EthoPaths('profiles');
    if any(ismember({'-list','-l'}, varargin))
        % List mode
        s = dir(profilesDir);
        allProfiles = setdiff({s.name}, {'.','..'});
        if nargout
            output = allProfiles;
        else
            prettyprint_columns(allProfiles);
        end
        return;
    end
    argIsCreateFlag = strcmp(varargin, '-create') | strcmp(varargin, '-c');
    varargin = varargin(~argIsCreateFlag);
    newProfile = varargin{1};
    if isempty(newProfile)
        newProfile = 'default';
    end
    if ~exist(fullfile(profilesDir, newProfile),'dir')
        if any(argIsCreateFlag)
            % Create a new profile
            mkdir(profilesDir, newProfile);
            message('Created new profile "%s".', newProfile);
        else
            error('EthoToolbox:noSuchProfile', ...
                'No such EthoToolbox profile');
        end
    end
    if nargout
        output = char(curProfile);
    end
    if ~isempty(curProfile)
        rmpath(fullfile(profilesDir, curProfile));
    end
    if ~isempty(newProfile)
        addpath(fullfile(profilesDir, newProfile));
        message('Switched to profile "%s"', newProfile);
    end
    curProfile = newProfile;
else
    output = char(curProfile);
end
