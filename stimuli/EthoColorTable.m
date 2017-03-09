function colorTable = EthoColorTable()

text = fileread('x11-colors.csv');
data = regexp(text, '([^,]+),(..)(..)(..)', 'tokens');
data = vertcat(data{:});

colorTable.names = data(:,1);
colorTable.values = reshape(hex2dec(data(:,2:end)), [], 3);
