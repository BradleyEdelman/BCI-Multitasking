function c = c_dot(a,b,dim)
	if nargin < 3
		% assume dim is first non-matching dimension
		sa = size(a);
		sb = size(b);
		ml = min(length(sa),length(sb));
		sa = sa(1:ml); 
		sb = sb(1:ml);
		dim = find(sa==sb,1,'first');
		if isempty(dim)
			error('No matching dimensions');
		end
	end
	c = sum(bsxfun(@times,a,b),dim);
end