%%
% amri_stat_iqr(): compute inter-quartile range
%
% Usage:
%   y = amri_stat_iqr(x)
% 
% Inputs:
%   x: 1-vector
%
% Outputs
%   y: inter-quartile range
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
%        16/11/2011 - JAdZ  - v1.00 included in amri_eegfmri_toolbox v0.1

function y = amri_stat_iqr(x)

if nargin<1
    eval('help amri_stat_iqr');
    return
end

%dim=size(x);
x1=x(:);
x1=sort(x1);
nx=length(x1);
y=x1(round(nx*3/4))-x1(round(nx/4));
