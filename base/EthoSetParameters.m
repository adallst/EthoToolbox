function EthoSetParameters(paramset, newPars, newDocs, varargin)

args = etho_simple_argparser({
    'Verbosity', 0;
    'Messenger', 'Etho';
    }, varargin);

message = EthoMakeMessenger(args.Messenger, args.Verbosity);

if ~exist('newDocs', 'var') || isempty(newDocs)
    newDocs = struct;
end

[pars, docs] = EthoParameters(paramset);

pfields = fieldnames(newPars);
for i=1:numel(pfields)
    pars.(pfields{i}) = newPars.(pfields{i});
end
pfields = fieldnames(pars);
% Ignore documentation fields for parameters that don't exist
dfields = intersect(fieldnames(newDocs), pfields);
for i=1:numel(dfields)
    docs.(dfields{i}) = newDocs.(dfields{i});
end
% Populate empty strings for undocumented parameters
dfields = fieldnames(docs);
undoc_pars = setdiff(pfields, dfields);
for i=1:numel(undoc_pars)
    docs.(dfields{i}) = '';
end

docs = orderfields(docs, pars);

table = [pfields, struct2cell(pars), struct2cell(docs)];

param_file = fullfile(EthoPaths('current_profile'), ...
    strcat(paramset, '.ethopars'));
EthoSaveTable(table, param_file, 'Fields', pfields);

message('Wrote paramset "%s" to %s.', paramset, param_file);
