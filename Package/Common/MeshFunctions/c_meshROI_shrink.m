function ROI = c_meshROI_shrink(mesh, ROI)

assert(c_mesh_isValid(mesh));

assert(c_meshROI_isValid(ROI));

if isempty(ROI.Vertices)
	% return unmodified ROI
	return;
end

if ~c_isFieldAndNonEmpty(mesh,'VertConn')
	% successive grows will be more efficient if this is calculated externally
	mesh = c_mesh_calculateVertexConnectivity(mesh);
end

verticesToRemove = findSelectionEdgeIndices(ROI.Vertices, mesh.VertConn);

ROI.Vertices(ismember(ROI.Vertices, verticesToRemove)) = [];

end

function indices = findSelectionEdgeIndices(iverts, vconn)

% find all indices connected to selection
indices = find(any(vconn(iverts,:),1));

% find unselected indices connected to selection
indices = setdiff(indices, iverts);

% find selected indices connected to unselected indices ('edge' indices)
indices = find(any(vconn(indices,:),1));

end
