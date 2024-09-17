function B = c_unpadArray(varargin)
% does the opposite of padarray() (e.g. for removing padding after applying a filter)
if nargin==0, testfn(); return; end;
p = inputParser;
p.addRequired('A',@(x) isnumeric(x) || islogical(x));
p.addRequired('padSize',@isvector);
p.addOptional('padval',[],@(x) isscalar(x) || ischar(x)); % not used
p.addOptional('direction','both',@ischar);
p.parse(varargin{:});
padSize = p.Results.padSize;
B = p.Results.A;

% adapted from http://www.mathworks.com/matlabcentral/answers/43387-how-to-crop-arrays-using-a-vector-reverse-of-padarray

otherDims = repmat({':'},ndims(B)-1,1);
for i=1:length(padSize)
	switch(p.Results.direction)
		case 'both'
			B = B(padSize(i)+1:end-padSize(i),otherDims{:});
		case 'post'
			B = B(1:end-padSize(i),otherDims{:});
		case 'pre'
			B = B(padSize(i)+1:end,otherDims{:});
		otherwise
			error('Invalid direction: %s',p.Results.direction);
	end
	B = shiftdim(B,1);
end

B = shiftdim(B,ndims(B)-length(padSize));

end

function testfn()
	A = rand(3,2)
	B = padarray(A,[1 2],0,'both')
	C = c_unpadArray(B,[1 2],0,'both')
	assert(all(size(A)==size(C)) && all(A(:)==C(:)));
end