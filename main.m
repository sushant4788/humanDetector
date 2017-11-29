% Steps to carry out in the main human detection
% Step -1: Read an image into the image array:
% Step -2: Construct a pyramid of images by resizing the given image
% Step -3: For each of these images, take the HOG features and detect the
% presence of a human

numlevels = 5;
scale = 0.9;
allowedPercentage = 25;
Image = imread('test9.png');
I= cell(1,numlevels);
I{1, numlevels} = Image;
 %Construct the image pyramid
for i = numlevels-1:-1:1
    I{1,i} = imresize(I{1,i+1}, scale);
    
end
% At this point we have generated the images
% We now want to generate the pixel overlaps across all frames.
% The idea is that pixel overlap should be higer in low resoltion images
% and higer lower in high resoltuion. SO we start by saying let the base
% levl have pixel overlap of 64, at each level we will increase the
% overlap by 20% 
pixOverlap = zeros(1, numlevels);
pixOverlap(1,numlevels) = 32;
delta = zeros(1,numlevels);
delta(1, numlevels) = 32;
for i =numlevels-1:-1:1
    pixOverlap(1,i) = ceil(pixOverlap(1,i+1) +  pixOverlap(1,i+1)*0.1);
    delta(1,i) = 64-pixOverlap(1,i);
end
% load the values of wt and biasterm

data = load('updatedweights.mat');
%data = load('weight.mat');
wT = data.updatedweights;
%wT = data.weight;
bias =0; % This is only since we know that the bias term is 0. FIXME:

% We now have all the data necessary to perfom the human detection on the
% test images in the dataset.
winDetAcrossFrames = cell(1, numlevels);
for i = 1:numlevels
    imshow(I{1,i});
    temp = humanDetector(I{1,i}, wT, delta(1,i));
    winDetAcrossFrames{1,i} = temp.retMat;
end
winDetAcrossFrames = winDetAcrossFrames';
%Detected windows. Now map them back to the original
% image
wScale = scale;
k = 1;
for i = numlevels-1: -1:1
    [rows, ~] = size(winDetAcrossFrames{i,1});
    wScale = scale^(numlevels -i);
    for j = 1:rows
        stRow = winDetAcrossFrames{i,1}(j,1);
        stCol = winDetAcrossFrames{i,1}(j,2);
        wscore = winDetAcrossFrames{i,1}(j,3);
        if(stRow == 1 && stCol == 1)
             winStRow = stRow;
             winStCol = stCol;
             
        else
            winStRow = ceil(stRow/wScale);
            winStCol = ceil(stCol/wScale);
        end
        wWidth = ceil(64/wScale);
        wHeight = ceil(128/wScale);
        framesToDraw{k,1} = [winStRow, winStCol, wWidth, wHeight, wscore];
        k=k+1;
    end
end
% Now draw the frames on the image
figure, imshow(Image);
hold on;
for i =1:length(framesToDraw);
    rectangle('Position', [framesToDraw{i,1}(1,2), framesToDraw{i,1}(1,1),...
        framesToDraw{i,1}(1,3),framesToDraw{i,1}(1,4)],  'EdgeColor', [0 1 0]);
end
hold off;
winMatrix = removeExtraFrames(Image, framesToDraw, allowedPercentage);
[rows, ~] = size(winMatrix);
imshow(Image);
hold on;
for i = 1:rows
    if ((winMatrix(i,6) == 1))
        rectangle('Position', [winMatrix(i, 2),winMatrix(i, 1), winMatrix(i, 3), winMatrix(i, 4)], 'EdgeColor', [1 0 1]);
    end
end
hold off;





























% I = imread('crop001604.png');
% Ig = rgb2gray(I);
% pyramid = reduce_gaussian (1.41, 5, Ig, 5);
% result = cell(1,6);
% for i =1 :6
%     temp = humanDetector(pyramid{1,i});
%     result{1,i} = temp.retMat;
% end
% someMat = cell(1,6);
% 
% for i = 1: 6
% someMat{1,i} = removeFrames(result{1,i}, pyramid{1,i}); 
% end