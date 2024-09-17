function [hObject,handles]=bci_ESI_TrainClassifier(hObject,handles,sigtype)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECK TRAINING PARAMETERS
[hObject,handles]=bci_ESI_CheckTraining(hObject,handles,sigtype);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARE DATA FROM TRAINING FILES
[hObject,handles]=bci_ESI_TrainPrepare(hObject,handles,sigtype);
        

if isequal(get(hObject,'userdata'),1)
    
    spatdomainfield=handles.TRAINING.spatdomainfield;
    
    % DEFINE SAVE PATHS
    % feature save folder
    savefiledir=handles.SYSTEM.savefiledir;
    featsavedir=strcat(savefiledir,'\Features');
    handles.TRAINING.dir=featsavedir;
    if ~exist(featsavedir,'dir')
        mkdir(featsavedir)
    end
    
    % spatial domain features
    spatsavedir=strcat(featsavedir,'\',spatdomainfield);
    handles.TRAINING.(spatdomainfield).dir=spatsavedir;
    if ~exist(spatsavedir,'dir')
        mkdir(spatsavedir)
    end
    
    % signal type features
    sigsavedir=strcat(spatsavedir,'\',sigtype);
    handles.TRAINING.(spatdomainfield).(sigtype).dir=sigsavedir;
    if ~exist(spatsavedir,'dir')
        mkdir(spatsavedir)
    end
    
    % temp domain features
    tempdomain=get(handles.tempdomain,'value');
    traintype=get(handles.traintype,'value');
    handles.TRAINING.(spatdomainfield).(sigtype).param.decodertype=traintype;
    switch tempdomain
        case 1 % None
        case 2 % Frequency
            
            broadband=handles.SYSTEM.broadband;
            if isequal(broadband,1)
                freqdisp={'Freq';'Broadband'};
            else
                freqanalysis=handles.SYSTEM.mwparam.freqvect;
                freqdisp=[{'Freq';'All'};cellstr(num2str(freqanalysis'));{'Broadband'}];
            end
            
            switch traintype
                case 1 % None
                case 2 % Linear Regression

                    [hObject,handles]=bci_ESI_TrainFreq2(hObject,handles,sigtype);

                case 3 % Mahalanobis Distance
                    
                    numtopfeat=30;
                    handles.TRAINING.(spatdomainfield).(sigtype).param.numtopfeat=numtopfeat;
                    [hObject,handles]=bci_ESI_TrainFreq2(hObject,handles,sigtype);

                case 4 % Linear Discriminant Analysis

                    lambdaanalysis=.05:.05:1;
                    lambdadisp=[{'Lambda';'All'};cellstr(num2str(lambdaanalysis'))];
                    handles.TRAINING.(spatdomainfield).(sigtype).param.lambda=lambdaanalysis;

                    gammaanalysis=.05:.05:1;
                    gammadisp=[{'Gamma';'All'};cellstr(num2str(gammaanalysis'))];
                    handles.TRAINING.(spatdomainfield).(sigtype).param.gamma=gammaanalysis;

                    [hObject,handles]=bci_ESI_TrainFreq2(hObject,handles,sigtype);
                    set(handles.freqfeatlambda,'string',lambdadisp,'value',1);
                    set(handles.freqfeatgamma,'string',gammadisp,'value',1);

                case 5 % Principle Component Analysis

                    lambdaanalysis=.05:.05:1;
                    lambdadisp=[{'Lambda';'All'};cellstr(num2str(lambdaanalysis'))];
                    handles.TRAINING.(spatdomainfield).(sigtype).param.lambda=lambdaanalysis;
                    
                    switch spatdomainfield
                        case 'Sensor'
                            pcanalysis=1:size(handles.TRAINING.(spatdomainfield).param.chanidxinclude,1);
                        case 'Source'
                            pcanalysis=1:size(handles.TRAINING.(spatdomainfield).param.vertidxinclude,2);
                        case 'SourceCluster'
                            pcanalysis=1:size(handles.TRAINING.(spatdomainfield).param.clusteridxinclude,2);
                    end
                    
                    pcdisp=[{'PC';'All'};cellstr(num2str(pcanalysis'))];
                    handles.TRAINING.(spatdomainfield).(sigtype).param.pc=pcdisp;

                    [hObject,handles]=bci_ESI_TrainFreq2(hObject,handles,sigtype);
                    set(handles.freqfeatlambda,'string',lambdadisp,'value',1);
                    set(handles.freqfeatpc,'string',pcdisp,'value',1);

                case 6 % Fisher's Linear Discriminant

                    lambdaanalysis=.05:.05:1;
                    lambdadisp=[{'Lambda';'All'};cellstr(num2str(lambdaanalysis'))];
                    handles.TRAINING.(spatdomainfield).(sigtype).param.lambda=lambdaanalysis;

                    gammaanalysis=.05:.05:1;
                    gammadisp=[{'Gamma';'All'};cellstr(num2str(gammaanalysis'))];
                    handles.TRAINING.(spatdomainfield).(sigtype).param.gamma=gammaanalysis;

                    [hObject,handles]=bci_ESI_TrainFreq2(hObject,handles,sigtype);
                    set(handles.freqfeatlambda,'string',lambdadisp,'value',1);
                    set(handles.freqfeatgamma,'string',gammadisp,'value',1);
                    
                case 7 % Mutual Information
                    
                    [hObject,handles]=bci_ESI_TrainFreq2(hObject,handles,sigtype);
                    
                case 8 % Support Vector Machine
                case 9 % Convolutional Neural Network
            end
            
            set(handles.freqfeatfreq,'string',freqdisp,'value',1);

        case 3 % Time

            windowanalysis=100:100:500;
            windowdisp=[{'Win';'All'};cellstr(num2str(windowanalysis'))];     
            handles.TRAINING.param.windows=windowanalysis;

            traintype=get(handles.traintype,'value');
            switch traintype
                case 1 % None
                case 2 % Linear Regression
                    
                    [hObject,handles]=bci_ESI_RegressionTime(hObject,handles);

                case 3 % Mahalanobis Distance
                    
                    [hObject,handles]=bci_ESI_MahalTime(hObject,handles);

                case 4 % Linear Discriminant Analysis
                    
                    lambdaanalysis=.05:.05:1;
                    lambdadisp=[{'Lambda';'All'};cellstr(num2str(lambdaanalysis'))];
                    handles.TRAINING.param.lambda=lambdaanalysis;

                    [hObject,handles]=bci_ESI_LDATime(hObject,handles);
                    set(handles.timefeatlambda,'string',lambdadisp,'value',1);
                    
                case 5 % Principle Component Analysis
                case 6 % Fisher's Linear Discriminant
                case 7 % Mutual Information
                case 8 % Support Vector Machine
                case 9 % Convolutional Neural Network
            end
            
            set(handles.timefeatwindow,'string',windowdisp,'value',1);

    end
    
end
        

