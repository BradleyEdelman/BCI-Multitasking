function tree = c_bintree_remapNodeValues(varargin)

	if nargin == 0, testfn(); return; end;
	
	p = inputParser();
	p.addRequired('tree',@isstruct);
	p.addRequired('field',@ischar);
	p.addParameter('map_origValues',[],@isvector); %TODO: also support cell maps for string values, etc.
	p.addParameter('map_newValues',[],@isvector);
	p.addParameter('mapFn',[],@(x) isa(x,'function_handle'));
	p.addParameter('nodeSet','all',@(x) ischar(x) && ismember(x,{'all','leaves'})); % valid: 'all','leaves'
	p.addParameter('copyOriginalValuesToField',[],@ischar);
	p.parse(varargin{:});
	s = p.Results;
	tree = s.tree;
	
	if isempty(s.mapFn)
		assert(~isempty(s.map_origValues));
		assert(~isempty(s.map_newValues));
		assert(length(s.map_origValues)==length(s.map_newValues));
		s.mapFn = @(x) mapValues(x,s.map_origValues,s.map_newValues);
	else
		assert(all(ismember({'map_origValues','map_newValues'},p.UsingDefaults)));
	end
	
	if tree.isLeaf || strcmpi(s.nodeSet,'all')
		val = tree.value.(s.field);
		if ~isempty(s.copyOriginalValuesToField)
			tree.value.(s.copyOriginalValuesToField) = val;
		end
		tree.value.(s.field) = s.mapFn(val);
	end
	
	if ~tree.isLeaf
		tree.left = c_bintree_remapNodeValues(tree.left,varargin{2:end});
		tree.right = c_bintree_remapNodeValues(tree.right,varargin{2:end});
	end
end

function mappedVal = mapValues(val,mapFrom,mapTo)
	index = find(ismember(mapFrom,val),1,'first');
	assert(~isempty(index)); % make sure val is in mapFrom
	mappedVal = mapTo(index);
end

		
function testfn()
	dataToCluster = rand(10,3);
	T = linkage(rand(10,3));
	figure; dendrogram(T);
	dists = pdist(dataToCluster,'euclidean');
	leafOrder = optimalleaforder(T,dists);
	tree = c_bintree_constructFromLinkageTree(T);
	newTree = c_bintree_remapNodeValues(tree,'linkageIndex',...
		'map_origValues',leafOrder,...
		'map_newValues',1:length(leafOrder),...
		'nodeSet','leaves',...
		'copyOriginalValuesToField','dataIndex');
	keyboard

end

