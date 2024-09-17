function Template_MenuGUI(varargin)

	%% input parsing and default parameters

	p = inputParser();
	p.addParameter('prespecifiedProcedures',{},@iscell);
	p.parse(varargin{:});

	s = p.Results;
	
	
	%% procedure selection

	procedureTree = {...
		'_root_',...
		'Template procedure',...
		{'Template category',...
			'Template subprocedure 1',...
			'Template subprocedure 2',...
		},...
		'Keyboard',...
		'End',...
	};

	doEnd = false;
	while ~doEnd

		if isempty(s.prespecifiedProcedures)
			c_say('Requesting user input on which procedures to run...');
			resp = c_menu(['Choose procedure to run'],procedureTree);
			proceduresToRun = {c_tree_getSubtreeAtNodeIndex(procedureTree,resp)};
			c_sayDone();
		else
			proceduresToRun = s.prespecifiedProcedures;
			s.prespecifiedProcedures = {};
		end
		
		didError = false;
		procedureIndex = 0;
		while procedureIndex < length(proceduresToRun) && ~didError
			procedureIndex = procedureIndex + 1;
			procedureToRun = proceduresToRun{procedureIndex};

			c_say('Running procedure ''%s''...',procedureToRun);
			
			% parse any additional procedure args from end of name (e.g. 'ProcedureName: arg1, arg2')
			procedureArgs = {};
			tmp = find(procedureToRun==':',1,'first');
			if ~isempty(tmp)
				procedureArgs = strtrim(strsplit(procedureToRun(tmp+1:end),','));
				procedureToRun = procedureToRun(1:tmp-1);
			end

			switch(procedureToRun)
				case 'Keyboard'
					keyboard
				case 'End'
					c_sayDone();
					doEnd = true;
					break;
				case 'Resize figure' %: input: left, bottom, width, height (normalized units)
					% (an example of a procedure with input arguments)
					
					if length(procedureArgs) ~= 4
						warning('Incorrect input');
						didError = true; continue;
					end
					
					pause(0.1);
					
					resizeFigureWindow(gcf,str2double(procedureArgs));
					
					pause(0.1);
				
				case 'Template procedure'
					if false
						warning('Problem encountered');
						didError = true; continue;
					end
					
					c_saySingle('Problem not encountered');
					
					proceduresToRun = c_insertProcedure('Template procedure follow-up',proceduresToRun,procedureIndex);
					
				case 'Template procedure follow-up'
					
					c_saySingle('Follow up');
				
				otherwise
					warning('Unrecognized procedure label (%s), skipping.',procedureToRun);
			end
			c_sayDone();
		end
		
		if didError
			c_sayDone();
			warning('Error detected. Any pre-specified procedures cleared.');
		end
	end
end
