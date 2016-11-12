%% CODE WRITTEN BY ... [TO BE ADDED IF PAPER IS ACCEPTED] AND USED IN PLOS ONE PAPER "SYNCHRONIZATION AND DECEPTION"

%% WHAT THIS PROGRAM DOES:

% 1. Takes as input data array structure generated from MotionAnalysisCoordinatesRegions.m
% 2. Also takes as input all videos to be analyzed
% 3. Based on x,y coordinates, splits videos into appropriate regions for each participant in each dyad ...
% 4. Performs frame substraction method to extract motion energy flows
% 5. Saves the displacement values, for each body region, in folder called "motionSeriesRegions"

% 1 = dyad, 2 = order, 3 = vertx, 4 = Left Legs, Left Head, Right Legs, Right Head

clear all

load('~/pointsmarkedRegions'); % import data array structure
tally = 0;
allfiles = dir('~vids/'); % folder with videos

%%// loop through videos to extract motion energy flows
for i = 1:length(allfiles),
    af1 = struct2cell(allfiles(i));
    holdtemp = cell2mat(af1(1));
    disp(holdtemp)
    if (strcmp(holdtemp,'.') ~= 1) && (strcmp(holdtemp,'..') ~= 1) && (strcmp(holdtemp,'.DS_Store') ~= 1),
        tally = tally + 1;
        movLoc = strcat('~vids/',holdtemp);
        
        %%// initialize variables for where data will be stored for participant on right or left of screen
        pLeft2 = []; pRight2 = []; pLeftFeet = []; pRightFeet = []; pLeftHead = []; pRightHead = []; pLeftMid = []; pRightMid = []; pBoth2 = [];
        
        % get video information
        vidobj=VideoReader(movLoc);
        numFrames = get(vidobj,'NumberOfFrames');
        vidHeight = vidobj.Height;
        vidWidth = vidobj.Width;
        vidFrameRate = vidobj.FrameRate;

        %%\\ sampling across every 5th frame
         for m = 5:5:numFrames-5, % if there are approximately 30 frames a second (based on obj information)
                    
            %preallocate for faster processing
            mov1(1) = struct('cdata',zeros(vidHeight, vidWidth, 3, 'uint8'),'colormap',[]);
            mov2(1) = struct('cdata',zeros(vidHeight, vidWidth, 3, 'uint8'),'colormap',[]);
             
            mov1(1).cdata = read(vidobj,m);
            mov2(1).cdata = read(vidobj,m+5);
            imgDiff = mov1(1).cdata(:,:,:)-mov2(1).cdata(:,:,:);

            % plays the motion differencing video in real time
%             figure(1) 
%             image(imgDiff);        
%             pause(1/6)
%             title(['frame: ' int2str(m)]);
                                        
            % separate movements of each participant into regions of interest
            parts = strread(holdtemp,'%s','delimiter','.');
            parts2 = strread(parts{1},'%s','delimiter','_');

            %%// get correct coordinates for current dyad from data array structure
            getRow = find((Points.coord(:,1)==str2num(parts2{1})) & (Points.coord(:,2)==str2num(parts2{2}))); 
            
            %%// codes correspond to column names in data array structure
            % 1 = dyad, 2 = convo, 3 = vertx, 4 = Left Legs, 5 = Left Head, 6 = Right Legs, 7 = Right Head
            
            % split, along horizontal            
            pLeft = mean(mean(mean(imgDiff(:, 1:round(Points.coord(getRow,3)), :)))); % collapsing over the 3 colors one number, the amount of displacement (RGB)
            pRight = mean(mean(mean(imgDiff(:, round(Points.coord(getRow,3))+1:getSize(2), :))));                       
            pLeft2 = [pLeft2 ; pLeft m/vidFrameRate];
            pRight2 = [pRight2 ; pRight m/vidFrameRate];
                        
            % mid below
            pLeftF = mean(mean(mean(imgDiff(round(Points.coord(getRow,4)):getSize(1),1:round(Points.coord(getRow,3)), :)))); % collapsing over the 3 colors one number, the amount of displacement (RGB)
            pLeftFeet = [pLeftFeet ; pLeftF m/vidFrameRate];
            %%%
            pRightF = mean(mean(mean(imgDiff(round(Points.coord(getRow,6)):getSize(1),round(Points.coord(getRow,3)):getSize(2), :))));
            pRightFeet = [pRightFeet ; pRightF m/vidFrameRate];
     
            % shoulder above
            pLeftH = mean(mean(mean(imgDiff(1:round(Points.coord(getRow,5)), 1:round(Points.coord(getRow,3)),:)))); % collapsing over the 3 colors one number, the amount of displacement (RGB)
            pLeftHead = [pLeftHead ; pLeftH m/vidFrameRate];
            %%%
            pRightH = mean(mean(mean(imgDiff(1:round(Points.coord(getRow,7)), round(Points.coord(getRow,3)):getSize(2),:))));
            pRightHead = [pRightHead ; pRightH m/vidFrameRate];

            % mid region
            pLeftM = mean(mean(mean(imgDiff(round(Points.coord(getRow,5)):round(Points.coord(getRow,4)), 1:round(Points.coord(getRow,3)),:)))); % collapsing over the 3 colors one number, the amount of displacement (RGB)
            pLeftMid = [pLeftMid ; pLeftM m/vidFrameRate];
            %%%
            pRightM = mean(mean(mean(imgDiff(round(Points.coord(getRow,7)):round(Points.coord(getRow,6)), round(Points.coord(getRow,3)):getSize(2),:))));
            pRightMid = [pRightMid ; pRightM m/vidFrameRate];

            % no separation, just one time series
            pBoth = mean(mean(mean(imgDiff(:,1:vidWidth,:)))); % collapsing over the 3 colors one number, the amount of displacement (RGB)
            pBoth2 = [pBoth2 ; pBoth m/vidFrameRate];
       
        end

        % creates folder in cwd if doesn't exist, stores trajectory outputs here
        if exist(strcat(CWD,'getFrames/motionSeriesRegions')) ~= 7,
            mkdir(strcat(CWD,'getFrames/motionSeriesRegions'))
        end
         
        %%%%
        left_data_file = strcat(CWD,'getFrames/motionSeriesRegions/',parts2{1},'_',parts2{2},'_L');
        right_data_file = strcat(CWD,'getFrames/motionSeriesRegions/',parts2{1},'_',parts2{2},'_R');
        both_data_file = strcat(CWD,'getFrames/motionSeriesRegions/',parts2{1},'_',parts2{2},'_B','.txt');

        % split
        dlmwrite([left_data_file '_ALL.txt'],pLeft2,'delimiter','\t','precision','%1.5f')
        dlmwrite([right_data_file '_ALL.txt'],pRight2,'delimiter','\t','precision','%1.5f')
        
        % legs
        dlmwrite([left_data_file '_LEGS.txt'],pLeftFeet,'delimiter','\t','precision','%1.5f')
        dlmwrite([right_data_file '_LEGS.txt'],pRightFeet,'delimiter','\t','precision','%1.5f')        
     
        % head
        dlmwrite([left_data_file '_HEAD.txt'],pLeftHead,'delimiter','\t','precision','%1.5f')
        dlmwrite([right_data_file '_HEAD.txt'],pRightHead,'delimiter','\t','precision','%1.5f')        

        % mid/arms/hands
        dlmwrite([left_data_file '_MID.txt'],pLeftMid,'delimiter','\t','precision','%1.5f')
        dlmwrite([right_data_file '_MID.txt'],pRightMid,'delimiter','\t','precision','%1.5f')        
 
        % combined signal
        dlmwrite([both_data_file '_ALL.txt'],pBoth2,'delimiter','\t','precision','%1.5f')
        
    end
end

