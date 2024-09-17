function mesh = c_mesh_calculateVertexConnectivity(mesh)
persistent PathModified;
if isempty(PathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/FromBrainstorm/anatomy'));
	PathModified = true;
end

if nargout==0
	warning('Must save output mesh struct to store results');
end
mesh.VertConn = tess_vertconn(mesh.Vertices,mesh.Faces);

end