function C = c_intersect(varargin) 
	% allows arbitrary number of inputs for operation, instead of pairwise like builtin equivalent
	
	if nargin == 1
		C = varargin{1};
		return;
	end
	
	assert(length(varargin)>1);
	
	C = varargin{1};
	for i=2:length(varargin)
		C = intersect(C,varargin{i});
	end
end