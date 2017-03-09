classdef EthoColors

    properties (Private)
        colorNames
        colorValues
        normalNames
        format
    end

    methods
        function obj = EthoColors(format)
            if ~exist('format','var') || isempty(format)
                format = '255';
            end
            colorTable = EthoColorTable;
            obj.colorNames = colorTable.names;
            obj.colorValues = colorTable.values;
            obj.normalNames = obj.normalizeString(colorTable.names);
            if isnumeric(format)
                format = num2str(format);
            end
            obj.format = format;
        end

        function val = get(obj, name)
            name = EthoColors.normalizeString(name);
            normalNames = internalGet(obj, 'normalNames');
            values = internalGet(obj, 'colorValues');
            [nameExists, colorInd] = ismember(name, normalNames);
            if ~all(nameExists)
                error('EthoToolbox:noSuchColor', ...
                    'No such color exists by name.');
            end
            val = values(colorInd,:);
            switch internalGet(obj, 'format')
                case '1'
                    val = val ./ 255;
                case '255'
                    % Nothing to do
                case 'hex'
                    error('EthoToolbox:notImplemented', ...
                        'Not yet implemented');
            end
        end

        function colorTable = list(obj)
            colorTable.names = internalGet(obj, 'colorNames');
            colorTable.values = internalGet(obj, 'colorValues');
        end

        function val = subsref(obj, sub)
            if strcmp(sub(1).type, '.')
                try
                    val = get(obj, sub(1).subs);
                catch err
                    if strcmp(err.identifier, 'EthoToolbox:noSuchColor')
                        val = builtin('subsref', obj, sub);
                        return;
                    end
                end
            end
            if ~isscalar(sub)
                val = subsref(val, sub(2:end));
            end
        end
    end

    methods (Private)
        function val = internalGet(obj, prop)
            val = builtin('subsref', obj, struct('type', '.', 'subs', prop));
        end
    end

    methods (Static)
        function val = c(name)
            val = get(EthoColors, name);
        end

        function s = normalizeString(s)
            s = tolower(regexprep(s, '\s', ''));
        end
    end
end
