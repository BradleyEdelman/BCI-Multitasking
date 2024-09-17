function c_plot_cortexConnectivityFromBrainstorm(varargin)

persistent PathModified;
if isempty(PathModified)
	mfilepath=fileparts(which(mfilename));
	addpath(fullfile(mfilepath,'../EEGAnalysisCode'));
	PathModified = true;
end

if nargin==0, testfn(); return; end;

p = inputParser();
p.addRequired('conn',@(x) ischar(x) || isstruct(x));
p.addRequired('mesh_cortex',@(x) ischar(x) || isstruct(x));
p.parse(varargin{:});
s = p.Results;

if ischar(s.conn)
	assert(exist(s.conn,'file')>0);
	conn = load(s.conn);
else
	conn = s.conn;
end

% use BST function to convert raw connectivity matrix to more useful format
c_initializeBrainstorm();
% from http://neuroimage.usc.edu/forums/showthread.php?1681-PLV-NxN-Read-matrix
connectivityMatrix = bst_memory('GetConnectMatrix',conn).'; % note transpose to flip in/out directions

% extract relevant information for ROIs
numROIs = length(conn.Atlas.Scouts);
ROIs.labels = {conn.Atlas.Scouts.Label};
ROIs.centerIndices = cell2mat({conn.Atlas.Scouts.Seed});
for r=1:numROIs
	ROIs.nodeIndices{r} = conn.Atlas.Scouts(r).Vertices;
	ROIs.colors(r,:) = conn.Atlas.Scouts(r).Color;
end

c_plot_cortexConnectivity(...
	'connectivityMatrix',connectivityMatrix,...
	'mesh_cortex',s.mesh_cortex,...
	'ROIs',ROIs);
end

function testfn()
	mfilepath=fileparts(which(mfilename));

	cortexPath = fullfile(mfilepath,'../Resources/example_brainstorm_meshCortex.mat');
	connectivityPath =  fullfile(mfilepath,'../Resources/example_brainstorm_grangerConnectivity.mat');
% 	connectivityPath =  fullfile(mfilepath,'../Resources/example_brainstorm_grangerConnectivity2.mat');

	c_plot_cortexConnectivityFromBrainstorm(connectivityPath,cortexPath);

end