function ETableSave(table, filename, varargin)

text = ETableSerialize(table, varargin{:});

fid = fopen(filename, 'w');
try
    fwrite(fid, text);
    fclose(fid);
catch e
    fclose(fid);
    rethrow(e);
end
