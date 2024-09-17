classdef TMSTriggerer < handle
	%%
	properties
		numPulses = 0;
		doSimulate;
	end
	
	properties(Access=protected)
		maxStimRate; % in Hz
		maxNumPulses;
		triggerDev;
		triggerCode;
		triggerCOMPort;
		intensityRelative;
		intensityAbsolute;
		RMT;
		pulseHistory;
	end
	
	%% Instance methods
	methods
		function o = TMSTriggerer(varargin)
			p = inputParser();
			p.addParameter('maxStimRate',1.1,@isscalar); % Hz
			p.addParameter('intensityRelative',120,@(x) isempty(x) || isscalar(x)); % relative to RMT, in %
			p.addParameter('intensityAbsolute',[],@(x) isempty(x) || isscalar(x));
			p.addParameter('RMT',[],@isscalar);
			p.addParameter('triggerCOMPort','',@ischar);
			p.addParameter('triggerCode',1,@isscalar); 
			p.addParameter('doSimulate',false,@islogical);
			p.parse(varargin{:});
			s = p.Results;
			
			% copy parsed input to object properties of the same name
			fieldNames = fieldnames(s);
			for iF=1:length(fieldNames)
				if isprop(o,p.Parameters{iF})
					o.(fieldNames{iF}) = s.(fieldNames{iF});
				end
			end
			
			o.pulseHistory = c_RingBuffer(1801,'dataIsStruct',true);
			
			if sum(ismember({'intensityRelative','intensiteAbsolute'},p.UsingDefaults)) ~= 1
				error('Only one of intensityRelative and intensityAbsolute should be non-empty');
			end
			if ~isempty(o.intensityAbsolute) 
				if isempty(o.RMT)
					error('RMT must be specified to convert absolute intensity to relative intensity');
				end
				o.intensityRelative = o.intensityAbsolute / o.RMT * 100;
				c_saySingle('Relative intensity calculated to be %.3g %% from absolute intensity %.3g / RMT %.3g',...
					o.intensityRelative, o.intensityAbsolute,o.RMT);
			end
			
			if o.intensityRelative < 2
				warning('Unexpectedly low intensity (%.3g). Was it specified in absolute units rather than percent?',o.intensityRelative)
				keyboard
			end
			
			% connect to trigger device
			o.connect();
		end
		
		function connect(o)
			if ~o.doSimulate
				o.triggerDev = BrainProductsTriggerBox('COMPort',o.triggerCOMPort);
			end
		end
		
		function applyPulse(o)
			
			if ~o.doSimulate
				o.triggerDev.sendTrigger(o.triggerCode);
			else
				c_saySingle('Simulated pulse, not actually applying.');
			end
			
			pulse = struct();
			pulse.time = datetime();
			pulse.intensity = o.intensityRelative;
			o.pulseHistory.pushBack(pulse);
			
			o.checkRecentPulseHistory();
		end
		
		function checkRecentPulseHistory(o)
			pulses = o.pulseHistory.peekBack(inf);
			
			if ~isempty(pulses)
				pulseTimes = c_struct_mapToArray(pulses,{'time'});
				pulseTimes = seconds(pulseTimes - pulseTimes(1));
				maxIntensity = max(cell2mat({pulses.intensity}));
				assertPulseTimesSafe(o,pulseTimes,maxIntensity,true);
			end
		end
		
		function assertPulseTimesSafe(o,pulseTimes,maxIntensity,doAssumePastChecked)
			
			if nargin < 4
				doAssumePastChecked = false;
			end
			
			if ~doAssumePastChecked
				for iP = length(pulseTimes):-1:1
					o.assertPulseTimesSafe(pulseTimes(1:iP),maxIntensity,true);
				end
				return;
			end
			
			% only apply constraints to most recent pulses as applicable, assuming this check has been run for each previous pulse as well
			if maxIntensity <= 2
				error('Unexpectedly small intensity. Should be specified in percent (e.g. 120, not 1.2)');
			end
			% based on table 4 from Rossi et al. 2009
			freqs = [1 5 10 20 25];
			if maxIntensity <= 90
				limits = [1800 10 5 2.05 1.28];
			elseif maxIntensity <= 100
				limits = [1800 10 5 2.05 1.28];
			elseif maxIntensity <= 110
				limits = [1800 10 5 1.6 0.84];
			elseif maxIntensity <= 120
				limits = [360 10 4.2 1 0.4];
			elseif maxIntensity <= 130
				limits = [50 10 2.9 0.55 0.24];
			else
				error('Unexpectedly high intensity');
			end
			
			for iF = length(freqs):-1:1
				indices = (pulseTimes(end) - pulseTimes(:)) < (limits(iF) + 60); % assuming adjacent trains can be considered distinct if separated by 60 s
				numPulsesInTimespan = sum(indices);
				if numPulsesInTimespan > 1
					lowerFreq = 0;
					if iF > 1
						lowerFreq = freqs(iF-1);
					end
					dt = diff(pulseTimes(indices));
					relevantIndices = 1./dt > lowerFreq; % time points where ITI corresponded to a freq in or exceeding current range
					firstIndex = find(relevantIndices,1,'first');
					lastIndex = find(relevantIndices,1,'last');
					if ~isempty(firstIndex) 
						trainDuration = pulseTimes(lastIndex+1) - pulseTimes(firstIndex);
						if trainDuration > limits(iF)
							error('Safety limits exceed. Train duration %.4g s > %.4g s with max freq of %.3g Hz at intensity of %.3g %% RMT',...
								trainDuration, limits(iF), max(1./dt), maxIntensity);
						end
					end
				end
			end
			if any(1./diff(pulseTimes) > max(freqs))
				error('Maximum safe frequency exceeded. Actual frequency: %.3g Hz',max(1./diff(pulseTimes)));
			end
			
			if ~isempty(o.maxStimRate) && any(1./diff(pulseTimes) > o.maxStimRate)
				error('User-set maximum frequency of %.3g Hz exceeded. Actual frequency: %.3g Hz',...
					o.maxStimRate, max(1./diff(pulseTimes)));
			end
		end
	end
	
	%% Static methods
	methods(Static)
		function addDependencies
			persistent pathModified;
			if isempty(pathModified)
				mfilepath=fileparts(which(mfilename));
				addpath(fullfile(mfilepath,'../'));
				pathModified = true;
			end
		end
		
		function jitterStim(varargin)
			p = inputParser();
			p.addParameter('ITISpan',[2 4],@(x) isvector(x) && length(x)==2); % min and max intertrial intervals, in s
			p.addParameter('numPulses',30,@isscalar);
			p.addParameter('intensityRelative',120,@isscalar);
			p.addParameter('doSaveHistory',true,@islogical);
			p.addParameter('saveDirectory','./',@ischar);
			p.addParameter('doSimulate',false,@islogical);
			p.parse(varargin{:});
			s = p.Results;
			
			TMSTriggerer.addDependencies();
			
			assert(s.ITISpan(2) >= s.ITISpan(1));
			
			pulseITIs = rand(1,s.numPulses)*diff(s.ITISpan) + s.ITISpan(1);
			pulseTimes = cumsum(pulseITIs);
			
			actualPulseITIs = nan(size(pulseITIs));
			actualPulseTimes = nan(size(pulseTimes));
			
			
			TMS = TMSTriggerer('doSimulate',s.doSimulate);
			c_say('Checking that planned pulse times are safe');
			TMS.assertPulseTimesSafe(pulseTimes,120);
			c_sayDone('Safe');
			
			c_say('Setup finished. Waiting for input to start');
			c_saySingle('Paused'); 
			pause
			c_sayDone();
			prog = c_progress(s.numPulses,'Pulse %d/%d','doAssumeUpdateAtEnd',true);
			prog.start('Starting stimulation');
			startTime = datetime;
			prevPulseTime = startTime; % dummy init value
			pulseITIs_s = seconds(pulseITIs);
			for iP = 1:s.numPulses;
				currentTime = datetime;
				deltaTime = (currentTime - prevPulseTime) - pulseITIs_s(iP);
				teps = 0.5e-3;
				teps_s = seconds(teps);
				% on a test run, this produces an undesired deviation from assigned ITIs of about +1 ms / - 0.1 ms.
				% This is better than observed Magstim rTMS setup which appears to vary about + 50 ms / - 0 ms.
				while deltaTime < -teps_s
					if deltaTime > teps_s*10
						pause(-seconds(deltaTime)/2);
					end
					currentTime = datetime;
					deltaTime = (currentTime - prevPulseTime) - pulseITIs_s(iP); % to enforce times between consecutive pulses
					% deltaTime = currentTime - (startTime + seconds(pulseTimes(iP))); to enforce absolute times
				end
				TMS.applyPulse();
				actualPulseITIs(iP) = seconds(currentTime - prevPulseTime);
				actualPulseTimes(iP) = seconds(currentTime - startTime);
				itiDiff = (seconds(currentTime-prevPulseTime) - pulseITIs(iP));
				prog.update(iP,'Desired ITI: %.3g s \t Actual ITI: %.3g s \t Diff: %.5g ms',...
					pulseITIs(iP),...
					actualPulseITIs(iP),...
					itiDiff*1e3);
				if abs(itiDiff) > 50e-3 
					warning('Actual ITI (%.3g s) differs from desired ITI (%.3g s) by %.4g ms',...
						actualPulseITIs(iP),...
						pulseITIs(iP),...
						itiDiff*1e3);
				end
				prevPulseTime = currentTime;
			end
			prog.stop('End of stimulation');
			
			if s.doSaveHistory
				filename = ['TMSTriggerHistory_' datestr(now,'yymmddHHMMSS') '.mat'];
				path = fullfile(s.saveDirectory,filename);
				save(path,...
					's',...
					'pulseITIs',...
					'pulseTimes',...
					'actualPulseITIs',...
					'actualPulseTimes');
				c_saySingle('Saved history to %s',path);
			end			
		end
		
		function testSafetyCheck()
			
			TMSTriggerer.addDependencies();
			
			tests = struct('freq',{},'intensity',{},'numPulses',{},'isSafe',{});
			test = struct(...
				'freq',1,'intensity',120,'numPulses',360,'isSafe',true);
			tests = [tests, test];
			
			test = struct(...
				'freq',1,'intensity',120,'numPulses',370,'isSafe',false);
			tests = [tests, test];
			
			test = struct(...
				'freq',1,'intensity',110,'numPulses',1800,'isSafe',true);
			tests = [tests, test];
			
			test = struct(...
				'freq',1,'intensity',110,'numPulses',1802,'isSafe',false);
			tests = [tests, test];
			
			test = struct(...
				'freq',1.1,'intensity',90,'numPulses',100,'isSafe',false); 
			tests = [tests, test];
			
			test = struct(...
				'freq',0.9,'intensity',90,'numPulses',100,'isSafe',true); 
			tests = [tests, test];
			
			test = struct(...
				'freq',0.1,'intensity',90,'numPulses',100,'isSafe',true); 
			tests = [tests, test];
			
			test = struct(...
				'freq',4.9,'intensity',90,'numPulses',10,'isSafe',true); 
			tests = [tests, test];
			
			test = struct(...
				'freq',5.1,'intensity',90,'numPulses',30,'isSafe',false); 
			tests = [tests, test];
			
			% technically according to consensus paper very low frequency trains should still be
			% limited to 1800 s, not 1800 pulses...
			test = struct(...
				'freq',0.1,'intensity',90,'numPulses',1800,'isSafe',false); 
			tests = [tests, test];
			
			test = struct(...
				'freq',26,'intensity',90,'numPulses',2,'isSafe',false); 
			tests = [tests, test];
			
			test = struct(...
				'freq',1,'intensity',140,'numPulses',2,'isSafe',false); 
			tests = [tests, test];
			
			prog = c_progress(length(tests),'Evaluating test case %d/%d');
			prog.start('Testing safety check');
			for iT = 1:length(tests)
				prog.updateStart();
				test = tests(iT);
				c_saySingleMultiline('Testing %s',c_toString(test));
				pulseTimes = 0:1/test.freq:(test.numPulses-1)/test.freq;
				assert(length(pulseTimes)==test.numPulses);
				TMS = TMSTriggerer('doSimulate',true,'maxStimRate',test.freq*1.1);
				try 
					TMS.assertPulseTimesSafe(pulseTimes,test.intensity);
					caughtError = false;
				catch E
					caughtError = true;
					c_saySingle(E.message);
				end
				if test.isSafe && ~caughtError
					c_saySingle('Correctly classified as safe');
				elseif ~test.isSafe && caughtError
					c_saySingle('Correctly classified as unsafe');
				elseif test.isSafe
					c_saySingle('Incorrectly classified as unsafe');
					keyboard
				else
					c_saySingle('Incorrectly classified as safe!');
					keyboard
				end
				prog.updateEnd();
			end
			prog.stop();
		end
	end
end