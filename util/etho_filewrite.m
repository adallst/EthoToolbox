function count = etho_filewrite(file, data, mode, precision, skip, arch)
% Write data to a file, opening and closing the file if needed
% Usage:
%   count = etho_filewrite(file, data, [mode, precision, skip, arch])
% If `file` is a numeric file identifier, acts exactly as the `fwrite` function,
% and the `mode` argument is ignored.
% If `file` is a string, first calls `fopen(file, [mode, arch])`, then calls
% `fwrite(fid, data, [precision, skip, arch])` with `fid` as the result of the
% `fopen` call, and finally `fclose(fid)`. If an error occurs during writing,
% the file identifier is closed before the error is rethrown. The default `mode`
% argument, if not supplied or empty, is 'a' (create or append to end of
% existing file).

fopen_args = {};
fwrite_args = {};
if exist('mode','var') && ~isempty(mode)
    fopen_args{1} = mode;
else
    fopen_args{1} = 'a';
end
if exist('precision', 'var')
    fwrite_args{1} = precision;
end
if exist('skip', 'var')
    fwrite_args{2} = skip;
end
if exist('arch','var')
    fopen_args{2} = arch;
    fwrite_args{3} = arch;
end

if isnumeric(file)
    % File identifier is already open
    count = fwrite(file, data, fwrite_args{:});
elseif ischar(file)
    % File path, safely open and write
    fid = fopen(file, fopen_args{:});
    try
        count = fwrite(fid, data, fwrite_args{:});
        fclose(fid);
    catch e
        fclose(fid);
        rethrow(e);
    end
end
