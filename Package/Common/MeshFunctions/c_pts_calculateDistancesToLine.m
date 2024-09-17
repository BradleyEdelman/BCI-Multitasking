function dists = c_pts_calculateDistancesToLine(pts,lineOrigin,lineVec)
% from https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Vector_formulation
lineVec = lineVec/c_norm(lineVec,2);

numPts = size(pts,1);
if numPts < 10 
	dists = nan(1,numPts);
	for iP = 1:size(pts,1)
		dists(iP) = c_norm((lineOrigin - pts(iP,:)) - (c_dot((lineOrigin - pts(iP,:)),lineVec,2)*lineVec),2);
	end
else
	% vectorized version
	amp = bsxfun(@minus,lineOrigin,pts);
	dists = c_norm(amp - c_dot(amp,lineVec,2),2,2);
end

end

function testfn()
	pts = rand(15,3);
	disp(c_toString(pts,'doPreferMultiline',true));
	
	pts = [0.81472 	0.14189 	0.70605 ;
		 0.90579 	0.42176 	0.031833;
		 0.12699 	0.91574 	0.27692 ;
		 0.91338 	0.79221 	0.046171;
		 0.63236 	0.95949 	0.097132;
		 0.09754 	0.65574 	0.82346 ;
		 0.2785  	0.035712	0.69483 ;
		 0.54688 	0.84913 	0.3171  ;
		 0.95751 	0.93399 	0.95022 ;
		 0.96489 	0.67874 	0.034446;
		 0.15761 	0.75774 	0.43874 ;
		 0.97059 	0.74313 	0.38156 ;
		 0.95717 	0.39223 	0.76552 ;
		 0.48538 	0.65548 	0.7952  ;
		 0.80028 	0.17119 	0.18687 ];
	
	lineOrigin = [1 1 1];
	lineVec = [0.5 1 1.5];
	
	dists = c_pts_calculateDistancesToLine(pts,lineOrigin,lineVec)'

end