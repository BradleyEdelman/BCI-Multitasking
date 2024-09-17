function [hObject,handles]=bci_ESI_DispSaved(hObject,handles,varargin)

nargs=nargin;
if isequal(nargs,2)

    value=get(handles.dispfiles,'value');
    dispfiles=cell(get(handles.dispfiles,'string'));
    displayfile=dispfiles{value};
    
elseif isequal(nargs,4)
    
    displayfile=varargin{1};
    AX=varargin{2};
    
end
    
    
if ismember(displayfile,{'Cortex' 'Lead Field' 'Noise Covariance'...
        'Source Covariance' 'Source Prior' 'Clusters'})
    
    switch displayfile
        case 'Cortex'
            
            % Check if variable is stored in handles
            if ~isempty(handles.ESI.cortex)
                Cortex=handles.ESI.cortex;
            % If not, check if ESI variables have been saved
            
            elseif exist(handles.ESI.savefile.file,'file')
                load(handles.ESI.savefile);
                Cortex=SaveESIcortex;
                
            else
                fprintf(2,'CORTEX NOT STORED IN HANDLES OR SAVED TO FILE\n');
                dispfiles(value)=[];
                set(handles.dispfiles,'string',dispfiles);
                set(handles.dispfiles,'value',size(dispfiles,1));
                
            end
            
            
            if exist('Cortex','var')
                
                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                 if exist('AX','var')
                    axes(AX);
                else
                    set(handles.Axis3Label,'string','Cortex');
                    axes(handles.axes3)
                 end
                dip=size(Cortex.Vertices,1);
                h=trisurf(Cortex.Faces,Cortex.Vertices(:,1),...
                    Cortex.Vertices(:,2),Cortex.Vertices(:,3),zeros(1,dip));
                set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                axis equal; axis off; view(-90,90)
                light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
                cmap=[.85 .85 .85]; colormap(cmap); caxis auto; rotate3d on
                
            end

        case 'Lead Field'
            
            % Check if variable is stored in handles
            if ~isempty(handles.ESI.cortex) && ~isempty(handles.ESI.leadfieldweights)
                Cortex=handles.ESI.cortex;
                R=handles.ESI.leadfieldweights;
                
            elseif exist(handles.ESI.savefile.file,'file')
                load(handles.ESI.savefile);
                Cortex=SaveESIcortex;
                R=SaveESIleadfieldweights;
                
            else
                fprintf(2,'CORTEX NOT STORED IN HANDLES OR SAVED TO FILE\n');
                dispfiles(value)=[];
                set(handles.dispfiles,'string',dispfiles);
                set(handles.dispfiles,'value',size(dispfiles,1));
                
            end
            
            
            if exist('Cortex','var') && exist('R','var')
                
                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                set(handles.Axis3Label,'string','Lead Field');
                h=trisurf(Cortex.Faces,Cortex.Vertices(:,1),...
                    Cortex.Vertices(:,2),Cortex.Vertices(:,3),R);
                set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                axis equal; axis off; view(-90,90)
                light; h2=light; lightangle(h2,90,-90); h3=light; lightangle(h3,-90,30);
                cmap=jet(256); colormap(cmap); caxis auto; rotate3d on
                    
            end
            
        case 'Noise Covariance'
            
            % Check if variable is stored in handles
            if ~isempty(handles.ESI.noisetype)
                
                noisetype=handles.ESI.noisetype;
                switch noisetype
                    case 1 % None
                    case 2 % No Noise Estimation
                        noisecov=handles.ESI.noisecov.nomodel;
                    case {3,4} % Diagonal or Full
                        noisecov_real=handles.ESI.noisecov.real;
                        noisecov_imag=handles.ESI.noisecov.imag;
                        noisecov=noisecov_real+noisecov_imag;
                end
                
            elseif exist(handles.ESI.savefile,'file')
                
                load(handles.ESI.savefile);
                noisetype=SaveESI.noisetype;
                switch noisetype
                    case 1 % None
                    case 2 % No Noise Estimation
                        noisecov=SaveESI.NoiseCov;
                    case {3,4} % Diagonal or Full
                        NoiseCov_real=SaveESI.noisecov.real;
                        NoiseCov_imag=SaveESI.noisecov.imag;
                        noisecov=NoiseCov_real+NoiseCov_imag;
                end
                
            else
                fprintf(2,'NOISE COVARIANCE NOT STORED IN HANDLES OR SAVED TO FILE\n');
                dispfiles(value)=[];
                set(handles.dispfiles,'string',dispfiles);
                set(handles.dispfiles,'value',size(dispfiles,1));
            end
            
            
            if exist('noisetype','var') && exist('noisecov','var')
                
                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                set(handles.Axis3Label,'string','Noise Covariance');
                axes(handles.axes3); rotate3d off;
                imagesc(noisecov); 
                axis off; axis auto; axis equal; view(0,90);
                cmap=jet(256); colormap(cmap);
                caxis([min(noisecov(:)) max(noisecov(:))*1.1])
                
            end
            
        case 'Source Covariance'
            
            % Check if variable is stored in handles
            if ~isempty(handles.ESI.NOCLUSTER.sourcecov)
                sourcecov=handles.ESI.NOCLUSTER.sourcecov;
            elseif exist(handles.ESI.savefile,'file')
                load(handles.ESI.savefile);
                sourcecov=SaveESI.sourcecov;
            else
                fprintf(2,'CORTEX NOT STORED IN HANDLES OR SAVED TO FILE\n');
                dispfiles(value)=[];
                set(handles.dispfiles,'string',dispfiles);
                set(handles.dispfiles,'value',size(dispfiles,1));
            end
            
            
            if exist('sourcecov','var')
                
                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                set(handles.Axis3Label,'string','Source Covariance');
                axes(handles.axes3); rotate3d off;
                imagesc(sourcecov); 
                axis off; axis auto; axis equal; view(0,90);
                cmap=jet(256); colormap(cmap);
                caxis([min(sourcecov(:)) max(sourcecov(:))*1.1])
                
            end
            
        case 'Source Prior'
        	
            % Check if variable is stored in handles
            if ~isempty(handles.ESI.priorind)
                PriorInd=handles.ESI.priorind;
                PriorVal=handles.ESI.priorval;
                Cortex=handles.ESI.cortex;
                
            % If not, check if ESI variables have been saved
            elseif exist(handles.ESI.savefile,'file')
                load(handles.ESI.savefile);
                PriorInd=SaveESI.priorind;
                PriorVal=SaveESI.priorval;
                Cortex=SaveESI.cortex;
                
            else
                fprintf(2,'fMRI PRIOR NOT STORED IN HANDLES OR SAVED TO FILE\n');
                dispfiles(value)=[];
                set(handles.dispfiles,'string',dispfiles);
                set(handles.dispfiles,'value',size(dispfiles,1));
            end
        
            if exist('PriorInd','var') && exist('PriorVal','var') &&...
                    exist('Cortex','var')
                Prior=Cortex.SulciMap;
                Prior=-.1*Prior-.1;
                PriorVal=(PriorVal-min(PriorVal))/(max(PriorVal)-min(PriorVal));
                Prior(PriorInd)=PriorVal;

%                     Subj=get(handles.Initials,'string');
%                     HRiCortex=strcat('M:\_bci_ESI\Brad_Test_Files\tess_cortex_pial_low_fig.mat');
%                     if exist(HRiCortex,'file')
%                         Cortex=load(HRiCortex);
%                     else
%                         Cortex=handles.ESI.Cortex;
%                     end

                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                set(handles.Axis3Label,'string','Source Prior');
                h=trisurf(Cortex.Faces,Cortex.Vertices(:,1),...
                    Cortex.Vertices(:,2),Cortex.Vertices(:,3),Prior);
                set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                axis equal; axis off; view(-90,90); rotate3d on
                light; h2=light; lightangle(h2,90,-90); h3=light;  lightangle(h3,-90,30);
                cmap=jet(128); cmap=[repmat([.7 .7 .7],[10,1]);repmat([.85 .85 .85],[10,1]);cmap]; colormap(cmap);
                caxis([-.2 1]);

            end
             
        case 'Clusters'
            
            % Check if variable is stored in handles
            if ~isempty(handles.ESI.CLUSTER.clusters)
                Clusters=handles.ESI.CLUSTER.verticesassigned;
                Cortex=handles.ESI.cortex;
                VertIdxExclude=handles.ESI.vertidxexclude;
                
            % If not, check if ESI variables have been saved
            elseif isfield(handles.ESI,'savefile') && exist(handles.ESI.savefile,'file')
                load(handles.ESI.savefile);
                Clusters=SaveESI.ESI.CLUSTER.verticesassigned;
                Cortex=SaveESI.ESI.cortex;
                VertIdxExclude=SaveESI.ESI.vertidxexclude;
                
            else
                fprintf(2,'fMRI PRIOR NOT STORED IN HANDLES OR SAVED TO FILE\n');
                dispfiles(value)=[];
                set(handles.dispfiles,'string',dispfiles);
                set(handles.dispfiles,'value',size(dispfiles,1));
            end

%             Cortex=load('M:\brainstorm_db\bci_ESI\anat\BE\tess_cortex_pial_low_fig.mat');
            if exist('Clusters','var') && exist('Cortex','var')
                
                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                if exist('AX','var')
                    axes(AX);
                else
                    set(handles.Axis3Label,'string','Cortical Clusters');
                    axes(handles.axes3)
                end
                h=trisurf(Cortex.Faces,Cortex.Vertices(:,1),...
                Cortex.Vertices(:,2),Cortex.Vertices(:,3),Clusters);
                set(h,'FaceColor','flat','EdgeColor','None','FaceLighting','gouraud');
                axis equal; axis off; view(-90,90); rotate3d on
                light; h2=light; lightangle(h2,90,-90); h3=light;  lightangle(h3,-90,30);
                cmap=[1 0 1;1 0 .5;.45 .45 1;.6 .6 0;.55 1 .75;...
                    .6 .3 0;1 .8 .8;1 0 0;1 .5 0;1 1 0;0 1 0;0 1 1;0 0 1;.5 0 1];
                numrep=ceil(size(unique(Clusters),1)/size(cmap,1));
                cmap=repmat(cmap,[numrep 1]);
                if ~isempty(VertIdxExclude)
                    cmap=[.85 .85 .85;cmap];
                end
                colormap(cmap); colorbar; caxis auto;
                
            end

        case 'Decoder Source'
            
            if ~exist(handles.save.decoder.source,'file')
                fprintf(2,'SOURCE DECODER FILE DOES NOT EXIST, TRAIN DECODER TO RESAVE\n');
                dispfiles(value)=[];
                set(handles.SaveFiles,'string',dispfiles);
                set(handles.SaveFiles,'value',size(dispfiles,1));
            else
                
                load(handles.save.cortex);
                SaveCortex=load('M:\brainstorm_db\bci_ESI\anat\BE\tess_cortex_pial_low_fig.mat');
                load(handles.save.decoder.source);
                DecoderType=SaveDecoderSource.DecoderType;
                TrainingScheme=SaveDecoderSource.TrainingScheme;
                
                switch DecoderType
                    case 1 % None
                    case 2 % Fisher LDA
                        
                        switch TrainingScheme
                          case 1 % None
                          case 2 % Average Time Window
                              
                            [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                            set(handles.Axis1Label,'string','Fisher Data Projection');
                            Y=SaveDecoderSource.Y;
                            plot(Y{1},zeros(1,size(Y{1},2)),'bo'); hold on
                            plot(Y{2},zeros(1,size(Y{2},2)),'ro');
%                             DB=SaveDecoderSource.DB(1,2);
%                             quiver(DB,-.5,0,2,'k','LineWidth',2);
                            hold off; axis off; axis auto
                              
                            set(handles.Axis3Label,'string','Fisher DA Weights');
                            Weights=SaveDecoderSource.W{1,2};
                            DispWeights=-.1*ones(1,size(SaveCortex.Vertices,1));
                            DispWeights(handles.TrainParam.verticesinclude)=Weights;
                            h=trisurf(SaveCortex.Faces,SaveCortex.Vertices(:,1),...
                            SaveCortex.Vertices(:,2),SaveCortex.Vertices(:,3),DispWeights);
                            set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                            axis equal; axis off; view(-90,90); caxis auto;
                            light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
                            caxis auto; rotate3d on
                            cmap=jet(256); cmap(1,:)=repmat([.85 .85 .85],1,1); colormap(cmap);
                              
                          case 3 % Time Resolved

                            Y=SaveDecoderSource.Y;
                            figure;
                            for i=1:size(Y,2)
                                subplot(5,5,i);
                                plot(Y{1,i},zeros(1,size(Y{1},2)),'bo'); hold on
                                plot(Y{2,i},zeros(1,size(Y{2},2)),'ro');
                                plot(Y{3,i},zeros(1,size(Y{3},2)),'go');
%                                 DB=SaveDecoderSource.DB(1,2,i);
%                                 quiver(DB,-.5,0,2,'k','LineWidth',2);
                                hold off; axis off; axis auto
                            end
                            set(gcf,'Color',[.94 .94 .94]);

                            Weights=SaveDecoderSource.Weights;
                            figure;
                            for i=1:size(Weights,2)
                                subplot(5,5,i)
                                DispWeights=-.1*ones(1,size(SaveCortex.Vertices,1));
                                DispWeights(handles.TrainParam.verticesinclude)=Weights(:,i);
                                h=trisurf(SaveCortex.Faces,SaveCortex.Vertices(:,1),...
                                SaveCortex.Vertices(:,2),SaveCortex.Vertices(:,3),DispWeights);
                                set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                                axis equal; axis off; view(-90,90); caxis auto;
                                light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
                            end
                            rotate3d on
                            set(gcf,'Color',[.94 .94 .94]);
                            cmap=jet(256); cmap(1,:)=repmat([.85 .85 .85],1,1); colormap(cmap);
                            suptitle('Time Resolved Sensor Fisher LDA Classifier Weights');
                              
                      end
                        
                    case 3 % LDA
                        
                        switch TrainingScheme
                            case 1 % None
                            case 2 % Average Time Window
                              
                                load(handles.save.cortex);
                                SaveCortex=load('M:\brainstorm_db\bci_ESI\anat\BE\tess_cortex_pial_low_fig.mat');
                                [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                                set(handles.Axis3Label,'string','Mahalanobis Distance');
                                W=SaveDecoderSource.W{2,3};
                                DispWeights=-.1*ones(1,size(SaveCortex.Vertices,1));
                                DispWeights(handles.TrainParam.verticesinclude)=W;
                                h=trisurf(SaveCortex.Faces,SaveCortex.Vertices(:,1),...
                                SaveCortex.Vertices(:,2),SaveCortex.Vertices(:,3),DispWeights);
                                set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                                axis equal; axis off; view(-90,90); caxis auto;
                                light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
                                set(gcf,'Color',[.94 .94 .94]); rotate3d on
                                cmap=jet(256); cmap(1,:)=repmat([.85 .85 .85],1,1); colormap(cmap);
                                colorbar
                              
                          case 3 % Time Resolved
                        end
                end
            end
            
        case 'Decoder Sensor'
            
            if ~exist(handles.save.decoder.sensor,'file')
                fprintf(2,'SENSOR DECODER FILE DOES NOT EXIST, TRAIN DECODER TO RESAVE\n');
                dispfiles(value)=[];
                set(handles.SaveFiles,'string',dispfiles);
                set(handles.SaveFiles,'value',size(dispfiles,1));
             else

              load(handles.save.decoder.sensor);
              DecoderType=SaveDecoderSensor.DecoderType;
              TrainingScheme=SaveDecoderSensor.TrainingScheme;
              
              switch DecoderType
                  case 1 % None
                  case 2 % Fisher LDA
                      
                      switch TrainingScheme
                          case 1 % None
                          case 2 % Average Time Window
                              
                            [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                            set(handles.Axis1Label,'string','Fisher Data Projection');
                            Y=SaveDecoderSensor.Dsq;
                            plot(Y{1},zeros(1,size(Y{1},2)),'bo'); hold on
                            plot(Y{2},zeros(1,size(Y{2},2)),'ro');
                            plot(Y{3},zeros(1,size(Y{3},2)),'go'); hold off
                            axis off; axis auto
                              
                            Weights=SaveDecoderSensor.W(:,3);
                            set(handles.Axis3Label,'string','Fisher DA Weights');
                            topoplot(Weights,handles.TrainParam.eLoc,'electrodes','ptlabels');
                            view(0,90); axis xy; set(gcf,'color',[.94 .94 .94]);
                            cmap=jet(256); colormap(cmap); caxis auto
                              
                          case 3 % Time Resolved
                              
                                Y=SaveDecoderSensor.TrainDataProjection;
                                figure;
                                for i=1:size(Y,2)
                                    subplot(4,4,i);
                                    plot(Y{1,i},zeros(1,size(Y{1,i},2)),'bo'); hold on
                                    plot(Y{2,i},zeros(1,size(Y{2,i},2)),'ro');
                                    DB=SaveDecoderSensor.DB(1,2,i);
                                    quiver(DB,-.5,0,2,'k','LineWidth',2);
                                    hold off; axis off; axis auto
                                end
                                set(gcf,'Color',[.94 .94 .94]);

                                Weights=SaveDecoderSensor.Weights;
                                figure;
                                for i=1:size(Weights,2)
                                	subplot(4,4,i)
                                	topoplot(Weights(:,i),handles.TrainParam.eLoc);
                                end
                                set(gcf,'Color',[.94 .94 .94]);
                                suptitle('Time Resolved Sensor Fisher LDA Classifier Weights');
                      end

                  case 3 % LDA
                      
                      switch TrainingScheme
                          case 1 % None
                          case 2 % Average Time Window
                            
                            [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                            W=SaveDecoderSensor.Dsq(3,:);
                            set(handles.Axis3Label,'string','Fisher DA Weights');
                            topoplot(W,handles.TrainParam.eLoc,'electrodes','ptlabels');
                            view(0,90); axis xy; set(gcf,'color',[.94 .94 .94]);
                            cmap=jet(256); colormap(cmap); caxis auto
                              
                              
                          case 3 % Time Resolved
                      end
              end
            end
    end
    
elseif ~isequal(size(strfind(DisplayFile,'Sensor MD'),2),0)
    
    TaskInd=str2double(regexp(DisplayFile,'.\d+','match'));
    load(handles.save.decoder.sensor);
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
    
    if TaskInd>size(SaveDecoderSensor.Dsq,1)
        dispfiles(value)=[];
        set(handles.SaveFiles,'string',dispfiles);
        set(handles.SaveFiles,'value',size(dispfiles,1));
    else
        MD=SaveDecoderSensor.Dsq(TaskInd,:);
        set(handles.Axis3Label,'string','Mahalanobis Distance');
        topoplot(MD,handles.TrainParam.eLoc,'electrodes','ptlabels');
        view(0,90); axis xy; set(gcf,'color',[.94 .94 .94]);
        cmap=jet(256); colormap(cmap); caxis auto
    end
    
elseif ~isequal(size(strfind(DisplayFile,'Source MD'),2),0)
    
    TaskInd=str2double(regexp(DisplayFile,'.\d+','match'));
    load(handles.save.decoder.source);
    load(handles.save.cortex);
    SaveCortex=load('M:\brainstorm_db\bci_ESI\anat\BE\tess_cortex_pial_low_fig.mat');
    [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
    
    if TaskInd>size(SaveDecoderSource.Dsq,1)
        dispfiles(value)=[];
        set(handles.SaveFiles,'string',dispfiles);
        set(handles.SaveFiles,'value',size(dispfiles,1));
    else
        set(handles.Axis3Label,'string','Mahalanobis Distance');
        MD=SaveDecoderSource.Dsq(TaskInd,:);
        DispMD=-.1*ones(1,size(SaveCortex.Vertices,1));
        DispMD(handles.TrainParam.verticesinclude)=MD;
        h=trisurf(SaveCortex.Faces,SaveCortex.Vertices(:,1),...
        SaveCortex.Vertices(:,2),SaveCortex.Vertices(:,3),DispMD);
        set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
        axis equal; axis off; view(-90,90); caxis auto;
        light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
        set(gcf,'Color',[.94 .94 .94]); rotate3d on
        cmap=jet(256); cmap(1,:)=repmat([.85 .85 .85],1,1); colormap(cmap); colorbar
    end
   
elseif ~isequal(size(strfind(DisplayFile,'Sensor Weights'),2),0)
    
    if ~exist(handles.save.decoder.sensor,'file')
        fprintf(2,'SENSOR DECODER FILE DOES NOT EXIST, TRAIN DECODER TO RESAVE\n');
        dispfiles(value)=[];
        set(handles.SaveFiles,'string',dispfiles);
        set(handles.SaveFiles,'value',size(dispfiles,1));
    else

        load(handles.save.decoder.sensor);
        DecoderType=SaveDecoderSensor.DecoderType;
        TrainingScheme=SaveDecoderSensor.TrainingScheme;
        TaskInd=str2double(regexp(DisplayFile,'.\d+','match'));
        
        if TaskInd>size(SaveDecoderSensor.OVA,2)
            dispfiles(value)=[];
            set(handles.SaveFiles,'string',dispfiles);
            set(handles.SaveFiles,'value',size(dispfiles,1));
        else
            switch DecoderType
                case 1 % None
                case 2 % Fisher LDA
                    switch TrainingScheme
                        case 1 % None
                        case 2 % Average Time Window

                            [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                            set(handles.Axis3Label,'string','FDA Sensor Weights');
                            W=SaveDecoderSensor.OVA(TaskInd).W;
                            topoplot(W,handles.TrainParam.eLoc,'electrodes','ptlabels');
                            view(0,90); axis xy; set(gcf,'color',[.94 .94 .94]);
                            cmap=jet(256); colormap(cmap); caxis auto
                    end

                case 3 % LDA
                    switch TrainingScheme
                        case 1 % None
                        case 2 % Average Time Window

                            [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                            set(handles.Axis3Label,'string','LDA Sensor Weights');
                            W=SaveDecoderSensor.OVA(TaskInd).W{1,2};
                            topoplot(W,handles.TrainParam.eLoc,'electrodes','ptlabels');
                            view(0,90); axis xy; set(gcf,'color',[.94 .94 .94]);
                            cmap=jet(256); colormap(cmap); caxis auto

                        case 3 % Time Resolved
                    end
            end
        end
    end
    
elseif ~isequal(size(strfind(DisplayFile,'Source Weights'),2),0)

    if ~exist(handles.save.decoder.source,'file')
        fprintf(2,'SOURCE DECODER FILE DOES NOT EXIST, TRAIN DECODER TO RESAVE\n');
        dispfiles(value)=[];
        set(handles.SaveFiles,'string',dispfiles);
        set(handles.SaveFiles,'value',size(dispfiles,1));
    else

%         load(handles.save.cortex);
        SaveCortex=load('M:\brainstorm_db\bci_ESI\anat\BE\tess_cortex_pial_low_fig.mat');
        load(handles.save.decoder.source);
        DecoderType=SaveDecoderSource.DecoderType;
        TrainingScheme=SaveDecoderSource.TrainingScheme;
        TaskInd=str2double(regexp(DisplayFile,'.\d+','match'));

        if TaskInd>size(SaveDecoderSource.OVA,2)
            dispfiles(value)=[];
            set(handles.SaveFiles,'string',dispfiles);
            set(handles.SaveFiles,'value',size(dispfiles,1));
        else
            switch DecoderType
                case 1 % None
                case 2 % Fisher LDA
                    switch TrainingScheme
                        case 1 % None
                        case 2 % Average Time Window

                        [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                        set(handles.Axis3Label,'string','FDA Source Weights');
                        W=SaveDecoderSource.OVA(TaskInd).W; min(W)
                        if min(W)<0
                            DispWeights=1.1*min(W)*ones(1,size(SaveCortex.Vertices,1));
                        else 
                            DispWeights=-1.1*min(W)*ones(1,size(SaveCortex.Vertices,1));
                        end
                        DispWeights(handles.TrainParam.verticesinclude)=W;
                        h=trisurf(SaveCortex.Faces,SaveCortex.Vertices(:,1),...
                        SaveCortex.Vertices(:,2),SaveCortex.Vertices(:,3),DispWeights);
                        set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                        axis equal; axis off; view(-90,90); caxis auto;
                        light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
                        set(gcf,'Color',[.94 .94 .94]); rotate3d on
                        cmap=jet(256); cmap(1,:)=repmat([.85 .85 .85],1,1); colormap(cmap);
                    end

                case 3 % LDA
                    switch TrainingScheme
                        case 1 % None
                        case 2 % Average Time Window

                            [hObject,handles]=bci_ESI_Reset(hObject,handles,'None',[]);
                            set(handles.Axis3Label,'string','LDA Source Weights');
                            W=SaveDecoderSource.OVA(TaskInd).W{1,2};
                            if min(W)<0
                                DispWeights=1.1*min(W)*ones(1,size(SaveCortex.Vertices,1));
                            else 
                                DispWeights=-1.1*min(W)*ones(1,size(SaveCortex.Vertices,1));
                            end
                            DispWeights(handles.TrainParam.verticesinclude)=W;
                            h=trisurf(SaveCortex.Faces,SaveCortex.Vertices(:,1),...
                            SaveCortex.Vertices(:,2),SaveCortex.Vertices(:,3),DispWeights);
                            set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud');
                            axis equal; axis off; view(-90,90); caxis auto;
                            light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);

                            rotate3d on
                            set(gcf,'Color',[.94 .94 .94]);
                            cmap=jet(256); cmap(1,:)=repmat([.85 .85 .85],1,1); colormap(cmap);

                        case 3 % Time Resolved
                    end
            end
        end
    end
    
else
    dispfiles(value)=[];
    set(handles.SaveFiles,'string',dispfiles);
    set(handles.SaveFiles,'value',size(dispfiles,1));
end