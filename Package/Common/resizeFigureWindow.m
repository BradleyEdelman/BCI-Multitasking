function resizeFigureWindow(figH,pos)

	if ~strcmp(get(figH,'Units'),'normalized')
% 		warning('Changing window units from %s to normalized',figH.Units);
		set(figH,'Units','normalized');
	end
	
	set(figH,'OuterPosition',remapToUsableSpace(figH,[pos]));
end

function [xywh] = remapToUsableSpace(figH,xywh)
	% assume input in normalized units
	
	x = xywh(1);
	y = xywh(2);
	w = xywh(3);
	h = xywh(4);
	
	prevUnits = get(0,'Units');
	set(0,'Units','pixels');
	scrSize = get(0,'ScreenSize');
	set(0,'Units',prevUnits);
	menuBarHeight = 40 / scrSize(4);
	
% 	windowHasMenu = ~strcmp(get(figH,'MenuBar'),'none'); %TODO: also check ToolBar properties and adjust accordingly
% 	if windowHasMenu
% 		topWindowOffset = 82 / scrSize(4);
% 	else
% 		topWindowOffset = 30 / scrSize(4);
% 	end
	topWindowOffset = 0;
	
% 	bottomWindowOffset = 5 / scrSize(4);
	bottomWindowOffset = 0;
% 	leftWindowOffset = 5 / scrSize(3);
% 	rightWindowOffset = leftWindowOffset;
	leftWindowOffset = 0;
	rightWindowOffset = 0;
	
	x = x*(1-leftWindowOffset - rightWindowOffset) + leftWindowOffset;
	y = (y*(1-menuBarHeight-topWindowOffset-bottomWindowOffset) + menuBarHeight+bottomWindowOffset);
	
	w = w*(1-leftWindowOffset - rightWindowOffset);
	h = h*(1-menuBarHeight-topWindowOffset-bottomWindowOffset);

	xywh = [x,y,w,h];
end