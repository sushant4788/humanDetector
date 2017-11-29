function winMatrix =removeExtraFrames(image, cellFrames, allowedPercentage)
% First step is to conver the cell array into a matrix
frameMatrix = cell2mat(cellFrames);
% this is to sort the matrix with the given score
% Matrix has the form [x,y,w,h, score]
sortedMatrix = sortrows(frameMatrix, 5);
% To sort in descending order
sortedMatrix = flipud(sortedMatrix);
[row, ~] = size(sortedMatrix);
valid = ones(row,1);
sortedMatrix = horzcat(sortedMatrix, valid);
for i = 1:row-1
    %if(~isempty(sortedMatrix(i,:)))
    if(sortedMatrix(i,5) > 150)
        sortedMatrix(i,6) =0;
    else
        for j = i+1:row
            if(~isempty(sortedMatrix(j,:)))
                firstterm = min(sortedMatrix(j, 1)+sortedMatrix(j, 4),sortedMatrix(i, 1)+sortedMatrix(i, 4));
                secondterm = max(sortedMatrix(j, 1),sortedMatrix(i, 1));
                rowOverlap = firstterm - secondterm;
                cfirstterm = min(sortedMatrix(j, 2)+sortedMatrix(j, 3),sortedMatrix(i, 2)+sortedMatrix(i, 3));
                csecondterm = max(sortedMatrix(j, 2),sortedMatrix(i, 2));
                colOverlap = cfirstterm - csecondterm;
                if(rowOverlap ~= 0 && colOverlap ~= 0)
                    % This indicated that there is actually a rectangle window
                    % overlap. Here we have to calculate the percentage overlap
                    % and discard the one with lower score if its overlap is
                    % high
                    intarea = rowOverlap * colOverlap;
                    unionarea =  sortedMatrix(j, 4) *sortedMatrix(j, 3) + sortedMatrix(i, 4) *sortedMatrix(i, 3) - intarea;
                    
                    percentOverlap = (intarea/unionarea)*100; 
                    if (percentOverlap >allowedPercentage)
                        % here we discard the frame as the overlap is too
                        % high we invlaidate the jth frame
                        sortedMatrix(j,6)= 0;
                    end
                end
            end
        end
    end
end
winMatrix = sortedMatrix;
% Further removal of the incorrect windows.
% Here we see that the actual size of the window lies outside the image, if
% so we diccard that frame
% [iRows, iCols] = size(image);
% [wRow, ~] = size(winMatrix);
% for i =1:wRow
%     winWidth = winMatrix(i, 2) + winMatrix(i, 3);
%     winHeight = winMatrix(i, 1) + winMatrix(i, 4);
%     if ((winWidth > iCols) || (winHeight > iRows))
%         % We have to discard that frame
%         winMatrix(i,6) = 0;
%     end
%     
% end
 end