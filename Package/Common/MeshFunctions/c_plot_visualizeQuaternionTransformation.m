function pts = c_plot_visualizeQuaternionTransformation(varargin)
	p = inputParser();
	p.addRequired('quaternion',@ismatrix);
	p.addParameter('unitLength',1,@isscalar);
	p.addParameter('doLabelLengths',false,@islogical);
	p.parse(varargin{:});
	s = p.Results;

	% colors for distance labeling text, etc.
	origColor = [0.5 0.5 0.5];
	newColor = [0 0 0];

	origPts = [
		0 0 0;
		1 0 0;
		0 0 0;
		0 1 0;
		0 0 0;
		0 0 1;
	];

	origPts = origPts * s.unitLength;

	newPts = c_pts_applyQuaternionTransformation(origPts,s.quaternion);

	symbolSize = 40;
	symbols = 'x*s.';
	colors = 'rgb';
	figure;
	for i=2:2:size(origPts,1);
		% assume pts specified as (start, end) pairs
		symbol = symbols(i/2);
		color = colors(i/2);
		x = origPts(i-1:i,1);
		y = origPts(i-1:i,2);
		z = origPts(i-1:i,3);
		plot3(x,y,z,color);
		hold on;
		scatter3(x(1),y(1),z(1),symbolSize,'k','o');
		scatter3(x(2),y(2),z(2),symbolSize,color,symbol);

		if s.doLabelLengths
			pts = [x, y, z];
			dist = c_norm(pts(1,:)-pts(2,:),2,2);
			midpt = mean(pts,1);
			args = c_mat_sliceToCell(midpt);
			text(args{:},sprintf('%.5g',dist),'color',origColor);
		end

		x = newPts(i-1:i,1);
		y = newPts(i-1:i,2);
		z = newPts(i-1:i,3);
		plot3(x,y,z,color);
		scatter3(x(1),y(1),z(1),symbolSize,'k','.');
		scatter3(x(2),y(2),z(2),symbolSize,color,symbol);

		if s.doLabelLengths
			pts = [x, y, z];
			dist = c_norm(pts(1,:)-pts(2,:),2,2);
			midpt = mean(pts,1);
			args = c_mat_sliceToCell(midpt);
			text(args{:},sprintf('%.5g',dist),'color',newColor);
		end
	end
	xlabel('x');
	ylabel('y');
	zlabel('z');
	axis equal
end