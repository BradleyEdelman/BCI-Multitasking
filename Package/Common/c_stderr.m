function stderr = c_stderr(varargin)

p = inputParser;
p.addRequired('X',@isnumeric);
p.addOptional('w',0,@isnumeric);
p.addOptional('dim',1,@isscalar);
p.addParameter('nanflag','omitnan',@ischar);
p.parse(varargin{:});
s = p.Results;

if ismember('dim',p.UsingDefaults)
	% set dim to first non-singleton dimension
	s.dim = find(size(s.X)~=1,1,'first');
end

stderr = std(s.X,s.w,s.dim,s.nanflag) / sqrt(size(s.X,s.dim));
end