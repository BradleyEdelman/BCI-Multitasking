classdef c_FigurePrinter < handle
	%FigurePrinter Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		ext = '-dpng';
		size = [];
		parentDirectory;
		figureDirectory;
		resolution = 300;
		disabled = false;
		doPrintText = false;
		alsoSaveNativeFig = true;
	end
	
	methods(Static)
		function initialize()
			persistent pathModified;
			if isempty(pathModified)
				c_saySingle('Adding dependencies to path');
				mfilepath=fileparts(which(mfilename));
				addpath(fullfile(mfilepath,'./ThirdParty/export_fig'));
%				addpath(fullfile(mfilepath,'./ThirdParty/imclipboard'));
				addpath(fullfile(mfilepath,'./CopyFileToClipboard'));
				addpath(fullfile(mfilepath,'./ThirdParty/captureScreens'));
				CopyFileToClipboard();
				pathModified = true;
			end
		end
		
		function copyMonitorScreenshotToClipboard(varargin)
			p = inputParser();
			p.addParameter('monitors',[],@(x) isnumeric(x) && isvector(x));
			p.parse(varargin{:});
			s = p.Results;
			c_say('Copying monitor screenshot(s) to clipboard');
			c_say('Capturing screenshots');
			ims = captureScreens();
			if ~isempty(s.monitors)
				% reduce to just selected monitor(s)
				ims = ims(mod(s.monitors-1,length(ims))+1);
			end
			c_sayDone();
			c_say('Saving %d screenshot%s to temporary location',length(ims),c_strIfNumIsPlural(length(ims)));
			baseName = tempname;
			filenames = {};
			for i = 1:length(ims)
				filenames{i} = [baseName '_' num2str(i) '.png'];
				imwrite(ims{i},filenames{i});
			end
			c_sayDone();
			c_say('Copying %d screenshot%s to clipboard',length(ims),c_strIfNumIsPlural(length(ims)));
			for i = length(filenames):-1:1
				CopyFileToClipboard(filenames{i});
				if i~=1, pause(1); end;
			end
			c_sayDone();
			c_sayDone();
		end
		
		function copyMultipleToClipboard(h,varargin)
			for i = 1:length(h)
				figure(h(i));
				drawnow();
				c_FigurePrinter.copyToClipboard(varargin{:});
				pause(0.5);
			end
		end
		
		function copyToClipboard(magnification,doCrop)
			if nargin < 1
				magnification = 1;
			end
			if nargin < 2
				doCrop = true;
			end
			c_say('Copying figure to clipboard');
			tmp = findobj(gcf,'Tag','c_NonPrinting');
			if ~isempty(tmp)
				c_saySingle('Hiding c_NonPrinting elements')
				tmpIndices = ismember(get(tmp,'Visible'),{'on'});
				set(tmp(tmpIndices),'Visible','off');
			end
			c_FigurePrinter.initialize();
			origBackground = get(gcf,'Color');
			c_saySingle('Setting axis background');
			set(gcf, 'Color', 'none'); % Sets axes background
			c_saySingle('Exporting figure to temporary file');
			filename = [tempname '.png'];
			extraArgs = {};
			if ~doCrop
				extraArgs = {'-nocrop'};
			end
			export_fig(filename,'-png','-transparent',['-m' num2str(magnification)],'-opengl',extraArgs{:});
			c_saySingle('Copying to clipboard');
			CopyFileToClipboard(filename);
			c_saySingle('Resetting axis background');
			set(gcf,'Color',origBackground);
			if ~isempty(tmp)
				c_saySingle('Restoring c_NonPrinting elements')
				set(tmp(tmpIndices),'Visible','on');
			end
			c_sayDone();
		end
	end
	
	methods
		function obj = c_FigurePrinter(FigureDirectory, defaultType, defaultSize)

			if nargin > 2
				obj.size = defaultSize;
			end
			if nargin > 1
				obj.ext = defaultType;
			end
			if nargin > 0
				obj.figureDirectory = FigureDirectory;
			else
				obj.figureDirectory = 'Figures';
			end
			
			if ~strcmp(obj.ext(1:2),'-d')
				error('Specified extension must begin with ''-d'', e.g. -dpng');
			end
			
			if ~exist(obj.figureDirectory,'dir') 
				mkdir(obj.figureDirectory);
			end
		end
		function enable(obj)
			obj.disabled = false;
		end
		function disable(obj)
			obj.disabled = true;
		end
		function disableNativeFigureSave(obj)
			obj.alsoSaveNativeFig = false;
		end
		function doPrint(obj)
			obj.doPrintText = true;
		end
		
		function save(obj,filename,ext,pageDimensions)
			if obj.disabled
				return % don't actually save
			end
			
			if nargin > 3
				set(gcf, 'PaperSize', [pageDimensions(1) pageDimensions(2)]);
				set(gcf,'PaperPosition',[0 0 pageDimensions(1) pageDimensions(2)]);
			elseif ~isempty(obj.size)
				set(gcf, 'PaperSize', [obj.size(1) obj.size(2)]);
			end
			if nargin <= 2 
				ext = obj.ext;
			end
			filepath = [obj.figureDirectory '/' filename];
			
			if obj.doPrintText
				fprintf('Saving figure to %s\n',filepath);
			end
			
			if obj.alsoSaveNativeFig
				savefig([filepath '.fig']);
			end
			
			print(ext,filepath,['-r' num2str(obj.resolution)]);
		end
		
		function export(obj,filename,ext,varargin)
			if obj.disabled
				return % don't actually save
			end
			
			if nargin <= 2 
				ext = obj.ext;
			end
			filepath = [obj.figureDirectory '/' filename];
			
			if obj.doPrintText
				fprintf('Saving figure to %s\n',filepath);
			end
			
			if obj.alsoSaveNativeFig
				savefig([filepath '.fig']);
			end
			
			%print(ext,filepath,['-r' num2str(obj.resolution)]);
			
			if strcmp(ext,'-dpng'), ext='-png'; end;
			if strcmp(ext,'-depsc'), ext='-eps'; end;
			export_fig(filepath,ext,varargin{:});
		
		end
	end
	
end

