% Written by MD MAHEENUL ISLAM
% Last Modified : 19/10/2016
%
% Version : 1
% This program reads the input video files from the ./data/videos/ 
% directory. The program operates on the no. of frames deterrmined by the
% value of the frame_skip variable. The frame_skip variable determines the
% interval in between each frames which will be used to yawning detection.
% The program outputs display yawning result for upto the first 36 frames 
% of the video.
%
% This algorithm has been designed using the procedures mentioned in the
% paper M. Omidyeganeh et al., "Yawning Detection Using Embedded Smart 
% Cameras," in IEEE Transactions on Instrumentation and Measurement, 
% vol. 65, no. 3, pp. 570-582, March 2016.
% Further improvements were made to the latter versions using this as a 
% base version

clear all
clc

%% Initial Setup
% To prevent the program from crashing caused by hardware accelerator
matlab.video.read.UseHardwareAcceleration('off')

% Setting up directories
inputPath = './data/videos/';               % Directory of the folder,
                                            % where data files are located
                                            
outputPath = './result/algorithm1/';        % Directory of the folder,
                                            % where the results are saved
                                            
liste = dir(strcat(inputPath,'*.avi'));     % Creates a list of all files 
                                            % in inputPath
                                            
files = {liste.name};                       % Creates a cell array with the 
                                            % name of the data file

for k=1:numel(files)
    fullName = strsplit(files{k},'.');
    fileName = char(strcat(inputPath,fullName(1),'.avi'));
    resultName = char(strcat(outputPath,fullName(1)));
    obj=VideoReader(fileName);
    vid = read(obj);
    frames = obj.NumberOfFrames;
    FDetect = vision.CascadeObjectDetector;
    MouthDetect = vision.CascadeObjectDetector('Mouth','MergeThreshold',2);
    
    frame_skip = 50;    %Number of frames to skip
    i_frame = 1:frame_skip:frames;
    yawn_test = zeros(size(i_frame));
    
    
    %% Initializing variable 
    NBR=0;                  % Number of black pixels in reference window
    result_enable = 1;      % Variable to control display of result
    bin_T = 55;             % Threshold for conversion to binary image
    thresholdBCBR = 2.4;    % Threshold for NBC/NBR
    thresholdBCWC = 0.085;  % Threshold for NBC/NWC
    
    
    for j = 1:1:size(i_frame,2);
        
        %% Face Detection
        %Detect objects using Viola-Jones Algorithm
        %Read the image in the current frame
        I = read(obj,i_frame(j));
        %Returns Bounding Box values based on number of objects
        BB = step(FDetect,I);
        
        %% If two faces or more are detected the one with bigger region is selected
        if (size(BB~=0)) % If a face is detected
            if (size(BB,1) >= 2)
                regionBB = zeros(1,size(BB,1));
                for i=1:1:size(BB,1)
                    regionBB(i) = BB(i,3)*BB(i,4);
                end
                [BB_ymax,BB_index] = max(regionBB(1,:));
                BB = BB(BB_index,:);
            end
            
            % Selects the lower face of the face
            Iface = I((BB(2)+BB(4)/2):(BB(2)+BB(4)),BB(1):(BB(1)+BB(3)),:);
            
            %% Mouth detection
            BB2=step(MouthDetect,Iface);
            if (size(BB2,1)~=0)   % If a mouth is detected
                %% If two of more mouth regions are detected select the one with higher y co-ordinate
                if (size(BB2,1) >= 2)
                    [BB2_ymax,BB2_index] = max(BB2(:,2));
                    BB2_new = BB2(BB2_index,:);
                else
                    BB2_new = BB2;
                end
                
                % Extracting mouth region from from the lower half of the face
                Imouth = Iface((BB2_new(1,2)):(BB2_new(1,2)+BB2_new(1,4)),...
                    BB2_new(1,1):(BB2_new(1,1)+BB2_new(1,3)),:);
                
                %% Converting mouth image from RGB to Gray
                mouth_gray = rgb2gray(Imouth);
                
                %% Converting from gray scale to binary image
                mouth_bin = (mouth_gray >=bin_T);
                
                %% Yawnning test
                if ((j==1)&&(size(BB2,1)~=0))
                    NBR = (size(mouth_bin,1)*size(mouth_bin,2)) -...
                        (sum(sum(mouth_bin)));
                    yawn_test(j) = -1;
                else
                    if (NBR~=0)
                        NWC = (sum(sum(mouth_bin)));
                        NBC = (size(mouth_bin,1)*size(mouth_bin,2)) - NWC;
                        if (((NBC/NBR)>=thresholdBCBR)&&((NBC/NWC)>=...
                                thresholdBCWC))
                            yawn_test(j)=1;
                        else
                            yawn_test(j)=0;
                        end
                    else
                        NBR = (size(mouth_bin,1)*size(mouth_bin,2)) -...
                            (sum(sum(mouth_bin)));
                        yawn_test(j) = -1;
                    end
                end
            else
                yawn_test(j) = -2;
            end
        else
            yawn_test(j) = -3;
        end
    end
    
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Result for yawning test
    if (result_enable==1)
        figImg = figure('units','normalized','outerposition',[0 0 1 1]);
        for i=1:1:size(i_frame,2)
            I = read(obj,i_frame(i));
            if (i<=36)
                subplot(6,6,i);
                imshow(I);
                if yawn_test(1,i)== 1
                    title('Yawning');
                end
                if yawn_test(1,i) == -1
                    title('Reference Image');
                end
                if yawn_test(1,i) == -2
                    title('Mouth not detected');
                end
                if yawn_test(1,i) == -3
                    title('Face not detected');
                end
                if yawn_test(1,i) == 0
                    title('Not Yawning');
                end
            end
        end
        saveas(figImg,resultName,'jpg');
        close(figImg);
    end
end

% Resetting hardware acceleration to default
matlab.video.read.UseHardwareAcceleration('off')