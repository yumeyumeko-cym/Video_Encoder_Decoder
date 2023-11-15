clear
clc 

coeff_bin = 'encoded_file_frame_1.txt';
i = 4;
width = 352;
height = 288;
% binaryString = readBinary(coeff_bin);
% output_expGo_decoded = expGolombExtendedDecode(binaryString); % revert from expGolomb
% output_RLE_decoded = customRLEDecode(output_expGo_decoded, i); % revert from RLE
% output = revertOrder(output_RLE_decoded,i); % revert zigzag like order
output = reverse_entropy(coeff_bin, width, height);
disp(output);


function output = reverse_entropy(coeff_bin, width, height)
    binaryString = readBinary(coeff_bin);
    output_expGo_decoded = expGolombExtendedDecode(binaryString); % revert from expGolomb
    output_RLE_decoded = customRLEDecode(output_expGo_decoded, width, height); % revert from RLE
    output = revertOrder(output_RLE_decoded,width, height); % revert zigzag like order

end


function binaryString = readBinary(filename)
    % Open the file with read permission
    fileId = fopen(filename, 'rt');
    
    % Check if the file has been opened successfully
    if fileId == -1
        error('Failed to open file for reading.');
    end
    
    % Read the text from the file
    binaryString = fscanf(fileId, '%c');
    
    % Close the file
    fclose(fileId);
end

function decoded = expGolombExtendedDecode(coded)
    % Initialize an empty array to store the decoded sequence
    decoded = [];
    
    % Initialize a pointer to keep track of the position in the coded sequence
    ptr = 1;
    flag = 0;
    % Loop until the end of the coded sequence is reached
    while ptr <= length(coded)
        % Find the length of the prefix of zeros
        prefixLen = 0;
        while ptr + prefixLen <= length(coded) && coded(ptr + prefixLen) == '0'
            prefixLen = prefixLen + 1;
        end
        
        % Break out of the loop if the end of the coded sequence is reached
        if ptr + prefixLen >= length(coded) && coded(ptr)=='1'
            flag = 1;
        end

        if ptr + prefixLen >= length(coded)
            break;
        end       

        % The length of the binary part
        binLen = prefixLen + 1;
        
        
        % Extract the binary part
        binary = coded(ptr + prefixLen  : ptr + prefixLen + binLen-1);
        %binary

        % Convert the binary part to an integer
        mappedVal = bin2dec(binary) - 1;
        
        if mod(mappedVal,2) == 0
            val = -mappedVal/2;
        else
            val = (mappedVal+1)/2;
        end    

        
        % Append the original value to the decoded sequence
        decoded = [decoded, val];
        
        % Update the pointer to point to the next coded value
        ptr = ptr + prefixLen + binLen;
    end
    if flag == 1
            decoded = [decoded, 0];
    end

end
function decoded = customRLEDecode(encoded, width, height)
    % Initialize an empty array to store the decoded sequence
    decoded = [];
    
    % Initialize the index variable
    i = 1;
    
    while i <= length(encoded)
        runLength = encoded(i);  % Get the run length
        i = i + 1;  % Increment the index
        
        if runLength < 0
            % Handle non-zero run
            decoded = [decoded, encoded(i:i-1+abs(runLength))];  % Append the non-zero values to the decoded sequence
            i = i + abs(runLength);  % Increment the index
        elseif runLength > 0
            % Handle zero run
            decoded = [decoded, zeros(1, runLength)];  % Append zeros to the decoded sequence
        else
            % Handle zero run at the end
            remainingLength = width*height - length(decoded);  % Compute the remaining length
            decoded = [decoded, zeros(1, remainingLength)];  % Append zeros to the decoded sequence
            break;  % Exit the loop as the rest of the elements are zeros
        end
    end
    
    % Reshape the decoded sequence to match the original dimensions
    
end

function reverted = revertOrder(output,width, height)
    
    rows = width;
    cols = height;
    reverted = zeros(rows, cols);
    index = 1;
    for sum = 0:(rows+cols-2)
        for i = 0:sum
            j = sum - i;
            if (i < rows) && (j < cols)
                reverted(i+1, j+1) = output(index);
                index = index + 1;
            end
        end
    end
end