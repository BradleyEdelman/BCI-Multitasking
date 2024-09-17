function out = c_isinteger(x)
	out = isinteger(x) || (isscalar(x) && ceil(x) == floor(x)) || (~isscalar(x) && all(arrayfun(@c_isinteger,reshape(x,1,[]))));
end