classdef c_progress < handle
%% Class for printing loop progress updates and estimating time remaining
% 
% Example usage:
%   prog = c_progress(N,'Message to print %d/%d'); % first %d is current loop variable, second %d is total
%   prog.start();
%   for i=1:N
%      prog.update();
%      % do some work here
%   end
%   prog.stop(); % print elapsed time
	
	
	properties
		N % total number expected
		formatStr 
		n % current number
		startTime
		lastTime
		lastPrintedTime
		doPrintTimeEstimate
		doAssumeUpdateAtEnd
		waitXSecsToPrint
		didSayStart
	end
	
	properties(SetAccess=protected)
		isParallel
	end
	
	properties(Access=protected)
		par_tmpDir = '';
		endsToNotPrintCounter = 0;
	end
	
	methods
		function obj = c_progress(varargin)
			
			if nargin==0
				obj.testfn();
				return;
			end
			
			p = inputParser;
			p.addRequired('N',@isscalar);
			p.addOptional('formatStr','%d/%d',@ischar); % should be format string with two fields, first for current n, and second for total N
			p.addParameter('initialn',0,@isscalar);
			p.addParameter('doPrintTimeEstimate',true,@islogical);
			p.addParameter('waitToPrint',0,@isscalar); % s
			p.addParameter('doAssumeUpdateAtEnd',false,@islogical);
			p.addParameter('isParallel',false,@islogical);
			p.parse(varargin{:});
			
			obj.N = p.Results.N;
			obj.formatStr = p.Results.formatStr;
			obj.n = p.Results.initialn;
			obj.doPrintTimeEstimate = p.Results.doPrintTimeEstimate;
			obj.doAssumeUpdateAtEnd = p.Results.doAssumeUpdateAtEnd;
			obj.waitXSecsToPrint = p.Results.waitToPrint;
			obj.isParallel = p.Results.isParallel;
			obj.didSayStart = false;
			
			if obj.isParallel
				obj.par_tmpDir = tempname();
				assert(exist(obj.par_tmpDir,'file')==0);
				mkdir(obj.par_tmpDir);
			end
			
			obj.start();
		end
		
		function start(obj,message,varargin)
			obj.n = 0;
			obj.startTime = clock();
			obj.lastTime = obj.startTime;
			obj.lastPrintedTime = obj.startTime;
			if nargin > 1
				obj.didSayStart = true;
				c_say(message,varargin{:});
			end
		end
		
		function stop(obj,message,varargin)
			if obj.didSayStart
				say = @c_sayDone;
			else
				say = @c_saySingle;
			end
			if nargin < 2
				say('Total time: %s',c_relTime_toStr(etime(clock(),obj.startTime)));
			else
				say([message,' Total time: %s'],varargin{:},c_relTime_toStr(etime(clock(),obj.startTime)));
			end
			
			if obj.isParallel
				rmdir(obj.par_tmpDir,'s');
			end
		end
		
		function updateStart(obj,n)
			if nargin < 2
				obj.n = obj.n + 1;
			else
				obj.n = n;
			end
			didPrint = obj.printUpdate(true);
			if ~didPrint
				obj.endsToNotPrintCounter = obj.endsToNotPrintCounter + 1;
			end
		end
		
		function updateEnd(obj,n,varargin)
			if obj.endsToNotPrintCounter > 0
				obj.endsToNotPrintCounter = obj.endsToNotPrintCounter - 1;
				return;
			end
			c_sayDone(varargin{:});
		end
		
		function update(obj,n,message,varargin)
			if nargin < 2
				if obj.isParallel
					warning('Should specify counter value during update when running inside parfor');
				end
				obj.n = obj.n + 1;
			else
				obj.n = n;
				if n==0
					obj.start();
				end
			end
			if nargin < 3
				obj.printUpdate();
			else
				obj.printUpdate(true);
				c_saySingle(message,varargin{:});
				c_sayDone();
			end
		end
	end
			
	methods (Access=protected)
		function didPrint = printUpdate(obj,isExplicitStart)
			
			if nargin < 2
				isExplicitStart = false;
			end
			
			currentTime = clock();
			totalElapsedTime = etime(currentTime,obj.startTime);
			elapsedTime = etime(currentTime,obj.lastTime);
			elapsedSinceLastPrint = etime(currentTime,obj.lastPrintedTime);
			
			obj.lastTime = currentTime;
			
			numFinished = obj.n - ~obj.doAssumeUpdateAtEnd;
			
			if obj.isParallel
				listing = dir(obj.par_tmpDir);
				numFiles = length(listing)-2; % assuming everything other than '.' and '..' is a file left by another worker
				numFinished = numFiles + obj.doAssumeUpdateAtEnd;
				
				fclose(fopen(fullfile(obj.par_tmpDir, [num2str(obj.n) '.tmp']), 'w')); % make empty file recording the update for this n'th iteration
			end
			
			if elapsedSinceLastPrint < obj.waitXSecsToPrint
				% do not print
				didPrint = false;
				return;
			end
			
			didPrint = true;
			
			if numFinished > 0
				ETR = (obj.N - numFinished) * totalElapsedTime / (numFinished);
				ETRStr = c_relTime_toStr(ETR);
				ETA = datenum(currentTime) + ETR/(60*60*24);
				ETAStr = c_dateNum_toStr(ETA);
				timeEstimateValid = true;
			else
				timeEstimateValid = false;
			end
			
			if isExplicitStart
				say = @c_say;
			else
				say = @c_saySingle;
			end
			
			obj.lastPrintedTime = currentTime;
			if ~obj.isParallel
				if obj.doPrintTimeEstimate && timeEstimateValid
					say([obj.formatStr '\t Elapsed: %s \t ETR: %s \t ETA: %s'],...
						obj.n,obj.N,c_relTime_toStr(elapsedTime), ETRStr,ETAStr);
				else
					say(obj.formatStr,obj.n,obj.N);
				end
			else
				if obj.doPrintTimeEstimate && timeEstimateValid
					say([obj.formatStr ' \t (parallel %d/%d) \t Elapsed: %s \t ETR: %s \t ETA: %s'],...
						obj.n,obj.N,numFinished,obj.N,c_relTime_toStr(elapsedTime), ETRStr,ETAStr);
				else
					say([obj.formatStr ' \t (parallel %d/%d)'],obj.n,obj.N,numFinished,obj.N);
				end
			end
		end
	end
		
	methods (Static)
		function testfn()
			%%
			clear all
			
			N = 20;
			prog = c_progress(N,'Progress test function %3d/%d');
			pause(0.5);
			prog.start();
			for i=1:N
				prog.update();
				pause(1);
			end
			prog.stop();
		end
		
		function partestfn()
			N = 200;
			prog = c_progress(N,'Parallel progress test function %d/%d','isParallel',true);
			prog.start();
			parfor i=1:N
				prog.update(i);
				pause(0.5);
			end
			prog.stop();
		end
	end



	
end

function str = c_relTime_toStr(relTimeSec)

	remainder = relTimeSec;

	days = 0;
% 	days = fix(remainder / (60*60*24));
% 	remainder = rem(remainder,(60*60*24));
	
	hours = fix(remainder / (60*60));
	remainder = rem(remainder,(60*60));
	
	minutes = fix(remainder / 60);
	seconds = rem(remainder,60);
	
	if days ~= 0
		str =sprintf('%d d %d h %d m %4.3g s',days,hours,minutes,seconds);
	elseif hours ~= 0
		str =sprintf(	  '%d h %d m %4.3g s'	 ,hours,minutes,seconds);
	elseif minutes ~= 0
		str =sprintf(		   '%d m %4.3g s'		   ,minutes,seconds);
	else
		str =sprintf(				'%4.3g s'				   ,seconds);
	end
end
	
function str = c_dateNum_toStr(absDateNum,relToDateNum)
	if nargin < 2
		relToDateNum = now();
	end
	
	%TODO: subtract comment elements if they are the same (i.e. don't show month if it is the same as current)

	str = datestr(absDateNum);
end
	
