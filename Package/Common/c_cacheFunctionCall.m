function [res, didUseCache] = c_cacheFunctionCall(varargin)
p = inputParser();
p.addParameter('fn','');
p.addParameter('key','cache',@ischar);
p.addParameter('doForceRefresh',false,@islogical);
p.addParameter('doUpdate',true,@islogical);
p.addParameter('doRemove',false,@islogical);
p.parse(varargin{:});
s = p.Results;

persistent map;
if isempty(map)
	map = containers.Map();
end

if s.doRemove
	map.remove(s.key);
	res = [];
	didUseCache = false;
	return; % do nothing else if asked to remove a key
end

assert(isa(s.fn,'function_handle'));

if s.doForceRefresh || ~map.isKey(s.key)
	res = p.Results.fn();
	if s.doUpdate
		map(p.Results.key) = res;
	end
	didUseCache = false;
else
	res = map(p.Results.key);
	didUseCache = true;
end

end