classdef App < handle
    properties
        name
        registeredFunctions
        registeredCallbacks
        magicWord
        debug
    end
    
    methods
        function obj = App()
            obj.name = 'App';
            obj.registeredFunctions = containers.Map();
            obj.registeredCallbacks = containers.Map();
            obj.magicWord = '#ARKITEKT';
            obj.debug = false;            
        end
        
        function port = intPort(obj, key, description)
            if nargin < 3
                description = '';
            end
            port = struct('key', key, 'nullable', false, ...
                'description', description, 'scope', 'GLOBAL', ...
                'kind', 'INT');
        end
        
        function port = omeTiffPort(obj, name, description)
            if nargin < 3
                description = '';
            end
            port = struct('key', name, 'nullable', false, ...
                'description', description, 'scope', 'LOCAL', ...
                'kind', 'STRUCTURE', 'identifier', 'OME_TIFF');
        end
        
        function sendMessage(obj, message)
            fprintf('%s%s\n', obj.magicWord + "||", jsonencode(struct("message", message)) + "||");
        end

        function dumpRegistry(obj)
            if obj.debug
                fprintf('Dumping registry\n');
            end
            keys = obj.registeredFunctions.keys;
            for i = 1:length(keys)
                key = keys{i};
                definition = obj.registeredFunctions(key);

                if isempty(definition)
                    error('Definition for %s is empty', key);
                end
                if obj.debug
                    fprintf('Registering %s\n', key);
                    fprintf('Definition: %s\n', jsonencode(definition));
                end
                obj.sendMessage(struct('type', 'REGISTER', 'interface', key, 'definition', definition));
            end
            obj.sendMessage(struct('type', 'REGISTER_DONE'));
        end

        function call(obj, id, interface, kwargs)
            if isKey(obj.registeredFunctions, interface)
                input = obj.registeredFunctions(interface);
                try
                    funcHandle = obj.registeredCallbacks(interface);
                    if obj.debug
                        fprintf('Calling %s\n', interface);
                        fprintf('Args: %s\n', jsonencode(kwargs));
                    end


                    % Get the defined arguments from the interface
                    args = input.args;

                    % Create a cell array of arguments in the correct order
                    functionArgs = cell(1, length(args));
                    for i = 1:length(args)
                        argName = args{i}.key;
                        if isfield(kwargs, argName)
                            functionArgs{i} = kwargs.(argName);
                        else
                            error('Missing required argument: %s', argName);
                        end
                    end

                    % Call the function with the ordered arguments
                    returnValue = funcHandle(functionArgs{:});
                    if isempty(returnValue)
                        returnValue = {};
                    end
                    if ~iscell(returnValue)
                        returnValue = {returnValue};
                    end
                    if length(returnValue) ~= length(input.returns)
                        error('Invalid return value');
                    end
                    returnDict = struct();
                    for i = 1:length(input.returns)
                        port = input.returns{i};
                        returnDict.(port.key) = returnValue{i};
                    end
                    obj.sendMessage(struct('type', 'DONE', 'id', id, 'returns', returnDict));
                catch e
                    obj.sendMessage(struct('type', 'ERROR', 'id', id, 'message', e.message));
                end
            else
                obj.sendMessage(struct('type', 'ERROR', 'id', id, 'message', 'Function not registered'));
            end
        end

        function run(obj)
            fprintf('Running\n');
            obj.sendMessage(struct('type', 'INIT', 'name', obj.name));
            
            while true
                message = input('', 's');
                if obj.debug
                    fprintf('Received message: %s\n', message);
                end
                parsedMessage = obj.parseCliMessage(message);
                if ~isempty(parsedMessage)
                    if strcmp(parsedMessage.type, 'INIT_REGISTRATION')
                        obj.dumpRegistry();
                    elseif strcmp(parsedMessage.type, 'ASSIGN')
                        obj.call(parsedMessage.id, parsedMessage.interface, parsedMessage.kwargs);
                    end
                end
            end
        end

        function register(obj, funcHandle, name, args, returns)
            definitionInput = struct('name', name, 'args', {args}, 'returns', {returns}, 'kind', 'FUNCTION', 'collections', {{}}, 'description', '', 'stateful', false, 'portGroups', {{}}, 'interfaces', {{}}, 'isDev', false, 'isTestFor', {{}});

            if obj.debug
                fprintf('Registering %s\n', name);
                fprintf('Definition: %s\n', jsonencode(definitionInput));
            end
            
            obj.registeredCallbacks(name) = funcHandle;
            obj.registeredFunctions(name) = definitionInput;

        end

        function parsedMessage = parseCliMessage(obj, message)
            if ~startsWith(message, obj.magicWord)
                parsedMessage = [];
                return;
            end
            message = message(length(obj.magicWord)+1:end);
            parsedMessage = jsondecode(message);
            parsedMessage = parsedMessage.message;
        end
    end
end

