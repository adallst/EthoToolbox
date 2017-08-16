function [pars, docs] = EthoParameters(paramset, param, varargin)

args = etho_parse_args({
    'Verbosity', 0;
    'Messenger', 'Etho';
    }, varargin);
message = EthoMakeMessenger(args.Messenger, args.Verbosity);

param_file = strcat(paramset, '.ethopars');

if ~exist(param_file,'file')
    pars = struct;
    docs = struct;
    return;
end

param_table = EthoLoadTable(param_file, 'TableFormat', 'cellarray');

message('Loaded parameter set "%s" from "%s".', paramset, param_file);

pars = cell2struct(param_table(:,2), param_table(:,1));
docs = cell2struct(param_table(:,3), param_table(:,1));

if exist('param','var') && ~isempty(param)
    pars = pars.(param);
    docs = docs.(param);
end
