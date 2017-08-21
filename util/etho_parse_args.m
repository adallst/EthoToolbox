function pars = etho_parse_args(defaults, args)
% Simplified argument parsing for parameter-value pairs
% Usage:
%   pars = etho_parse_args(defaults, args)
%     `defaults`
%         A set of parameter-value default pairs. Can be supplied either as a
%         scalar struct, as in:
%           struct('Param1', default1, 'Param2', default2, ...)
%         or as an N-by-2 cell array, as in:
%           { 'Param1', default1;
%             'Param2', default2;
%             ...                 }
%     `args`
%         A cell array of the arguments to parse into parameter-value pairs.
%         Typically this will just be the `varargin` array. As a notational
%         convenience, input arguments beginning with - or ~ will be expanded
%         as:
%             '-Parameter'    -->    'Parameter', true
%             '~Parameter'    -->    'Parameter', false
%     `pars`
%         A scalar struct containing all the parameter-value pairs from `args`,
%         with any missing values filled in from `args`. Parameters supplied in
%         `args` which are not in `defaults` appear normally.

if isstruct(defaults)
    defaults = [fieldnames(defaults), struct2cell(defaults)];
end
defaults = defaults';
defaults = defaults(:);
defaultParameters = defaults(1:2:end);
defaultValues = defaults(2:2:end);

isChildParameter = strncmp(defaultParameters, '>', 1);
childParameters = cellfun(@(s)s(2:end), ...
    defaultParameters(isChildParameter), ...
    'UniformOutput', false);
parameterParents = defaultValues(isChildParameter);
defaultParameters = defaultParameters(~isChildParameter);
defaultValues = defaultValues(~isChildParameter);

args = expandFlagArguments(args(:)');

% Workaround Octave not implementing inputParser.StructExpand
verInfo = ver;
if any(strcmp('Octave', {verInfo.Name}))
    args = octaveArgFix(args);
end

p = inputParser;
p.KeepUnmatched = true;
for i=1:numel(defaultParameters)
    p.addParamValue(defaultParameters{i}, defaultValues{i});
end
p.parse(args{:});

results = p.Results;
result_names = fieldnames(results);

unmatched = p.Unmatched;
unmatched_names = fieldnames(unmatched);

all_args = vertcat(struct2cell(results), struct2cell(unmatched));
all_names = vertcat(result_names, unmatched_names);

pars = cell2struct(all_args, all_names);

child_not_set = ~ismember(childParameters, all_names)';
for i=find(child_not_set)
    pars.(childParameters{i}) = pars.(parameterParents{i});
end

function args = expandFlagArguments(args)
i = 1;
while i <= numel(args)
    if ischar(args{i})
        if args{i}(1) == '-'
            args{i} = args{i}(2:end);
            args = [args(1:i), {true}, args(i+1:end)];
        elseif args{i}(1) == '~'
            args{i} = args{i}(2:end);
            args = [args(1:i), {false}, args(i+1:end)];
        end
        i = i+2;
    else
        i = i+1;
    end
end

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
