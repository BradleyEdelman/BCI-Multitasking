function handles = c_plot_scatter3(varargin)
p = inputParser();
p.addRequired('pts',@(x) ismatrix(x) && size(x,2)==3);
p.addParameter('ptSizes',[],@(x) isempty(x) || (isnumeric(x) && (isscalar(x) || isvector(x))))
p.addParameter('ptColors',[],@ismatrix);
p.addParameter('ptLabels',[],@iscellstr);
p.addParameter('doPlotLabels',false,@(x) islogical(x) || (ischar(x) && strcmpi(x,'auto'))); % 'auto'=plot if specified
p.addParameter('labelColors',[0.4 0.4 0.4],@ismatrix);
p.addParameter('labelLineColors',[0.4 0.4 0.4],@ismatrix);
p.addParameter('markerType','sphere',@ischar); % valid: 'sphere' or any of scatter3's 'o+*.xsd^v><ph' or 'none'
p.addParameter('aspectRatio',[],@isvector); % for drawing 3D marker shapes such as sphere, what aspect ratio to use
p.addParameter('doRelativeSize',false,@islogical);
p.addParameter('axis',[],@ishandle);
p.addParameter('sphereN',20,@isscalar);
p.addParameter('patchArgs',{'EdgeColor','none'},@iscell);
p.addParameter('scatter3Args',{},@iscell);
p.parse(varargin{:});
s = p.Results;

if isempty(s.axis)
	s.axis = gca;
end

numPts = size(s.pts,1);

if isempty(s.aspectRatio)
	% assume axes will be equal aspect ratio
	s.aspectRatio = [1 1 1];
end

if isempty(s.ptSizes)
	s.ptSizes = 5;
end
if isscalar(s.ptSizes)
	s.ptSizes = repmat(s.ptSizes,numPts,1);
end
% make point sizes relative to largest effective dimension
% (e.g. size of 1 corresponds to 1% of max xyz width, accounting for aspect ratio)
if s.doRelativeSize
	xyzLim = extrema(s.pts,[],1);
	xyzWidths = diff(xyzLim,1,2)';
	effectiveWidths = s.aspectRatio.*xyzWidths;
	s.ptSizes = s.ptSizes / max(effectiveWidths) * 100;
end

if isvector(s.ptSizes)
	s.ptSizes = bsxfun(@times,s.ptSizes,s.aspectRatio);
end

handles = [];

if ~isempty(s.ptLabels)
	if (islogical(s.doPlotLabels) && s.doPlotLabels) || (ischar(s.doPlotLabels) && strcmpi(s.doPlotLabels,'auto'))
		h1 = [];
		h2 = [];
		centerXYZ = nanmean(s.pts,1);
		for iP = 1:numPts
			labelCoords = s.pts(iP,:) + (s.pts(iP,:)-centerXYZ)*0.2;
			args = c_mat_sliceToCell(labelCoords);
			h1(iP) = text(args{:},s.ptLabels{iP},'Color',s.labelColors(mod(iP-1,size(s.labelColors,1))+1,:));
			linePts = cat(1,labelCoords,s.pts(iP,:));
			args = c_mat_sliceToCell(linePts,2);
			h2(iP) = line(args{:},'Color',s.labelLineColors(mod(iP-1,size(s.labelLineColors,1))+1,:));
		end
		handles = cat(2,handles,h1,h2);
	end
end



customMarkerTypes = {'sphere'};
if ismember(s.markerType,customMarkerTypes)
	% use custom plotting code
	switch s.markerType
		case 'sphere'
			[x,y,z] = sphere(s.sphereN);
			spherePatch = surf2patch(x,y,z);
			for iP = 1:numPts
				tmpPatch = spherePatch;
				tmpPatch.vertices = bsxfun(@times,tmpPatch.vertices,s.ptSizes(iP,:));
				tmpPatch.vertices = bsxfun(@plus,tmpPatch.vertices,s.pts(iP,:));
				patchArgs = {'parent',s.axis};
				if ~isempty(s.ptColors)
					if size(s.ptColors,1)==1
						patchArgs = [patchArgs,'FaceColor',s.ptColors];
					else
						patchArgs = [patchArgs,'FaceColor',s.ptColors(iP,:)];
					end
				end
				patchArgs = [patchArgs, s.patchArgs];
					
				h = patch(tmpPatch,patchArgs{:});
				handles = cat(2,handles,h);
				if iP==1
					hold(s.axis,'on');
				end
			end
		otherwise
			error('Invalid marker type');
	end
else
	% use built-in scatter3
	xyzArgs = c_mat_sliceToCell(s.pts,2);
	ptColors = [0,0,0];
	if ~isempty(s.ptColors)
		ptColors = s.ptColors;
	end
	h = scatter3(xyzArgs{:},mean(s.ptSizes,2)*10,ptColors,s.markerType,s.scatter3Args{:});
	handles = cat(2,handles,h);
end
end
