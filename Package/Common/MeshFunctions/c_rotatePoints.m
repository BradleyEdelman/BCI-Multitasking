function rotPts = c_rotatePoints(pts,rotationOrigin,rotationAngles,doReverse)

	if nargin < 4
		doReverse = false;
	end

	if nargin == 0
		warning('no arguments, just testing rotation');
		
		figure;
		n = 5;
		for i=1:n
			pts = [	1,0.1,0;
					1,0,0;
					0,0,0;
					0,1,0;
					0,0,0;
					0,0,1];
				
			pts(:,3) = pts(:,3) + 1;
			
			rotation = [30*i,30,45];
			
			pts = c_rotatePoints(pts,[0,0,0],rotation);
			
			line(pts(:,1),pts(:,2),pts(:,3),'color',[i/n,0,0]);
			
			hold on
		end
		
		
		axis equal;
		axis([-2 2 -2 2 -2 2]);
		
		view(50,20);
		
		return
	end

	pts = pts';
	rotationOrigin = rotationOrigin';

	pts = pts - repmat(rotationOrigin,1,size(pts,2));

	th = rotationAngles(1);
	R_z = [ cosd(th) -sind(th)		0; 
			sind(th)  cosd(th)		0;
					0		0		1];
	th = rotationAngles(2);
	R_xp = [			1		0		0;
			0 cosd(th) -sind(th);
			0 sind(th)  cosd(th)];
% 	R_y = [ cosd(th)		0  sind(th);
% 					0		1		0;
% 			-sind(th)		0  cosd(th)];
	th = rotationAngles(3);
	R_zpp = [ cosd(th) -sind(th)		0;
			sind(th)  cosd(th)		0;
					0		0		1];
				
	R = R_z*R_xp*R_zpp;
	
	if ~doReverse
		rotPts = R*pts;
	else
		rotPts = (pts'*R)';
	end
	
	rotPts = rotPts + repmat(rotationOrigin,1,size(pts,2));
	
	rotPts = rotPts';

end


