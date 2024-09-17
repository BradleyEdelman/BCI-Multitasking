function C = c_or(varargin) 
	% allows arbitrary number of inputs for operation, instead of pairwise like builtin equivalent
	
	assert(length(varargin)>1);
	
	C = varargin{1};
	for i=2:length(varargin)
		C = or(C,varargin{i});
	end
end