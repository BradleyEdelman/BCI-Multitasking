classdef c_RunCallbackOnDelete < handle
	properties
		callback = [];
	end
	
	methods
		function o = c_RunCallbackOnDelete(callback)
			assert(isa(callback,'function_handle'));
			o.callback = callback;
		end
		
		function delete(o)
			if ~isempty(o.callback)
				o.callback();
			end
		end
		
		function cancel(o)
			o.callback = [];
		end
	end
end