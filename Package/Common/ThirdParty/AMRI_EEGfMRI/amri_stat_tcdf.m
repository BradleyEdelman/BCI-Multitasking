%%    
% amri_stat_tcdf: Student's t cumulative distrubtion function 
%
% Usage
%    pval = amri_stat_tcdf(tval, df);
% 
% Version
% 1.00

%% DISCLAIMER AND CONDITIONS FOR USE:
%     This software is distributed under the terms of the GNU General Public
%     License v3, dated 2007/06/29 (see http://www.gnu.org/licenses/gpl.html).
%     Use of this software is at the user's OWN RISK. Functionality is not
%     guaranteed by creator nor modifier(s), if any. This software may be freely
%     copied and distributed. The original header MUST stay part of the file and
%     modifications MUST be reported in the 'MODIFICATION HISTORY'-section,
%     including the modification date and the name of the modifier.

%% MODIFICATION HISTORY
% 1.00 - 08/02/2010 - ZMLIU - create the file
%        16/11/2011 - JAdZ  - v1.00 included in amri_eegfmri_toolbox v0.1
 
%%
function p = amri_stat_tcdf(x,v)

% Initialize P.
if isa(x,'single') || isa(v,'single')
    p = NaN(size(x),'single');
else
    p = NaN(size(x));
end

nans = (isnan(x) | ~(0<v)); %  v==NaN ==> (0<v)==false

% First compute F(-|x|).
%
% Cauchy distribution.  See Devroye pages 29 and 450.
cauchy = (v == 1);
p(cauchy) = .5 + atan(x(cauchy))/pi;

% Normal Approximation.
normal = 0;

% See Abramowitz and Stegun, formulas 26.5.27 and 26.7.1
gen = ~(cauchy | normal | nans);
if any(gen(:))
    gen = find(gen);
    t = (v(gen) < x(gen).^2);
    if any(t)
        % For small v, form v/(v+x^2) to maintain precision
        tg = gen(t);
        p(tg) = betainc(v(tg) ./ (v(tg) + x(tg).^2), v(tg)/2, 0.5)/2;
        xpos = (x(tg)>0);
        if any(xpos)
            p(tg(xpos)) = 1-p(tg(xpos));
        end
    end
    
    t = (v(gen) >= x(gen).^2);
    if any(t)
        % For large v, form x^2/(v+x^2) to maintain precision
        tg = gen(t);
        p(tg) = 0.5 + sign(x(tg)) .* ...
                betainc(x(tg).^2 ./ (v(tg) + x(tg).^2), 0.5, v(tg)/2)/2;
    end
end
% Make the result exact for the median.
p(x == 0 & ~nans) = 0.5;


