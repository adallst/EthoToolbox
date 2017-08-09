function pars = etho_simple_argparser(parameters, args)

if isstruct(parameters)
    parameters = [fieldnames(parameters), struct2cell(parameters)];
end
parameters = parameters';
parameters = parameters(:);
paramNames = parameters(1:2:end);
paramDefaults = parameters(2:2:end);

% Workaround Octave not implementing inputParser.StructExpand
verInfo = ver;
if any(strcmp('Octave', {verInfo.Name}))
    args = octaveArgFix(args);
end

p = inputParser;
p.KeepUnmatched = true;
for i=1:numel(paramNames)
    p.addParamValue(paramNames{i}, paramDefaults{i});
end
p.parse(args{:});

results = p.Results;
result_names = fieldnames(results);

unmatched = p.Unmatched;
unmatched_names = fieldnames(unmatched);

all_args = vertcat(struct2cell(results), struct2cell(unmatched));
all_names = vertcat(result_names, unmatched_names);

pars = cell2struct(all_args, all_names);

function fixedArgs = octaveArgFix(args)
fixedArgs = {};
i = 1;
while i <= numel(args)
    if isstruct(args{i})
        structArgs = [fieldnames(args{i}), struct2cell(args{i})]';
        fixedArgs(end+(1:numel(structArgs))) = structArgs(:)';
        i = i+1;
    else
        fixedArgs(end+(1:2)) = args(i+(0:1));
        i = i+2;
    end
end
