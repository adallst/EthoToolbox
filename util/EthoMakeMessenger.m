function messenger = EthoMakeMessenger(pre, verbose)

if ~exist('pre','var') || isempty(pre)
    pre = 'Etho';
end
if ~exist('verbose','var') || isempty(verbose)
    verbose = 1;
end
if verbose > 0
    if isa(pre, 'function_handle')
        messenger = pre;
    else
        messenger = @(message, varargin)print_message(pre, message, varargin);
    end
else
    messenger = @no_op;
end

function no_op(varargin)
% Do nothing.

function print_message(pre, format_str, format_args)
sz = get(0,'CommandWindowSize');
if sz(1) == 0
    width = 80;
else
    width = sz(1);
end

width = width - length(pre) - 2;
if iscellstr(format_str)
    format_str = strjoin(format_str, ' ');
end
message = sprintf(format_str, format_args{:});
message_lines = estr_wrap(message, width, true);
for i = 1:numel(message_lines)
    fprintf('%s: %s\n', pre, message_lines{i});
end
