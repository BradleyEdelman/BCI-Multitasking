classdef c_FigureRecorder < handle
	%FigureRecorder Summary of this class goes here
	%   Detailed explanation goes here
	
	properties(SetAccess=protected)
		size = [];
		outputDir;
		filename;
		doOverwriteExisting;
		doVerbose;
		method;
		frameRate;
		isInProgress = false;
		vidObj;
		outputPath;
		printPrefix = 'FigureRecorder: ';
	end
	
	methods(Static)
		function initialize()
			persistent pathModified;
			if isempty(pathModified)
				c_saySingle('FigureRecorder: Adding dependencies to path');
				mfilepath=fileparts(which(mfilename));
				addpath(fullfile(mfilepath,'./CopyFileToClipboard'));
				pathModified = true;
			end
		end
		
		function testfn()
			hf = figure;
			
			fr = c_FigureRecorder();
			
			N = 100;
			x = 1:N;
			y = cumsum(rand(1,N));
			
			fr.start();
			for i=1:N
				plot(x(1:i),y(1:i));
				xlim(extrema(x));
				ylim(extrema(y));
				fr.captureFrame(hf);
			end
			fr.stop();
			
			fr.openLastSaved();
		end
	end
	
	methods
		function o = c_FigureRecorder(varargin)
			p = inputParser();
			p.addParameter('outputDir','./Figures',@ischar);
			p.addParameter('filename','FigureMovie.avi',@ischar);
			p.addParameter('doOverwriteExisting',false,@islogical);
			p.addParameter('doVerbose',false,@islogical);
			p.addParameter('method','VideoWriter',@ischar);
			p.addParameter('frameRate',10,@isscalar); % in fps
			p.parse(varargin{:});
			s = p.Results;
			
			% copy parsed input to object properties of the same name
			fieldNames = fieldnames(s);
			for iF=1:length(fieldNames)
				if isprop(o,p.Parameters{iF})
					o.(fieldNames{iF}) = s.(fieldNames{iF});
				end
			end
		end
		
		function ensureOutputDirExists(o)
			if ~exist(o.outputDir,'dir')
				if o.doVerbose
					c_saySingle('%sCreating output dir at %s',o.printPrefix,o.outputDir);
				end
				mkdir(o.outputDir);
			end
		end
		
		function start(o)
			if o.isInProgress
				error('Already in progress');
			end
			
			o.ensureOutputDirExists();
			
			if o.doVerbose, c_say('%sSetting output path',o.printPrefix); end;
			o.outputPath = fullfile(o.outputDir,o.filename);
			counter = 0;
			while ~o.doOverwriteExisting && exist(o.outputPath,'file')
				if o.doVerbose, c_saySingle('%sFile already exists at %s',o.printPrefix,o.outputPath); end;
				counter = counter+1;
				[path,filename,ext] = fileparts(o.filename);
				filename = [filename '_' num2str(counter) ext];
				o.outputPath = fullfile(o.outputDir,path,filename);
			end
			if o.doVerbose
				if exist(o.outputPath,'file')
					c_saySingle('%sOverwriting file at %s',o.printPrefix,o.outputPath);
				else
					c_saySingle('%sOutput path: %s',o.printPrefix,o.outputPath);
				end
				c_sayDone();
			end
			
			switch(o.method)
				case 'VideoWriter'
					o.vidObj = VideoWriter(o.outputPath);
					o.vidObj.Quality = 100;
					o.vidObj.FrameRate = o.frameRate;
					open(o.vidObj);
				otherwise
					error('Invalid method');
			end
			
			o.isInProgress = true;
		end
		
		function captureFrame(o,varargin) 
			p = inputParser();
			p.addOptional('graphicsHandle',[],@ishandle);
			p.parse(varargin{:});
			s = p.Results;
			
			if isempty(s.graphicsHandle)
				s.graphicsHandle = gcf;
			end
			
			if ~o.isInProgress
				o.start();
			end
			
			if o.doVerbose, c_say('%sCapturing frame',o.printPrefix); end;
			
			switch(o.method)
				case 'VideoWriter'
					writeVideo(o.vidObj, getframe(s.graphicsHandle));
				otherwise
					error('Invalid method');
			end
			
			if o.doVerbose, c_sayDone(); end;
		end
		
		function stop(o)
			if ~o.isInProgress
				error('Not in progress');
			end

			if o.doVerbose, c_saySingle('%sClosing',o.printPrefix); end;
			
			switch(o.method)
				case 'VideoWriter'
					close(o.vidObj);
				otherwise
					error('Invalid method');
			end
			
			o.isInProgress = false;
		end
		
		function openLastSaved(o)
			if o.doVerbose
				c_say('%Opening last saved at %s',o.printPrefix,o.outputPath);
			end
			if o.isInProgress
				warning('Save still in progress');
			end
			
			if exist(o.outputPath,'file')
				winopen(o.outputPath);
			end
			
			if o.doVerbose, c_sayDone(); end;
		end
	end
	
end

