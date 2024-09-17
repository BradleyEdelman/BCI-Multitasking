function res = c_dialogInputParser(args,dlgTitle)
	% args should be a struct, with each field representing a parameter to display

	if nargin == 0, testfn(); return; end;

	if nargin < 2
		dlgTitle = 'Input parameters';
	end

	names = {};
	defaults = {};
	fieldNames = fieldnames(args);
	for i=1:length(fieldnames(args))
		fieldName = fieldNames{i};
		if isempty(args.(fieldName).name)
			args.(fieldName).name = fieldName;
		end
		if ~isempty(args.(fieldName).default)
			% make sure that validator works, and that specified default is valid.
			assert(args.(fieldName).validator(args.(fieldName).default));
		end

		names = [names, {args.(fieldName).name}];
		defaults = [defaults, {c_toString(args.(fieldName).default)}];
	end

	prompts = fieldnames(args);
	for i=1:length(fieldnames(args))
		fieldName = fieldNames{i};
		if ~isempty(args.(fieldName).description)
			prompts{i} = [prompts{i} ' (' args.(fieldName).description ')'];
		end
	end

	resp = inputdlg(prompts,dlgTitle,1,defaults);

	if length(resp) ~= length(fieldnames(args))
		% user pressed cancel, or some other error
		res = {};
		return;
	end

	for i=1:length(fieldnames(args))
		fieldName = fieldNames{i};
		if isempty(resp{i})
			convertedValue = '';
		else
			convertedValue = eval(resp{i});
		end
		if args.(fieldName).validator(convertedValue)
			res.(fieldName) = convertedValue;
		else
			error('Invalid input: %s=%s should obey %s',...
				args.(fieldName).name,resp{i},func2str(args.(fieldName).validator));
		end
	end
end

function testfn()
	% test
	dlgTitle = 'test';
	templateArg = struct('name','','description','','validator',@(x) false(1),'default','');

	args.var1 = templateArg;
	args.var1.name = 'VarName1';
	args.var1.validator = @ischar;
	args.var1.description = 'a string';

	args.var2 = templateArg;
	args.var2.name = 'VarName2';
	args.var2.validator = @isscalar;
	args.var2.description = 'a number';
	args.var2.default = 3.14;

	args.var3 = templateArg;
	args.var3.name = 'VarName3';
	args.var3.validator = @isvector;
	args.var3.description = 'a vector';

	res = c_dialogInputParser(args, dlgTitle);
end