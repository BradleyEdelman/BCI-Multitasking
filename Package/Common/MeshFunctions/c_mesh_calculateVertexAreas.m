function mesh = c_mesh_calculateVertexAreas(mesh)
% approximate surface node areas by finding areas of member faces

	assert(c_mesh_isValid(mesh));
	
	if ~c_isFieldAndNonEmpty(mesh,'FaceAreas')
		mesh = c_mesh_calculateFaceAreas(mesh);
	end
	
	nodesPerElem = 3; % triangles
	areas = zeros(size(mesh.Vertices,1),1);
	for i=1:nodesPerElem
		nodeIndices = mesh.Faces(:,i);
		% approximate area assuming all faces connected to node are the same size
		areas(nodeIndices) = areas(nodeIndices) + mesh.FaceAreas(:)/nodesPerElem;
	end

	mesh.VertexAreas = areas;
end