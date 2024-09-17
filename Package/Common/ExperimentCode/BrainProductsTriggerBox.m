classdef BrainProductsTriggerBox < handle
	%% BrainProductsTriggerBox - class to interface with Brain Products' Trigger Box via its virtual serial port
	%
	% Example usage:
	%		tb = BrainProductsTriggerBox();
	%		tb.sendTrigger(1); % send trigger S1
	%
	% To specificy COM port instead of autodetecting, initialize with
	%		tb = BrainProductsTriggerBox('COMPort','COM1');
	%
	% To not autoterminate triggers and instead control trigger duration, use
	%		tb = BrainProductsTriggerBox('doAutoTerminate',false);
	%		tb.sendTrigger(1);
	%		pause(0.1);
	%		tb.sendTrigger(0); % terminate previous trigger
	%
	% To test with loop of trigger values:
	%       BrainProductsTriggerBox.test()
	%

	%% Instance variables
	properties
		s; % serial port handle
		COMPort;
		BaudRate;
		doAutoTerminate;
	end
	
	%% Instance methods
	methods
		%% constructor
		function obj = BrainProductsTriggerBox(varargin)
			p = inputParser();
			p.addParameter('COMPort','',@ischar);
			p.addParameter('BaudRate',57600,@(x) ismember(x,[9600, 19200, 57600, 115200]));
			p.addParameter('doAutoTerminate',true,@islogical); % whether to automatically send a zero immediately after each trigger
															% (if false, repeated triggers will not be counted)
			p.parse(varargin{:});
			
			% copy parsed inputs to object (assuming variable names are all identical)
			for iP = 1:length(p.Parameters)
				obj.(p.Parameters{iP}) = p.Results.(p.Parameters{iP});
			end
			
			if isempty(obj.COMPort)
				% autoset COM port to last available port on system
				hwinfo = instrhwinfo('serial');
				availablePorts = hwinfo.AvailableSerialPorts;
				if isempty(availablePorts)
					error('No ports available');
				end
				obj.COMPort = availablePorts{end};
				fprintf('TriggerBox: Autoselected COM port %s\n', obj.COMPort);
			else
				fprintf('TriggerBox: Selected COM port %s\n', obj.COMPort);
			end
			
			% connect to port
			obj.s = serial(obj.COMPort);
			
			% set baud rate
			% (it's not clear whether the specified baud rate actually makes a difference for
			% virtual serial port, but if it does make a difference, higher speeds probably have
			% lower latencies)
			set(obj.s,'BaudRate',obj.BaudRate); 
			
			% open port for writing
			fopen(obj.s); % this will generate error if port is not available / does not exist
		end
		
		%% destructor
		function delete(obj)
			fclose(obj.s);
			delete(obj.s);
		end
		
		%% send trigger
		function sendTrigger(obj,triggerNum)
			if triggerNum < 0 || triggerNum > 255
				error('Invalid trigger value: %d' );
			end
			fwrite(obj.s,uint8(triggerNum));
			if obj.doAutoTerminate
				fwrite(obj.s,uint8(0));
			end
		end
	end
	
	%% Class methods
	methods(Static)
		function test(varargin)
			tb = BrainProductsTriggerBox(varargin{:});
			while true
				for i=1:255
					fprintf('Sending %3d (%s)\n',i,dec2bin(i,8));
					tb.sendTrigger(i);
					pause(0.5);
				end
			end
		end
	end
end
				
				