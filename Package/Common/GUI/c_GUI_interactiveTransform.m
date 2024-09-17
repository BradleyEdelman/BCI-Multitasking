function transform = c_GUI_interactiveTransform(varargin)
	if nargin == 0, testfn; return; end;
	
	p = inputParser();
	p.addParameter('doAllowTranslation',true,@islogical);
	p.addParameter('translationScale',1,@isscalar);
	p.addParameter('doAllowRotation',true,@islogical);
	p.addParameter('doAllowScaling',true,@islogical);
	p.addParameter('doShowTransform',true,@islogical);
	p.addParameter('initialTransform',[],@ismatrix);
	p.addParameter('callback_transformChanged',[],@(x) isa(x,'function_handle'));
	p.addParameter('container',[],@ishandle);
	p.parse(varargin{:});
	s = p.Results;
	
	if nargout > 0
		s.doBlock = true;
	else
		s.doBlock = false;
	end
	
	if isempty(s.initialTransform)
		s.initialTransform = eye(4);
	end
	
	s.currentTransform = s.initialTransform;
	
	didMakeContainer = false;
	if isempty(s.container)
		% create figure in which to place controls
		s.container = figure('name','Interactive transform controls',...
			'CloseRequestFcn',@(h,e) callback_closeContainer());
		didMakeContainer = true;
	end
	
	%% setup
	% assume we have full space of parent view to in which to place controls
	guiH = struct();
	numPanels = s.doAllowTranslation + s.doAllowRotation + s.doAllowScaling + 1;
	
	panelNum = 0;
	
	panelNum = panelNum+1;
	guiH.mainPanel = uipanel('parent',s.container,...
			'Units','normalized',...
			'Position',[0 (numPanels - panelNum)/numPanels 0.5 1/numPanels],...
			'Title','Main');
	labelActionPairs = {
		'Reset',@(h,e) callback_reset,...
	};

	if s.doBlock
		s.doneBlocking = false;
		labelActionPairs = [labelActionPairs,...
			{'Done',@(h,e) callback_done}];
	end

	numButtons = length(labelActionPairs)/2;
	ylims = [0,1];
	guiH.mainButtons = [];
	for iB = 1:numButtons
		guiH.mainButtons(iB) = uicontrol(...
			'parent',guiH.mainPanel,...
			'style','pushbutton',...
			'String',labelActionPairs{iB*2-1},...
			'Callback',labelActionPairs{iB*2},...
			'Units','normalized',...
			'Position',[0,ylims(2)-diff(ylims)/numButtons*iB,1,diff(ylims)/numButtons]...
			);
	end
		
	if s.doShowTransform
		guiH.transformPanel = uipanel('parent',s.container,...
			'Units','normalized',...
			'Position',[0.5 (numPanels - panelNum)/numPanels 0.5 1/numPanels],...
			'Title','Raw transform');
		guiH.transformTable = uitable('parent',guiH.transformPanel,...
			'Units','normalized',...
			'Position',[0 0 1 1],...
			'Data',s.currentTransform);
	end
	
	if s.doAllowTranslation
		panelNum = panelNum+1;
		guiH.translationPanel = createInteractiveTransformSubpanel('Parent',s.container,...
			'Units','normalized',...
			'Position',[0 (numPanels-panelNum)/numPanels 1 1/numPanels],...
			'callback_changeAlongDimension',@callback_changeTranslation,...
			'ScaleIncrements',[1e-2 1e-1 1 1e1 1e2]*s.translationScale,...
			'Title','Translation');
	end
	
	if s.doAllowRotation
		panelNum = panelNum+1;
		guiH.rotationPanel = createInteractiveTransformSubpanel('Parent',s.container,...
			'Units','normalized',...
			'Position',[0 (numPanels-panelNum)/numPanels 1 1/numPanels],...
			'callback_changeAlongDimension',@callback_changeRotation,...
			'ScaleIncrements',[1e-1 1 5 15 45],...
			'UnitStr','degrees',...
			'Title','Rotation');
	end
	
	if s.doAllowScaling
		panelNum = panelNum+1;
		guiH.rotationPanel = createInteractiveTransformSubpanel('Parent',s.container,...
			'Units','normalized',...
			'Position',[0 (numPanels-panelNum)/numPanels 1 1/numPanels],...
			'callback_changeAlongDimension',@callback_changeScaling,...
			'Dims',{'X','Y','Z','All'},...
			'ScaleIncrements',[0.1 1 10 100],...
			'UnitStr','%',...
			'Title','Scaling');
	end
	
	
	
	%%
	
	if s.doBlock
		pause(0.1);
		while ~s.doneBlocking
			pause(0.1)
		end
		% if did block, delete all gui elements before returning
		fields = fieldnames(guiH);
		for iF = 1:length(fields)
			if ishandle(guiH.(fields{iF}))
				delete(guiH.(fields{iF}));
			end
		end
		if didMakeContainer
			delete(s.container)
		end
	end
	
	transform = s.currentTransform;

	%%
	
	function callback_closeContainer()
		closereq();
		if s.doBlock
			s.doneBlocking = true;
		end
	end
	
	function callback_changeTranslation(changeAmt, dimension)
		assert(ismember(dimension,1:3));
		curValues = s.currentTransform(1:3,4);
		curValues(dimension) = curValues(dimension) + changeAmt;
		s.currentTransform(1:3,4) = curValues;
		
		c_saySingle('Change amount: %.3g',changeAmt);
		
		callback_transformChanged();
	end

	function callback_changeRotation(changeAmt, dimension)
		assert(ismember(dimension,1:3));
		
		addedTransform = eye(4);
		addedTransform(1:3,1:3) = calculateRotationMatrix(changeAmt,dimension);
		
		s.currentTransform = s.currentTransform*addedTransform;
		
		callback_transformChanged();
	end

	function callback_changeScaling(changePercent, dimension)
		assert(ismember(dimension,1:4));
		
		addedTransform = eye(4);
		if dimension == 4
			addedTransform = addedTransform * (1+changePercent/100);
			addedTransform(4,4) = 1;
		else
			addedTransform(:,dimension) = addedTransform(:,dimension) * (1+changePercent/100);
		end
		
		s.currentTransform = s.currentTransform*addedTransform;
		
		callback_transformChanged();
		
	end

	function callback_transformChanged()
		if ~isempty(s.callback_transformChanged)
			s.callback_transformChanged(s.currentTransform);
		end
		if s.doShowTransform
			guiH.transformTable.Data = s.currentTransform;
		end
	end

	function callback_done()
		s.doneBlocking = true;
	end
	
	function callback_reset()
		s.currentTransform = s.initialTransform;
		callback_transformChanged();
	end
	
end


function rot = calculateRotationMatrix(theta, axis)
%from https://en.wikipedia.org/wiki/Rotation_matrix
	switch(axis)
		case 1
			rot = [		1			0			0			  ;
						0		cosd(theta)	-sind(theta)	  ;
						0		sind(theta)	cosd(theta)		]';
		case 2
			rot = [	cosd(theta)		0		sind(theta)		  ;
						0			1			0			  ;
					-sind(theta)	0		cosd(theta)		]';
		case 3
			rot = [	cosd(theta)	-sind(theta)	0			  ;
					sind(theta)	cosd(theta)		0			  ;
						0			0			1			]';
		otherwise
			error('unsupported axis');
	end
end



%%
function testfn()
	c_GUI_interactiveTransform('doAllowTranslation',true)

end

%%
function h = createInteractiveTransformSubpanel(varargin)
	p = inputParser();
	p.addParameter('Title','',@ischar);
	p.addParameter('Parent',[],@ishandle);
	p.addParameter('Position',[0 0 1 1],@isvector);
	p.addParameter('Units','normalized',@ischar);
	p.addParameter('ScaleIncrements',[1e-2 1e-1 1 1e1 1e2],@isvector);
	p.addParameter('CurrentScaleIndex',3,@isscalar);
	p.addParameter('Limits',[-inf inf],@isnumeric);
	p.addParameter('Dims',{'X','Y','Z'});
	p.addParameter('UnitStr','',@ischar);
	p.addParameter('CurrentValues',[],@isvector);
	p.addParameter('callback_changeAlongDimension',[],@(x) isa(x,'function_handle'));
	p.parse(varargin{:});
	s = p.Results;
	
	if isempty(s.Parent)
		error('Parent must be specified');
	end
	
	h = struct();
	
	h.panel = uipanel(...
		'Units',s.Units,...
		'Position',s.Position,...
		'Title',s.Title);
	
	% radio buttons to select scale increment
	scalePanelWidth = 0.25;
	h.scale_bg = uibuttongroup(...
		'Title','Scale',...
		'Parent',h.panel,...
		'Units','normalized',...
		'Position',[0 0 scalePanelWidth 1],...
		'SelectionChangedFcn',@callback_scaleIncrementChanged);
	
	h.scale_b = [];
	numButtons = length(s.ScaleIncrements);
	for iB = 1:numButtons
		if iB == s.CurrentScaleIndex
			selectedState = true;
		else
			selectedState = false;
		end
		h.scale_b(iB) = uicontrol(h.scale_bg,...
			'Style','radiobutton',...
			'String',sprintf('%s%s',c_toString(s.ScaleIncrements(iB)),s.UnitStr),...
			'Units','normalized',...
			'Position',[0 (numButtons - iB)/numButtons 1 1/numButtons],...
			'Value',selectedState,...
			'UserData',struct('index',iB));
	end
	
	% increment/decrement buttons for each dimension
	h.dim = {};
	numDimensions = length(s.Dims);
	for iD = 1:numDimensions
		h.dim{iD}.panel = uipanel(...
			'Parent',h.panel,...
			'Title',s.Dims{iD},...
			'Units','normalized',...
			'Position',[scalePanelWidth + (1-scalePanelWidth)*(iD-1)/numDimensions, 0, (1-scalePanelWidth)/numDimensions, 1]);
		
		h.dim{iD}.incrBtn = uicontrol(h.dim{iD}.panel,...
			'Style','pushbutton',...
			'String','+',...
			'Units','normalized',...
			'Position',[0 0.5 1 0.5],...
			'Callback',@(h,e) callback_changeAlongDimension('increment',iD));
		
		h.dim{iD}.decrBtn = uicontrol(h.dim{iD}.panel,...
			'Style','pushbutton',...
			'String','-',...
			'Units','normalized',...
			'Position',[0 0 1 0.5],...
			'Callback',@(h,e) callback_changeAlongDimension('decrement',iD));	
	end
	
	
	function callback_scaleIncrementChanged(src,dat)
		newIndex = dat.NewValue.UserData.index;
% 		c_saySingle('Increment changed from %s to %s',c_toString(s.ScaleIncrements(s.CurrentScaleIndex)), c_toString(s.ScaleIncrements(newIndex)));
		s.CurrentScaleIndex = newIndex;
	end

	function callback_changeAlongDimension(changeType, dimensionIndex)
		if ~isempty(s.callback_changeAlongDimension)
			change = s.ScaleIncrements(s.CurrentScaleIndex);
			if strcmpi(changeType,'decrement')
				change = change*-1;
			end
			s.callback_changeAlongDimension(change,dimensionIndex);
		end
	end
		
		
	

end