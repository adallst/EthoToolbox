function EthoSaveTable(table, filename, varargin)

text = EthoSerializeTable(table, varargin{:});

fid = fopen(filename, 'w');
fwrite(fid, text);
fclose(fid);
