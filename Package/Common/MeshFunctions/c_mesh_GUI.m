function c_mesh_GUI(varargin)

	%% add dependencies
	persistent pathModified;
	if isempty(pathModified)
		mfilepath=fileparts(which(mfilename));
		addpath(fullfile(mfilepath,'.'));
		addpath(fullfile(mfilepath,'../'));
		addpath(fullfile(mfilepath,'../EEGAnalysisCode'));
		addpath(fullfile(mfilepath,'../ThirdParty/uisplitpane'));
		addpath(fullfile(mfilepath,'../ThirdParty/findjobj'));
		addpath(fullfile(mfilepath,'../ThirdParty/iso2mesh'));
		addpath(fullfile(mfilepath,'../GUI'));
		pathModified = true;
	end
	if 1
		%TODO: debug, delete
		[~,currentFolder,~] = fileparts(pwd);
		if ~strcmp(currentFolder,'MontageGenerator')
			cd(fullfile(mfilepath,'../../MontageGenerator')); 
		end
	end

	%% inputs / settings
	p = inputParser();
	p.addParameter('BaseDirectory','./',@ischar);
	p.addParameter('metamesh',[],@isempty);
	p.addParameter('mesh',[],@(x) ischar(x));
	p.addParameter('ROI',[],@(x) ischar(x));
	p.addParameter('montage',[],@(x) ischar(x));
	p.addParameter('defaultROIColor',[0.2 0.8 0.2],@isnumeric);
	p.addParameter('doLabelElectrodes',false,@islogical);
	p.addParameter('doPlotInterelectrodeDistances',false,@islogical);
	p.addParameter('meshFiducials',[],@(x) ischar(x) || isa(x,'c_DigitizedMontage'));
	p.addParameter('view',[-135,20]);
	p.addParameter('doTest',false,@islogical);
	p.parse(varargin{:});
	s = p.Results;
	
	if s.doTest
		testfn(varargin{:});
		return;
	end

	%% construct model 
	if isempty(s.metamesh)
		s.metamesh = struct(...
			'mesh',[],...
			'dir','',...
			'filename','',...
			'ext','',...
			'name','',...
			'distScale',NaN);
	else
		keyboard %TODO
	end

	%% construct GUI
	global h; %TODO: make persistent
	if ~isempty(h) && ishandle(h)
		close(h);
	end
	h = figure('name','Mesh GUI',...
		'SizeChangedFcn',@(h,e) callback_GUI_setPositions(),...
		'CloseRequestFcn',@(h,e) callback_GUI_CloseFigure());
	guiH.fig = h;

	[guiH.controlsPanel, guiH.mainAndAuxPanel, ~] = uisplitpane(guiH.fig,'Orientation','horizontal','DividerLocation',0.25);
	guiH.tabgrp_controls = uitabgroup(guiH.controlsPanel,'Position',[0 0 1 1],'Units','normalized');
	
	% main plot view
	[guiH.auxPanel, guiH.mainPanel, ~] = uisplitpane(guiH.mainAndAuxPanel,'Orientation','vertical','DividerLocation',0);
	s.auxIsVisible = false;
	guiH.meshAxis = axes('parent',guiH.mainPanel);
	axis(guiH.meshAxis,'off');
	guiH.MeshHandle = [];
	guiH.ROIHandle = [];
	guiH.SelectionHandle = [];
	
	% aux plot view
	guiH.auxAxis = axes('parent',guiH.auxPanel);
		
	setup_MainTab();
	setup_ROITab();
	setup_MontageTab();
	setup_SettingsTab();
	
	%% handle inputs
	if ~isempty(s.mesh)
		if ischar(s.mesh)
			callback_mesh_load(s.mesh);
		else
			keyboard %TODO
		end
	end
	
	if ~isempty(s.meshFiducials)
		if ischar(s.meshFiducials)
			callback_meshFiducials_load(s.meshFiducials);
		else
			keyboard %TODO
		end
	end
	
	if ~isempty(s.montage) 
		if ischar(s.montage)
			callback_montage_load(s.montage);
		else
			keyboard %TODO
		end
	end
	
	c_fig_arrange('maximize',guiH.fig,'monitor',2);
	
	%% callbacks
	
	function callback_GUI_setPositions()
		

	end

	function callback_GUI_CloseFigure()
		closereq();
	end

	

	%% Main tab code
	
	function setup_MainTab()
		guiH.tab_controls_main = uitab(guiH.tabgrp_controls,'Title','Main');
		
		dir = s.BaseDirectory;
		filename = 'mesh';
		ext = 'mat';
		if ~isempty(s.metamesh)
			if ~isempty(s.metamesh.dir),		dir =		s.metamesh.dir;			end;
			if ~isempty(s.metamesh.filename),	filename =	s.metamesh.filename;	end;
			if ~isempty(s.metamesh.ext),		ext =		s.metamesh.ext;			end;
		end
		
		guiH.filefield_inputMesh = c_GUI_FilepathField(...
			'label','Input mesh',...
			'mode','load-only',...
			'dir',dir,...
			'filename',filename,...
			'ext',ext,...
			'validFileTypes','*.stl;*.fsmesh;*.off;*.mat',...
			'loadCallback',@callback_mesh_load,...
			'parent',guiH.tab_controls_main,...
			'Units','normalized',...
			'Position',[0 0.9 1 0.1]...
			);
		
		guiH.filefield_outputMesh = c_GUI_FilepathField(...
			'label','Output mesh',...
			'mode','save-only',...
			'dir',s.BaseDirectory,...
			'filename','mesh',...
			'ext','mat',...
			'validFileTypes','*.stl;*.fsmesh;*.off;*.mat',...
			'saveCallback',@callback_saveMesh,...
			'parent',guiH.tab_controls_main,...
			'Units','normalized',...
			'Position',[0 0.8 1 0.1]...
			);
		
		labelActionPairs = {...
			'Create mesh: sphere',@(h,e) callback_mesh_createSphere()...
			'Hide mesh',@(h,e) callback_mesh_hide(),...
			'Redraw mesh',@(h,e) callback_redrawMesh(),...
		};
	
		numButtons = length(labelActionPairs)/2;
		ylims = [0,0.8];
		guiH.MontageButtons = {};
		for iB = 1:numButtons
			guiH.MontageButtons{iB} = uicontrol(...
				'parent',guiH.tab_controls_main,...
				'style','pushbutton',...
				'String',labelActionPairs{iB*2-1},...
				'Callback',labelActionPairs{iB*2},...
				'Units','normalized',...
				'Position',[0,ylims(2)-diff(ylims)/numButtons*iB,1,diff(ylims)/numButtons]...
				);
		end
	end

	function callback_mesh_load(filepath)
		if ~strcmp(guiH.filefield_inputMesh.path,filepath)
			guiH.filefield_inputMesh.path = filepath;
		end
		if ~exist(filepath,'file')
			warning('File does not exist at %s',filepath);
			return;
		end
		c_say('Loading mesh from %s',filepath);
		mesh = c_mesh_load(filepath);
		if ~c_mesh_isValid(mesh,'exhaustive',true)
			warning('Loaded mesh is invalid, discarding.');
			return;
		end
		mesh.isValidated = true;
		s.metamesh.mesh = mesh;
		[s.metamesh.dir, s.metamesh.filename, s.metamesh.ext] = fileparts(filepath);
		s.metamesh.name = s.metamesh.filename;
		s.metamesh.distScale = calculateMeshDistScale(s.metamesh.mesh);
		c_sayDone();
		callback_redrawMesh();
	end

	function callback_saveMesh(filepath)
		c_say('Saving mesh to %s',filepath);
		c_mesh_save(filepath,s.metamesh.mesh);
		c_sayDone();
	end

	function callback_redrawMesh()
		if ~isempty(guiH.MeshHandle)
			[az, el] = view();
			prevView = [az,el];
			delete(guiH.MeshHandle);
			guiH.MeshHandle = [];
		else
			prevView = s.view;
		end
		if ~isempty(s.metamesh.mesh)
			c_saySingle('Redrawing mesh');
			guiH.MeshHandle = c_mesh_plot(s.metamesh.mesh,...
				'axis',guiH.meshAxis);
		end
		callback_redrawROI();
		callback_redrawSelection();
		view(guiH.meshAxis,prevView);
	end

	function callback_mesh_hide()
		if ~isempty(guiH.MeshHandle)
			[az, el] = view();
			prevView = [az,el];
			delete(guiH.MeshHandle);
			guiH.MeshHandle = [];
		end
	end

	function callback_mesh_createSphere()
		
		
		ip = c_InputParser();
		ip.addParameter('Center',[0 0 0],@(x) isvector(x) && length(x)==3);
		ip.addParameter('Radius',95,@isscalar);
		ip.addParameter('MaxTriSize',1,@isscalar);
		ip.addParameter('distScale',1e-3,@isscalar);
		ip.parseFromDialog('title','Mesh a sphere');
		
		[node,face] = meshasphere(ip.Results.Center, ip.Results.Radius, ip.Results.MaxTriSize);
		
		mesh = struct(...
			'Vertices',node,...
			'Faces',face);
		
		s.metamesh = struct(...
			'mesh',mesh,...
			'distScale',ip.Results.distScale,...
			'dir','',...
			'filename','',...
			'ext','',...
			'name','Sphere');
		
		callback_ROI_clear();
		callback_redrawMesh();
		
	end

	%% ROI tab code
	function setup_ROITab()
		guiH.tab_controls_ROIs = uitab(guiH.tabgrp_controls,'Title','ROIs');
		
		if isempty(s.ROI)
			s.ROI = struct(...
				'Vertices',{},...
				'Label',{},...
				'Color',{},...
				'Seed',{});
		end

		% selection is essentially an intermediate ROI
		s.selectionColor = [0.2 0.2 0.7];
		s.selection = struct(...
			'Vertices',[],...
			'Label','selection',...
			'Color',s.selectionColor,...
			'Seed',[]);
		
		guiH.filefield_ROI = c_GUI_FilepathField(...
			'label','ROI file',...
			'mode','load-save',...
			'dir',s.BaseDirectory,...
			'filename','ROI',...
			'ext','mat',...
			'validFileTypes','*.mat',...
			'loadCallback',@callback_ROI_load,...
			'saveCallback',@callback_ROI_save,...
			'parent',guiH.tab_controls_ROIs,...
			'Units','normalized',...
			'Position',[0 0.8 1 0.2]...
			);
		
		labelActionPairs = {...
			'Add point to selection',@(h,e) callback_selection_addPoint,...
			'Remove point from selection',@(h,e) callback_selection_removePoint,...
			'Grow selection',@(h,e) callback_selection_grow,...
			'Shrink selection',@(h,e) callback_selection_shrink,...
			'Select all',@(h,e) callback_selection_selectAll,...
			'Clear selection',@(h,e) callback_selection_clear,...
			'Add selection to ROI',@(h,e) callback_ROI_addSelection,...
			'Remove selection from ROI',@(h,e) callback_ROI_removeSelection,...
			'Clear ROI',@(h,e) callback_ROI_clear,...
			'Redraw ROI',@(h,e) callback_redrawROI,...
			'Redraw selection',@(h,e) callback_redrawSelection,...
			'Hide ROI',@(h,e) callback_ROI_hide,...
			'Hide selection',@(h,e) callback_selection_hide,...
		};
	
		numButtons = length(labelActionPairs)/2;
		ylims = [0,0.8];
		guiH.ROIButtons = {};
		for iB = 1:numButtons
			guiH.ROIButtons{iB} = uicontrol(...
				'parent',guiH.tab_controls_ROIs,...
				'style','pushbutton',...
				'String',labelActionPairs{iB*2-1},...
				'Callback',labelActionPairs{iB*2},...
				'Units','normalized',...
				'Position',[0,ylims(2)-diff(ylims)/numButtons*iB,1,diff(ylims)/numButtons]...
				);
		end
	end

	function callback_redrawROI()
		if ~isempty(guiH.ROIHandle)
			delete(guiH.ROIHandle);
			guiH.ROIHandle = [];
		end
		if ~isempty(s.ROI) && ~ischar(s.ROI) && ~isempty(s.metamesh.mesh)
			c_saySingle('Redrawing ROI');
			guiH.ROIHandle = c_meshROI_plot(s.ROI, s.metamesh.mesh,...
				'axis',guiH.meshAxis,...
				'doPlotMesh',false);
		end
	end

	function callback_redrawSelection()
		if ~isempty(guiH.SelectionHandle)
			delete(guiH.SelectionHandle);
			guiH.SelectionHandle = [];
		end
		if ~isempty(s.selection.Vertices) && ~isempty(s.metamesh.mesh)
			c_saySingle('Redrawing selection');
			guiH.SelectionHandle = c_meshROI_plot(s.selection, s.metamesh.mesh,...
				'axis',guiH.meshAxis,...
				'doPlotMesh',false);
		end
	end

	function callback_selection_hide()
		if ~isempty(guiH.SelectionHandle)
			delete(guiH.SelectionHandle);
			guiH.SelectionHandle = [];
		end
	end

	function callback_ROI_hide()
		if ~isempty(guiH.ROIHandle)
			delete(guiH.ROIHandle);
			guiH.ROIHandle = [];
		end
	end


	function index = getMeshVertexIndexFromDataCursor()
		dcm_obj = datacursormode(guiH.fig);
		info_struct = getCursorInfo(dcm_obj);
		dcm_obj.Enable = 'off';
		if isempty(info_struct)
			warning('No point selected');
			index = [];
			return;
		end
		coord = info_struct.Position;
		
		% find closest coord in mesh
		[dist,index] = min(c_norm(bsxfun(@minus,s.metamesh.mesh.Vertices, coord),2,2));
		if dist > eps*1e2
			warning('Selection point is %.4g from closest mesh point',dist);
		end
	end

	function callback_selection_addPoint()
		index = getMeshVertexIndexFromDataCursor();
		if isempty(index)
			return;
		end
		
		s.selection.Vertices = cat(2,s.selection.Vertices,index);
		if isempty(s.selection.Seed)
			s.selection.Seed = s.metamesh.mesh.Vertices(index,:);
		end
		
		callback_redrawSelection();
	end

	function callback_selection_removePoint()
		index = getMeshVertexIndexFromDataCursor();
		if isempty(index)
			return;
		end
		
		indicesToRemove = find(s.selection.Vertices==index);
		if isempty(indicesToRemove)
			warning('Point was already not a part of selection');
			return;
		end
		
		s.selection.Vertices(indicesToRemove) = [];
		
		callback_redrawSelection();
	end

	function callback_selection_grow()
		if isempty(s.selection.Vertices)
			warning('Must have non-empty selection from which to grow');
			return;
		end
		s.selection = c_meshROI_grow(s.metamesh.mesh, s.selection);
		
		callback_redrawSelection();
	end

	function callback_selection_shrink()
		if isempty(s.selection.Vertices)
			warning('Selection is already empty, cannot shrink further.');
			return;
		end
		s.selection = c_meshROI_shrink(s.metamesh.mesh, s.selection);
		
		callback_redrawSelection();
	end

	function callback_selection_selectAll()
		s.selection.Vertices = 1:size(s.metamesh.mesh.Vertices,1);
		if isempty(s.selection.Seed)
			s.selection.Seed = s.metamesh.mesh.Vertices(1,:);
		end
		
		callback_redrawSelection();
	end

	function callback_ROI_addSelection()
		if isempty(s.ROI)
			s.ROI = s.selection;
			s.ROI.Color = s.defaultROIColor;
		else
			s.ROI = c_meshROI_union(s.ROI, s.selection);
		end
		callback_redrawROI();
		callback_selection_hide();
	end

	function callback_ROI_removeSelection()
		if isempty(s.ROI)
			warning('ROI already empty.');
			return;
		end
		if isempty(s.selection.Vertices)
			warning('Selection empty, nothing to remove.');
			return;
		end
		s.ROI = c_meshROI_setdiff(s.ROI,s.selection);
		callback_redrawROI();
		callback_selection_hide();
	end

	function callback_selection_clear()
		s.selection = struct(...
			'Vertices',[],...
			'Label','selection',...
			'Color',s.selectionColor,...
			'Seed',[]);
		callback_redrawSelection();
	end

	function callback_ROI_clear()
		s.ROI = struct(...
			'Vertices',{},...
			'Label',{},...
			'Color',{},...
			'Seed',{});
		
		callback_redrawROI();
	end

	function callback_ROI_save(filepath)
		c_say('Saving ROI to %s',filepath);
		c_meshROI_save(filepath,s.ROI);
		c_sayDone();
	end

	function callback_ROI_load(filepath)
		if ~strcmp(guiH.filefield_ROI.path,filepath)
			guiH.filefield_ROI.path = filepath;
		end
		if ~exist(filepath,'file')
			warning('File does not exist at %s',filepath);
			return;
		end
		c_say('Loading ROI from %s',filepath);
		newROI = c_meshROI_load(filepath);
		if ~c_meshROI_isValid(newROI,'exhaustive',true)
			warning('Loaded ROI is invalid, discarding.');
			return;
		end
		newROI.isValidated = true;
		s.ROI = newROI;
		c_sayDone();
		
		callback_redrawROI();
	end
	
	%% Montage tab code
	function setup_MontageTab()
		guiH.tab_controls_montage = uitab(guiH.tabgrp_controls,'Title','Montage');
		
		guiH.filefield_Montage = c_GUI_FilepathField(...
			'label','Montage file',...
			'mode','load-save',...
			'dir',s.BaseDirectory,...
			'filename','Montage',...
			'ext','pos',...
			'validFileTypes','*.pos;*.elp;*.3dd;*.mat',...
			'loadCallback',@callback_montage_load,...
			'saveCallback',@callback_montage_save,...
			'parent',guiH.tab_controls_montage,...
			'Units','normalized',...
			'Position',[0 0.9 1 0.1]...
			);
		
		guiH.filefield_MeshFiducials = c_GUI_FilepathField(...
			'label','Mesh Fiducials',...
			'mode','load-save',...
			'dir',s.BaseDirectory,...
			'filename','MeshFiducials',...
			'ext','pos',...
			'validFileTypes','*.pos;*.elp;*.3dd;*.mat',...
			'loadCallback',@callback_meshFiducials_load,...
			'saveCallback',@callback_meshFiducials_save,...
			'parent',guiH.tab_controls_montage,...
			'Units','normalized',...
			'Position',[0 0.8 1 0.1]...
			);
		
		guiH.MontageHandle = [];
		guiH.MeshFiducialsHandle = [];
		
		labelActionPairs = {...
			'Mesh: Set LPA',@(h,e) callback_meshFiducials_set('LPA'),...
			'Mesh: Set RPA',@(h,e) callback_meshFiducials_set('RPA'),...
			'Mesh: Set NAS',@(h,e) callback_meshFiducials_set('NAS'),...
			'Align montage with fiducials',@(h,e) callback_montageAlignWithFiducials(),...
			'Interactively transform montage',@(h,e) callback_montage_interactivelyTransform(),...
			'Move electrodes to closest mesh points',@(h,e) callback_montage_moveElectrodesToMesh(),...
			'Add electrode',@(h,e) callback_montage_addElectrode(),...
			'Remove electrode',@(h,e) callback_montage_removeElectrode(),...
			'Clear montage',@(h,e) callback_montage_clear(),...
			'Do label electrodes',@(h,e) callback_montage_doLabelElectrodes(true),...
			'Do not label electrodes',@(h,e) callback_montage_doLabelElectrodes(false),...
			'Do plot interelectrode distances',@(h,e) callback_montageDoPlotInterelectrodeDistances(true),...
			'Do not plot interelectrode distances',@(h,e) callback_montageDoPlotInterelectrodeDistances(false),...
			'Redraw montage',@(h,e) callback_redrawMontage(),...
			'Redraw fiducials',@(h,e) callback_redrawMeshFiducials(),...
		};
	
		numButtons = length(labelActionPairs)/2;
		ylims = [0,0.8];
		guiH.MontageButtons = {};
		for iB = 1:numButtons
			guiH.MontageButtons{iB} = uicontrol(...
				'parent',guiH.tab_controls_montage,...
				'style','pushbutton',...
				'String',labelActionPairs{iB*2-1},...
				'Callback',labelActionPairs{iB*2},...
				'Units','normalized',...
				'Position',[0,ylims(2)-diff(ylims)/numButtons*iB,1,diff(ylims)/numButtons]...
				);
		end
	end

	function callback_montage_load(filepath)
		if ~strcmp(guiH.filefield_Montage.path,filepath)
			guiH.filefield_Montage.path = filepath;
		end
		c_say('Loading montage from %s',filepath);
		%[~,s.montage] = c_montage_loadData(filepath);
		s.montage = c_DigitizedMontage('initFromFile',filepath);
		c_sayDone();
		
		callback_redrawMontage();
	end

	function callback_montage_save(filepath)
		c_say('Saving montage to %s',filepath);
		s.montage.saveToFile(filepath);
		c_sayDone();
	end

	function callback_montage_clear(filepath)
		s.montage = [];
		
		callback_redrawMontage();
	end

	function callback_redrawMontage()
		if ~isempty(guiH.MontageHandle)
			delete(guiH.MontageHandle);
			guiH.MontageHandle = [];
		end
		c_say('Redrawing montage');
		if s.doPlotInterelectrodeDistances
			interElectrodePlotDist = 0.06/s.metamesh.distScale;
		else
			interElectrodePlotDist = 0;
		end
		
		if ~isempty(s.montage)
			guiH.MontageHandle = s.montage.plot(...
				'axis',guiH.meshAxis,....
				'distUnit',s.metamesh.distScale,...
				'doLabelElectrodes',s.doLabelElectrodes,...
				'doPlotInterelectrodeDistancesLessThan',interElectrodePlotDist,...
				'view',[]);
		end
		c_sayDone();
	end

	function callback_montage_addElectrode()
		% add electrode at selected point
		index = getMeshVertexIndexFromDataCursor();
		
		if isempty(index)
			warning('No point selected');
			return;
		end
		
		coord = s.metamesh.mesh.Vertices(index,:);
		
		if isempty(s.montage)
			s.montage = c_DigitizedMontage();
		end
		
		s.montage.addElectrodes('fromXYZ',coord,'distUnit',s.metamesh.distScale);
		
		callback_redrawMontage();
	end

	function callback_montage_removeElectrode()
		% remove closest electrode to selected point on mesh
		index = getMeshVertexIndexFromDataCursor();
		
		if isempty(index)
			warning('No point selected');
			return;
		end
		
		coord = s.metamesh.mesh.Vertices(index,:);
		
		s.montage.deleteElectrodes('byXYZ',coord,'distUnit',s.metamesh.distUnit)
		
		callback_redrawMontage();
	end

	function callback_montage_doLabelElectrodes(doLabel)
		s.doLabelElectrodes = doLabel;
		callback_redrawMontage();
	end

	function callback_montageDoPlotInterelectrodeDistances(doPlot)
		s.doPlotInterelectrodeDistances = doPlot;
		callback_redrawMontage();
	end

	function callback_montageAlignWithFiducials()
		if isempty(s.montage)
			warning('Missing montage to align');
			return;
		end
		if isempty(s.meshFiducials)
			warning('Missing fiducials for alignment');
			return;
		end
		
		s.montage.alignTo(s.meshFiducials);
		
		callback_redrawMontage();
	end

	function callback_montage_interactivelyTransform()
		transform = c_GUI_interactiveTransform(...
			'translationScale',1/s.metamesh.distScale/10,...
			'callback_transformChanged',@callback_montage_temporarilyTransform);
		if c_dialog_verify('Accept transform?')
			s.montage.transform(transform);
		end
		callback_redrawMontage();
	end

	function callback_montage_temporarilyTransform(transform)
		orig = s.montage.copy();
		s.montage.transform(transform);
		callback_redrawMontage();
		s.montage = orig;
	end
		
	function callback_montage_moveElectrodesToMesh()
		assert(c_isFieldAndNonEmpty(s.metamesh,'mesh'));
		
		s.montage.moveElectrodesToMesh(s.metamesh.mesh,'distUnit',s.metamesh.distScale);
		
		callback_redrawMontage();
	end


	function callback_meshFiducials_load(filepath)
		if ~strcmp(guiH.filefield_MeshFiducials.path,filepath)
			guiH.filefield_MeshFiducials.path = filepath;
		end
		
		s.meshFiducials = c_DigitizedMontage('initFromFile',filepath);
		
		keyboard
		
		callback_redrawMeshFiducials();
	end

	function callback_meshFiducials_save(filepath)
		if isempty(s.meshFiducials)
			warning('No mesh fiducials set, not saving.');
			return
		end
		s.meshFiducials.saveToFile(filepath);
	end

	function callback_redrawMeshFiducials()
		if ~isempty(guiH.MeshFiducialsHandle)
			delete(guiH.MeshFiducialsHandle);
			guiH.MeshFiducialsHandle = [];
		end
		if ~isempty(s.meshFiducials)
			c_saySingle('Redrawing mesh fiducials');
			
			guiH.MeshFiducialsHandle = s.meshFiducials.plot(...
				'axis',guiH.meshAxis,....
				'colorFiducials',[0 0.8 0],...
				'distUnit',s.metamesh.distScale,...
				'view',[]);
		end
	end
	
	function callback_meshFiducials_set(fiducialStr)
		index = getMeshVertexIndexFromDataCursor();
		if isempty(index)
			warning('No point selected');
			return
		end
		
		if isempty(s.meshFiducials)
			s.meshFiducials = c_DigitizedMontage();
		end
		
		s.meshFiducials.setFiducial(fiducialStr,...
			'xyz',s.metamesh.mesh.Vertices(index,:),...
			'distUnit',s.metamesh.distScale);
		
		callback_redrawMeshFiducials();
	end
	

	

	%% Settings tab code
	function setup_SettingsTab()
		guiH.tab_controls_settings = uitab(guiH.tabgrp_controls,'Title','Settings');
		
		guiH.keyboardButton = uicontrol(...
			'style','pushbutton',...
			'String','keyboard',...
			'parent',guiH.tab_controls_settings,...
			'Callback',@(h,e) callback_keyboard,...
			'Units','normalized',...
			'Position',[0 0.9 1 0.1]);
		
		labelActionPairs = {...
			'Axis on',@(h,e) callback_axis('on'),...
			'Axis off',@(h,e) callback_axis('off'),...
		};
	
		numButtons = length(labelActionPairs)/2;
		ylims = [0,0.8];
		guiH.MontageButtons = {};
		for iB = 1:numButtons
			guiH.MontageButtons{iB} = uicontrol(...
				'parent',guiH.tab_controls_settings,...
				'style','pushbutton',...
				'String',labelActionPairs{iB*2-1},...
				'Callback',labelActionPairs{iB*2},...
				'Units','normalized',...
				'Position',[0,ylims(2)-diff(ylims)/numButtons*iB,1,diff(ylims)/numButtons]...
				);
		end
	end

	function callback_keyboard()
		keyboard
	end

	function callback_axis(state)
		axis(guiH.meshAxis,state);
	end


end

function distScale = calculateMeshDistScale(mesh)
	distScale = c_norm(diff(extrema(mesh.Vertices,[],1),1,2),2);
	% estimate whether in mm, cm, or m
	
	typicalHeadSize = 0.2; % m
	
	if distScale < 0.5 * typicalHeadSize
		error('Unexpected scale');
	elseif distScale < 5*typicalHeadSize 
		distScale = 1; % m
	elseif distScale < 500*typicalHeadSize
		distScale = 0.01; % cm
	elseif distScale < 5000*typicalHeadSize
		distScale = 0.001; % mm
	else
		error('Unexpected scale');
	end
end

%%
function testfn(varargin)

	c_sayResetLevel();
	
	meshPath = '';
	roiPath = '';
	fiducialsPath = '';
	montagePath = '';
	
	meshPath = './colin27_t1_tal_hires_ExtractedSkin_Resampled.mat';
	roiPath = './colin27_t1_tal_hires_ExtractedSkin_Resampled_ROI_HeadV3.mat';
	fiducialsPath = './fiducials.mat';
	montagePath = './TransformedMontage_Fitted.pos';
	
	c_mesh_GUI(...
		varargin{:},...
		'mesh',meshPath,...
		'ROI',roiPath,...
		'meshFiducials',fiducialsPath,...
		'montage',montagePath,...
		'doTest',false);
	
end
	