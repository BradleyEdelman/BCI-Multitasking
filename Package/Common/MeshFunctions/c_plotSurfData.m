function h = c_plotSurfData(varargin)
	p = inputParser();
	p.addRequired('nodes');
	p.addRequired('elems');
	p.addRequired('data');
	p.addParameter('doSlowRendering',false,@islogical);
	p.addParameter('doInterpolate',true,@islogical);
	p.addParameter('trisurfArgs',{},@iscell);
	p.addParameter('edgeColor','none',@(x) ischar(x) || isnumeric(x));
	p.addParameter('tetrameshArgs',{},@iscell);
	p.addParameter('defaultView',{-72,40});
	p.addParameter('doTransparencyFromData',false,@islogical);
	p.parse(varargin{:});
	
	nodes = p.Results.nodes;
	elems = p.Results.elems;
	data = p.Results.data;
	
	if size(elems,2)~=3 && size(elems,2)~=4
		error('Elems should m x 3, each row corresponding to a triangle, or m x 4, with each row corresponding to a tetrahedron.');
	end
	
	if p.Results.doInterpolate
		faceColorStr = 'interp';
	else
		faceColorStr = 'flat';
	end
	
	extraArgs = {};
	if p.Results.doTransparencyFromData
		limits = prctile(data,[33 99.9]);
		alphaData = max(data - limits(1),0);
		alphaData = min(alphaData,diff(limits));
		alphaData = alphaData/diff(limits);
		extraArgs = [extraArgs,'FaceAlpha','interp','FaceVertexAlphaData',alphaData];
	end
	
	
	if size(elems,2)==3
		assert(size(nodes,1)==length(data)); % one data point per node
		h = trisurf(elems,nodes(:,1),nodes(:,2),nodes(:,3),data,...
			'FaceColor',faceColorStr,...
			'EdgeColor',p.Results.edgeColor,...
			extraArgs{:},...
			p.Results.trisurfArgs{:});
	else
		assert(size(elems,1)==length(data)); % one data point per tetrahedron
		h = tetramesh(elems, nodes, data,...
			'FaceColor',faceColorStr,...
			'EdgeColor',p.Results.edgeColor,...
			extraArgs{:},...
			p.Results.tetrameshArgs{:});
	end
	
	axis equal
	
 	material dull
	if p.Results.doSlowRendering 
		% change options to provide more depth to rendering, but much slower for zooming/rotating plot
		lightColor = [0.5 0.5 0.5];
		lighting gouraud
		light('Position',[-1 -1 1]*2,'Style','local','Color',lightColor);
		light('Position',[-1 1 1]*2,'Style','local','Color',lightColor);
		light('Position',[1 -1 1]*2,'Style','local','Color',lightColor);
	end
	
	view(p.Results.defaultView{:});
end