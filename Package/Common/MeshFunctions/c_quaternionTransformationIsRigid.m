function isRigid = c_quaternionTransformationIsRigid(varargin)
p = inputParser();
p.addRequired('quaternion',@ismatrix);
p.addParameter('testPointScalar',1,@isscalar);
p.addParameter('relativeErrorThreshold',0.01,@isscalar);
p.addParameter('actionIfFalse','warning',@ischar);
p.addParameter('numPts',100,@isscalar);
p.parse(varargin{:});
s = p.Results;

origPts = rand(s.numPts,3)*s.testPointScalar;

origDists = calculatePairwiseDistances(origPts);

tranPts = c_pts_applyQuaternionTransformation(origPts,s.quaternion);

tranDists = calculatePairwiseDistances(tranPts);

deltaDists = max(abs(origDists(:)-tranDists(:)));

if deltaDists>s.relativeErrorThreshold*s.testPointScalar
	isRigid = false;
	switch(s.actionIfFalse)
		case 'warning'
			warning('Quaternion not rigid: error=%.3g',deltaDists);
		case 'error'
			error('Quaternion not rigid: error=%.3g',deltaDists);
		case 'print'
			c_saySingle('Quaternion not rigid: error=%.3g',deltaDists)
		case 'keyboard'
			c_saySingle('Quaternion not rigid: error=%.3g',deltaDists)
			keyboard
		case 'none'
			% do nothing
		otherwise
			error('Unsupported actionIfFalse');
	end
else
	isRigid = true;
end

	
end

function dists = calculatePairwiseDistances(pts)
numPts = size(pts,1);
dists = zeros(numPts,numPts);
for i=1:numPts
	for j=i+1:numPts
		dists(i,j) = c_norm(pts(i,:)-pts(j,:),2,2);
	end
end
end