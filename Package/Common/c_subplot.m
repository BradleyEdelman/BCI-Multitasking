function h = c_subplot(varargin)
% input can be:
%  numRows, numColumns, row, column
% or 
%  figNum, numFigs
% or 
%  numRows, numColumns, index
% or
%  'position',[left bottom width height]


%TODO: convert to using inputParser for parsing input with variable number
%of more descriptive inputs.
%TODO: add support for 'Position' argument of subplot()

if nargin == 0
	%%debug
	warning('Debugging c_subplot');
	N = 4;
	data = rand(100,N) - 0.5;
	data = cumsum(data,1);
	
	figure('name','debug');
	for i=1:N
		c_subplot(i,N);
		plot(1:100,data(:,i));
		title(num2str(i));
		%c_subplot_makeInteractive(h,num2str(i));
	end
	
	h = 0;
	return;
end

extraArgs = {};
if isscalar(varargin{1}) || (ischar(varargin{1}) && strcmpi(varargin{1},'position'))
	numRecognizedArgs = 1;
else
	error('invalid input');
end
for i=2:nargin
	if isnumeric(varargin{i}) || (ischar(varargin{i}) && strcmpi(varargin{i},'Number'))
		numRecognizedArgs = numRecognizedArgs + 1;
	else
		% start of "extra" args reached
		break;
	end
end
if numRecognizedArgs < nargin
	extraArgs = varargin(numRecognizedArgs+1:end);
	assert(mod(length(extraArgs),2)==0); % make sure there are even number of extra args (assuming they are all (name,value) pairs
end
subVarargin = varargin(1:numRecognizedArgs);

if numRecognizedArgs >= 1
	arg1 = subVarargin{1};
end
if numRecognizedArgs >= 2
	arg2 = subVarargin{2};
end
if numRecognizedArgs >= 3
	arg3 = subVarargin{3};
end
if numRecognizedArgs >= 4
	arg4 = subVarargin{4};
end

if numRecognizedArgs >= 2 && ischar(arg1)
	% (name, value) arguments
	
	p = inputParser;
	p.addParameter('Position',[0 0 1 1],@isvector);
	p.addParameter('Number',0,@isscalar);
% 		p.addParameter('FrameWidth',0.05,@isscalar);
% 		p.addParameter('FrameHeight',0.05,@isscalar);
% 		p.addParameter('LeftInset',0.05,@isscalar);
% 		p.addParameter('BottomInset',0.05,@isscalar);

	p.parse(subVarargin{:});
	
	l = p.Results.Position(1);
	b = p.Results.Position(2);
	w = p.Results.Position(3);
	h = p.Results.Position(4);
% 	fw = p.Results.FrameWidth;
% 	fh = p.Results.FrameHeight;
% 	li = p.Results.LeftInset;
% 	bi = p.Results.BottomInset;
% 	
% 	al = (l+fw/2)*(1-li)+li;
% 	ab = (b+fh/2)*(1-bi)+bi;
% 	aw = (w-fw)*(1-li);
% 	ah = (h-fh)*(1-bi);
	
	if 1
		argsToSubplot = {};
		h = axes('OuterPosition',[l b w h],'ActivePositionProperty','outerposition',extraArgs{:});
	else
		argsToSubplot = {'Position',[l b w h]};
	end
	index = p.Results.Number;
	
elseif numRecognizedArgs == 2
		figNum = arg1;
		numFigs = arg2;

		if numFigs == 3
			numCols = numFigs;
			numRows = 1;
		elseif numFigs == 6
			numCols = 3;
			numRows = 2;
		elseif numFigs == 8
			numCols = 4;
			numRows = 2;
		else
			numCols = ceil(sqrt(numFigs));
			numRows = ceil(numFigs/numCols);
		end

		index = figNum;
		
		argsToSubplot = {numRows, numCols, index};
		
elseif numRecognizedArgs == 3
	index = arg3; % third argument is actually index (i.e. same args as normal subplot() )
	argsToSubplot = {arg1, arg2, index};
else
	index = (arg3-1)*arg2 + arg4;
	argsToSubplot = {arg1, arg2, index};
end

if ~isempty(argsToSubplot)
	h = subplot(argsToSubplot{:},extraArgs{:});
end
figHandle = get(h,'parent');
c_figure_addInteractive(figHandle,h,index);

ud = get(h,'UserData');
if iscell(ud)
	index = find(cellfun(@isstruct,ud),1,'first');
	if isempty(index)
		index = length(ud)+1;
		ud{index} = struct();
	end
	ud{index}.SubplotIndex = index;
else
	ud.SubplotIndex = index;
end
set(h,'UserData',ud);

end

function c_figure_addInteractive(figHandle,subplotHandle,index)

	% Define a context menu; it is not attached to anything
	hcmenu = get(figHandle,'uicontextmenu');
	if isempty(hcmenu)
		hcmenu = uicontextmenu;
	end
	% Define callbacks for context menu items that change linestyle
	% Define the context menu items and install their callbacks
	item1 = uimenu(hcmenu, 'Label', ['Pop out ' num2str(index)], 'Callback', {@c_copySubplotToNewFig,subplotHandle,num2str(index)});
	set(figHandle,'uicontextmenu',hcmenu);
end


function c_copySubplotToNewFig(cb,eventdata,handle,label)
	parentHandle = get(handle,'parent');
	parentName = get(parentHandle,'name');
	figName = [parentName ' subplot ' label];
	hh = copyobj(handle,figure('name',figName));
	parentFields = get(parentHandle);
	if isfield(parentFields,'Colormap')
		colormap(hh,parentFields.Colormap);
	end
	%resize the axis to fill the figure
	set(hh, 'Position', get(0, 'DefaultAxesPosition'));
end