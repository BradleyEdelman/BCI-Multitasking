function [choice, choiceStr] = c_menu(menuStr,optionTree)

	if nargin == 0
		% test
		tree = {'_root','Test 1',{'Test 2','2.1','2.2'},'Test 3',{'Test 4','4.1','4.2',{'4.3','4.3.1','4.3.2'}}};
		choice = c_menu('test',tree)
		choiceStr = c_tree_getSubtreeAtNodeIndex(tree,choice)
		keyboard
		return;
	end

	options = optionTree;
	
	assert(ischar(options{1})); % root node label should be string
	
	isRecursive = false(size(options));
	for i=1:length(options)
		if iscell(options{i})
			opts{i} = [options{i}{1} '...']; % top of a menu
			isRecursive(i) = true;
		else
			opts{i} = options{i};
		end
	end
	
	
	while true
		choice = menu(menuStr,opts(2:end));
		if choice==0
			% dialog closed without a choice
			choiceStr = '';
			return;
		end
		choice = choice+1;

		if isRecursive(choice)
			choice_inner = c_menu([menuStr sprintf('\n->') options{choice}{1}],[options{choice}{1}, {'<- Back'}, options{choice}(2:end)]);
			if choice_inner==2 % back
				continue;
			end
			choice_inner(1) = choice_inner(1) - 1;
			choice = [choice, choice_inner];
		end
		break;
	end
	
	choiceStr = c_tree_getSubtreeAtNodeIndex(optionTree,choice);
end


function choice = menu(title,choices)
	buttonHeight = 40;
	buttonWidth = 300;
	spacing = 10;
	
	numLines = 1+length(strfind(title,sprintf('\n')));
	textHeight = 20*numLines;
	
	sideTextWidth = 20;
	
	choice = 0;
	
	numChoices = length(choices);
	
	height = (spacing+textHeight + spacing + (buttonHeight+spacing)*numChoices);
	outerHeight = height+0;
	
	mp = get(0,'MonitorPositions');
	mIndex = 1;
	mIndex = mod(mIndex-1,size(mp,1))+1;
	tlc = [mp(mIndex,1) + mp(mIndex,3) - buttonWidth - sideTextWidth - spacing*3 - 6, mp(mIndex,2)+mp(mIndex,4)-100];
	
	possibleChoices = ['1':'9', '0','a':'z','A':'Z'];
	assert(numChoices <= length(possibleChoices)); % assume we'll never have more than this many options
	possibleChoices = possibleChoices(1:numChoices);
	
	hf = figure(...
		'Position',[tlc(1), tlc(2)-outerHeight, sideTextWidth+buttonWidth+spacing*3,outerHeight],...
		'MenuBar','None',...
		'KeyPressFcn',@(~,e) keyPressed(e.Character,possibleChoices),...
		'Name','Menu');
	uicontrol('Parent',hf,...
		'Style','text',...
		'Units','Pixels',...
		'Position',[spacing, height-textHeight-spacing, buttonWidth,textHeight],...
		'HorizontalAlignment','left',...
		'String',title);
	
	btns = [];
	for i=1:numChoices
		uicontrol('Parent',hf,...
			'Style','text',...
			'Units','Pixels',...
			'Position',[spacing, height-textHeight-(buttonHeight+spacing)*i-buttonHeight/4,sideTextWidth,buttonHeight],...
			'String',possibleChoices(i));
		btns(i) = uicontrol('Parent',hf,...
			'Style','pushbutton',...
			'Position', [spacing*2+sideTextWidth, height-textHeight-(buttonHeight+spacing)*i, buttonWidth, buttonHeight],...
			'Callback',@(h,e) buttonPressed(i),...
			'String',choices{i});
	end
	
	uiwait(hf);
	
	if choice ~= 0
		c_saySingle('Menu: selected choice: %s',choices{choice});
	else
		c_saySingle('Menu: no choice selected');
	end
	
	function keyPressed(character,possibleChoices)
		if ismember(character,possibleChoices)
			choice = find(possibleChoices==character,1,'first');
			delete(hf);
		end
	end
	
	function buttonPressed(buttonNum)
		choice = buttonNum;
		delete(hf);
	end
	
end