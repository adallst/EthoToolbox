function etho_update_parameters(paramset, varargin)

% Gentle argument parsing
params = {};
values = {};
i = 1;
while i <= numel(varargin)
    if isstruct(varargin{i})
        newParams = fieldnames(varargin{i});
        newValues = struct2cell(varargin{i});
        params = [params; newParams];
        values = [values; newValues];
        i = i + 1;
    else
        params = [params; varargin(i)];
        values = [values; varargin(i+1)];
        i = i + 2;
    end
end

end_of_params_marker = '% -- END OF PARAMS -- %';

param_file = fullfile(EthoPaths('current_profile'), ...
    ['EthoPars_' paramset '.m']);

filetext = fileread(param_file);

file_sections = strsplit(filetext, end_of_params_marker);
params_text = file_sections{1};

for i=1:numel(params)
    value_str = etho_repr(values{i});
    param_str = strcat('pars\.', regexptranslate('escape', params{i}));

    pattern = sprintf('(?m)(?-s)^(\s*pars.%s *= *)(.+)(; *(%%.*)?)$', ...
        param_str);
    replace = sprintf('$1%s$3', value_str);

    params_text = regexprep(params_text, pattern, replace);
end

file_sections{1} = params_text;
filetext = strjoin(file_sections, end_of_params_marker);

value_str = etho_repr(value);

param_str = strcat('pars\.', regexptranslate('escape', param));
pattern = sprintf('(?m)(?-s)^(\s*pars.%s *= *)(.+)(; *(%%.*)?)$', param_str);
replace = sprintf('$1%s$3', value_str);

filetext = regexprep(filetext, pattern, value_str);
param_path = fullfile(EthoPaths('current_profile'), [param_file '.m']);

fid = fopen(param_path, 'w');
fwrite(fid, filetext);
fclose(fid);
