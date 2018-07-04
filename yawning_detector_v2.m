% Written by MD MAHEENUL ISLAM
% Last Modified : 19/10/2016
%
% Version : 2
% This program reads the input video files from the ./data/videos/ 
% directory. The program operates on the no. of frames deterrmined by the
% value of the frame_skip variable. The frame_skip variable determines the
% interval in between each frames which will be used to yawning detection.
% The program outputs display yawning result for upto the first 36 frames 
% of the video.
%
% This algorithm is the final algorithm designed for the purpose of yawning
% detection. It includes a face detection via cross-correlation whenever 
% the viola-jones algorithm fails to detect a face initially. Here the
% method for yawning detection is much different than the previous 
% methodology. For yawning detection a template of a face is fitted on the
% face image and the mouth area is calculated. Yawning is then determined 
% using the area of the mouth.

clear all
clc
close all
%% Initial Setup
% To prevent the program from crashing caused by hardware accelerator
matlab.video.read.UseHardwareAcceleration('off')

% Loading chehra fitting
fitting_model='./data/models/Chehra_f1.0.mat';
load(fitting_model);

% Adding path to functions
addpath('./data/');
addpath('./data/mex_functions');

% Setting up directories
inputPath = './data/videos/';               % Directory of the folder,
                                            % where data files are located
                                            
outputPath = './result/algorithm2/';        % Directory of the folder,
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
    result_enable = 1;      % Variable to control display of result
    minArea_T = 400;        % Lower bound for mouth detection
    maxArea_T = 1130;       % Higher bound for yawning detection
    xrange = 60;            % one-sided increase for cross correlation
    yrange = 60;            % one-sided increase for cross correlation

    for j = 1:1:size(i_frame,2);
        %Read the image in the current frame
        I = read(obj,i_frame(j));

        %% Face detection by Viola-Jones
        %Returns Bounding Box values based on number of objects
        BB = step(FDetect,I);
        
        % DO NOT CHANGE
        % est_counter is used for debugging. MUST be 0 here.
        est_counter = 0;
        % est_counter is to indicate first face detection. MUST be 0 here.
        en_xcorr = 0;
        
        % If two faces or more are detected the one with bigger region is
        % selected
        if (size(BB~=0)) % If a face is detected by V-J
            if (size(BB,1) >= 2)
                regionBB = zeros(1,size(BB,1));
                for i=1:1:size(BB,1)
                    regionBB(i) = BB(i,3)*BB(i,4);
                end
                [BB_ymax,BB_index] = max(regionBB(1,:));
                BB = BB(BB_index,:);
            end
            
            %% Face detection by cross-correlation when V-J fails
            Ipast = I((BB(2)):(BB(2)+BB(4)),BB(1):(BB(1)+BB(3)),:);
            BB_past=BB;
            BB_corr = BB + [-xrange,-yrange,2*xrange,2*yrange];
            for ibcor = 1:1:length(BB_corr)
                if (BB_corr(ibcor) <=1)
                    BB_corr(ibcor)=1;
                end
            end

            en_xcorr=1;
            yawn_test(j) = -1;
            
        else
            %If a earlier face was detected new face will be detected by
            %cross-correlation -> when V-J fails to detect face
            if (en_xcorr==1)
                Inew = I((BB_corr(2)):(BB_corr(2)+BB_corr(4)),...
                    BB_corr(1):(BB_corr(1)+BB_corr(3)),:);
                c_R = normxcorr2(Ipast(:,:,1),Inew(:,:,1));
                c_G = normxcorr2(Ipast(:,:,2),Inew(:,:,2));
                c_B = normxcorr2(Ipast(:,:,3),Inew(:,:,3));
                c = (c_R + c_G + c_B)./3;
                [max_c, imax] = max(c(:));
                [ycpeak, xcpeak] = ind2sub(size(c),imax(1));
                BB_estm = [BB_corr(1)-BB_past(3)+xcpeak,BB_corr(2)-...
                    BB_past(4)+ycpeak,BB_past(3),BB_past(4)];
                BB=BB_estm;
                est_counter = 1;
                for ibb = 1:1:length(BB)
                    if (BB(ibb) <=1)
                        BB(ibb)=1;
                    end
                end
            end
        end

        if (size(BB~=0)) % If a face is returned
             if (j==1)
                 BB_array = BB;
             else
                 BB_array = [BB_array;BB];
             end

            % Selects the lower half of the face and crops the width by 1/4
            % on each sides
            
            %% Preparing image for landmark fitting
            test_image = imcrop(I, [BB(1), BB(2), BB(3), BB(4)]);
            scaleFactor = 150/size(test_image, 1);
            test_image = imresize(test_image, scaleFactor);

            

            % Load Image
            test_image=im2double(test_image);

            BB = [1,1,size(test_image,1),size(test_image,2)];

            test_init_shape = InitShape(BB,refShape);
            test_init_shape = reshape(test_init_shape,49,2);
            if size(test_image,3) == 3
                test_input_image = im2double(rgb2gray(test_image));
            else
                test_input_image = im2double((test_image));
            end
            
            % % Maximum Number of Iterations
            % % 3 < MaxIter < 7
            %% Fitting landmark
            MaxIter=6;
            test_points = Fitting(test_input_image,test_init_shape,...
                RegMat,MaxIter);
            temp = vertcat(test_points((32:43),:),test_points((32:32),:));
            temp2=polyarea((temp(:,1)),(temp(:,2)));
            yawn_area(j)=temp2;
            
            %% Yawning detection
            if (temp2<=minArea_T) 
                yawn_test(j) = -2;
            else
                if (temp2>minArea_T)&& (temp2<=maxArea_T)
                    yawn_test(j) = 0;
                else
                    yawn_test(j) = 1;
                end
            end


        else
            yawn_test(j) = -3;
        end
    end
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    
    %% Displays the result for yawning test
    figImg = figure('units','normalized','outerposition',[0 0 1 1]);
    for i=1:1:size(i_frame,2)
        I = read(obj,i_frame(i));
        if (i<=36)
        subplot(6,6,i);
        imshow(I)
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