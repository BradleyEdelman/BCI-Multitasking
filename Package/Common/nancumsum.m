function B = nancumsum(x,varargin)
	x(isnan(x))=0;
	B = cumsum(x,varargin{:});
end
