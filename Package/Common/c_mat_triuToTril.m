function mat = c_mat_triuToTril(mat)
% copy upper triangular part of matrix to lower triangular part

assert(ismatrix(mat));
assert(size(mat,1)==size(mat,2));

mat = triu(mat) + triu(mat,1)';

end

function testfn()
a = rand(4,4);

c_saySingle('Starting matrix:');
disp(a)
c_saySingle('Upper triangular part:');
disp(triu(a));

b = c_mat_triuToTril(a);

c_saySingle('After mirroring:');
disp(b)

end