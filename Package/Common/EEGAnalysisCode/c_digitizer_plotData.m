function handles = c_digitizer_plotData(varargin)
p = inputParser();
p.addRequired('data',@isstruct); % chanlocs or raw digitizer struct
p.addParameter('doPlotFiducials',true,@islogical); % if available
p.addParameter('doPlotElectrodes',true,@islogical);
p.addParameter('doPlotHeadshape',true,@islogical); % if available
p.addParameter('axis',[],@ishandle);
p.addParameter('view',[3],@(x) isempty(x) || isvector(x));
p.addParameter('colorFiducials',[0 0.5 0],@isnumeric);
p.addParameter('colorElectrodes',[0 0 0.7],@isnumeric);
p.addParameter('colorShapePts',[1 1 1]*0.8,@isnumeric);
p.addParameter('markerSize',0.005,@isscalar);
p.addParameter('sizeScalar',1e2,@isscalar);
p.addParameter('transformation',[],@ismatrix);
p.parse(varargin{:});
s = p.Results;

if isempty(s.axis)
	s.axis = gca;
end

axis(s.axis,'equal');
if ~isempty(s.view)
	view(s.view);
end

if isfield(s.data,'electrodes') || isfield(s.data,'shape')
	% assume the input is in raw format
elseif isfield(s.data,'labels') && isfield(s.data,'X') 
	% assume the input is in chanlocs format
	s.data = convertChanlocsToRaw(s.data);
else
	error('Unrecognized input format (or missing required fields)');
end

if ~isempty(s.transformation)
	s.data = c_digitizer_applyTransform(s.data,s.transformation);
end

sizeScalar = s.sizeScalar;
scatterArgs = {'ptSizes',s.markerSize*sizeScalar};

handles = [];

%% plot fiducials
if s.doPlotFiducials
	if c_isFieldAndNonEmpty(s.data,'electrodes.fiducials')
		pts = c_struct_mapToArray(s.data.electrodes.fiducials,{'X','Y','Z'});
		ptLabels = {s.data.electrodes.fiducials.label};
		h = c_plot_scatter3(pts*sizeScalar,...
			'ptColors',s.colorFiducials,...
			'ptLabels',ptLabels,...
			scatterArgs{:});
		handles = cat(2,handles,h);
	end
	
	if c_isFieldAndNonEmpty(s.data,'shape.fiducials')
		pts = c_struct_mapToArray(s.data.shape.fiducials,{'X','Y','Z'});
		ptLabels = {s.data.shape.fiducials.label};
		h = c_plot_scatter3(pts*sizeScalar,...
			'ptColors',s.colorFiducials,...
			'ptLabels',ptLabels,...
			scatterArgs{:});
		handles = cat(2,handles,h);
	end
end

%% plot electrodes
if s.doPlotElectrodes
	if c_isFieldAndNonEmpty(s.data,'electrodes.electrodes')
		pts = c_struct_mapToArray(s.data.electrodes.electrodes,{'X','Y','Z'});
		ptLabels = {s.data.electrodes.electrodes.label};
		h = c_plot_scatter3(pts*sizeScalar,...
			'ptColors',s.colorElectrodes,...
			'ptLabels',ptLabels,...
			scatterArgs{:});
		handles = cat(2,handles,h);
	end
end

%% plot head points
if s.doPlotHeadshape
	if c_isFieldAndNonEmpty(s.data,'shape.points')
		pts = c_struct_mapToArray(s.data.shape.points,{'X','Y','Z'});
		h = c_plot_scatter3(pts*sizeScalar,...
			'ptColors',s.colorShapePts,...
			scatterArgs{:});
		handles = cat(2,handles,h);
	end
end


end

function raw = convertChanlocsToRaw(chanlocs)
raw = struct();
raw.electrodes = struct();
raw.electrodes.electrodes = struct(...
	'label',{},...
	'X',{},....
	'Y',{},....
	'Z',{});

for iE = 1:length(chanlocs)
	newE = struct(...
		'label',chanlocs(iE).labels,...
		'X',chanlocs(iE).X,...
		'Y',chanlocs(iE).Y,...
		'Z',chanlocs(iE).Z);
	raw.electrodes.electrodes(iE) = newE;
end
end