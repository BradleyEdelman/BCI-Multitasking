function values = c_bintree_getNodeValues(varargin)

	if nargin == 0, testfn(); return; end;
	
	p = inputParser();
	p.addRequired('tree',@isstruct);
	p.addRequired('field',@ischar);
	p.addParameter('nodeSet','all',@(x) ischar(x) && ismember(x,{'all','leaves'})); % valid: 'all','leaves'
	p.addParameter('valuesField','value',@ischar);
	p.addParameter('nodeIndexField','nodeIndex',@ischar);
	p.addParameter('preallocValues',{},@iscell);
	p.addParameter('valuesFn',[],@(x) isa(x,'function_handle')); % optional function to apply to values for each node before returning (e.g. cell2mat)
	p.parse(varargin{:});
	s = p.Results;
	tree = s.tree;
	
	values = s.preallocValues;
	
	if tree.isLeaf || strcmpi(s.nodeSet,'all')
		if ~c_isFieldAndNonEmpty(tree.value,s.nodeIndexField)
			error('NodeIndexField ''%s'' is not set. Should be assigned prior to calling %s',s.nodeIndexField,mfilename);
		end
		nodeIndex = tree.value.(s.nodeIndexField);
		val = tree.(s.valuesField).(s.field);
		if ~isempty(s.valuesFn)
			val = s.valuesFn(val);
		end
		values{nodeIndex} = val;
	end
	
	if ~tree.isLeaf
		values = c_bintree_getNodeValues(tree.left,s.field,varargin{3:end},'preallocValues',values);
		values = c_bintree_getNodeValues(tree.right,s.field,varargin{3:end},'preallocValues',values);
	end
end

