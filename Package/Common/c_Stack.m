classdef c_Stack < handle
	properties(Access=protected)
		stack = {};
	end
		
	methods
		function o = c_Stack()
		end
		
		function push(o,item)
			o.stack{end+1} = item;
		end
		
		function item = pop(o)
			if o.isempty()
				error('Stack is empty');
			end
			item = o.stack{end};
			o.stack = o.stack(1:end-1);
		end
		
		function item = peek(o)
			if o.isempty()
				error('Stack is empty');
			end
			item = o.stack{end};
		end
		
		function clear(o)
			o.stack = {};
		end
		
		function l = length(o)
			l = length(o.stack);
		end
		
		function e = isempty(o)
			e = isempty(o.stack);
		end
	end
end