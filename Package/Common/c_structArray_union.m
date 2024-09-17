function out = c_structArray_union(varargin)

for i = 1:nargin
	assert(isstruct(varargin{i}));
	assert(isvector(varargin{i}));
end

dim = c_findFirstNonsingletonDimension(varargin{1});
out = cat(dim,varargin{:});
out = c_structArray_unique(out);

end