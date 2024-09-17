function c_exportFigure(directory,name,ext,resolution)
	if nargin < 4
		resolution = 600;
	end
	if nargin < 3
		ext = eps;
	end
	
	if isempty(directory)
		path = name;
	else
		path = [directory '/' name];
	end
	
	if strcmp(ext,'eps')
		extArg = '-depsc';
	else
		extArg = ['-d' ext];
	end
	
	print(extArg,path,['-r' num2str(resolution)])
	
end