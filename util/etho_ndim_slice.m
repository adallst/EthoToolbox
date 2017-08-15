function ao = etho_ndim_slice(ai, idx, dim)
% Get a lower-dimensional slice from an arbitrary-dimensional array
% Usage:
%   ao = etho_ndim_slice(ai, idx)
%   ao = etho_ndim_slice(ai, idx, dim)
%    `ai`
%      An N-dimensional array of any type
%    `idx`
%      An index vector for one dimension of the array
%    `dim`
%      Which dimension to index. Default is 1.
%    `ao`
%      An array formed by indexing `ai` only along dimension `dim` and using
%      : for all other dimensions. I.e.,
%        ao = ai(:, :, ..., idx, :, :, ...)
%      such that dim-1 :'s appear before idx, and N-dim after.

if ~exist('dim', 'var') || isempty(dim)
    dim = 1;
end

sub.type = '()';
sub.subs = repmat({':'}, 1, ndims(ai));
sub.subs{dim} = idx;

ao = subsref(ai, sub);
