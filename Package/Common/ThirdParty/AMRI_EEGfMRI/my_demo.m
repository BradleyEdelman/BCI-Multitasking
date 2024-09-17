%%    
% my_demo: 
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



% add paths to amri_eegfmri_toolbox and eeglab
% (<codedir> should be replaced with the proper location of these toolboxes)
addpath(genpath('<codedir>/eeglab/'));
addpath(genpath('<codedir>/amri_toolbox/'));

% load EEG raw data recorded with BrainProducts system
% (pop_loadbv is a function from the eeglab toolbox)
% (<datadir> should be replaced with the proper location of the example_data
% folder)
eeg = pop_loadbv('<datadir>/example_data/','eceo.vhdr');

% remove gradient artifacts
eeg_gac = amri_eeg_gac(eeg);

% select ECG from EEG
% (pop_select is a function from the eeglab toolbox)
ecg_gac = pop_select(eeg_gac,'channel',{'ECG'});

% detect peak of QRS complex
eeg_gac_r = amri_eeg_rpeak(eeg_gac,ecg_gac);

% remove non-EEG channels
% (optional but recommended when ica will be used for removing pulse
% artifacts)
% (pop_select is a function from the eeglab toolbox)
eeg_gac_r = pop_select(eeg_gac_r,'nochannel',{'ECG','EOG'});

% remove pulse artifacts 
eeg_gac_r_cbc = amri_eeg_cbc(eeg_gac_r,ecg_gac);

% display the result (or intermediates)
% (pop_eegplot is a function from the eeglab toolbox)
pop_eegplot(eeg_gac_r_cbc);
