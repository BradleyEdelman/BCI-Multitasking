function n = c_nannorm(A,p,dim)
% c_norm: calculate pth norm along specified dimension, ignoring NaNs
% If dim is not specified, operates along first non singleton dimension

	if nargin < 3
		dim = c_findFirstNonsingletonDimension(A);
	end
	A(isnan(A)) = 0;
	switch(p)
		case 1
			n = sum(abs(A),dim);
		case 2
			n = sqrt(sum(A.^2,dim));
		case '2sq'
			n = sum(A.^2,dim); % L2 norm, squared
		case inf
			n = max(abs(A),[],dim);
		otherwise
			error('%d norm not supported',dim);
	end
			
end


