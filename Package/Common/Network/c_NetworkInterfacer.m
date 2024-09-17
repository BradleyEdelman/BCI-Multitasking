classdef c_NetworkInterfacer < handle
	properties
		IP;
		port;
		protocol;
		con = [];
		method;
		doDebug;
		isServer;
		connectionTimeout;
	end
	
	properties(Dependent,SetAccess=protected)
		isTCP;
		isUDP;
	end
	
	properties(Access=protected)
		jtcpBufferLength;
		jtcpDoUseHelperClass;
		jtcpHelperClassPath = '';
	end
	
	methods
		%% constructor
		function o = c_NetworkInterfacer(varargin)
			p = inputParser();
			p.addParameter('IP','127.0.0.1',@ischar);
			p.addParameter('port',5555,@isscalar);
			p.addParameter('protocol','TCP',@(x) ischar(x) && ismember(x,{'UDP','TCP'}));
			p.addParameter('tcp_doUsePnet',false,@islogical);
			p.addParameter('doDebug',false,@islogical);
			p.addParameter('jtcpBufferLength',5e3,@isscalar);
			p.addParameter('jtcpDoUseHelperClass',false,@islogical);
			p.addParameter('isServer',false,@islogical);
			p.addParameter('connectionTimeout',1e3,@isscalar);
			p.parse(varargin{:});
			
			% copy parameters to class properties with the same names
			for iP = 1:length(p.Parameters)
				if isprop(o,p.Parameters{iP})
					o.(p.Parameters{iP}) = p.Results.(p.Parameters{iP});
				end
			end
		
			switch(o.protocol)
				case 'UDP'
					error('UDP not yet supported');
				case 'TCP'
					if p.Results.tcp_doUsePnet
						o.method = 'pnet-tcp';
					else
						o.method = 'jtcp';
					end
				otherwise
					error('Invalid protocol');
			end
			
			if strcmpi(o.method,'jtcp') && o.jtcpDoUseHelperClass
				% look for java helper class
				path = which('jtcp');
				dir = fileparts(path);
				helperPath = fullfile(dir,'Java','DataReader.class');
				if exist(helperPath,'file')
					% found helper class
					o.jtcpHelperClassPath = fileparts(helperPath);
				else
					warning('jtcp helper class not located at %s. Not using.',helperPath)
					o.jtcpDoUseHelperClass = false;
					o.jtcpHelperClassPath = '';
				end
			end
			
			o.connect();
		end
		
		%% destructor
		function delete(o)
			o.close();
		end
		%% connection
		function connect(o)
			switch(o.method)
				case 'jtcp'
					try
						% if timeout is a multiple of 1 s, break into smaller chunks to allow interruption
						shorterTimeout = 1e3;
						if o.connectionTimeout > shorterTimeout && (isinf(o.connectionTimeout) || mod(o.connectionTimeout,shorterTimeout)==0)
							numRepeats = o.connectionTimeout / shorterTimeout;
							counter = 0;
							o.con = [];
							
							while counter < numRepeats && isempty(o.con)
								try
									counter = counter + 1;
									if o.isServer
										o.con = jtcp('accept', o.port,...
											'serialize',false,...
											'timeout',shorterTimeout,...
											'receiveBufferSize',o.jtcpBufferLength);
									else
										o.con = jtcp('request', o.IP, o.port,...
											'serialize',false,...
											'timeout',shorterTimeout,...
											'receiveBufferSize',o.jtcpBufferLength);
									end
								catch e
									if ~(o.isServer && strcmp(e.identifier,'jtcp:connectionAcceptFailed')) && ...
											~(~o.isServer && strcmp(e.identifier,'jtcp:connectionRequestFailed')) 
										rethrow(e)
									end
								end
							end
						else
							if o.isServer
								o.con = jtcp('accept', o.port,...
										'serialize',false,...
										'timeout',o.connectionTimeout,...
										'receiveBufferSize',o.jtcpBufferLength);
							else
								o.con = jtcp('request', o.IP, o.port,...
									'serialize',false,...
									'timeout',o.connectionTimeout,...
									'receiveBufferSize',o.jtcpBufferLength);
							end
						end

					catch e
						if strcmp(e.identifier,'jtcp:connectionRequestFailed') || strcmp(e.identifier,'jtcp:connectionAcceptFailed')
							warning('Failed to connect. Is server running?');
							o.con = [];
						else
							rethrow(e)
						end
					end
				case 'pnet-tcp'
					o.con = pnet('tcpconnect', o.IP, o.port);
					% Check established connection and display a message
					stat = pnet(o.con,'status');
					if stat <= 0
						warning('Failed to connect. Is server running?');
						o.con = [];
					end
				otherwise
					error('Invalid method');
			end
			if ~isempty(o.con)
				if o.doDebug
					c_saySingle('Connection to %s:%d successful',o.IP,o.port);
				end
			end
		end
		
		function iscon = isConnected(o)
			iscon = ~isempty(o.con);
		end
		
		function close(o)
			if ~isempty(o.con)
				switch(o.method)
					case 'jtcp'
						jtcp('close',o.con);
					case 'pnet-tcp'
						pnet('closeall'); %TODO: probably replace this with a more specific call to avoid closing other objects' connections
					otherwise
						error('Invalid method');
				end	
				o.con = [];
			end
			if o.doDebug
				c_saySingle('Connection closed');
			end
		end
		
		
		%% receiving 
		function bytesRead = tryRead(o,varargin)
			p = inputParser();
			p.addParameter('numBytes',[],@(x) isscalar(x) || isempty(x));
			p.addParameter('maxNumBytes',[],@(x) isscalar(x) || isempty(x));
			p.addParameter('doBlock',false,@islogical);
			p.parse(varargin{:});
			s = p.Results;
			
			bytesRead = [];
			
			if s.doBlock
				keyboard %TODO: implement blocking calls
			else
				switch(o.method)
					case 'jtcp'
						numAvailableBytes = o.con.socketInputStream.available;
						if numAvailableBytes == o.jtcpBufferLength
							warning('Buffer overflow detected.');
						end
						
						if isempty(s.numBytes) || numAvailableBytes >= s.numBytes
							args = {};
							if ~isempty(s.maxNumBytes)
								args = [args,'MAXNUMBYTES',s.maxNumBytes];
							elseif ~isempty(s.numBytes)
								args = [args,'NUMBYTES',s.numBytes];
							end
							if o.jtcpDoUseHelperClass
								args = [args,'helperClassPath',o.jtcpHelperClassPath];
							end
							bytesRead = jtcp('READ',o.con, args{:});
						else
							bytesRead = [];
						end
					case 'pnet-tcp'
						keyboard %TODO
					otherwise
						error('Invalid method');
				end
			end
		end
		
		function numBytes = numBytesAvailable(o)
			switch(o.method)
				case 'jtcp'
					numBytes = o.con.socketInputStream.available;
				otherwise
					keyboard %TODO
			end
		end
		
		%% sending
		function send(o,toSend)
			assert(iscell(toSend) || isvector(toSend));
			
			if ~iscell(toSend)
				toSend = {toSend};
			end
			
			% crude serialization
			for i = 1:length(toSend)
				for j = 1:length(toSend{i})
					assert(isscalar(toSend{i}(j)));
					o.sendBytes(typecast(toSend{i}(j),'int8'));
				end
			end
		end
		
		function sendBytes(o,bytesToSend)
			assert(isa(bytesToSend,'int8'));
			switch(o.method)
				case 'jtcp'
					jtcp('write',o.con,bytesToSend);
				case 'pnet-tcp'
					keyboard %TODO
				otherwise
					error('Invalid method');
			end
		end
		
		%% getters/setters
		function isTCP = get.isTCP(o)
			isTCP = strcmpi(o.protocol,'TCP');
		end
		
		function isUDP = get.isUDP(o)
			isUDP = strcmpi(o.protocol,'UDP');
		end
				
	end
	
	methods(Static)
		function addDependencies
			persistent pathModified;
			if isempty(pathModified)
				mfilepath=fileparts(which(mfilename));
				addpath(fullfile(mfilepath,'../ThirdParty/judp'));
				addpath(fullfile(mfilepath,'../ThirdParty/jtcp'));
				addpath(fullfile(mfilepath,'../ThirdParty/pnet'));
				pathModified = true;
			end
		end
	end
end