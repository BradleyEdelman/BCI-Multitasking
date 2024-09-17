function handle = c_mesh_plot(mesh,varargin)
	if nargin==0, testfn(); return; end;

	assert(isstruct(mesh));
	
	defaultArgs = {...
	'edgeColor','none',...
	'faceAlpha',1,...
	'view',[],...
	'renderingMode',1};
	
	handle = c_plotSurface(mesh.Vertices, mesh.Faces,defaultArgs{:},varargin{:});
	
end

function testfn()

	filetypes = '*.stl;*.fsmesh;*.off';
	[fn,fp] = uigetfile(filetypes,'Choose mesh file to plot');
	if fn == 0
		error('no file chosen');
	end
	filepath = fullfile(fp,fn);
	
	mesh = c_mesh_load(filepath);
	
	figure('name',fn);
	c_mesh_plot(mesh);
end