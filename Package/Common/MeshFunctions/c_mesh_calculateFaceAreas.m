function mesh = c_mesh_calculateFaceAreas(mesh)

	assert(c_mesh_isValid(mesh));
	
	nodesPerElem = 3; % triangles
	
	% pull out coordinates of each element
	numElems = size(mesh.Faces,1);
	elemAreas = NaN(numElems,1);
	elemNodes = NaN(numElems,3,nodesPerElem);
	for i=1:nodesPerElem
		elemNodes(:,:,i) = mesh.Vertices(mesh.Faces(:,i),:);
	end
		
	% calculate areas of each element
	mesh.FaceAreas = 0.5*c_norm(cross(elemNodes(:,:,3)-elemNodes(:,:,1),elemNodes(:,:,3)-elemNodes(:,:,2)),2,2);
end