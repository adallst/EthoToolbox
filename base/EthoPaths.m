function p = EthoPaths(d)

if ispc
    homedir = fullfile(getenv('HOMEDRIVE'), getenv('HOMEPATH'));
else
    homedir = getenv('HOME');
end

etho_paths.root = fileparts(which('EthoToolbox'));
etho_paths.settings = fullfile(homedir, '.EthoToolbox');
etho_paths.profiles = fullfile(etho_paths.settings, 'profiles');
etho_paths.current_profile = fullfile(etho_paths.profiles, EthoProfile());

if ~exist('d', 'var') || isempty(d)
    p = etho_paths;
else
    p = etho_paths.(d);
end
