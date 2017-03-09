function messenger = EthoMakeMessenger(pre, verbose)

if ~exist('pre','var')
    pre = 'Etho'
end
if ~exist('verbose','var')
    verbose = true;
end
if ~verbose
    messenger = @(varargin)();
else
    messenger = @(varargin)fprintf('%s: %s\n', pre, sprintf(varargin{:}));
end
