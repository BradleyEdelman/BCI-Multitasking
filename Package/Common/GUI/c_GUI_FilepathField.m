classdef c_GUI_FilepathField < handle

	% dependencies:
	%	- Common/ThirdParty/findjobj
	
	properties
		label
		isDir
		validFileTypes
		parent
		Units
		Position
		loadCallback
		saveCallback
		clearCallback
		browseCallback
		pathChangedCallback
	end
	
	properties(SetAccess=protected)
		doIncludeClearButton
		doAllowManualEditing
	end
	
	properties(AbortSet) % only call set.* methods for these properties if their values change
		relativeTo
		relPath % path relative to 'relativeTo' (if set)
	end
	
	properties(Dependent)
		dir
		relDir
		filename
		ext
		path % full path, independent of 'relativeTo'
		BackgroundColor
	end
	
	properties(Access=protected)
		panel
		textfield
		loadButton
		reloadButton
		saveButton
		resaveButton
		clearButton
		browseButton
		mode
		mutex_checkingPathChange = false;
		constructorFinished = false;
		isForSaving = false;
	end
	
	methods
		function o = c_GUI_FilepathField(varargin)
			p = inputParser();
			p.addParameter('label','File',@ischar);
			p.addParameter('isDir',false,@islogical);
			p.addParameter('relPath','',@ischar);
			p.addParameter('path','',@ischar);
			p.addParameter('relativeTo','',@ischar);
			p.addParameter('validFileTypes','*.*',@(x)ischar(x) || iscell(x)); % e.g. '*.stl;*.fsmesh;%.off'
			p.addParameter('mode','load-only',@(x)ismember(x,{...
				'load-only',...
				'save-only',...
				'load-reload',...
				'load-save',...
				'browse-only',...
				'save-browse',...
				}));
			p.addParameter('doIncludeClearButton',false,@islogical);
			p.addParameter('doAllowManualEditing',false,@islogical);
			p.addParameter('parent',[],@ishandle);
			p.addParameter('Position',[0 0 1 1],@isvector);
			p.addParameter('Units','normalized',@ischar);
			p.addParameter('loadCallback',[],@(x)isa(x,'function_handle'));
			p.addParameter('saveCallback',[],@(x)isa(x,'function_handle'));
			p.addParameter('clearCallback',[],@(x)isa(x,'function_handle'));
			p.addParameter('browseCallback',[],@(x)isa(x,'function_handle'));
			p.addParameter('pathChangedCallback',[],@(x)isa(x,'function_handle'));
			p.parse(varargin{:});
			s = p.Results;
			
			% assume each parser parameter has property with identical name
			for iF = 1:length(p.Parameters)
				o.(p.Parameters{iF}) = s.(p.Parameters{iF});
			end
			
						
			if ~isempty(s.path) && ~isempty(s.relPath)
				error('Should only specify one of ''path'' or ''relPath'' in constructor');
			end
			if ~isempty(s.path)
				o.path = s.path;
			end
			if ~isempty(s.relPath)
				o.relPath = s.relPath;
			end
			
			o.panel = uipanel(...
				'parent',s.parent,...
				'Title',o.label,...
				'Position',o.Position,...
				'Units',o.Units);
			
			numButtons = 0;
			buttonNum = 0;
			
			if s.doIncludeClearButton
				numButtons = numButtons+1;
			end
			
			buttonHeight = 0.5;
			textWidth = 1;
			textHeight = 1-buttonHeight;
			
			if ismember(o.mode,{'save-only','load-save','save-browse'})
				o.isForSaving = true;
			end
			
			switch(o.mode)
				case 'load-reload'
					numButtons = numButtons + 2;
					buttonNum = buttonNum + 1;
					o.loadButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','Load from...',...
						'Callback',@o.callback_browseAndLoad,...
						'Units','normalized',...
						'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
					buttonNum = buttonNum+1;
					o.reloadButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','Reload',...
						'Callback',@o.callback_load,...
						'Units','normalized',...
						'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
				case 'load-only'
					numButtons = numButtons + 1;
					buttonNum = buttonNum + 1;
					o.loadButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','Load from...',...
						'Callback',@o.callback_browseAndLoad,...
						'Units','normalized',...
						'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
				case 'save-only'
					numButtons = numButtons + 2;
					buttonNum = buttonNum+1;
					o.resaveButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','Save',...
						'Callback',@o.callback_save,...
						'Units','normalized',...
						'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
					buttonNum = numButtons + buttonNum+1;
					o.saveButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','Save to...',...
						'Callback',@o.callback_browseAndSave,...
						'Units','normalized',...
						'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
				case 'load-save'
					numButtons = numButtons + 2;
					buttonNum = buttonNum+1;
					o.loadButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','Load from...',...
						'Callback',@o.callback_browseAndLoad,...
						'Units','normalized',...
						'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
					buttonNum = buttonNum+1;
					o.saveButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','Save to...',...
						'Callback',@o.callback_browseAndSave,...
						'Units','normalized',...
						'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
				case 'browse-only'
					assert(~s.doIncludeClearButton); % browse-only mode assumes only one button, no clear
					textWidth = 0.9;
					textHeight = 1;
					o.browseButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','...',...
						'Callback',@o.callback_browse,...
						'Units','normalized',...
						'Position',[0.9 0 0.1 1]);
				case 'save-browse'
					assert(~s.doIncludeClearButton); % browse mode assumes only one button, no clear
					textWidth = 0.9;
					textHeight = 1;
					o.browseButton = uicontrol(o.panel,...
						'style','pushbutton',...
						'String','...',...
						'Callback',@o.callback_browse,...
						'Units','normalized',...
						'Position',[0.9 0 0.1 1]);
				otherwise
					error('Invalid mode: %s',o.mode);
			end
			
			if s.doIncludeClearButton
				numButtons = numButtons+1;
				buttonNum = buttonNum+1;
				o.clearButton = uicontrol(o.panel,...
					'style','pushbutton',...
					'String','Clear',...
					'Callback',@o.callback_clear,...
					'Units','normalized',...
					'Position',[(buttonNum-1)/numButtons 0 1/numButtons buttonHeight]);
			end
			
			if ~o.doAllowManualEditing
				o.textfield = uicontrol(o.panel,...
					'style','text',...
					'String',o.relPath,...
					'Units','normalized',...
					'Position',[0 (1-textHeight) textWidth textHeight]); 
			else
				o.textfield = uicontrol(o.panel,...
					'style','edit',...
					'String',o.relPath,...
					'Units','normalized',...
					'Position',[0 (1-textHeight) textWidth textHeight],...
					'Callback',@o.callback_manualEdit);
				
			end

			o.constructorFinished = true;
		end
		
		function simulateButtonPress(o,buttonName)
			switch(lower(buttonName))
				case 'save to...'
					assert(ismember(o.mode,{'save-only','load-save'}));
					o.callback_browseAndSave([],[]);
				case 'save'
					assert(ismember(o.mode,{'save-only','load-save'}));
					o.callback_save([],[]);
				case 'load from...'
					assert(ismember(o.mode,{'load-reload','load-only','load-save'}));
					o.callback_browseAndLoad([],[]);
				case 'load'
					assert(ismember(o.mode,{'load-reload','load-only','load-save'}));
					o.callback_load([],[]);
				case 'clear'
					assert(o.doIncludeClearButton);
					o.callback_clear([],[]);
				otherwise
					error('Unsupported buttonName: %s',buttonName);
			end
		end
		%%
		
		% note from MATLAB documentation: 
		% "A set method for one property can assign values to other properties of the object. 
		%  These assignments do call any set methods defined for the other properties"
		
		function o = set.Position(o,newPos)
			o.panel.Position = newPos;
			o.Position = newPos;
		end
		function pos = get.Position(o)
			pos = o.Position;
		end
		
		function o = set.relPath(o,newRelPath)
% 			c_say('Start set.relPath');
			o.relPath = newRelPath;
			o.pathUpdated();
% 			c_sayDone('End set.relPath');
		end
		
		function o = set.path(o,newPath)
% 			c_say('Start set.path');
			if ~isempty(o.relativeTo)
				newRelPath = c_path_convert(newPath,'makeRelativeTo',o.relativeTo);
			else
				newRelPath = newPath;
			end
			o.relPath = newRelPath;
% 			c_sayDone('End set.path: relPath=%s',o.relPath);
		end
		
		function o = set.dir(o,newDir) % assumes dir is not relative to relativeTo
% 			c_say('Start set.dir');
			tmpPath = fullfile(newDir,o.filename)
			o.path = fullfile(newDir,o.filename);
% 			c_sayDone('End set.dir');
		end
		
		function o = set.filename(o,newFilename)
% 			c_say('Start set.filename');
			o.path = fullfile(o.dir, newFilename);
% 			c_sayDone('End set.filename');
		end
		
		function o = set.relativeTo(o,newRelativeTo)
% 			c_say('Start set.relativeTo');
			o.relativeTo = newRelativeTo;
			o.pathUpdated();
% 			c_sayDone('End set.relativeTo');
		end
		
		function path = get.path(o)
			if ~isempty(o.relativeTo)
				path = fullfile(o.relativeTo,o.relPath);
			else
				path = o.relPath;
			end
		end
		
		function relPath = get.relPath(o)
			relPath = o.relPath;
		end
		
		function filename = get.filename(o)
			if isempty(o.relPath)
				filename = '';
				return;
			end
			[~,filename] = fileparts(o.relPath);
		end
		
		function dir = get.dir(o)
			if isempty(o.path)
				dir = '';
				return;
			end
			[dir,~] = fileparts(o.path);
		end
		
		function relDir = get.relDir(o)
			[relDir,~] = fileparts(o.relPath);
		end
		
		function o = set.BackgroundColor(o,newColor)
			o.textfield.BackgroundColor = newColor;
		end
		function color = get.BackgroundColor(o)
			color = o.textfield.BackgroundColor;
		end
		
		function path = getPath(o)
			path = o.path;
		end
		
		function changeBasePath(o,newRelativeTo)
			% change relative to only (i.e. afterwards, o.relPath will be different but o.path will be unchaged)
			path = o.path;
			o.relativeTo = newRelativeTo;
			o.path = path;
		end
	end
	%%
	methods(Access=protected)
		
		function pathUpdated(o)
% 			c_say('Start pathUpdated');
			o.textfield.String = o.relPath;
			if o.constructorFinished && ~isempty(o.pathChangedCallback)
				o.pathChangedCallback(o.path);
			end
% 			c_sayDone('End pathUpdated');
		end
		
		function callback_manualEdit(o,h,e)
			o.relPath = o.textfield.String;
		end
		
		function callback_browseAndLoad(o,h,e)
			dlgStr = sprintf('Select %s to load',o.label);
			if o.isDir
				pn = uigetdir(deepestExistingPath(o.path),dlgStr);
				fn = '';
			else
				[fn, pn] = uigetfile(o.validFileTypes,...
					dlgStr,...
					o.path);
			end
			if fn==0 || pn==0
				% user cancelled browse, don't change anything
				return
			end
			o.path = fullfile(pn,fn);
			o.callback_load(h,e);
		end
		
		function callback_load(o,h,e)
			if ~isempty(o.loadCallback)
				o.loadCallback(o.path);
			else
				warning('No load callback set');
				keyboard
			end
		end
		
		function callback_browseAndSave(o,h,e)
			dlgStr = sprintf('Select where to save %s',o.label);
			if o.isDir
				pn = uigetdir(deepestExistingPath(o.path),dlgStr);
				fn = '';
			else
				[fn, pn] = uiputfile(o.validFileTypes,...
					dlgStr,...
					o.path);
			end
			if fn==0 || pn==0
				% user cancelled browse, don't change anything
				return
			end
			o.path = fullfile(pn,fn);
			o.callback_save(h,e);
		end
		
		function callback_save(o,h,e)
			if ~isempty(o.saveCallback)
				o.saveCallback(o.path);
			else
				warning('No save callback set');
				keyboard
			end
		end

		function callback_clear(o,h,e)
			o.relPath = '';
			if ~isempty(o.clearCallback)
				o.clearCallback(o.path);
			end
		end
		
		function callback_browse(o,h,e)
			dlgStr = sprintf('Select %s',o.label);
			if o.isDir
				pn = uigetdir(deepestExistingPath(o.path),dlgStr);
				fn = '';
			else
				if ~o.isForSaving
					guiFn = @uigetfile;
					startStr = deepestExistingPath(o.path);
				else
					guiFn = @uiputfile;
					startStr = o.path;
				end
				[fn, pn] = guiFn(o.validFileTypes,dlgStr,startStr);
			end
			if (~o.isDir && isscalar(fn) && fn==0) || (o.isDir && isscalar(pn) && pn==0)
				% user cancelled browse, don't change anything
				return
			end
			o.path = fullfile(pn,fn);
			if ~isempty(o.browseCallback)
				o.browseCallback(o.path);
			end
		end
	end
end

function path = deepestExistingPath(path)
	if isempty(path)
		return;
	end
	if exist(path,'file')
		return;
	else
		path = deepestExistingPath(fileparts(path));
	end
end
	