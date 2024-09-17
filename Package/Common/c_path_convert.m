function path = c_path_convert(varargin)
if nargin==0, testfn(); return; end;

p = inputParser();
p.addRequired('path',@ischar);
p.addParameter('makeRelativeTo','',@ischar);
p.parse(varargin{:});
s = p.Results;
path = s.path;

% add dependencies to path
persistent pathModified;
if isempty(pathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'./ThirdParty/GetFullPath'));
	pathModified = true;
end

%%
if ~isempty(s.makeRelativeTo) && ~isempty(path)
	path = GetFullPath(path);
	relToPath = GetFullPath(s.makeRelativeTo);
	if isequal(addTrailingSlash(path),addTrailingSlash(relToPath)) 
		% handle special case where path and relToPath are identical
		if path(end) == filesep
			path = strcat('.',filesep);
		else
			path = '.';
		end
	else
		relToPath = addTrailingSlash(relToPath);
		prefix = c_str_findCommonPrefix({path,relToPath});
		
		% make sure prefix ends in trailing slash to not be a partial filename match
		prefix = prefix(1:find(prefix==filesep,1,'last'));
		path = path(length(prefix)+1:end);
		
		i = 0;
		limit = 20;
		while ~isequal(GetFullPath(fullfile(s.makeRelativeTo,path)),GetFullPath(s.path)) && i<limit
			path = fullfile('../',path);
			i = i+1;
		end
		if i == limit
			keyboard
			error('Problem constructing relative path');
		end
	end
	assert(isequal(GetFullPath(fullfile(s.makeRelativeTo,path)),GetFullPath(s.path)));
	
	%c_saySingle('Converted ''%s'' to ''%s'' + ''%s''',s.path,s.makeRelativeTo,path);
end
	
end

function path = addTrailingSlash(path)
	if path(end) ~= filesep
		path(end+1) = filesep;
	end
end


function testfn()

% test makeRelativeTo

i = 0;
i = i+1;
testcase(i) = struct(...
	'input','../../folder2/test.file',...
	'relTo','../../folder2',...
	'output','test.file');

i = i+1;
testcase(i) = struct(...
	'input','../../folder2/test.file',...
	'relTo','../../folder',...
	'output','../folder2/test.file');

i = i+1;
testcase(i) = struct(...
	'input','../../folder2/',...
	'relTo','../../folder2',...
	'output','./');

i = i+1;
testcase(i) = struct(...
	'input','../../folder2',...
	'relTo','../../folder2',...
	'output','.');

i = i+1;
testcase(i) = struct(...
	'input','../../folder2/',...
	'relTo','../../folder2',...
	'output','./');

i = i+1;
testcase(i) = struct(...
	'input','../',...
	'relTo','./',...
	'output','../');

i = i+1;
testcase(i) = struct(...
	'input','',...
	'relTo','../',...
	'output','');

i = i+1;
testcase(i) = struct(...
	'input','./test',...
	'relTo','',...
	'output','./test');

i = i+1;
testcase(i) = struct(...
	'input','/test/test2/../test3',...
	'relTo','/test2',...
	'output','../test');


for i = 1:length(testcase)
	testPath = testcase(i).input;
	relTo = testcase(i).relTo;
	newPath = c_path_convert(testPath,'makeRelativeTo',relTo);
	c_saySingle('Converted ''%s'' to ''%s'' + ''%s''',testPath,relTo,newPath);
	expectedOutput = testcase(i).output;
	assert(isequal(GetFullPath(expectedOutput),GetFullPath(newPath)));
end
	
end