function [index, minDist] = c_pts_findIndexClosestToPt(pts,queryPt)
	assert(size(pts,2)==length(queryPt));
	dists = c_norm(bsxfun(@minus,pts,queryPt),2,2);
	[minDist,index] = min(dists);
end