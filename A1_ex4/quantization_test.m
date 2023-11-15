i = 192; % i=[2, 8, 64], i is the block dimension
QP = min(6,log2(i)+7); % quantization parameter
Q = get_quantization_para(i, QP);

A = imread('example_2.jpg'); % Read an image
A = rgb2gray(A); % Convert to grayscale if necessary
subplot(1,2,1);
imshow(A);
title('A');

A_ITC = residual_processing_before_entropy(A, i, QP);
subplot(1,2,2);
imshow(A_ITC);
title('A, before entropy');


% 
% A_TC = dct2(A);
% 
% A_TC_quantized = quantization(A_TC,i, QP);
% % subplot(3,1,1);
% % imshow(A_TC_quantized);
% % title('A, quantized');
% 
% A_TC_rescaled = A_TC_quantized .* Q;
% subplot(3,1,2);
% imshow(A_TC_rescaled);
% title('A, rescaled');
% 
% A_ITC = idct2(A_TC_rescaled);
% A_ITC = uint8(max(min(A_ITC, 255), 0));
% subplot(3,1,3);
% imshow(A_ITC);
% title('A, inversed DCT');

function data_ITC = residual_processing_before_entropy(data, i, QP)
    data_TC = dct2(data); %2D DCT
    data_TC_quantized = quantization(data_TC,i, QP); % quantization
    Q = get_quantization_para(i, QP); % get quantization parameter
    data_TC_rescaled = data_TC_quantized .* Q; % rescaling
    data_ITC = idct2(data_TC_rescaled); % inverse DCT
    data_ITC = uint8(max(min(data_ITC, 255), 0)); % Clip values and convert to uint8
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