% parameters
test_file_path = 'foreman_cif.yuv';
width = 352; % default width of cif format
height = 288; % default height of cif format
frame_num = 10; % number of frames to operate
i = 16; % i=[2, 8, 64], i is the block dimension
r = 1; % search range
%n = 2; % n=[1, 2, 3], n is Approximated Residual Block Argument
QP = min(6,log2(i)+7); % quantization parameter

[paddedFileName, padWidth, padHeight] = file_preparation(test_file_path, width, height, i); % This build padded yuv file if needed
paddedWidth = width + padWidth;
paddedHeight = height + padHeight;
exercise3(paddedFileName, paddedWidth, paddedHeight, frame_num, i, r, QP);



function [paddedFileName, padWidth, padHeight] = file_preparation(yuv_path, width, height, i)
    filename = yuv_path;
    fileID = fopen(filename,'r');
    y_only_filename = 'foreman_y_only.yuv';
    yFileID = fopen(y_only_filename, 'w');

    while ~feof(fileID)
        Y = fread(fileID, [width, height], 'uint8');
        if numel(Y) < width*height % Check if a full frame has been read
            break;
        end
        fwrite(yFileID, Y, 'uint8');
    
        % Skip U and V
        fseek(fileID, width * height /2, 'cof');
    end  
    fclose(fileID);
    fclose(yFileID);

    padWidth = i - mod(width, i);
    if padWidth == i
        padWidth = 0;
    end


    padHeight = i - mod(height, i);
    if padHeight == i
        padHeight = 0;
    end
    yFileID = fopen(y_only_filename, 'r');
    paddedYFileID = fopen('foreman_y_only_padded.yuv', 'w');
    frameCounter = 0;
    
    while ~feof(yFileID)
        Y = fread(yFileID, [width, height], 'uint8');
        if numel(Y) < width*height
            break;
        end
        frameCounter = frameCounter + 1;
        Y = padarray(Y', [padHeight, padWidth], 128, 'post');
        %imshow(Y, []);
        fwrite(paddedYFileID, Y', 'uint8');
        %pause(1/30);
    end
    fclose(yFileID);
    fclose(paddedYFileID);
    paddedFileName = 'foreman_y_only_padded.yuv';
end


function exercise3(yuv_path, width, height, num_frames, i, r, QP)
    % Initialize a reference frame filled with 128
    reference = 128 * ones(height, width);
    
    % Open the YUV file for reading
    fid = fopen(yuv_path, 'r');
    
    % Create a file to save motion vectors
    mv_fid = fopen('motion_vectors.txt', 'w');
    
    %y_bytes = width * height;
    %uv_bytes = y_bytes /2;
    
    % Create a file to save approximated residual values in binary format
    res_bin_fid = fopen('approx_residuals.bin', 'wb');
    fwrite(res_bin_fid, [height, width, num_frames], 'int');


    for frame = 1:num_frames
        Y = fread(fid, [width, height], 'uint8')'; % current frame
        %fseek(fid, uv_bytes, 'cof');  % skip the U and V components
        
        predicted_frame = zeros(size(Y));
        residual_frame_me = zeros(size(Y));
        approx_residual_frame = zeros(size(Y));
        reconstructed_frame = zeros(size(Y));


        for row = 1:i:height
            for col = 1:i:width
                block = Y(row:min(row+i-1, height), col:min(col+i-1, width)); % current block
                [dx, dy] = block_search(reference, block, row, col, r);
                [predicted_block,mode] = intra_search(reconstructed_frame, block, row, col, i);
                mode
                % Save motion vector
                fprintf(mv_fid, '%d,%d,%d,%d\n', row, col, dx, dy);
                
                % Form the predicted block
                  

                residual_block_me = double(block) -double(predicted_block) ;
                approx_residual_block = residual_processing_before_entropy(residual_block_me, i, QP);
                approx_residual_block_entropy_preparation = residual_processing_entropy(residual_block_me, i, QP);
                size(approx_residual_block);
                reconstructed_block = predicted_block + approx_residual_block;
              
                
                predicted_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = predicted_block;
                residual_frame_me(row:min(row+i-1, height), col:min(col+i-1, width)) = residual_block_me;
                approx_residual_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = approx_residual_block;
                approx_residual_frame_entropy_preparation(row:min(row+i-1, height), col:min(col+i-1, width)) = approx_residual_block_entropy_preparation;
                reconstructed_frame(row:min(row+i-1, height), col:min(col+i-1, width)) = reconstructed_block;


            end
        end
        
        % Display the frames
        figure;
        subplot(3,3,1); imshow(reference, [0, 255]); title('Reference (previous) frame');
        subplot(3,3,2); imshow(Y, [0, 255]); title('Source frame (to encode)');
        subplot(3,3,3); imshow(abs(double(Y) - double(reference)), [0, 255]); title('Residual without motion compensation');
        subplot(3,3,4); imshow(predicted_frame, [0, 255]); title('Predicted frame after motion compensation');
        subplot(3,3,5); imshow(residual_frame_me, [0, 255]); title('Residual after motion compensation');

        

        % Write the dimensions of the approxResidualBlock to the binary file before the block data
        [blockHeight, blockWidth] = size(approx_residual_frame);
        fwrite(res_bin_fid, [blockHeight, blockWidth], 'int');
        % Dump the approximated residual values into the binary file
        fwrite(res_bin_fid, approx_residual_frame, 'int16');   

        subplot(3,3,6); imshow(reconstructed_frame, [0, 255]); title('Reconstructed frame from approximated residual and predicted frame')
        subplot(3,3,7); imshow(approx_residual_frame, [0,255]); title('Approximated residual frame')
        subplot(3,3,8); imshow(approx_residual_frame_entropy_preparation); title('Approximated residual frame with entropy')
        coeff_bin = sprintf('encoded_file_frame_%d.txt', frame);
        
        entropy(approx_residual_frame_entropy_preparation, width, height, coeff_bin);
        


        % Update the reference frame
        reference = reconstructed_frame;
    end
    
    fclose(fid);
    %fclose(mv_fid);

    fclose(res_bin_fid);  % close the binary residuals file

end

function [dx, dy] = block_search(reference, block, row, col, r)
    % Initialize
    best_mae = inf;
    dx = 0;
    dy = 0;
    
    % Define the search range
    start_row = max(1, row-r);
    end_row = min(size(reference, 1) - size(block, 1) + 1, row+r);
    start_col = max(1, col-r);
    end_col = min(size(reference, 2) - size(block, 2) + 1, col+r);
    
    % Search for the best match
    for y = start_row:end_row
        for x = start_col:end_col
            ref_block = reference(y:y+size(block, 1)-1, x:x+size(block, 2)-1);
            mae = mean(abs(double(block(:)) - double(ref_block(:))));
            
            if mae < best_mae
                best_mae = mae;
                dx = x - col;
                dy = y - row;
            end
        end
    end
end

function [ref_block, mode] = intra_search(reference, block, row, col, i)
    % Initialize
    %mode = 2; % vertical 0 and horizontal 1
    vertical_border = 128*ones(1, i);
    horizontal_border = 128*ones(i,1);

    % vertical
    row_ref = row - 1;

    start_col = col;
    end_col = col + i - 1;

    if row_ref > 0
        vertical_border = reference(row_ref,start_col:end_col);
    end    
    ref_block_vertical = repmat(vertical_border, i, 1);

    % horizontal
    col_ref = col - 1;

    start_row = row;
    end_row = row + i - 1;

    if col_ref > 0
        horizontal_border = reference(start_row:end_row,col_ref);
    end    
    ref_block_horizontal = repmat(horizontal_border, 1, i);    

    size(block)
    mae_vertical = mean(abs(double(ref_block_vertical)-double(block)));
    mae_horizontal = mean(abs(double(ref_block_horizontal)-double(block)));

    if mae_vertical>mae_horizontal
        mode = 1; % horizontal
        ref_block = ref_block_horizontal;
    else
        mode = 0; % vertical
        ref_block = ref_block_vertical;
    end
    
end

function data_ITC = residual_processing_before_entropy(data, i, QP)
    data_TC = dct2(data); %2D DCT
    data_TC_quantized = quantization(data_TC,i, QP); % quantization
    Q = get_quantization_para(i, QP); % get quantization parameter
    data_TC_rescaled = data_TC_quantized .* Q; % rescaling
    data_ITC = idct2(data_TC_rescaled); % inverse DCT
    data_ITC = double(data_ITC); % Clip values and convert to double
end

function data_TC_quantized = residual_processing_entropy(data, i, QP)
    data_TC = dct2(data); %2D DCT
    data_TC_quantized = quantization(data_TC,i, QP); % quantization
end



function data_quantized = quantization(data, i, QP)
    Q = get_quantization_para(i, QP);
    data_quantized = round(data./Q);

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

function entropy(input, width, height, coeff_bin)
    output = reorder(input);
    output_RLE = customRLE(output,width, height);
    output_entropy = expGolombExtended(output_RLE);
    writeBinary(coeff_bin, output_entropy);
end



% order in document
function output = reorder(input)
    % Assume input is an 8x8 matrix
    [rows, cols] = size(input);
    output = zeros(1, rows*cols);
    index = 1;
    for sum = 0:(rows+cols-2)
        for i = 0:sum
            j = sum - i;
            if (i < rows) && (j < cols)
                output(index) = input(i+1, j+1);
                index = index + 1;
            end
        end
    end
end

% zigzag order
% function output = zigzag_order(input)
%     % Assume input is an 8x8 matrix
%     [rows, cols] = size(input);
%     output = zeros(1, rows*cols);
%     index = 1;
%     for sum = 0:(rows+cols-2)
%         if mod(sum, 2) == 0  % Even sum: move from bottom-left to top-right
%             for j = 0:sum
%                 i = sum - j;
%                 if (i < rows) && (j < cols)
%                     output(index) = input(i+1, j+1);
%                     index = index + 1;
%                 end
%             end
%         else  % Odd sum: move from top-right to bottom-left
%             for i = 0:sum
%                 j = sum - i;
%                 if (i < rows) && (j < cols)
%                     output(index) = input(i+1, j+1);
%                     index = index + 1;
%                 end
%             end
%         end
%     end
% end

function encoded = customRLE(seq,width, height)
    encoded = [];  % Initialize an empty array to store the encoded sequence
    n = width*height;  % Get the length of the input sequence
    i = 1;  % Initialize the index variable

    while i <= n
        runStart = i;  % Store the start index of the current run
        if seq(i) ~= 0
            % Handle non-zero run
            while i <= n && seq(i) ~= 0
                i = i + 1;
            end
            runLength = i - runStart;  % Compute the length of the run
            encoded = [encoded, -runLength, seq(runStart:i-1)];  % Append the run length and the numbers to the encoded sequence
        else
            % Handle zero run
            while i <= n && seq(i) == 0
                i = i + 1;
            end
            runLength = i - runStart;  % Compute the length of the run
            if i <= n  % Check if there are more non-zero numbers
                encoded = [encoded, runLength];  % Append the run length to the encoded sequence
            else
                encoded = [encoded, 0];  % Append 0 to indicate that the rest of the elements are zeros
            end
        end
    end
end


function coded = expGolombExtended(input)
    % Initialize an empty array to store the coded sequence
    coded = '';
    
    % Loop through each element in the input sequence
    for i = 1:length(input)
        % Get the current value
        val = input(i);
        
        % Map the input value to a non-negative integer
        if val<= 0
            mappedVal = -2*round(val);
        else
            mappedVal = max(0,2*round(val)-1);
        end    
        
        mappedVal = round(mappedVal);
        % Get the Exponential-Golomb code of the mapped value
        
        egCode = expGolomb(mappedVal);
        
        % Append the Exponential-Golomb code to the coded sequence
        coded = [coded, egCode];
    end
end

function code = expGolomb(num)
    % Compute the length of the binary part
    binLen = floor(log2(num + 1)) + 1;
    
    % Compute the prefix (a string of binLen - 1 zeros)
    prefix = repmat('0', 1, binLen - 1);
    
    % Compute the binary representation of num + 1
    binary = dec2bin(num + 1, binLen);
    
    % Concatenate the prefix and binary parts to form the Exponential-Golomb code
    code = [prefix, binary];
end


function writeBinary(filename, binaryString)
    % Open the file with write permission
    fileId = fopen(filename, 'wt');
    
    % Check if the file has been opened successfully
    if fileId == -1
        error('Failed to open file for writing.');
    end
    
    % Write the binary string to the file
    fprintf(fileId, '%s', binaryString);
    
    % Close the file
    fclose(fileId);
end