%% CODE WRITTEN BY ... [TO BE ADDED IF PAPER IS ACCEPTED] AND USED IN PLOS ONE PAPER "SYNCHRONIZATION AND DECEPTION"

%% WHAT THIS PROGRAM DOES:

% RUNS WINDOWED LAGGED CROSS-CORRELATION ON TEXT FILE OUTPUT FROM MotionAnalysisGeneratedFlow.m

clear all

ROUNDS = [1 2]; % when have multiple conditions where data is in separate locations, folders; in this case between-subjects data for disagreement(1) and agreement(2)

for getRound = 1:length(ROUNDS)
    clear Sync SyncAll
    ROUND = ROUNDS(getRound);
    FILELOC = ['~/' int2str(ROUND) '/motionSeriesRegions/'];
    
    if ROUND == 1,
        SUBS = [7:9 11 13 15 18:19 21 24:25 27 30:31 33:34 37 35 38 26 36 39:41];
        SUBSv = [9 11 13 15 18:19 21 24:25 27 30:31 33:34 37 35 38 26 36 39:41 7:8];
        SESSION = 2:3;
        CONFLICT = 1;
    elseif ROUND == 2,
        SUBS = [1:6 12:16 19:21 23:26 28:30 32:34]; 
        SUBSv = [2:6 12:17 19:21 23:26 28:30 32:34 1];
        SESSION = 2:3;
        CONFLICT = 2;
    end
    
    %%// BRING IN TEXT FILES OF MOTION ENERGY FLOWS GENERATED IN MotionAnalysisGenerateFlow.m AS VARIABLES
    files_list = dir([FILELOC '*.txt']);
    file_number = numel(files_list);
    for k = 1:file_number
        information = files_list(k);
        file_name = {information.name};
        var_name = {file_name{1}(1:end-4)}; % remove '.txt'
        file_name1 = information.name;
        eval(['data_imp = importdata(''' num2str([FILELOC file_name1]) ''' );']);
        eval(['move' cell2mat(var_name) ' = data_imp;']); 
        clear data_imp information
    end
    
    %%// INITIALIZE VARIABLES AND SET PARAMETERS
    tally = 0; CORR = 0; VCORR = 0;     
    FRAMESEC = .1668; % what is sampling rate of time series (video)? originally, 29.97Hz (33.37ms), taking every 5th frame (166.83ms), approximately 6Hz sampling rate (1001.001ms)
    SHIFT = 30; % going to go with 5000 ms; SET LAG FOR cross-correlation, windowed cross-correlation
    lagsec = floor(SHIFT*FRAMESEC); % needs to be an integer    
    [b1, a1] = butter(3,.10,'low'); 
    WIN_SECTIONS = SHIFT*2; % breaking windows into 2 x SHIFT, so windows of 10000 ms each
    
    bregion = {'HEAD','MID','LEGS','ALL'};
    
    for dyad=1:length(SUBS) % first column,
        for sess=SESSION % second column,
            for bindex=1:4 % last column
                
                %%// IDENTIFY DYADS IN CORRECT CONDITIONS AND REGIONS OF INTEREST
                %DA, dyad, session, convodeception(either 0 or 1)
                if exist([FILELOC num2str(SUBS(dyad)) '_' num2str(sess) '_DA_0_' cell2mat(bregion(bindex)) '.txt'],'file') == 2,
                    convodec = 0;
                    eval(['y1=move' num2str(SUBS(dyad)) '_' num2str(sess) '_DA_0_' cell2mat(bregion(bindex)) ';'])
                elseif exist([FILELOC num2str(SUBS(dyad)) '_' num2str(sess) '_DA_1_' cell2mat(bregion(bindex)) '.txt'],'file') == 2,
                    convodec = 1;
                    eval(['y1=move' num2str(SUBS(dyad)) '_' num2str(sess) '_DA_1_' cell2mat(bregion(bindex)) ';'])
                end
                
                %notDA, dyad, session, convodeception(either 0 or 1)
                if exist([FILELOC num2str(SUBS(dyad)) '_' num2str(sess) '_notDA_0_' cell2mat(bregion(bindex)) '.txt'],'file') == 2,
                    eval(['y2=move' num2str(SUBS(dyad)) '_' num2str(sess) '_notDA_0_' cell2mat(bregion(bindex)) ';'])
                elseif exist([FILELOC num2str(SUBS(dyad)) '_' num2str(sess) '_notDA_1_' cell2mat(bregion(bindex)) '.txt'],'file') == 2,
                    eval(['y2=move' num2str(SUBS(dyad)) '_' num2str(sess) '_notDA_1_' cell2mat(bregion(bindex)) ';'])
                end
                
                % virtual partner to compare DA against
                if exist([FILELOC num2str(SUBSv(dyad)) '_' num2str(sess) '_notDA_0_' cell2mat(bregion(bindex)) '.txt'],'file') == 2,
                    eval(['y2v=move' num2str(SUBSv(dyad)) '_' num2str(sess) '_notDA_0_' cell2mat(bregion(bindex)) ';'])
                elseif exist([FILELOC num2str(SUBSv(dyad)) '_' num2str(sess) '_notDA_1_' cell2mat(bregion(bindex)) '.txt'],'file') == 2,
                    eval(['y2v=move' num2str(SUBSv(dyad)) '_' num2str(sess) '_notDA_1_' cell2mat(bregion(bindex)) ';'])
                end
                
                %%// PREPROCESS, NORMALIZE AND FILTER
                y1z = zscore(y1(:,1));
                DA = filter(b1,a1,y1z);
                y2z = zscore(y2(:,1));
                notDA = filter(b1,a1,y2z);
                y2vz = zscore(y2v(:,1));
                notDAv = filter(b1,a1,y2vz);
                                
                % METHODS FOR MEASURING SYNCHRONIZATION: CORR, XCORR
                
                tally = tally + 1;
                disp(tally)
                
                % cross-correlation between shifted time series with lags up to 5000 (five seconds) in either direction,
                Sync.xcorr(tally,:) = [SUBS(dyad) sess convodec CONFLICT bindex bindex xcorr(DA,notDA,SHIFT,'coeff')']; % see:http://stats.stackexchange.com/questions/49901/intuitive-understanding-covariance-cross-covariance-auto-cross-correliation-a or EVERNOTE 'stats' for a great explanation

                % cross-correlation between shifted time series with lags up to 5000 (five seconds) BUT within windows prespecifed above (in this case, windows of 10 seconds // accounts for, takes advantage of, non stationarity)
                [Cdata,Ldata,Tdata] = corrgram(DA,notDA,SHIFT,fix(length(DA)/WIN_SECTIONS),0); % no overlap betwen win_section
                Sync.wincross(tally,:) = [SUBS(dyad) sess convodec CONFLICT bindex bindex mean(Cdata,2)'];

                % can use this to look at differences over time, across window sizes (very useful for determining differences from early windows to late windows, i.e., bins)
                try % sometimes the conversations run longer than average, and an additional window is added to analysis, this truncates it to what is specified above (e.g., caps the size)
                    Sync.wincross2(:,:,tally) = [repmat(SUBS(dyad),size(Cdata,1),1) repmat(sess,size(Cdata,1),1) repmat(convodec,size(Cdata,1),1) repmat(CONFLICT,size(Cdata,1),1) repmat(bindex,size(Cdata,1),1) repmat(bindex,size(Cdata,1),1) Cdata(:,1:WIN_SECTIONS)];
                catch
                    disp(['Subscripting problem when trying to build WINCROSS2 for ' num2str(SUBS(dyad)) ' ' num2str(sess) ' ' num2str(convodec)])
                end
                disp('Completed CORR ANALYSIS')

                % virtual analysis
                size_virt = min(size(DA,1),size(notDAv,1)); % grab whichever is smallest
                Sync.xcorrV(tally,:) = [SUBS(dyad) sess convodec CONFLICT bindex bindex xcorr(DA(1:size_virt),notDAv(1:size_virt),SHIFT,'coeff')'];

                [CdataV,LdataV,TdataV] = corrgram(DA(1:size_virt),notDAv(1:size_virt),SHIFT,fix(length(DA(1:size_virt))/WIN_SECTIONS),0); % no overlap betwen win_section
                Sync.wincrossV(tally,:) = [SUBS(dyad) sess convodec CONFLICT bindex bindex mean(CdataV,2)'];
                try
                    Sync.wincross2V(:,:,tally) = [repmat(SUBS(dyad),size(CdataV,1),1) repmat(sess,size(CdataV,1),1) repmat(convodec,size(CdataV,1),1) repmat(CONFLICT,size(CdataV,1),1) repmat(bindex,size(CdataV,1),1) repmat(bindex,size(CdataV,1),1) CdataV(:,1:WIN_SECTIONS)];
                catch
                    disp(['Subscripting problem when trying to build WINCROSS2V for ' num2str(SUBS(dyad)) ' ' num2str(sess) ' ' num2str(convodec)])
                end
                disp('Completed CORR VIRTUAL')

            end
            clear y1 y2 y2v j1 DA notDA notDAv convodec both
        end
    end
    save(['mat/' 'SyncAllBP_' num2str(lagsec) 'sec.mat'])
    save(['mat/' 'SyncBP_' num2str(lagsec) 'sec.mat'],'-struct','Sync') % saves just Sync data structures
   
    %%// SAVE ALIGNMENT LAGGED DATA WITH ALL LAGS PRESERVED AS EXCEL

    if exist('LAGGED_DATA.xls','file') == 2,
        delete('LAGGED_DATA.xls')
    end

    alignData = {'xcorr','xcorrV','wincross','wincrossV'};
    alignCode = [1,2,3,4];

    for item = 1:length(alignData)
        eval(['datastr = Sync.' cell2mat(alignData(item)) ';'])
        dlmwrite('LAGGED_DATA.xls',[datastr repmat(alignCode(item),size(datastr,1),1)],'-append','delimiter','\t');
    end
end







 