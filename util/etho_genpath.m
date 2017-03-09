function p = etho_genpath(d)
% A slighly customized version of genpath which excludes all directories
% beginning with '.'.

error('Not working right, stop now and fix.');
% Need to use builtin genpath rather than recursive dir, because recursive dir
% seems to follow symlinks into infinite loops

listing = dir(d);
listing_entries = {listing.name};
subdirs = listing_entries([listing.isdir] & ~strncmp(listing_entries, '.', 1));
subdirs = fullfile(d, subdirs);
subpaths = cell(size(subdirs));
for i = 1:numel(subdirs)
    subpaths{i} = etho_genpath(subdirs{i});
end
p = strjoin([{d}, subpaths],pathsep);
