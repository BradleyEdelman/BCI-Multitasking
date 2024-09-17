function i = indexInAClosestToB(A,B)
	assert(isvector(A));
	assert(isscalar(B));
	[~,i] = min(abs(A-B));
end