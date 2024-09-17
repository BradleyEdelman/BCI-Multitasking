function [estimatedTransform, movedPts] = c_pts_estimateAligningTransformation(varargin)

if nargin==0, testfn(); return; end;

p = inputParser();
p.addParameter('stationaryPts',[],@ismatrix);
p.addParameter('movingPts',[],@ismatrix);
p.addParameter('doRigid',true,@islogical);
p.addParameter('numdim',3,@isscalar);
p.addParameter('method','svd',@ischar);
p.addParameter('doPlot',false,@islogical);
p.parse(varargin{:});
s = p.Results;

assert(s.numdim==3); % for now, only 3D is supported
assert(~isempty(s.stationaryPts));
assert(~isempty(s.movingPts));
assert(size(s.stationaryPts,2)==s.numdim);
assert(size(s.movingPts,2)==3);
assert(size(s.stationaryPts,1)==size(s.movingPts,1)); % for now, require that both point sets have the same number of points

persistent icpOnPath;

switch(s.method)
	case 'icp'		
		if isempty(icpOnPath)
			mfilepath=fileparts(which(mfilename));
			addpath(fullfile(mfilepath,'../ThirdParty/icp'));
			icpOnPath = true;
		end
		
		[TR, TT] = icp(s.stationaryPts', s.movingPts');
		
		estimatedTransform = cat(1,cat(2,TR,TT),[0 0 0 1]);
		
		warning('This method may not work correctly');
		%TODO: test more thoroughly
		
	case 'svd'
		% this method may assume point to point correspondence (i.e. that pt 1 in movingPts corresponds to pt 1 in stationaryPts)
		[TR, TT] = rigid_transform_3D_SVD(s.movingPts,s.stationaryPts);
		
		estimatedTransform = cat(1,cat(2,TR,TT),[0 0 0 1]);
		
	otherwise
		error('Invalid method: %s',s.method);
end

if nargout > 1 || s.doPlot
	movedPts = c_pts_applyQuaternionTransformation(s.movingPts,estimatedTransform);
end

if s.doPlot
	figure('name','Estimated transform');
	c_subplot(1,2);
	ptGrps = {s.stationaryPts,s.movingPts};
	grpLabels = {'Stationary','Moving'};
	colors = c_getColors(length(ptGrps));
	markers = '.o';
	for iG = 1:length(ptGrps)
		pts = ptGrps{iG};
		ptArgs = c_mat_sliceToCell(pts,2);
% 		plot3(ptArgs{:},[markers(iG) '-'],'Color',colors(iG,:));
		scatter3(ptArgs{:},[],colors(iG,:),markers(iG));
		hold on;
	end
	legend(grpLabels,'location','SouthOutside');	
	title('Before alignment');
	c_subplot(2,2);
	ptGrps = {s.stationaryPts,movedPts};
	grpLabels = {'Stationary','Moved'};
	colors = c_getColors(length(ptGrps));
	for iG = 1:length(ptGrps)
		pts = ptGrps{iG};
		ptArgs = c_mat_sliceToCell(pts,2);
% 		plot3(ptArgs{:},[markers(iG) '-'],'Color',colors(iG,:));
		scatter3(ptArgs{:},[],colors(iG,:),markers(iG));
		hold on;
	end
	legend(grpLabels,'location','SouthOutside');	
	title('After alignment');
end
end

function testfn()

	origPts = rand(10,3);
	origTrans = [
		1 0 0 20;
		0 1 .1 30;
		0 0 .9 -10;
		0 0 0 1];
% 	origTrans = [
% 		1 0 0 1;
% 		0 0 1 0;
% 		0 -1 0 0;
% 		0 0 0 1];
	newPts = c_pts_applyQuaternionTransformation(origPts,origTrans);
	estTrans = c_pts_estimateAligningTransformation('movingPts',origPts,'stationaryPts',newPts,'doPlot',true);
	
	origTrans
	estTrans
end

function [R,t] = rigid_transform_3D_SVD(A, B)
% Adapted from http://nghiaho.com/?page_id=671
% This function finds the optimal Rigid/Euclidean transform in 3D space
% It expects as input a Nx3 matrix of 3D points.
% It returns R, t

    if nargin ~= 2
	    error('Missing parameters');
    end

    assert(all(size(A) == size(B)))

    centroid_A = mean(A);
    centroid_B = mean(B);

    N = size(A,1);

    H = (A - repmat(centroid_A, N, 1))' * (B - repmat(centroid_B, N, 1));

    [U,S,V] = svd(H);

    R = V*U';

    if det(R) < 0
        c_saySingle('Reflection detected');
        V(:,3) = V(:,3)*-1;
        R = V*U';
    end

    t = -R*centroid_A' + centroid_B';
end

