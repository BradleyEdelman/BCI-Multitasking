function [c, didSucceed] = c_stringToCell(s)
	%TODO: generalize to parse any variable string (cell, numeric array, string, etc.)
	
	if nargin == 0
		% test
		c_stringToCell('{''test'',[1 2 3],''a1'',{''test inner'', 5}}')
		return
	end

	c = {};
	
	if ~ischar(s)
		didSucceed = false;
		return;
	end
	
	if ~(strcmp(s(1),'{') && strcmp(s(end),'}'))
		didSucceed = false;
		return;
	end
	
	c = eval(s); %TODO: replace with more "secure" version that doesn't allow execution of arbitrary code
	
	if ~iscell(c)
		didSucceed = false;
		c = {};
		return;
	end
	
	didSucceed = true;
	
end

