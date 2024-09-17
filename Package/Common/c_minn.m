function [M, I] = c_minn(A,B,dim,n)
% find n minimum numbers, sorted, in A

if nargin == 0, testfn(); return; end;

assert(isempty(B)) % second argument ignored, should be empty

if isempty(dim)
	dim = c_findFirstNonsingletonDimension(A);
end

assert(n>=0);
if n == 0
	M = [];
	I = [];
	return
elseif n == 1
	[M, I] = min(A,B,dim);
	return
end

n = min(size(A,dim),n);

if dim > 2 || ndims(A) > 2
	% can permute, but this adds time
	permOrder = 1:ndims(A);
	permOrder(1) = dim;
	permOrder(dim) = 1;
	A = permute(A,permOrder);
	origSize = size(A);
	A = reshape(A,size(A,1),[]);
	dim = 1;
	didPermute = true;
else
	didPermute = false;
end

doAlwaysSort = false;
if doAlwaysSort || n > size(A,dim) / 2
	[M,I] = sort(A,dim);
	if dim==1
		M = M(1:n,:);
		I = I(1:n,:);
	elseif dim==2
		M = M(:,1:n);
		I = I(:,1:n);
	else
		error('dim');
	end
elseif 1
	if dim==1
		M = nan(n,size(A,2));
		I = nan(n,size(A,2));
		for iN = 1:n
			[M(iN,:), I(iN,:)] = min(A,[],1);
			A(sub2ind(size(A),I(iN,:),1:size(A,2))) = NaN;
		end
	elseif dim==2
		M = nan(size(A,1),n);
		I = nan(size(A,1),n);
		for iN = 1:n
			[M(:,iN), I(:,iN)] = min(A,[],dim);
			A(sub2ind(size(A),1:size(A,1),I(:,iN)')) = NaN;
		end
	else
		error('dim');
	end
else
	if dim~=1
		error('not supported')
	end
	M = inf(n+1,size(A,2));
	I = nan(n+1,size(A,2));
	for iA = 1:size(A,1)
		iJ = true(1,size(A,2));
		for iN = n:-1:1
			iJ(iJ) = A(iA,iJ) <= M(iN,iJ);
			if all(~iJ)
				break;
			end
			M(iN+1,iJ) = M(iN,iJ);
			I(iN+1,iJ) = I(iN,iJ);
			M(iN,iJ) = A(iA,iJ);
			I(iN,iJ) = iA;
		end
	end
	M = M(1:n,:);
	I = I(1:n,:);
end

if didPermute
	M = reshape(M,[n,origSize(2:end)]);
	M = ipermute(M, permOrder);
end

end

function [M,I] = c_minn_alt(A,B,dim,n)
	permOrder = 1:ndims(A);
	permOrder(1) = dim;
	permOrder(dim) = 1;
	A = permute(A,permOrder);
	origSize = size(A);
	A = reshape(A,size(A,1),[]);
	
	[M,I] = sort(A,1);
	M = M(1:n,:);
	I = I(1:n,:);
	
	M = reshape(M,[n,origSize(2:end)]);
	M = ipermute(M, permOrder);

end

%%
function testfn()
k = 100;
m = 100000;
n = 5;
A = rand(k,m);

[M,I] = c_minn(A,[],2,n);

[M2,I2] = c_minn_alt(A,[],2,n);

% time comparison
fn = @() c_minn(A,[],2,n);
t = timeit(fn);
c_saySingle('%.9g s for c_minn',t);

fn = @() c_minn_alt(A,[],2,n);
t = timeit(fn);
c_saySingle('%.9g s for alt',t);


keyboard


end