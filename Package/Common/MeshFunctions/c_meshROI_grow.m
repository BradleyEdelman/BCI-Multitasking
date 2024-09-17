function ROI = c_meshROI_grow(mesh, ROI)

assert(c_mesh_isValid(mesh));

assert(c_meshROI_isValid(ROI));

if isempty(ROI.Vertices)
	warning('ROI must be non-empty to grow');
	% return unmodified ROI
	return;
end

if ~c_isFieldAndNonEmpty(mesh,'VertConn')
	% successive grows will be more efficient if this is calculated externally
	mesh = c_mesh_calculateVertexConnectivity(mesh);
end

ROI.Vertices = cat(2,ROI.Vertices,findConnectedIndices(ROI.Vertices, mesh.VertConn));

end

function indices = findConnectedIndices(iverts, vconn)
% adapted from Brainstorm

indices = find(any(vconn(iverts,:), 1));

end
