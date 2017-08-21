function ETableWriteFile(table, file, varargin)

text = ETableSerialize(table, varargin{:});

% Determine file identifier type
if isnumeric(file)
    fid = file;
    fwrite(fid, text);
elseif ischar(file)
    fid = fopen(file, 'a');
    
