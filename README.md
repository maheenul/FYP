# Yawning detection in car driver #

*Completed as a part of the Final Year Project in Monash University*

***

This directory contains the two algorithms designed for my final year project for the purpose of yawning detection inside vehicles. All programming tasks required for this project were completed in a MATLAB environment. In order to test the algorithm a video dataset named [YawDD](http://www.discover.uottawa.ca/images/files/external/YawDD_Dataset/YawDD.rar) which contains videos of drivers simulating different driving conditions has been used. This dataset will have to be downloaded in order to test the algorithms. There are two sets of videos in this dataset "Mirror" and "Dash" which represents two locations from where the videos of the drivers were taken.

For both algorithm, the "Dash" videos from the [YawDD dataset](http://www.discover.uottawa.ca/images/files/external/YawDD_Dataset/YawDD.rar) will be considered with the assumption that the camera will be placed over the dashboard whenever these algorithms are implemented. Any video or videos from the Dash directory of the YawDD dataset will have to be placed inside the "data/videos" directory in order to test either of the algorithms.


## Algorithm ##

Both the algorithms execute the following steps at the beginning:

-   Rendering images from video:   The first step in both algorithms is to extract video from the dataset given. The extracted video is then converted into a sequence of image resulting in an image array. Images are then read at regular intervals. The interval is kept small enough to simulate a real-time process, however it is not too small which will hinder the speed of detecting yawning. For all the algorithms the frame interval is 50, this means that there are 50 frames in between each frame that are analysed in the video.
The videos used for simulation runs at a rate of 30 frames per seconds which accounts for a time gap of approximately 1.7 seconds between each analysed frame. This gap is sufficiently high to detect yawning as any typical yawning by humans lasts for about 5 seconds.

-   Face detection: Face detection is then carried out on the selected images from the image array. This is achieved by using the Viola-Jones algorithm. The Viola-Jones algorithm can be directly applied to the images using MATLAB’s built-in function.

-   Multiple Face detection problem: Often there is a problem of detection multiple face when Viola-Jones is applied, this occurs when some background image is mistaken as a face. When two or more faces are detected, the bounding box with more area is usually the face. Using this assumption, the actual face can be extracted from the result of Viola-Jones.

The steps mentioned above are same for all the algorithms developed.


## Algorithm-1 ##
The MATLAB file "yawning_detector_v1.m" is the first algorithm that was developed for yawning detection. It was designed using the methods mentioned in the paper "Yawning Detection Using Embedded Smart Cameras," in IEEE Transactions on Instrumentation and Measurement. 

The steps unique to this algorithm are discussed below:
-   **Mouth detection:** Whenever a face is detected, the lower half of the face is used as the search area for mouth. Viola-Jones algorithm is used here again to detect the mouth using a merge threshold of 2.

-   **Multiple Mouth detection problem:** Sometimes in the lower half of the face the nose was also detected as a mouth. To overcome this issue, the bounding box which is located at lower position in the image is selected.

-   **Binary Thresholding:**    The mouth image is converted to grayscale from RGB which are are then compared with a threshold. This threshold was obtained by using back-projection theory on all the images.

-   **Yawning detection:** A few assumptions are made prior to yawning detection. It is assumed that a person is **NOT** yawning at the start of the video. Based on this assumption the first frame is used as a reference frame for yawning detection in the remaining frames. To estimate yawning a few parameters are calculated. The parameters computed are described below:
    -   NBR: The number of black pixels in the first frame's binary mouth image.
    -   NBC: The number of black pixels in the current frame's binary mouth image.
    -   NWC: The number of white pixels in the current frame's binary mouth image.

To determine yawning appropriate ratio of these parameters(NBR,NBC,NWC) are taken and compared with thresholds(Th1,Th2).
-   (NBC/NBR)>Th1
-   (NBC/NWC)>Th2

The value of Th1 and Th2 were determined experimentally to be 2.4 and 0.085 respectively.

If both the equations above are satisfied, then the driver is considered to be yawning.


## Algorithm-2 ##

The MATLAB file "yawning_detector_v2.m" is the final algorithm that was developed for yawning detection. It was designed to be an improvised version with a higher rate for correct yawning detection.

The steps unique to this algorithm are discussed below:
-   **Secondary face detection:** In the first algorithm, whenever the Viola-Jones algorithm fails to detect a face, the algorithm skips the current frame and moves to the next frame. To improve the rate of face detection, a secondary face detection method which involves the use of cross correlation has been employed in this algorithm. Given a face has been detected in any of the previous frames, using the previously saved face image and the frame for which no face was detected, the cross correlation is calculated. The region in the new frame where the cross correlation is maximum is assumed to be the new face. 

- **Landmark annotation:** At this step, a predefined model with 49 landmark points is loaded into the program.
The face image is then scaled and normalized to ensure all the face images have the same resolution. The face image is then converted to double precision followed by a conversion to grayscale. These pre-processing are required to ensure the landmarks are correctly annotated on the face. After that the predefined model with 49 landmark positions is iteratively fitted on the face image.

- **Yawning detection:** For this algorithm yawning is detected by calculating the area enclosed by the mouth. Using 12 landmark points surrounding the lips, the area of the mouth is calculated. These point are connected to form a polygon and its area is then used to determine yawning. There are some cases where the landmark positions are misplaced on the face. Whenever the landmark positions are misplaced they are usually clumped very close to each other. For this phenomenon, the area calculated for the mouth could be used to decide whether the landmarks have been properly placed on the face. Therefore, the mouth area is checked whether it exceeds a certain threshold. If the area is greater, then it is concluded that the person is yawning otherwise it is assumed that there is no yawning.

This approach results in a yawning detection rate of about 89%, wheras the yawning detection rate for the previous algorithm(algorithm-1) is only about 68%.