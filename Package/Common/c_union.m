function C = c_union(varargin) 
	% allows arbitrary number of inputs for operation, instead of pairwise like builtin equivalent
	
	if isempty(varargin)
		C = {};
		return
	end
	
	if length(varargin)==1
		C = varargin{1};
		return;
	end
	
	assert(length(varargin)>1);
	
	C = varargin{1};
	for i=2:length(varargin)
		C = union(C,varargin{i});
	end
end