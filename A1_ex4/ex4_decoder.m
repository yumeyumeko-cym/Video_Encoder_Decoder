% parameters
approx_residuals_path = 'approx_residuals.bin';
mv_path = 'motion_vectors.txt';
width = 352; % default width of cif format
height = 288; % default height of cif format

num_frames = 10; % number of frames to operate
i = 8; % i=[2, 8, 64], i is the block dimension
QP = min(6,log2(i)+7); % quantization parameter

% check pad
if i == 64
    width = 384;
    height = 320;
end


r = 8; % search range
n = 2; % n=[1, 2, 3], n is Approximated Residual Block Argument
%read_residual(approx_residuals_path)
decoder(mv_path,  width, height, i, num_frames, QP);


function decoder(mv_path,  width, height, i, num_frames, QP)
    % Initialize a reference frame filled with 128
    reference = 128 * ones(height, width);

    % Open the motion vectors
    mv_fid = fopen(mv_path, 'r');

    % Create a file to save the Y-only-decoded frames
    y_decoded_fid = fopen('Y_decoded.yuv', 'wb');


    % Read approximated residual
    % Open the binary residuals file with read permission
    %res_bin_fid = fopen(approx_residuals_path, 'rb');
    % Read metadata from the binary file
    %dims = fread(res_bin_fid, 3, 'int');
    %num_frames = dims(3);


    

    for frame = 1:num_frames

        % Read the approximated residual block data from the binary file
        % Read block dimensions from the binary file
        % blockDims = fread(res_bin_fid, 2, 'int');
        % blockHeight = blockDims(1);
        % blockWidth = blockDims(2);
        
        
        % Read the approximated residual block data from the binary file
        coeff_bin = sprintf('encoded_file_frame_%d.txt', frame);
        approx_residual_frame = reverse_entropy(coeff_bin, width, height);
        size(approx_residual_frame)

        %approx_residual_frame = fread(res_bin_fid, [blockHeight, blockWidth], 'int16');
        
        % Display the approximated residual block
        %figure;
        %imshow(approx_residual_frame, [0,255]);  % auto scale
        %title(['Approximated Residual Frame ', num2str(frame)]);


        % Build decoded frames
        decoded_frame = zeros(height, width);
        
        for row = 1:i:height
            for col = 1:i:width
                % Read the motion vector for the current block
                mv_data = fscanf(mv_fid, '%d,%d,%d,%d\n', [4 1]);
                dx = mv_data(3);
                dy = mv_data(4);
                % Form the predicted block

                predicted_block = reference(row+dy:min(row+dy+i-1, height), col+dx:min(col+dx+i-1, width));
                approx_residual_block = approx_residual_frame(row:min(row+i-1, height), col:min(col+i-1, width));
                approx_residual_block = rescaling_idct(approx_residual_block, i, QP);
                % Add the approximated residual block to the predicted block to get the decoded block
                decoded_block = predicted_block + approx_residual_block;
                decoded_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = decoded_block;
                
                approx_residual_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = approx_residual_block;
                

            end
        end
        figure;
        imshow(decoded_frame, [0, 255]);
        title(['Decoded Frame ', num2str(frame)])
        
        % Write the decoded frame to the Y-only-decoded file
        fwrite(y_decoded_fid, uint8(decoded_frame)', 'uint8');

        % Update the reference frame
        reference = decoded_frame;
    end
    
    % Close the files
    fclose(mv_fid);
    % fclose(res_bin_fid);
    fclose(y_decoded_fid);
end






function read_residual(filename)
    % Open the binary residuals file with read permission
    res_bin_fid = fopen(filename, 'rb');

    % Read metadata from the binary file
    dims = fread(res_bin_fid, 3, 'int');
    num_frames = dims(3);
    
    for frame = 1:num_frames
        % Read block dimensions from the binary file
        blockDims = fread(res_bin_fid, 2, 'int');
        blockHeight = blockDims(1);
        blockWidth = blockDims(2);
        
        
        % Read the approximated residual block data from the binary file
        
        approxResidualBlock = fread(res_bin_fid, [blockHeight, blockWidth], 'int16');
        
        % Display the approximated residual block
        figure;
        imshow(approxResidualBlock, [0,255]);  % auto scale
        title(['Approximated Residual Frame ', num2str(frame)]);
    end
    
    % Close the binary residuals file
    fclose(res_bin_fid);
end

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
    
    rows = height;
    cols = width;
    reverted = zeros(rows, cols);
    index = 1;
    for sum = 0:(rows+cols-2)
        for i = 0:sum
            j = sum - i;
            if (i < rows) && (j < cols)
                
                reverted(i+1, j+1) = output(index);
                index = index + 1;
                if index >= 101376
                    break;
                end
            end
        end
    end
end

function data_ITC = rescaling_idct(data, i, QP)
    Q = get_quantization_para(i, QP); % get quantization parameter
    data_TC_rescaled = data .* Q; % rescaling
    data_ITC = idct2(data_TC_rescaled); % inverse DCT
    data_ITC = double(data_ITC); % Clip values and convert to double
end

function Q = get_quantization_para(i, QP)
    Q = zeros(i,i);
    
    for x = 1:i
        for y = 1:i
            if (x+y-2 < i-1) % -2, x and y start from 1
                Q(x,y) = 2^(QP);
            elseif (x+y-2 == i-1)
                Q(x,y) = 2^(QP+1);
            else
                Q(x,y) = 2^(QP+2);
            end
        end
    end
end







