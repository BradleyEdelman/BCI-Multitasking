function c_mesh_plotVertexNormals(mesh,doInvert)
	
	if nargin < 2
		doInvert = false;
	end
	
	m = 1;
	if doInvert
		m = -1;
	end

	assert(isstruct(mesh));

	quiver3(mesh.Vertices(:,1),mesh.Vertices(:,2),mesh.Vertices(:,3),...
			m*mesh.VertNormals(:,1),m*mesh.VertNormals(:,2),m*mesh.VertNormals(:,3),...
			'Marker','.');
		
	
		
end