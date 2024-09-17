function ROIs = c_meshROI_cluster(varargin)
p = inputParser;
p.addRequired('mesh',@c_mesh_isValid);
p.addRequired('ROI',@c_meshROI_isValid);
p.addParameter('numClusters',[],@isscalar);
p.parse(varargin{:});
s = p.Results;
mesh = s.mesh;

persistent PathModified;
if isempty(PathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../ThirdParty/FromBrainstorm/anatomy'));
	PathModified = true;
end

if ~c_isFieldAndNonEmpty(mesh,'VertConn')
	mesh = c_mesh_calculateVertexConnectivity(mesh);
end

assert(length(s.ROI)==1); %TODO: add support for multiple input ROIs

ROIConn = mesh.VertConn(s.ROI.Vertices,s.ROI.Vertices);

labels = tess_cluster(ROIConn, s.numClusters);

uniqueLabels = unique(labels);

assert(length(uniqueLabels)==s.numClusters); 
% if this is violated, could add smallest cluster merging code similar
% to that done in Brainstorm's panel_scout()

ROIs = s.ROI;
for iL = 1:length(uniqueLabels)
	ROIs(iL) = s.ROI;
	ROIs(iL).Vertices = s.ROI.Vertices(labels == uniqueLabels(iL));
	ROIs(iL).Label = [s.ROI.Label '.' num2str(iL)];
	%ROIs(iL).Color = s.ROI.Color * (1-iL/length(uniqueLabels)/2);
	ROIs(iL).Color = max(min(s.ROI.Color + (0.5-rand(1,3))/2,1),0);
end

end