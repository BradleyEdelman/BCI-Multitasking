function [hObject,handles]=bci_ESI_DispFreqFeat(hObject,handles)

freqfeatidx=get(handles.freqfeat,'value');
freqfeatstr=get(handles.freqfeat,'string');
set(hObject,'userdata',1);

% CHECK IF REGRESSION VARIABLE LIST IS POPULATED
if ~isempty(freqfeatstr)
    
    displayvar=freqfeatstr{freqfeatidx};
    
    if isequal(strfind(displayvar,'SSVEP'),1)
        sigtype='SSVEP';
    else
        sigtype='SMR';
    end
    
    % CHECK IF A VISUALIZATION METHOD IS SELECTED
    allfreq=0;
    % IDENTIFY FREQUENCY FOR DISPLAY
    freqvect=handles.SYSTEM.lowcutoff:handles.SYSTEM.highcutoff;
    broadband=handles.SYSTEM.broadband;
    freqfeatfreq=get(handles.freqfeatfreq,'value');
    set(handles.freqfeatfreq,'backgroundcolor','white')
    if isequal(freqfeatfreq,1) % None selected ("Frequency")
        fprintf(2,'MUST SELECT A FREQUENCY ANALYSIS RESULT TO VISUALIZE RESULTS\n');
        set(handles.freqfeatfreq,'backgroundcolor','red');
        freqidx=nan;
    elseif isequal(freqfeatfreq,2) % ("All") or ("Broadband")
        if isequal(broadband,1)
            freqidx=size(freqvect,2)+1;
        else
            freqidx=nan;
            allfreq=1;
        end
    else % Numerical
        freqidx=freqfeatfreq-2;
    end
    

    if isequal(allfreq,1) || ~isnan(freqidx) && strcmp(sigtype,'SMR') %|| isnan(freqidx) &&...
            %strcmp(sigtype,'SSVEP')

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % PLOT DESIRED RESULT
        
        % DETERMINE SPATIAL DOMAIN OF FEATURES
        if ~isequal(size(strfind(displayvar,'SourceCluster'),2),0)
            spatdomainfield='SourceCluster';
        elseif ~isequal(size(strfind(displayvar,'Source'),2),0)
            spatdomainfield='Source';
        elseif ~isequal(size(strfind(displayvar,'Sensor'),2),0)
            spatdomainfield='Sensor';
        else
            set(hObject,'userdata',0)
        end
        
        % DETERMINE FEATURE TYPE
        if ~isequal(size(strfind(displayvar,'Regress'),2),0)
            feattype='regress';
        elseif ~isequal(size(strfind(displayvar,'Mahal'),2),0)
            feattype='mahal';
        elseif ~isequal(size(strfind(displayvar,'RLDA'),2),0)
            feattype='rlda';
        elseif ~isequal(size(strfind(displayvar,'PCA'),2),0)
            feattype='pca';
        elseif ~isequal(size(strfind(displayvar,'FDA'),2),0)
            feattype='fda';
        elseif ~isequal(size(strfind(displayvar,'MI'),2),0)
            feattype='mi';
        else
            set(hObject,'userdata',0);
        end
        
        if isequal(get(hObject,'userdata'),1)
                
            % IDENTIFY ONE-vs-REST, ONE-vs-ONE, or ONE-vs-ALL
            taskidx=str2double(regexp(displayvar,'.\d+','match'));
            vartype=1;
            if ~isempty(strfind(displayvar,'Rest'))
            elseif size(taskidx,2)>1
                for i=1:size(handles.TRAINING.(spatdomainfield).(sigtype).freq.(feattype).label{2},1)
                    if isequal(taskidx,str2num(handles.TRAINING.(spatdomainfield).(sigtype).freq.(feattype).label{2}(i,:)))
                        taskidx=i;
                    end
                end
                vartype=2;
            elseif ~isempty(strfind(displayvar,'All'))
                vartype=3;
            end
                
            if ~exist(handles.TRAINING.(spatdomainfield).(sigtype).freq.(feattype).file{vartype},'file')
                freqfeatstr(freqfeatidx)=[];
                set(handles.FreqFeat,'string',freqfeatstr,'value',size(freqfeatstr,1));
                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                fprintf(2,'SAVED FEATURE FILE DOES NOT EXIST FOR TASK "%s"\n',freqfeatstr{freqfeatidx});
            else
                load(handles.TRAINING.(spatdomainfield).(sigtype).freq.(feattype).file{vartype});
                
                switch spatdomainfield
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %                        SENSOR                       %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    case {'Sensor'}
                        
%                         switch sigtype
%                             case 'SMR'
                        
                                if isequal(allfreq,1)

                                    switch feattype

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %        SENSOR ALL FREQ REGRESSION       %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'regress'

                                            label.xticklabel=[]; label.xlabel=[]; label.ylabel=[];

                                            % PLOT R VALUES FOR ALL FREQ
                                            R=SaveRegressSensor.R(:,:,taskidx);
                                            label.title='R values';
                                            PlotTotal(handles,1,label,R)
                                            caxis([-max(abs(caxis)) max(abs(caxis))]);
                                            set(handles.axes1,'Position',handles.axes(1).positioncb)

                                            % PLOT P VALUES FOR ALL FREQ
                                            pval=SaveRegressSensor.pval(:,:,taskidx);
                                            label.title='p values';

                                            PlotTotal(handles,2,label,pval)
                                            set(handles.axes2,'Position',handles.axes(2).positioncb)

                                            % PLOT R-SQUARED VALUES FOR ALL FREQ
                                            Rsq=SaveRegressSensor.Rsq(:,:,taskidx);
                                            label.title='R-squared values';
                                            label.xticklabel={freqvect,'BB'};
                                            label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                            PlotTotal(handles,3,label,Rsq)
                                            set(handles.axes3,'Position',handles.axes(3).positioncb)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %           SENSOR ALL FREQ MAHAL         %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'mahal'

                                            % PLOT MD FOR ALL FREQ
                                            MD=SaveMahalSensor.MD(:,:,taskidx);
                                            label.title='Mahalanobis Distance';
                                            label.xticklabel={freqvect,'BB'};
                                            label.xlabel='Freq (Hz)'; label.ylabel='Chan #'; 
                                            PlotTotal(handles,3,label,MD)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %           SENSOR ALL FREQ RLDA          %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'rlda'

                                            lambdavect=SaveRLDASensor.lambda;
                                            % Identify selected lambda
                                            lambdaidx=get(handles.freqfeatlambda,'value');
                                            set(handles.freqfeatlambda,'backgroundcolor','white')
                                            if isequal(lambdaidx,1) % None selected
                                                fprintf(2,'MUST SELECT ONE LAMBDA TO VIEW RLDA RESULTS\n');
                                                set(handles.freqfeatlambda,'backgroundcolor','red')
                                                lambdaidx=0;
                                            elseif isequal(lambdaidx,2) % All
                                                fprintf(2,'CAN ONLY VIEW RLDA ALL FREQUENCY RESULTS FOR ONE LAMBDA AT A TIME\n');
                                                set(handles.freqfeatlambda,'value',1)
                                                lambdaidx=0;
                                            else % Lambda value
                                                lambdaidx=lambdaidx-2;
                                                set(handles.freqfeatlambda,'backgroundcolor','white')
                                                Acc=SaveRLDASensor.Acc(:,taskidx,lambdaidx);
                                            end

                                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                            %         ALL FREQ, ONE LAMBDA        %
                                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                            if ~isequal(lambdaidx,0)
                                                % PLOT RLDA WEIGHTS FOR ALL FREQ, ONE LAMBDA
                                                W=SaveRLDASensor.W(:,:,taskidx,lambdaidx);
                                                l=lambdavect(get(handles.freqfeatlambda,'value')-2);
                                                label.title=['RLDA Weights: f=All,lambda=',num2str(l)];
                                                label.xticklabel={freqvect,'BB'};
                                                label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                                PlotTotal(handles,3,label,W);

                                                % PLOT X-VALIDATED TRAINING ACCURACIES FOR ALL FREQ, ONE LAMBDA
                                                axes(handles.axes2); cla;
                                                title=['XVal Accuracies: f=All,lambda=',num2str(l)];
                                                set(handles.Axis2Label,'string',title);
                                                plot([freqvect,freqvect(end)+1],Acc,'k','LineWidth',2);
                                                set(gca,'color',[.94 .94 .94],...
                                                    'ylim',[25 100],'xlim',[freqvect(1),...
                                                    freqvect(end)+1],'xtick',...
                                                    [freqvect,freqvect(end)+1]);
        %                                             'position',handles.axes(2).position)
                                                ylabel('Accuracy (%)')
                                                grid on
                                            end

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %            SENSOR ALL FREQ PCA          %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'pca'

                                            pcvect=1:size(SavePCASensor.chaninclude,1);
                                            % Identify selected PC
                                            pcidx=get(handles.freqfeatpc,'value');
                                            set(handles.freqfeatpc,'backgroundcolor','white')
                                            if isequal(pcidx,1) % None selected
                                                fprintf(2,'MUST SELECT ONE PC TO VIEW PCA RESULTS\n');
                                                set(handles.freqfeatpc,'backgroundcolor','red')
                                                pcidx=0;
                                            elseif isequal(pcidx,2) % All
                                                fprintf(2,'CAN ONLY VIEW PCA ALL FREQUENCY RESULTS FOR ONE PC AT A TIME\n');
                                                set(handles.freqfeatpc,'value',1)
                                                pcidx=0;
                                            else % Lambda value
                                                pcidx=pcidx-2;
                                                set(handles.freqfeatpc,'backgroundcolor','white')
                                            end

                                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                            %           ALL FREQ, ONE PC          %
                                            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                            if ~isequal(pcidx,0)

                                                % PLOT PCs FOR ALL FREQ
                                                PCs=squeeze(SavePCASensor.U(:,pcidx,:,taskidx));
                                                label.title='Principle Components';
                                                pc=pcvect(get(handles.freqfeatpc,'value')-2);
                                                label.title=['PCA Weights: f=All,PC=',num2str(pc)];
                                                label.xticklabel={freqvect,'BB'};
                                                label.xlabel='Freq (Hz)'; label.ylabel='Chan #'; 
                                                PlotTotal(handles,3,label,PCs)

                                                % PLOT VARIANCE EXPLAINED
                                                VE=squeeze(SavePCASensor.VE(:,taskidx,pcidx));
                                                TVE=squeeze(SavePCASensor.TVE(:,taskidx,pcidx));
                                                axes(handles.axes1); cla; hold off
                                                scatter(1:size(VE,1),VE,15,'b'); hold on
                                                scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                                set(gca,'color',[.94 .94 .94])
                                                legend('Var Exp','Tot Var Exp','Location','Best')
                                                set(handles.Axis1Label,'string','PC Variance');

                                            end

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %            SENSOR ALL FREQ FDA          %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'fda'

                                            % PLOT FDA WEIGHTS FOR ALL FREQ
                                            W=SaveFDASensor.W(:,:,taskidx);
                                            label.title='Fisher LDA Weights';
                                            label.xticklabel={freqvect,'BB'};
                                            label.xlabel='Freq (Hz)'; label.ylabel='Chan #'; 
                                            PlotTotal(handles,3,label,W)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %            SENSOR ALL FREQ MI           %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                                        case 'mi'

                                            % PLOT MI FOR ALL FREQ
                                            MI=SaveMISensor.MI(:,:,taskidx);
                                            label.title='Mutual Information';
                                            label.xticklabel={freqvect,'BB'};
                                            label.xlabel='Freq (Hz)'; label.ylabel='Chan #'; 
                                            PlotTotal(handles,3,label,MI)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    end   

                                else
                                    eLoc=handles.SYSTEM.Electrodes.current.eLoc;

                                    switch feattype

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %        SENSOR ONE FREQ REGRESSION       %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'regress'

                                            % PLOT FREQ SPECIFIC R VALUES TOPO
                                            R=SaveRegressSensor.R(:,freqidx,taskidx);
                                            PlotTopo(handles,1,'R values',eLoc,R)
                                            caxis([-max(abs(caxis)) max(abs(caxis))]);
                                            set(handles.axes1,'Position',handles.axes(1).positioncb)

                                            % PLOT FREQ SPECIFIC P VALUES TOPO
                                            pval=SaveRegressSensor.pval(:,freqidx,taskidx);
                                            PlotTopo(handles,2,'p values',eLoc,pval)
                                            set(handles.axes2,'Position',handles.axes(2).positioncb)

                                            % PLOT FREQ SPECIFIC R-SQUARED VALUES TOPO
                                            Rsq=SaveRegressSensor.Rsq(:,freqidx,taskidx);
                                            PlotTopo(handles,3,'R-squared values',eLoc,Rsq)
                                            set(handles.axes3,'Position',handles.axes(3).positioncb)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %           SENSOR ONE FREQ MAHAL         %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'mahal'

                                            % PLOT FREQ SPECIFIC MD
                                            MD=SaveMahalSensor.MD(:,freqidx,taskidx);
                                            PlotTopo(handles,3,'Mahalanobis Distance',eLoc,MD)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %           SENSOR ONE FREQ RLDA          %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'rlda'

                                            lambdavect=SaveRLDASensor.lambda;
                                            % Identify selected lambda
                                            lambdaidx=get(handles.freqfeatlambda,'value');
                                            set(handles.freqfeatlambda,'backgroundcolor','white');
                                            if isequal(lambdaidx,1) % None selected
                                                fprintf(2,'MUST SELECT ONE LAMBDA TO VIEW RLDA RESULTS\n');
                                                set(handles.freqfeatlambda,'backgroundcolor','red');
                                                lambdaidx=0;
                                            elseif isequal(lambdaidx,2) % All
                                                lambdaidx=(1:size(lambdavect,2))+2;
                                                Acc=squeeze(SaveRLDASensor.Acc(freqidx,taskidx,:));
                                            else % Numeric
                                                lambdaidx=lambdaidx-2;
                                            end

                                            if ~isequal(lambdaidx,0)

                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                %       ONE FREQ, ALL LAMBDA      %
                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                if size(lambdaidx,2)>1

                                                    % PLOT RLDA WEIGHTS FOR ONE FREQ, ALL LAMBDA
                                                    W=squeeze(SaveRLDASensor.W(:,freqidx,taskidx,:));
                                                    f=get(handles.freqfeatfreq,'value')-2;
                                                    % If not broadband option
                                                    if f<=size(freqvect,2)
                                                        f=freqvect(f);
                                                        label.title=['RLDA Weights: f=',num2str(f),'Hz, lambda=All'];
                                                    else
                                                        label.title=['RLDA Weights: f=Broadband, lambda=All'];
                                                    end
                                                    label.xticklabel=lambdavect(1:2:end);
                                                    label.xlabel='Lambda'; label.ylabel='Chan #';
                                                    PlotTotal(handles,3,label,W);

                                                    % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
                                                    axes(handles.axes2); cla;
                                                    title=['XVal Accuracies: f=',num2str(f),'Hz, lambda=ALL'];
                                                    set(handles.Axis2Label,'string',title);
                                                    plot(lambdavect,Acc,'k','LineWidth',2);
                                                    set(gca,'color',[.94 .94 .94],...
                                                        'ylim',[25 100],'xtick',lambdavect(1:3:end));%,...
        %                                                 'position',handles.axes(2).position)
                                                    ylabel('Accuracy (%)')
                                                    grid on

                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                %       ONE FREQ, ONE LAMBDA      %
                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                else

                                                    W=SaveRLDASensor.W(:,freqidx,taskidx,lambdaidx);
                                                    l=lambdavect(get(handles.freqfeatlambda,'value')-2);
                                                    % If not broadband option
                                                    if freqidx<=size(freqvect,2)
                                                        f=freqvect(freqidx);
                                                        title=['RLDA Weights: f=',num2str(f),'Hz, lambda=',num2str(l)];
                                                    else
                                                        title=['RLDA Weights: f=Broadband, lambda=',num2str(l)];
                                                    end
                                                    PlotTopo(handles,3,title,eLoc,W)

                                                end
                                            end

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %           SENSOR ONE FREQ PCA          %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        case 'pca'

                                            pcvect=1:size(SavePCASensor.chaninclude,1);
                                            % Identify selected lambda
                                            pcidx=get(handles.freqfeatpc,'value');
                                            set(handles.freqfeatpc,'backgroundcolor','white');
                                            if isequal(pcidx,1) % None selected
                                                fprintf(2,'MUST SELECT ONE PC TO VIEW PCA RESULTS\n');
                                                set(handles.freqfeatpc,'backgroundcolor','red');
                                                pcidx=0;
                                            elseif isequal(pcidx,2) % All
                                                pcidx=(1:size(pcvect,2))+2;
        %                                         Acc=squeeze(SaveRLDASensor.Acc(Freq,TaskInd,:));
                                            else % Numeric
                                                pcidx=pcidx-2;
                                            end

                                            if ~isequal(pcidx,0)

                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                %         ONE FREQ, ALL PC        %
                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                if size(pcidx,2)>1

                                                    % PLOT RLDA WEIGHTS FOR ONE FREQ, ALL LAMBDA
                                                    PCs=SavePCASensor.U(:,:,freqidx,taskidx);
                                                    % If not broadband option
                                                    if freqidx<=size(freqvect,2)
                                                        f=freqvect(freqidx);
                                                        label.title=['PCA Weights: f=',num2str(f),'Hz, PC=All'];
                                                    else
                                                        label.title=['PCA Weights: f=Broadband, PC=All'];
                                                    end
                                                    label.xticklabel=pcvect(1:2:end);
                                                    label.xlabel='Lambda'; label.ylabel='Chan #';
                                                    PlotTotal(handles,3,label,PCs);

                                                    % PLOT VARIANCE EXPLAINED
                                                    VE=squeeze(SavePCASensor.VE(freqidx,taskidx,:));
                                                    TVE=squeeze(SavePCASensor.TVE(freqidx,taskidx,:));
                                                    axes(handles.axes1); cla; hold off
                                                    scatter(1:size(VE,1),VE,15,'b'); hold on
                                                    scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                                    set(gca,'color',[.94 .94 .94])
                                                    legend('Var Exp','Tot Var Exp','Location','Best')
                                                    set(handles.Axis1Label,'string','PC Variance');

        % % %                                             % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
        % % %                                             axes(handles.axes2); cla;
        % % %                                             title=['XVal Accuracies: f=',num2str(f),'Hz, lambda=ALL'];
        % % %                                             set(handles.Axis2Label,'string',title);
        % % %                                             plot(LambdaVect,Acc,'k','LineWidth',2);
        % % %                                             set(gca,'color',[.94 .94 .94],...
        % % %                                                 'ylim',[25 100],'xtick',LambdaVect(1:3:end),...
        % % %                                                 'position',handles.axes(2).position)
        % % %                                             ylabel('Accuracy (%)')
        % % %                                             grid on

                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                %         ONE FREQ, ONE PC        %
                                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                else

                                                    PCs=SavePCASensor.U(:,pcidx,freqidx,taskidx);
                                                    pc=pcvect(get(handles.freqfeatpc,'value')-2);
                                                    % If not broadband option
                                                    if freqidx<=size(freqvect,2)
                                                        f=freqvect(freqidx);
                                                        title=['RLDA Weights: f=',num2str(f),'Hz, lambda=',num2str(pc)];
                                                    else
                                                        title=['RLDA Weights: f=Broadband, lambda=',num2str(pc)];
                                                    end
                                                    PlotTopo(handles,3,title,eLoc,PCs)

                                                    % PLOT VARIANCE EXPLAINED
                                                    VE=squeeze(SavePCASensor.VE(freqidx,taskidx,:));
                                                    TVE=squeeze(SavePCASensor.TVE(freqidx,taskidx,:));
                                                    axes(handles.axes1); cla; hold off
                                                    scatter(1:size(VE,1),VE,15,'b'); hold on
                                                    scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                                    legend('Var Exp','Tot Var Exp','Location','Best')
                                                    scatter(pc,VE(pc),15,'r','filled');
                                                    scatter(pc,TVE(pc),50,'r','filled');
                                                    set(gca,'color',[.94 .94 .94])
                                                    set(handles.Axis1Label,'string','PC Variance');

                                                     % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
                                                    axes(handles.axes2); cla;
        %                                             lambdavect=SavePCASource.lambda;
                                                    lambdavect=.05:.05:1;
                                                    title=['XVal Accuracies: f=',num2str(freqidx),'Hz, lambda=ALL'];
                                                    set(handles.Axis2Label,'string',title);
                                                    Acc=SavePCASensor.Acc{freqidx,taskidx,pcidx};
                                                    if isempty(Acc)
                                                        fprintf(2,'\nPC VAR EXP TOO SMALL TO COMPUTE XVAL ACC\n');
                                                    else
                                                        plot(lambdavect,Acc,'k','LineWidth',2);
                                                        set(handles.axes2,'color',[.94 .94 .94],...
                                                            'ylim',[25 100],'xtick',lambdavect(1:3:end),...
                                                            'position',handles.axes(2).position)
                                                        ylabel('Accuracy (%)')
                                                        grid on
                                                    end

                                                end
                                            end

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %            SENSOR ONE FREQ FDA          %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                                        case 'fda'

                                            % PLOT FREQ SPECIFIC FDA WEIGHTS
                                            W=SaveFDASensor.W(:,freqidx,taskidx);
                                            PlotTopo(handles,3,'Fisher LDA Weights',eLoc,W)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')


                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %            SENSOR ONE FREQ MI           %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
                                        case 'mi'

                                            % PLOT FREQ SPECIFIC MUTUAL INFO
                                            MI=SaveMISensor.MI(:,freqidx,taskidx);
                                            PlotTopo(handles,3,'Mutual Information',eLoc,MI)

                                            set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                            set(handles.freqfeatpc,'value',1,'backgroundcolor','white')

                                    end
                                end
                        
%                             case 'SSVEP'
%                                 
%                                 switch feattype
                                    
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    %           SENSOR ALL FREQ RLDA          %
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                     case 'rlda'
% 
%                                         lambdavect=SaveRLDASensor.lambda;
%                                         % Identify selected lambda
%                                         lambdaidx=get(handles.freqfeatlambda,'value');
%                                         set(handles.freqfeatlambda,'backgroundcolor','white')
%                                         if isequal(lambdaidx,1) % None selected
%                                             fprintf(2,'MUST SELECT ONE LAMBDA TO VIEW RLDA RESULTS\n');
%                                             set(handles.freqfeatlambda,'backgroundcolor','red')
%                                             lambdaidx=0;
%                                         elseif isequal(lambdaidx,2) % All
%                                             fprintf(2,'CAN ONLY VIEW RLDA ALL FREQUENCY RESULTS FOR ONE LAMBDA AT A TIME\n');
%                                             set(handles.freqfeatlambda,'value',1)
%                                             lambdaidx=0;
%                                         else % Lambda value
%                                             lambdaidx=lambdaidx-2;
%                                             set(handles.freqfeatlambda,'backgroundcolor','white')
%                                             Acc=SaveRLDASensor.Acc(taskidx,lambdaidx);
%                                         end
%                                         
%                                         W=SaveRLDASensor.W(:,taskidx,lambdaidx);
%                                         l=lambdavect(get(handles.freqfeatlambda,'value')-2);
%                                         
%                                         
%                                         
%                                         % If not broadband option
%                                         if freqidx<=size(freqvect,2)
%                                             f=freqvect(freqidx);
%                                             title=['RLDA Weights: f=',num2str(f),'Hz, lambda=',num2str(l)];
%                                         else
%                                             title=['RLDA Weights: f=Broadband, lambda=',num2str(l)];
%                                         end
%                                         PlotTopo(handles,3,title,eLoc,W)
                                
                                
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %                        SOURCE                       %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                    case {'Source'}
                        
                        if isequal(allfreq,1)
                            
                            switch feattype
                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE ALL FREQ REGRESSION       %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'regress'
                                    
                                    label.xticklabel=[]; label.xlabel=[]; label.ylabel=[];
                                    
                                    % PLOT R VALUES FOR ALL FREQ
                                    R=SaveRegressSource.R(:,:,taskidx);
                                    label.title='R values';
                                    PlotTotal(handles,1,label,R)
                                    caxis([-max(abs(caxis)) max(abs(caxis))]);

                                    % PLOT P VALUES FOR ALL FREQ
                                    pval=SaveRegressSource.pval(:,:,taskidx);
                                    label.title='p values';
                                    PlotTotal(handles,2,label,pval)

                                    % PLOT R-SQUARED VALUES FOR ALL FREQ
                                    Rsq=SaveRegressSource.Rsq(:,:,taskidx);
                                    label.title='R-squared values';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    PlotTotal(handles,3,label,Rsq)
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %           SOURCE ALL FREQ MAHAL         %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'mahal'
                                    
                                    % PLOT MD FOR ALL FREQ
                                    label.title='Mahalanobis Distance';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    MD=SaveMahalSource.MD(:,:,taskidx);
                                    PlotTotal(handles,3,label,MD)
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %           SOURCE ALL FREQ RLDA          %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'rlda'

                                    lambdavect=SaveRLDASource.lambda;
                                    % Identify selected lambda
                                    lambdaidx=get(handles.freqfeatlambda,'value');
                                    set(handles.freqfeatlambda,'backgroundcolor','white')
                                    if isequal(lambdaidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE LAMBDA TO VIEW RLDA RESULTS\n');
                                        set(handles.freqfeatlambda,'backgroundcolor','red');
                                        lambdaidx=0;
                                    elseif isequal(lambdaidx,2) % All
                                        fprintf(2,'CAN ONLY VIEW RLDA ALL FREQUENCY RESULTS FOR ONE LAMBDA AT A TIME\n');
                                        set(handles.freqfeatlambda,'value',1,'backgroundcolor','red')
                                        lambdaidx=0;
                                    else % Lambda value
                                        lambdaidx=lambdaidx-2;
                                        set(handles.freqfeatlambda,'backgroundcolor','white')
                                        Acc=SaveRLDASource.Acc(:,taskidx,lambdaidx);
                                    end

                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    %         ALL FREQ, ONE LAMBDA        %
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    if ~isequal(lambdaidx,0)
                                            
                                        % PLOT RLDA WEIGHTS FOR ALL FREQ, ONE LAMBDA
                                        W=SaveRLDASource.W(:,:,taskidx,lambdaidx);
                                        l=lambdavect(get(handles.freqfeatlambda,'value')-2);
                                        label.title=['RLDA Weights: f=All, lambda=',num2str(l)];
                                        label.xticklabel={freqvect,'BB'};
                                        label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                        PlotTotal(handles,3,label,W);

                                        % PLOT X-VALIDATED TRAINING ACCURACIES FOR ALL FREQ, ONE LAMBDA
                                        axes(handles.axes2); cla;
                                        title=['XVal Accuracies: f=All, lambda=',num2str(l)];
                                        set(handles.Axis2Label,'string',title); size(freqvect)
                                        plot([freqvect,freqvect(end)+1],Acc,'k','LineWidth',2);
                                        set(gca,'color',[.94 .94 .94],...
                                            'ylim',[25 100],'xlim',[freqvect(1),...
                                            freqvect(end)+1],'xtick',...
                                            [freqvect,freqvect(end)+1],...
                                            'position',handles.axes(2).position)
                                        ylabel('Accuracy (%)')
                                        grid on
                                        
                                    end
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %            SOURCE ALL FREQ PCA          %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'pca'
                                    
                                    pcvect=1:size(SavePCASource.chaninclude,1);
                                    % Identify selected PC
                                    pcidx=get(handles.freqfeatpc,'value');
                                    set(handles.freqfeatpc,'backgroundcolor','white')
                                    if isequal(pcidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE PC TO VIEW PCA RESULTS\n');
                                        set(handles.freqfeatpc,'backgroundcolor','red')
                                        pcidx=0;
                                    elseif isequal(pcidx,2) % All
                                        fprintf(2,'CAN ONLY VIEW PCA ALL FREQUENCY RESULTS FOR ONE PC AT A TIME\n');
                                        set(handles.freqfeatpc,'value',1)
                                        pcidx=0;
                                    else % Lambda value
                                        pcidx=pcidx-2;
                                        set(handles.freqfeatpc,'backgroundcolor','white')
                                    end
                                    
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    %           ALL FREQ, ONE PC          %
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    if ~isequal(pcidx,0)
                                        
                                        % PLOT PCs FOR ALL FREQ
                                        PCs=squeeze(SavePCASource.U(:,pcidx,:,taskidx));
                                        label.title='Principle Components';
                                        pc=pcvect(get(handles.freqfeatpc,'value')-2);
                                        label.title=['PCA Weights: f=All,PC=',num2str(pc)];
                                        label.xticklabel={freqvect,'BB'};
                                        label.xlabel='Freq (Hz)'; label.ylabel='Chan #'; 
                                        PlotTotal(handles,3,label,PCs)
                                        
                                        % PLOT VARIANCE EXPLAINED
                                        VE=squeeze(SavePCASource.VE(:,taskidx,pcidx));
                                        TVE=squeeze(SavePCASource.TVE(:,taskidx,pcidx));
                                        axes(handles.axes1); cla; hold off
                                        scatter(1:size(VE,1),VE,15,'b'); hold on
                                        scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                        set(gca,'color',[.94 .94 .94])
                                        legend('Var Exp','Tot Var Exp','Location','Best')
                                        set(handles.Axis1Label,'string','PC Variance');
                                    
                                    end
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %            SOURCE ALL FREQ FDA          %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'fda'
                                    
                                    % PLOT FDA WEIGHTS FOR ALL FREQ
                                    label.title='FDA Weights';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    W=SaveFDASource.W(:,:,taskidx);
                                    PlotTotal(handles,3,label,W)
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %            SOURCE ALL FREQ MI           %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                                case 'mi'
                                    
                                    % PLOT MUTUAL INFO FOR ALL FREQ
                                    label.title='Mutual Information';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    MI=SaveMISource.MI(:,:,taskidx);
                                    PlotTotal(handles,3,label,MI)
                                    
                            end

                        else
                            
                            Cortex=handles.ESI.cortex;
%                             Cortex=load('M:\brainstorm_db\bci_fESI\anat\BE\tess_cortex_pial_low_fig.mat');
        
                            switch feattype
                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE ONE FREQ REGRESSION       %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'regress'
                                    
                                    % PLOT FREQ SPECIFIC R VALUES ON CORTEX
                                    R=-.1*ones(1,size(Cortex.Vertices,1));
                                    R(SaveRegressSource.chaninclude)=SaveRegressSource.R(:,freqidx,taskidx);
                                    PlotBrain(handles,1,'R values',Cortex,R)
                                    caxis([-max(abs(caxis)) max(abs(caxis))]); 

                                    % PLOT FREQ SPECIFIC P VALUES ON CORTEX
                                    pval=-.1*ones(1,size(Cortex.Vertices,1));
                                    pval(SaveRegressSource.chaninclude)=SaveRegressSource.pval(:,freqidx,taskidx);
                                    PlotBrain(handles,2,'p values',Cortex,pval)

                                    % PLOT FREQ SPECIFIC R-SQUARED VALUES ON CORTEX
                                    Rsq=-.1*ones(1,size(Cortex.Vertices,1));
                                    Rsq(SaveRegressSource.chaninclude)=SaveRegressSource.Rsq(:,freqidx,taskidx);
%                                     Rsq(pval>.01)=-.1;
                                    PlotBrain(handles,3,'R-squared values',Cortex,Rsq)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %           SOURCE ONE FREQ MAHAL         %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'mahal'
                                    
                                    % PLOT FREQ SPECIFIC MD ON CORTEX
                                    MD=-.1*ones(1,size(Cortex.Vertices,1));
                                    MD(SaveMahalSource.chaninclude)=SaveMahalSource.MD(:,freqidx,taskidx);
                                    PlotBrain(handles,3,'Mahalanobis Distance',Cortex,MD)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %           SOURCE ONE FREQ RLDA          %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'rlda'
                                    
                                    lambdavect=SaveRLDASource.lambda;
                                    % Identify selected lambda
                                    lambdaidx=get(handles.freqfeatlambda,'value');
                                    if isequal(lambdaidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE LAMBDA TO VIEW RLDA RESULTS\n');
                                        set(handles.freqfeatlambda,'backgroundcolor','red');
                                        lambdaidx=0;
                                    elseif isequal(lambdaidx,2) % All
                                        lambdaidx=(1:size(lambdavect,2))+2;
                                        Acc=squeeze(SaveRLDASource.Acc(freqidx,taskidx,:));
                                    else % Numeric
                                        lambdaidx=lambdaidx-2;
                                    end

                                    % If a lambda is selected
                                    if ~isequal(lambdaidx,0)

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %       ONE FREQ, ALL LAMBDA      %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        if size(lambdaidx,2)>1

                                            % PLOT RLDA WEIGHTS FOR ONE FREQ, ALL LAMBDA
                                            W=squeeze(SaveRLDASource.W(:,freqidx,taskidx,:));
                                            % If not broadband option
                                            if freqidx<=size(freqvect,2)
                                                f=freqvect(freqidx);
                                                label.title=['RLDA Weights: f=',num2str(f),'Hz, lambda=All'];
                                            else
                                                label.title=['RLDA Weights: f=Broadband, lambda=All'];
                                            end
                                            label.xticklabel=lambdavect(1:2:end);
                                            label.xlabel='Lambda'; label.ylabel='Chan #';
                                            PlotTotal(handles,3,label,W);

                                            % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
                                            axes(handles.axes2); cla;
                                            title=['XVal Accuracies: f=',num2str(f),'Hz, lambda=ALL'];
                                            set(handles.Axis2Label,'string',title);
                                            plot(lambdavect,Acc,'k','LineWidth',2);
                                            set(handles.axes2,'color',[.94 .94 .94],...
                                                'ylim',[25 100],'xtick',lambdavect(1:3:end),...
                                                'position',handles.axes(2).position)
                                            ylabel('Accuracy (%)')
                                            grid on

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %       ONE FREQ, ONE LAMBDA      %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        else

                                            % PLOT RLDA WEIGHTS FOR ONE FREQ, ONE LAMBDA
                                            Wtmp=SaveRLDASource.W(:,freqidx,taskidx,lambdaidx);
                                            offset=-(max(abs(Wtmp))+.1*max(abs(Wtmp)));
                                            W=offset*ones(1,size(Cortex.Vertices,1));
                                            W(SaveRLDASource.chaninclude)=Wtmp;
                                            l=lambdavect(get(handles.freqfeatlambda,'value')-2);
                                            if freqidx<=size(freqvect,2)
                                                f=freqvect(freqidx);
                                                title=['RLDA Weights: f=',num2str(f),'Hz, lambda=',num2str(l)];
                                            else
                                                title=['RLDA Weights: f=Broadband, lambda=',num2str(l)];
                                            end
                                            
                                            PlotBrain(handles,3,title,Cortex,W)

                                        end
                                    end

                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %           SOURCE ONE FREQ PCA           %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'pca'
                                    
                                    pcvect=1:size(SavePCASource.chaninclude,1);
                                    % Identify selected lambda
                                    pcidx=get(handles.freqfeatpc,'value');
                                    set(handles.freqfeatpc,'backgroundcolor','white');
                                    if isequal(pcidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE PC TO VIEW PCA RESULTS\n');
                                        set(handles.freqfeatlambda,'backgroundcolor','red');
                                        pcidx=0;
                                    elseif isequal(pcidx,2) % All
                                        pcidx=(1:size(pcvect,2))+2;
%                                         Acc=squeeze(SaveRLDASource.Acc(Freq,TaskInd,:));
                                    else % Numeric
                                        pcidx=pcidx-2;
                                    end
                                    
                                    if ~isequal(pcidx,0)

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %         ONE FREQ, ALL PC        %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        if size(pcidx,2)>1
                                            
                                            % PLOT RLDA WEIGHTS FOR ONE FREQ, ALL LAMBDA
                                            PCs=SavePCASource.U(:,:,freqidx,taskidx);
                                            f=get(handles.freqfeatfreq,'value')-2;
                                            % If not broadband option
                                            if f<=size(freqvect,2)
                                                f=freqvect(f);
                                                label.title=['PCA Weights: f=',num2str(f),'Hz, PC=All'];
                                            else
                                                label.title=['PCA Weights: f=Broadband, PC=All'];
                                            end
                                            label.xticklabel=[];
                                            label.xlabel='PCs'; label.ylabel='Chan #';
                                            PlotTotal(handles,3,label,PCs);
                                            
                                            % PLOT VARIANCE EXPLAINED
                                            VE=squeeze(SavePCASource.VE(freqidx,taskidx,:));
                                            TVE=squeeze(SavePCASource.TVE(freqidx,taskidx,:));
                                            axes(handles.axes1); cla; hold off
                                            scatter(1:size(VE,1),VE,15,'b'); hold on
                                            scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                            set(gca,'color',[.94 .94 .94])
                                            legend('Var Exp','Tot Var Exp','Location','Best')
                                            set(handles.Axis1Label,'string','PC Variance');

% % %                                             % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
% % %                                             axes(handles.axes2); cla;
% % %                                             title=['XVal Accuracies: f=',num2str(f),'Hz, lambda=ALL'];
% % %                                             set(handles.Axis2Label,'string',title);
% % %                                             plot(LambdaVect,Acc,'k','LineWidth',2);
% % %                                             set(gca,'color',[.94 .94 .94],...
% % %                                                 'ylim',[25 100],'xtick',LambdaVect(1:3:end),...
% % %                                                 'position',handles.axes(2).position)
% % %                                             ylabel('Accuracy (%)')
% % %                                             grid on

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %         ONE FREQ, ONE PC        %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        else
                                            
                                            PCtmp=SavePCASource.U(:,pcidx,freqidx,taskidx);
                                            offset=-(max(abs(PCtmp))+.1*max(abs(PCtmp)));
                                            PCs=offset*ones(1,size(Cortex.Vertices,1));
                                            PCs(SavePCASource.chaninclude)=PCtmp;
                                            pc=pcvect(get(handles.freqfeatpc,'value')-2);
                                            f=get(handles.freqfeatfreq,'value')-2;
                                            % If not broadband option
                                            if f<=size(freqvect,2)
                                                f=freqvect(f);
                                                title=['RLDA Weights: f=',num2str(f),'Hz, PC=',num2str(pc)];
                                            else
                                                title=['RLDA Weights: f=Broadband, PC=',num2str(pc)];
                                            end
                                            PlotBrain(handles,3,title,Cortex,PCs)
                                            
                                            % PLOT VARIANCE EXPLAINED
                                            VE=squeeze(SavePCASource.VE(freqidx,taskidx,:));
                                            TVE=squeeze(SavePCASource.TVE(freqidx,taskidx,:));
                                            axes(handles.axes1); cla; hold off
                                            scatter(1:size(VE,1),VE,15,'b'); hold on
                                            scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                            legend('Var Exp','Tot Var Exp','Location','Best')
                                            scatter(pc,VE(pc),15,'r','filled');
                                            scatter(pc,TVE(pc),50,'r','filled');
                                            set(gca,'color',[.94 .94 .94])
                                            set(handles.Axis1Label,'string','PC Variance');
                                            
                                            % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
                                            axes(handles.axes2); cla;
%                                             lambdavect=SavePCASource.lambda;
                                            lambdavect=.05:.05:1;
                                            title=['XVal Accuracies: f=',num2str(f),'Hz, lambda=ALL'];
                                            set(handles.Axis2Label,'string',title);
                                            Acc=SavePCASource.Acc{freqidx,taskidx,pcidx};
                                            if isempty(Acc)
                                                fprintf(2,'\nPC VAR EXP TOO SMALL TO COMPUTE XVAL ACC\n');
                                            else
                                                plot(lambdavect,Acc,'k','LineWidth',2);
                                                set(handles.axes2,'color',[.94 .94 .94],...
                                                    'ylim',[25 100],'xtick',lambdavect(1:3:end),...
                                                    'position',handles.axes(2).position)
                                                ylabel('Accuracy (%)')
                                                grid on
                                            end

                                        end
                                    end
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %            SOURCE ONE FREQ FDA          %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'fda'
                                    
                                    % PLOT FREQ SPECIFIC FDA WEIGHTS ON CORTEX
                                    W=-.1*ones(1,size(Cortex.Vertices,1));
                                    W(SaveFDASource.chaninclude)=SaveFDASource.W(:,freqidx,taskidx);
                                    PlotBrain(handles,3,'Fisher LDA Weights',Cortex,W)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %            SOURCE ONE FREQ MI           %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                                case 'mi'
                                    
                                    % PLOT FREQ SPECIFIC MUTUAL INFO ON CORTEX
                                    MI=-.1*ones(1,size(Cortex.Vertices,1));
                                    MI(SaveMISource.chaninclude)=SaveMISource.MI(:,freqidx,taskidx);
                                    PlotBrain(handles,3,'Mutual Information',Cortex,MI)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    
                                    
                            end
                        end
                        
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %                    SOURCE CLUSTER                   %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
                    case {'SourceCluster'}
                        
                        if isequal(allfreq,1)
                            
                            switch feattype
                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %    SOURCE CLUSTER ALL FREQ REGRESSION   %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'regress'
                                    
                                    label.xticklabel=[]; label.xlabel=[]; label.ylabel=[];
                                    
                                    % PLOT R VALUES FOR ALL FREQ
                                    R=SaveRegressSourceCluster.R(:,:,taskidx);
                                    label.title='R values';
                                    PlotTotal(handles,1,label,R)
                                    caxis([-max(abs(caxis)) max(abs(caxis))]);

                                    % PLOT P VALUES FOR ALL FREQ
                                    pval=SaveRegressSourceCluster.pval(:,:,taskidx);
                                    label.title='p values';
                                    PlotTotal(handles,2,label,pval)

                                    % PLOT R-SQUARED VALUES FOR ALL FREQ
                                    Rsq=SaveRegressSourceCluster.Rsq(:,:,taskidx);
                                    label.title='R-squared values';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    PlotTotal(handles,3,label,Rsq)
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %       SOURCE CLUSTER ALL FREQ MAHAL     %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'mahal'
                                    
                                    % PLOT MD FOR ALL FREQ
                                    label.title='Mahalanobis Distance';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    MD=SaveMahalSourceCluster.MD(:,:,taskidx);
                                    PlotTotal(handles,3,label,MD)
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %       SOURCE CLUSTER ALL FREQ RLDA      %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'rlda'

                                    lambdavect=SaveRLDASourceCluster.lambda;
                                    % Identify selected lambda
                                    lambdaidx=get(handles.freqfeatlambda,'value');
                                    set(handles.freqfeatlambda,'backgroundcolor','white')
                                    if isequal(lambdaidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE LAMBDA TO VIEW RLDA RESULTS\n');
                                        set(handles.freqfeatlambda,'backgroundcolor','red');
                                        lambdaidx=0;
                                    elseif isequal(lambdaidx,2) % All
                                        fprintf(2,'CAN ONLY VIEW RLDA ALL FREQUENCY RESULTS FOR ONE LAMBDA AT A TIME\n');
                                        set(handles.freqfeatlambda,'value',1,'backgroundcolor','red')
                                        lambdaidx=0;
                                    else % Lambda value
                                        lambdaidx=lambdaidx-2;
                                        set(handles.freqfeatlambda,'backgroundcolor','white')
                                        Acc=SaveRLDASourceCluster.Acc(:,taskidx,lambdaidx);
                                    end

                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    %         ALL FREQ, ONE LAMBDA        %
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    if ~isequal(lambdaidx,0)
                                            
                                        % PLOT RLDA WEIGHTS FOR ALL FREQ, ONE LAMBDA
                                        W=SaveRLDASourceCluster.W(:,:,taskidx,lambdaidx);
                                        l=lambdavect(get(handles.freqfeatlambda,'value')-2);
                                        label.title=['RLDA Weights: f=All, lambda=',num2str(l)];
                                        label.xticklabel={freqvect,'BB'};
                                        label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                        PlotTotal(handles,3,label,W);

                                        % PLOT X-VALIDATED TRAINING ACCURACIES FOR ALL FREQ, ONE LAMBDA
                                        axes(handles.axes2); cla;
                                        title=['XVal Accuracies: f=All, lambda=',num2str(l)];
                                        set(handles.Axis2Label,'string',title); size(freqvect)
                                        plot([freqvect,freqvect(end)+1],Acc,'k','LineWidth',2);
                                        set(gca,'color',[.94 .94 .94],...
                                            'ylim',[25 100],'xlim',[freqvect(1),...
                                            freqvect(end)+1],'xtick',...
                                            [freqvect,freqvect(end)+1],...
                                            'position',handles.axes(2).position)
                                        ylabel('Accuracy (%)')
                                        grid on
                                        
                                    end
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE CLUSTER ALL FREQ PCA      %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'pca'
                                    
                                    pcvect=1:size(SavePCASourceCluster.chaninclude,1);
                                    % Identify selected PC
                                    pcidx=get(handles.freqfeatpc,'value');
                                    set(handles.freqfeatpc,'backgroundcolor','white')
                                    if isequal(pcidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE PC TO VIEW PCA RESULTS\n');
                                        set(handles.freqfeatpc,'backgroundcolor','red')
                                        pcidx=0;
                                    elseif isequal(pcidx,2) % All
                                        fprintf(2,'CAN ONLY VIEW PCA ALL FREQUENCY RESULTS FOR ONE PC AT A TIME\n');
                                        set(handles.freqfeatpc,'value',1)
                                        pcidx=0;
                                    else % Lambda value
                                        pcidx=pcidx-2;
                                        set(handles.freqfeatpc,'backgroundcolor','white')
                                    end
                                    
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    %           ALL FREQ, ONE PC          %
                                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                    if ~isequal(pcidx,0)
                                        
                                        % PLOT PCs FOR ALL FREQ
                                        PCs=squeeze(SavePCASourceCluster.U(:,pcidx,:,taskidx));
                                        label.title='Principle Components';
                                        pc=pcvect(get(handles.freqfeatpc,'value')-2);
                                        label.title=['PCA Weights: f=All,PC=',num2str(pc)];
                                        label.xticklabel={freqvect,'BB'};
                                        label.xlabel='Freq (Hz)'; label.ylabel='Chan #'; 
                                        PlotTotal(handles,3,label,PCs)
                                        
                                        % PLOT VARIANCE EXPLAINED
                                        VE=squeeze(SavePCASourceCluster.VE(:,taskidx,pcidx));
                                        TVE=squeeze(SavePCASourceCluster.TVE(:,taskidx,pcidx));
                                        axes(handles.axes1); cla; hold off
                                        scatter(1:size(VE,1),VE,15,'b'); hold on
                                        scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                        set(gca,'color',[.94 .94 .94])
                                        legend('Var Exp','Tot Var Exp','Location','Best')
                                        set(handles.Axis1Label,'string','PC Variance');
                                        
                                    end
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE CLUSTER ALL FREQ FDA      %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'fda'
                                    
                                    % PLOT FDA WEIGHTS FOR ALL FREQ
                                    label.title='FDA Weights';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    W=SaveFDASourceCluster.W(:,:,taskidx);
                                    PlotTotal(handles,3,label,W)
                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %   SOURCE CLUSTER ALL FREQ MUTUAL INFO   %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                                case 'mi'
                                    
                                    % PLOT MUTUAL INFO FOR ALL FREQ
                                    label.title='Mutual Information';
                                    label.xticklabel={freqvect,'BB'};
                                    label.xlabel='Freq (Hz)'; label.ylabel='Chan #';
                                    MI=SaveMISourceCluster.MI(:,:,taskidx);
                                    PlotTotal(handles,3,label,MI)
                                    
                            end

                        else
                            
                            Cortex=handles.ESI.cortex;
%                             Cortex=load('M:\brainstorm_db\bci_fESI\anat\BE\tess_cortex_pial_low_fig.mat');
        
                            switch feattype
                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %    SOURCE CLUSTER ONE FREQ REGRESSION   %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'regress'
                                    
                                    % PLOT FREQ SPECIFIC R VALUES ON CORTEX
                                    Rtmp=SaveRegressSourceCluster.R(:,freqidx,taskidx);
                                    offset=-(max(abs(Rtmp))+.1*max(abs(Rtmp)));
                                    R=offset*ones(1,size(Cortex.Vertices,1));
                                    clusters=SaveRegressSourceCluster.clusters;
                                    for i=1:size(clusters,2)-1
                                        R(clusters{i})=Rtmp(i);
                                    end
                                    PlotBrain(handles,1,'R values',Cortex,R) 

                                    % PLOT FREQ SPECIFIC P VALUES ON CORTEX
                                    pvaltmp=SaveRegressSourceCluster.pval(:,freqidx,taskidx);
                                    offset=-(max(abs(pvaltmp))+.1*max(abs(pvaltmp)));
                                    pval=offset*ones(1,size(Cortex.Vertices,1));
                                    clusters=SaveRegressSourceCluster.clusters;
                                    for i=1:size(clusters,2)-1
                                        pval(clusters{i})=pvaltmp(i);
                                    end
                                    PlotBrain(handles,2,'p values',Cortex,pval)

                                    % PLOT FREQ SPECIFIC R-SQUARED VALUES ON CORTEX
                                    Rsqtmp=SaveRegressSourceCluster.Rsq(:,freqidx,taskidx);
                                    offset=-(max(abs(Rsqtmp))+.1*max(abs(Rsqtmp)));
                                    Rsq=offset*ones(1,size(Cortex.Vertices,1));
                                    clusters=SaveRegressSourceCluster.clusters;
                                    for i=1:size(clusters,2)-1
                                        Rsq(clusters{i})=Rsqtmp(i);
                                    end
                                    PlotBrain(handles,3,'R-squared values',Cortex,Rsq)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE CLUSTER ONE FREQ MAHAL    %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'mahal'
                                    
                                    % PLOT FREQ SPECIFIC MD ON CORTEX
                                    MDtmp=SaveMDSourceCluster.MD(:,freqidx,taskidx);
                                    offset=-(max(abs(MDtmp))+.1*max(abs(MDtmp)));
                                    MD=offset*ones(1,size(Cortex.Vertices,1));
                                    
                                    clusters=SaveMDSourceCluster.clusters;
                                    for i=1:size(clusters,2)-1
                                        MD(clusters{i})=MDtmp(i);
                                    end
                                    
                                    PlotBrain(handles,3,'Mahalanobis Distance',Cortex,MD)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %       SOURCE CLUSTER ONE FREQ RLDA      %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'rlda'
                                    
                                    lambdavect=SaveRLDASourceCluster.lambda;
                                    % Identify selected lambda
                                    lambdaidx=get(handles.freqfeatlambda,'value');
                                    if isequal(lambdaidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE LAMBDA TO VIEW RLDA RESULTS\n');
                                        set(handles.freqfeatlambda,'backgroundcolor','red');
                                        lambdaidx=0;
                                    elseif isequal(lambdaidx,2) % All
                                        lambdaidx=(1:size(lambdavect,2))+2;
                                        Acc=squeeze(SaveRLDASourceCluster.Acc(freqidx,taskidx,:));
                                    else % Numeric
                                        lambdaidx=lambdaidx-2;
                                    end

                                    % If a lambda is selected
                                    if ~isequal(lambdaidx,0)

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %       ONE FREQ, ALL LAMBDA      %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        if size(lambdaidx,2)>1

                                            % PLOT RLDA WEIGHTS FOR ONE FREQ, ALL LAMBDA
                                            W=squeeze(SaveRLDASourceCluster.W(:,freqidx,taskidx,:));
                                            % If not broadband option
                                            if freqidx<=size(freqvect,2)
                                                f=freqvect(freqidx);
                                                label.title=['RLDA Weights: f=',num2str(f),'Hz, lambda=All'];
                                            else
                                                label.title=['RLDA Weights: f=Broadband, lambda=All'];
                                            end
                                            label.xticklabel=lambdavect(1:2:end);
                                            label.xlabel='Lambda'; label.ylabel='Chan #';
                                            PlotTotal(handles,3,label,W);

                                            % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
                                            axes(handles.axes2); cla;
                                            title=['XVal Accuracies: f=',num2str(f),'Hz, lambda=ALL'];
                                            set(handles.Axis2Label,'string',title);
                                            plot(lambdavect,Acc,'k','LineWidth',2);
                                            set(handles.axes2,'color',[.94 .94 .94],...
                                                'ylim',[25 100],'xtick',lambdavect(1:3:end),...
                                                'position',handles.axes(2).position)
                                            ylabel('Accuracy (%)')
                                            grid on

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %       ONE FREQ, ONE LAMBDA      %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        else

                                            % PLOT RLDA WEIGHTS FOR ONE FREQ, ONE LAMBDA
                                            
                                            Wtmp=SaveRLDASourceCluster.W(:,freqidx,taskidx,lambdaidx);
                                            offset=-(max(abs(Wtmp))+.1*max(abs(Wtmp)));
                                            W=offset*ones(1,size(Cortex.Vertices,1));
                                            
                                            clusters=SaveRLDASourceCluster.clusters;
                                            for i=1:size(clusters,2)-1
                                                W(clusters{i})=Wtmp(i);
                                            end
                                            
                                            l=lambdavect(get(handles.freqfeatlambda,'value')-2);
                                            if freqidx<=size(freqvect,2)
                                                f=freqvect(freqidx);
                                                title=['RLDA Weights: f=',num2str(f),'Hz, lambda=',num2str(l)];
                                            else
                                                title=['RLDA Weights: f=Broadband, lambda=',num2str(l)];
                                            end
                                            
                                            PlotBrain(handles,3,title,Cortex,W);

                                        end
                                    end

                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE CLUSTER ONE FREQ PCA      %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'pca'
                                    
                                    pcvect=1:size(SavePCASourceCluster.chaninclude,1);
                                    % Identify selected lambda
                                    pcidx=get(handles.freqfeatpc,'value');
                                    set(handles.freqfeatpc,'backgroundcolor','white');
                                    if isequal(pcidx,1) % None selected
                                        fprintf(2,'MUST SELECT ONE PC TO VIEW PCA RESULTS\n');
                                        set(handles.freqfeatpc,'backgroundcolor','red');
                                        pcidx=0;
                                    elseif isequal(pcidx,2) % All
                                        pcidx=(1:size(pcvect,2))+2;
%                                         Acc=squeeze(SaveRLDASource.Acc(Freq,TaskInd,:));
                                    else % Numeric
                                        pcidx=pcidx-2;
                                    end
                                    
                                    if ~isequal(pcidx,0)

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %         ONE FREQ, ALL PC        %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        if size(pcidx,2)>1
                                            
                                            % PLOT RLDA WEIGHTS FOR ONE FREQ, ALL LAMBDA
                                            PCs=SavePCASourceCluster.U(:,:,freqidx,taskidx);
                                            % If not broadband option
                                            if freqidx<=size(freqvect,2)
                                                f=freqvect(freqidx);
                                                label.title=['PCA Weights: f=',num2str(f),'Hz, PC=All'];
                                            else
                                                label.title=['PCA Weights: f=Broadband, PC=All'];
                                            end
                                            label.xticklabel=[];
                                            label.xlabel='PCs'; label.ylabel='Chan #';
                                            PlotTotal(handles,3,label,PCs);
                                            
                                            % PLOT VARIANCE EXPLAINED
                                            VE=squeeze(SavePCASourceCluster.VE(freqidx,taskidx,:));
                                            TVE=squeeze(SavePCASourceCluster.TVE(freqidx,taskidx,:));
                                            axes(handles.axes1); cla; hold off
                                            scatter(1:size(VE,1),VE,15,'b'); hold on
                                            scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                            set(gca,'color',[.94 .94 .94])
                                            legend('Var Exp','Tot Var Exp','Location','Best')
                                            set(handles.Axis1Label,'string','PC Variance');
                                            
                                            
% % %                                             % PLOT X-VALIDATED TRAINING ACCURACIES FOR ONE FREQ, ALL LAMBDA
% % %                                             axes(handles.axes2); cla;
% % %                                             title=['XVal Accuracies: f=',num2str(f),'Hz, lambda=ALL'];
% % %                                             set(handles.Axis2Label,'string',title);
% % %                                             plot(LambdaVect,Acc,'k','LineWidth',2);
% % %                                             set(gca,'color',[.94 .94 .94],...
% % %                                                 'ylim',[25 100],'xtick',LambdaVect(1:3:end),...
% % %                                                 'position',handles.axes(2).position)
% % %                                             ylabel('Accuracy (%)')
% % %                                             grid on

                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        %         ONE FREQ, ONE PC        %
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        else
                                            
                                            PCstmp=SavePCASourceCluster.U(:,pcidx,freqidx,taskidx);
                                            offset=-(max(abs(PCstmp))+.1*max(abs(PCstmp)));
                                            PCs=offset*ones(1,size(Cortex.Vertices,1));
                                            
                                            clusters=SavePCASourceCluster.clusters;
                                            for i=1:size(clusters,2)-1
                                                PCs(clusters{i})=PCstmp(i);
                                            end
                                            pc=pcvect(get(handles.freqfeatpc,'value')-2);
                                            f=get(handles.freqfeatfreq,'value')-2;
                                            % If not broadband option
                                            if f<=size(freqvect,2)
                                                f=freqvect(f);
                                                title=['RLDA Weights: f=',num2str(f),'Hz, PC=',num2str(pc)];
                                            else
                                                title=['RLDA Weights: f=Broadband, PC=',num2str(pc)];
                                            end
                                            PlotBrain(handles,3,title,Cortex,PCs)
                                            
                                            % PLOT VARIANCE EXPLAINED
                                            VE=squeeze(SavePCASourceCluster.VE(freqidx,taskidx,:));
                                            TVE=squeeze(SavePCASourceCluster.TVE(freqidx,taskidx,:));
                                            axes(handles.axes1); cla; hold off
                                            scatter(1:size(VE,1),VE,15,'b'); hold on
                                            scatter(1:size(TVE,1),TVE,50,'g'); grid on
                                            legend('Var Exp','Tot Var Exp','Location','Best')
                                            scatter(pc,VE(pc),15,'r','filled');
                                            scatter(pc,TVE(pc),50,'r','filled');
                                            set(gca,'color',[.94 .94 .94])
                                            set(handles.Axis1Label,'string','PC Variance');

                                        end
                                    end
                                    
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE CLUSTER ONE FREQ FDA      %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'fda'
                                    
                                    % PLOT FREQ SPECIFIC FDA WEIGHTS ON CORTEX
                                    Wtmp=SaveFDASourceCluster.W(:,freqidx,taskidx);
                                    offset=-(max(abs(Wtmp))+.1*max(abs(Wtmp)));
                                    W=offset*ones(1,size(Cortex.Vertices,1));
                                    clusters=SavePCASourceCluster.clusters;
                                    for i=1:size(clusters,2)-1
                                        W(clusters{i})=Wtmp(i);
                                    end
                                            
                                    PlotBrain(handles,3,'Fisher LDA Weights',Cortex,W)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                %        SOURCE CLUSTER ONE FREQ MI       %
                                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                case 'mi'
                                    
                                    % PLOT FREQ SPECIFIC FDA WEIGHTS ON CORTEX
                                    MItmp=SaveMISourceCluster.MI(:,freqidx,taskidx);
                                    offset=-(max(abs(MItmp))+.1*max(abs(MItmp)));
                                    MI=offset*ones(1,size(Cortex.Vertices,1));
                                    clusters=SaveMISourceCluster.clusters;
                                    for i=1:size(clusters,2)-1
                                        MI(clusters{i})=MItmp(i);
                                    end
                                    
                                    PlotBrain(handles,3,'Fisher LDA Weights',Cortex,MI)
                                    
                                    set(handles.freqfeatlambda,'value',1,'backgroundcolor','white')
                                    set(handles.freqfeatpc,'value',1,'backgroundcolor','white')
                                    
                            end
                        end
                        
                end
            end
        end
    end
end






%%
function PlotBrain(handles,Axis,Label,Cortex,Data)

switch Axis
    case 1
        axes(handles.axes1); cla
        set(handles.Axis1Label,'string',Label);
        set(gca,'position',handles.axes(1).positioncb)
    case 2
        axes(handles.axes2); cla
        set(handles.Axis2Label,'string',Label);
        set(gca,'position',handles.axes(2).positioncb)
    case 3
        axes(handles.axes3); cla
        set(handles.Axis3Label,'string',Label);
        set(gca,'position',handles.axes(3).positioncb)
end
        
h=trisurf(Cortex.Faces,Cortex.Vertices(:,1),...
    Cortex.Vertices(:,2),Cortex.Vertices(:,3),Data);
set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
axis equal; axis off; view(-90,90); rotate3d on
light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
% cmap=jet(256); cmap(1,:)=repmat([.85 .85 .85],1,1); colormap(cmap);  
cmap=jet(128); cmap=[repmat([.85 .85 .85],[3 1]);cmap]; colormap(cmap)
colorbar
caxis([min(Data) max(Data)])


function PlotTopo(handles,Axis,Label,eLoc,Data)

switch Axis
    case 1
        axes(handles.axes1); cla
        set(handles.Axis1Label,'string',Label);
        set(gca,'position',handles.axes(1).positioncb)
    case 2
        axes(handles.axes2); cla
        set(handles.Axis2Label,'string',Label);
        set(gca,'position',handles.axes(2).positioncb)
    case 3
        axes(handles.axes3); cla
        set(handles.Axis3Label,'string',Label);
        set(gca,'position',handles.axes(3).positioncb)
end

topoplot(Data,eLoc,'electrodes','ptlabels','numcontour',0);
view(0,90); axis xy; rotate3d off;
set(gcf,'color',[.94 .94 .94]);
cmap=jet(256); colormap(cmap); colorbar; caxis auto 


function PlotTotal(handles,Axis,Label,Data)

switch Axis
    case 1
        axes(handles.axes1); cla
        set(handles.Axis1Label,'string',Label.title);
        set(gca,'position',handles.axes(1).positioncb)
    case 2
        axes(handles.axes2); cla
        set(handles.Axis2Label,'string',Label.title);
        set(gca,'position',handles.axes(2).positioncb)
    case 3
        axes(handles.axes3); cla
        set(handles.Axis3Label,'string',Label.title);
        set(gca,'position',handles.axes(3).positioncb)
end

imagesc(Data);
if isfield(Label,'xticklabel') && ~isempty(Label.xticklabel)
    set(gca,'xticklabel',Label.xticklabel);
    if iscell(Label.xticklabel)
        Xtick=Label.xticklabel{:};
        set(gca,'xtick',1:1:size(Xtick,2)+1)
    end
else
    set(gca,'xticklabel',[])
end

if isfield(Label,'xlabel') && ~isempty(Label.xlabel)
    xlabel(Label.xlabel)
end

if isfield(Label,'ylabel') && ~isempty(Label.ylabel)
    ylabel(Label.ylabel)
end

view(0,90); axis xy; rotate3d off; set(gcf,'color',[.94 .94 .94]);
cmap=jet(256); colormap(cmap);
colorbar; caxis auto;  


