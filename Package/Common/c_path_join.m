function path = c_path_join(varargin)
% intended to be the opposite of fileparts() to join dir, filename, and optionally ext together
%
% Note that if specifying extension separately, it must begin with '.'. Otherwise it will assumed to be a filename and the previous argument a parent dir.
%
% e.g. 
%	c_path_join('SuperParent','Parent','file','.ext')=='SuperParent/Parent/file.ext'
%	c_path_join('Parent','file.ext')=='Parent/file.ext
%	c_path_join('Parent','file')=='Parent/file'

if nargin == 0
	path ='';
	return;
end

if nargin == 1
	path = varargin{1};
	return;
end

% if last input starts with '.', assume it is an extension
lastInput = varargin{nargin};
if ~isempty(lastInput) && lastInput(1)=='.'
	ext = lastInput;
	hasSeparateExt = true;
else
	hasSeparateExt = false;
end

if hasSeparateExt
	path = fullfile(varargin{1:nargin-1});
	path = [path ext];
else
	path = fullfile(varargin{:});
end