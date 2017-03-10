function p = etho_genpath(d)
% A slighly customized version of genpath which excludes all directories
% beginning with '.'.

%error('Not working right, stop now and fix.');
% Need to use builtin genpath rather than recursive dir, because recursive dir
% seems to follow symlinks into infinite loops

fullset = genpath(d);
subdirs = strsplit(fullset, pathsep);
isNotHidden = cellfun(@isempty, strfind(subdirs, [filesep '.']));
subdirs = subdirs(isNotHidden);
p = strjoin(subdirs, pathsep);
