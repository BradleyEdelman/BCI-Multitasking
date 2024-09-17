function allequal = c_allEqual(varargin)
	% allows arbitrary number of inputs for operation, instead of pairwise like builtin equivalent
	
	if length(varargin)==1
		allequal = true;
		return;
	end
	
	assert(length(varargin)>1);
	
	tmp = true(1,nargin-1);
	for i=2:nargin
		tmp(i-1) = isequal(varargin{1},varargin{i});
	end
	allequal = all(tmp);
end