function ETableWriteHead(table, file, varargin)
% Write the header for a table to file

[~, names] = ETableAutoType(table, varargin{:});
body = cell(0,numel(names));

text = ETableSerialize(body, varargin{:}, ...
    'TableNamesOut', names, '-PrintHeader');

if isnumeric(file)
    fprintf(file, text);
elseif ischar(file)
    fid = fopen(file, 'a');
    try
        fwrite(fid, text);
        fclose(fid);
    catch e
        fclose(fid);
        rethrow(e);
    end
else
    error('Not a file identifier');
end
