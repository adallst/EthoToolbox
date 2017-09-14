function lazy_handle = lazy_eval(func, varargin)
% Lazy evaluation for MATLAB
% Usage:
%   lazy_handle = lazy_eval(@func, [arg1, arg2, ...])
%   value = lazy_handle()
%
% For a function call func(arg1, arg2, ...), the call
%   lazy_eval(@func, arg1, arg2, ...)
% returns a "lazy evaluator", a function handle which will call the
% function only once, and remember its result. Subsequent calls to the lazy
% evaluator return the result without calling the original function again.
% Additionally, calling lazy_eval multiple times with the same combination
% of function and arguments will return equivalent lazy evaluators, sharing
% the same cached result.
%
% Example:
%   >> lh1 = lazy_eval(@fprintf, 1, 'hello lazy world');
%   >> lh1() % fprintf is only called when the lazy evaluator is
%   hello lazy world
%   ans =
%       16
%   >> lh1() % fprintf is not called again, but the result is returned
%   ans =
%       16
%   >> lh2 = lazy_eval(@fprintf, 1, 'hello lazy world');
%   >> lh2() % Function & arguments are remembered and not evaluated again
%   ans =
%       16

persistent lazy_cache;

if isempty(lazy_cache)
    lazy_cache = struct('func', {}, 'args', {}, 'is_evaluated', {}, ...
            'value', {});
end

pre_cached = false;
for ind=1:numel(lazy_cache)
    if isequal(func, lazy_cache(ind).func) && ...
            isequal(varargin, lazy_cache(ind).args)
        pre_cached = true;
        break;
    end
end

if ~pre_cached
    ind = numel(lazy_cache)+1;
    lazy_cache(ind) = struct('func', func, 'args', {varargin}, ...
        'is_evaluated', false, 'value', []);
end

    function value = get_lazy_value(ind)
        if lazy_cache(ind).is_evaluated
            value = lazy_cache(ind).value;
            return;
        end
        value = feval(lazy_cache(ind).func, lazy_cache(ind).args{:});
        lazy_cache(ind).value = value;
        lazy_cache(ind).is_evaluated = true;
    end

lazy_handle = @()get_lazy_value(ind);

end
