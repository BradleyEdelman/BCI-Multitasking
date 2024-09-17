function c_plot_cortexConnectivityFromEConnectome(varargin)
if nargin==0, testfn(); return; end;

p = inputParser();
p.addRequired('DTF',@(x) ischar(x) || isstruct(x));
p.addRequired('mesh_cortex',@(x) ischar(x) || isstruct(x));
p.parse(varargin{:});
s = p.Results;

if ischar(s.DTF)
	assert(exist(s.DTF,'file')>0);
	tmp = load(s.DTF);
	DTF = tmp.DTF;
else
	DTF = s.DTF;
end

ROIs.labels = DTF.labels;
ROIs.centers = DTF.locations;
ROIs.nodeIndices = DTF.vertices;

connectivityMatrix = DTF.matrix;

c_plot_cortexConnectivity(...
	'connectivityMatrix',connectivityMatrix,...
	'mesh_cortex',s.mesh_cortex,...
	'meshScalar',1e-3,...
	'ROIs',ROIs);
end

function testfn()

	mfilepath=fileparts(which(mfilename));

	cortexPath = fullfile(mfilepath,'../ThirdParty/FromEConnectome/resources/colincortex.mat');
	connectivityPath = fullfile(mfilepath,'../ThirdParty/FromEConnectome/resources/example-connectivityresults.mat');

	c_plot_cortexConnectivityFromEConnectome(connectivityPath,cortexPath);

end