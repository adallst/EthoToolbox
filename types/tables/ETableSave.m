function ETableSave(table, filename, varargin)

text = EthoSerializeTable(table, varargin{:});

fid = fopen(filename, 'w');
try
    fwrite(fid, text);
catch e
    fclose(fid);
    rethrow(e);
end
