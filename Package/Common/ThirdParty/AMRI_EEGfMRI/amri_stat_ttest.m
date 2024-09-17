%% 
% amri_stat_ttest: student's t test
%    (Used only when statistic toolbox is not available)
%
% Usage
%    [h,p,ci,stats] = amri_stat_ttest(x); % against a zero mean t-distribution
%    [h,p,ci,stats] = amri_stat_ttest(x,y); % paired ttest
%    [h,p,ci,stats] = amri_stat_ttest(x,y,alpha); % given alpha threshold
% 
% Inputs
%     x: 1-D vector 
%     y: 1-D vector or a scalar value {default: 0}
% alpha: significance level {default: 0.05}
%  tail: {'left','both','right'} {default: 'both'}
%
% Outputs
%     h: test result 1 or 0
%     p: p-value
%    ci: confidence interval (nan)
% stats: tval and df 
%
% See also
%   amri_stat_tcdf, spm_Tcdf
%
% Version
%   1.00

%% DISCLAIMER AND CONDITIONS FOR USE:
%     This software is distributed under the terms of the GNU General Public
%     License v3, dated 2007/06/29 (see http://www.gnu.org/licenses/gpl.html).
%     Use of this software is at the user's OWN RISK. Functionality is not
%     guaranteed by creator nor modifier(s), if any. This software may be freely
%     copied and distributed. The original header MUST stay part of the file and
%     modifications MUST be reported in the 'MODIFICATION HISTORY'-section,
%     including the modification date and the name of the modifier.

%% MODIFICATION HISTORY
% 1.00 - 07/07/2010 - ZMLIU - create the file
%        16/11/2011 - JAdZ  - v1.00 included in amri_eegfmri_toolbox v0.1

%%
function [h,p,ci,stats] = amri_stat_ttest(x,m,alpha,tail)

if nargin<1
    eval('help amri_stat_ttest');
    return
end

if nargin < 2 || isempty(m)
    m = 0;
elseif ~isscalar(m) % paired t-test
    if ~isequal(size(m),size(x))
        error('amri_stat_ttest():InputSizeMismatch');
    end
    x = x - m;
    m = 0;
end

x = x(:);
m = m(:);

if nargin < 3 || isempty(alpha)
    alpha = 0.05;
elseif ~isscalar(alpha) || alpha <= 0 || alpha >= 1
    error('amri_stat_ttest():BadAlpha');
end

if nargin < 4 || isempty(tail)
    tail = 0;    % two-tailed test
elseif ischar(tail) && (size(tail,1)==1)
    tail = find(strncmpi(tail,{'left','both','right'},length(tail))) - 2;
end

if ~isscalar(tail) || ~isnumeric(tail)
    error('amri_stat_ttest():BadTail');
end

% samplesize is the number of non-nan elements 
nans = isnan(x);
if any(nans(:))
    samplesize = sum(~nans);
else
    samplesize = length(x); % a scalar, => a scalar call to tinv
end
% degree of freedom
df = max(samplesize-1,0);
% mean, std and ser
xmean = mean(x(~nans));
sdpop = std(x(~nans));
ser = sdpop ./ sqrt(samplesize);
tval = (xmean - m) ./ ser;
if nargout > 3
    stats = struct('tstat', tval, 'df', cast(df,class(tval)), 'sd', sdpop);
    if isscalar(df) && ~isscalar(tval)
        stats.df = repmat(stats.df,size(tval));
    end
end

% if exist('spm_Tcdf')==2 %#ok<EXIST>
%     p0 = spm_Tcdf(-abs(tval),df);
% else
    p0 = amri_stat_tcdf(-abs(tval),df);
% end

if tail==0 % two-tailed test
    p = 2 * p0;
elseif tail==1  % right one-tailed test
    p = p0;
elseif tail==2 % left one-tailed test
    p = p0;
else
    error('amri_stat_ttest(): BadTail');
end
h = cast(p <= alpha, class(p));
ci=nan; % not implemented


% function p = my_tcdf(x,v)
% 
% % Initialize P.
% if isa(x,'single') || isa(v,'single')
%     p = NaN(size(x),'single');
% else
%     p = NaN(size(x));
% end
% 
% nans = (isnan(x) | ~(0<v)); %  v==NaN ==> (0<v)==false
% 
% % First compute F(-|x|).
% %
% % Cauchy distribution.  See Devroye pages 29 and 450.
% cauchy = (v == 1);
% p(cauchy) = .5 + atan(x(cauchy))/pi;
% 
% % Normal Approximation.
% normal = 0;
% 
% % See Abramowitz and Stegun, formulas 26.5.27 and 26.7.1
% gen = ~(cauchy | normal | nans);
% if any(gen(:))
%     gen = find(gen);
%     t = (v(gen) < x(gen).^2);
%     if any(t)
%         % For small v, form v/(v+x^2) to maintain precision
%         tg = gen(t);
%         p(tg) = betainc(v(tg) ./ (v(tg) + x(tg).^2), v(tg)/2, 0.5)/2;
%         xpos = (x(tg)>0);
%         if any(xpos)
%             p(tg(xpos)) = 1-p(tg(xpos));
%         end
%     end
%     
%     t = (v(gen) >= x(gen).^2);
%     if any(t)
%         % For large v, form x^2/(v+x^2) to maintain precision
%         tg = gen(t);
%         p(tg) = 0.5 + sign(x(tg)) .* ...
%                 betainc(x(tg).^2 ./ (v(tg) + x(tg).^2), 0.5, v(tg)/2)/2;
%     end
% end
% % Make the result exact for the median.
% p(x == 0 & ~nans) = 0.5;
% 
% 
