function pts = c_pts_applyQuaternionTransformation(pts,quaternion)
	% based on https://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1.h
	assert(isnumeric(pts));
	assert(ismatrix(pts));
	assert(size(pts,2)==3);
	
	assert(isnumeric(quaternion));
	assert(ismatrix(quaternion));
	assert(size(quaternion,1)==4);
	assert(size(quaternion,2)==4);
	assert(all(abs(quaternion(4,1:3))<eps*1e2));
	assert(abs(abs(quaternion(4,4))-1)<eps*1e2);
	
	pts = bsxfun(@plus,quaternion(1:3,1:3)*bsxfun(@times,pts,[1 1 quaternion(4,4)]).',quaternion(1:3,4)).';
end