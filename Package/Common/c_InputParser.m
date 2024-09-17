classdef c_InputParser < handle
	%% instance variables
	properties
		parameterNames = {};
		parameterDefaults = {};
		parameterValidators = {};
		parameterDescriptions = {};
		parameterIsRequired = [];
		parameterIsOptional = [];
		parameterExtraInfo = {};
		numParameters = 0;
		Results = [];
		isParsed = false;
	end
	
	%% internal instance methods
	methods (Access=protected)
		
		
	end
	
	%% instance methods
	methods
		%% constructor
		function o = c_InputParser(varargin)
			p = inputParser();
			p.parse(varargin{:});
		end	
		
		%%
		
		function addRequired(o,varargin)
			p = inputParser();
			p.addRequired('paramName',@ischar);
			p.addOptional('paramValidator',@true,@(x) isa(x,'function_handle'));
			p.addOptional('paramDescription','',@ischar);
			p.parse(varargin{:});
			s = p.Results;
			
			n = o.numParameters+1;
			o.parameterNames{n} = s.paramName;
			o.parameterDefaults{n} = '';
			o.parameterValidators{n} = s.paramValidator;
			o.parameterDescriptions{n} = s.paramDescription;
			o.parameterIsRequired(n) = true;
			o.parameterIsOptional(n) = false;
			o.parameterExtraInfo{n} = struct();
			o.numParameters = o.numParameters+1;
		end
		
		function addParameter(o,varargin)
			p = inputParser();
			p.addRequired('paramName',@ischar);
			p.addRequired('paramDefault');
			p.addOptional('paramValidator',@true,@(x) isa(x,'function_handle'));
			p.addOptional('paramDescription','',@ischar);
			p.parse(varargin{:});
			s = p.Results;
			
			n = o.numParameters+1;
			o.parameterNames{n} = s.paramName;
			o.parameterDefaults{n} = s.paramDefault;
			o.parameterValidators{n} = s.paramValidator;
			o.parameterDescriptions{n} = s.paramDescription;
			o.parameterIsRequired(n) = false;
			o.parameterIsOptional(n) = false;
			o.parameterExtraInfo{n} = struct();
			o.numParameters = o.numParameters+1;
		end
		
		function addOptional(o,varargin)
			p = inputParser();
			p.addRequired('paramName',@ischar);
			p.addRequired('paramDefault');
			p.addOptional('paramValidator',@true,@(x) isa(x,'function_handle'));
			p.addOptional('paramDescription','',@ischar);
			p.parse(varargin{:});
			s = p.Results;
			
			n = o.numParameters+1;
			o.parameterNames{n} = s.paramName;
			o.parameterDefaults{n} = s.paramDefault;
			o.parameterValidators{n} = s.paramValidator;
			o.parameterDescriptions{n} = s.paramDescription;
			o.parameterIsRequired(n) = false;
			o.parameterIsOptional(n) = true;
			o.parameterExtraInfo{n} = struct();
			o.numParameters = o.numParameters+1;
		end
		
		function addRequiredFilename(o,varargin)
			o.addParameterFilename(varargin{1},'',varargin{2:end},'isRequired',true);
		end
		function addOptionalFilename(o,varargin)
			o.addParameterFilename(varargin{:},'isOptional',true);
		end
		
		function addParameterFilename(o,varargin)
			p = inputParser();
			p.addRequired('paramName',@ischar);
			p.addRequired('paramDefault');
			p.addOptional('paramValidator',@(x) true,@(x) isa(x,'function_handle'));
			p.addOptional('paramDescription','',@ischar);
			p.addParameter('doAssertExists',false,@islogical);
			p.addParameter('doAssertFileExists',false,@islogical); % legacy, use doAssertExists + isDir instead
			p.addParameter('doAssertDirExists',false,@islogical); % legacy, use doAssertExists + isDir instead
			p.addParameter('doAllowEmpty',true,@islogical);
			p.addParameter('relativeToDir','',@ischar);
			p.addParameter('validFileTypes','',@(x)ischar(x) || iscell(x)); % e.g. '*.stl;*.fsmesh;%.off'
			p.addParameter('isForWriting',false,@islogical); % affects whether file selection GUI says "open" or "save"
			p.addParameter('isDir',false,@islogical);
			p.addParameter('isRequired',false,@islogical);
			p.addParameter('isOptional',false,@islogical);
			p.parse(varargin{:});
			s = p.Results;
			
			% construct validator
			customValidator = s.paramValidator;
			fpConstructor = @(relPath) fullfile(s.relativeToDir,relPath);
			if s.doAssertExists
				existsValidator = @(relPath) (s.doAllowEmpty && isempty(relPath)) || exist(fpConstructor(relPath),'file')>0;
			else
				existsValidator = @(relPath) true;
			end
			if s.doAssertFileExists || (s.doAssertExists && ~s.isDir)
				fileExistsValidator = @(relPath) (s.doAllowEmpty && isempty(relPath)) || ismember(exist(fpConstructor(relPath),'file'),[2 3 4 5 6]);
			else
				fileExistsValidator = @(relPath) true;
			end
			if s.doAssertDirExists || (s.doAssertExists && s.isDir)
				dirExistsValidator = @(relPath) (s.doAllowEmpty && isempty(relPath)) || exist(fpConstructor(relPath),'dir')>0;
			else
				dirExistsValidator = @(relPath) true;
			end
			if ~s.doAllowEmpty
				emptyValidator = @(relPath) ~isempty(relPath);
			else
				emptyValidator = @(relPath) true;
			end
			if ~isempty(s.validFileTypes)
				fileTypeValidator = @(relPath) true; %TODO: debug, delete
				%TODO: add validator to check file types, either in '*.stl;*.fsmesh;%.off' or {'*.stl','*.fsmesh','%.off'} format
			else
				fileTypeValidator = @(relPath) true;
			end
				
			validator = @(relPath) ...
				customValidator(relPath) &&...
				existsValidator(relPath) &&...
				fileExistsValidator(relPath) &&...
				dirExistsValidator(relPath) &&...
				emptyValidator(relPath) &&...
				fileTypeValidator(relPath);
			
			n = o.numParameters+1;
			o.parameterNames{n} = s.paramName;
			o.parameterDefaults{n} = s.paramDefault;
			o.parameterValidators{n} = validator;
			o.parameterDescriptions{n} = s.paramDescription;
			o.parameterIsRequired(n) = s.isRequired;
			o.parameterIsOptional(n) = s.isOptional;
			o.parameterExtraInfo{n} = struct();
			o.parameterExtraInfo{n}.isFilename = true;
			extraFields = {... % to copy into parameterExtraInfo
				'isForWriting',...
				'relativeToDir',...
				'isDir',...
				'validFileTypes'};
			for iF = 1:length(extraFields)
				o.parameterExtraInfo{n}.(extraFields{iF}) = s.(extraFields{iF});
			end
			o.numParameters = o.numParameters+1;
		end
		
		function changeDefault(o,varargin)
			p = inputParser();
			p.addRequired('paramName',@ischar)
			p.addRequired('newDefault');
			p.parse(varargin{:});
			s = p.Results;
			
			n = find(ismember(o.parameterNames,s.paramName));
			assert(~isempty(n));
			o.parameterDefaults{n} = s.newDefault;
		end
		
		function parseFromDialog(o,varargin)
			p = inputParser();
			p.addParameter('title','Input parser',@ischar);
			p.addParameter('doLiveValidation',true,@ischar);
			p.parse(varargin{:});
			s = p.Results;
			
			o.Results = [];
			
			prompts = cell(1,o.numParameters);
			for i=1:o.numParameters
				if isempty(o.parameterDescriptions{i})
					prompts{i} = o.parameterNames{i};
				else
					prompts{i} = [o.parameterNames{i} ' (' o.parameterDescriptions{i} ')'];
				end
			end
			doUseBuiltinInputDlg = false;
			if doUseBuiltinInputDlg
				defaults = cellfun(@c_toString,o.parameterDefaults,'UniformOutput',false);
				resp = inputdlg(prompts,s.title,1,defaults);
			else
				defaults = o.parameterDefaults;
				if s.doLiveValidation
					resp = c_inputdlg(prompts,s.title,1,defaults,...
						'Validators',o.parameterValidators,...
						'ParamExtraInfos',o.parameterExtraInfo,...
						'doLiveValidation',true);
				else
					resp = c_inputdlg(prompts,s.title,1,defaults,...
						'ParamExtraInfos',o.parameterExtraInfo);
				end
				
			end
			
			if length(resp) ~= o.numParameters
				% user pressed cancel, or some other error
				warning('Parsing canceled');
				return; % without parsing
			end
			
			res = struct();
			for i=1:o.numParameters
				if doUseBuiltinInputDlg
					if isempty(resp{i})
						convertedValue = '';
					else
						convertedValue = eval(resp{i});
					end
				else
					convertedValue = resp{i};
				end
				if o.parameterValidators{i}(convertedValue)
					res.(o.parameterNames{i}) = convertedValue;
				else
					error('Invalid input: %s=%s should obey %s',...
						o.parameterNames{i},resp{i},func2str(o.parameterValidators{i}));
				end
			end
			o.Results = res;
			o.isParsed = true;
		end
		
		function parse(o,varargin)
			o.Results = [];
			
			p = inputParser();
			for i=1:o.numParameters
				if o.parameterIsRequired(i)
					p.addRequired(o.parameterNames{i},o.parameterValidators{i});
				elseif o.parameterIsOptional(i)
					p.addOptional(o.parameterNames{i},o.parameterDefaults{i},o.parameterValidators{i});
				else
					p.addParameter(o.parameterNames{i},o.parameterDefaults{i},o.parameterValidators{i});
				end
			end
			p.parse(varargin{:});
			
			o.Results = p.Results;
		
			o.isParsed = true;
		end
	end
end



function testfn()
	cp = c_InputParser();
	cp.addParameter('Str','test',@ischar,'a string');
	cp.addParameter('Num',3.14,@isscalar,'a number');
	cp.addParameter('Vec',[1 2 3],@isvector,'a vector');
	cp.addParameter('Cell',{1, 'test'},@iscell,'a cell');
	cp.addParameterFilename('File','','relativeToDir','../','validFileTypes','*.m','doAssertExists',true);
	cp.addParameterFilename('Dir','','isDir',true,'doAssertExists',true);
	cp.addParameter('Str2','test2',@ischar,'a string');
	
	if 0
		cp.parse('Str','test2','Vec',[1:5],'Cell',{'test2',2},'File','./c_InputParser.m','Dir','./');
		res1 = cp.Results
	end
	
	cp.parseFromDialog();
	
	res2 = cp.Results
	
	keyboard
end