function c_callFns(fnHandles,varargin)
% an ugly hack because Matlab doesn't allow multiline anonymous functions
% Instead, create a cell array of anonymous functions to call in sequence and feed in to this
% intermediate variables cannot be used since the same varargin is passed to all callbacks

assert(iscell(fnHandles));
for i = 1:length(fnHandles)
	assert(isa(fnHandles{i},'function_handle'));
	fnHandles{i}(varargin{:});
end
end