% ʹ������ƵĶ����ָ�����
clc;  % ��������д���
clear;% �������
close all;% �����ͼ

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ͼ��ˮӡǶ��%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ����ͼƬ
load('Cameraman256x256.mat');      % ��ȡLenaͼƬ
image256x256 = Cameraman256x256;
% load('Peppers256x256.mat');
% image256x256 = Peppers256x256;

% ����original table
table_height=128;
table_width=128;
block_height=2;
block_width=2;
key = 13;
original_table = zeros(table_height,table_width,'uint32');
for i =0:1:table_height-1
    for j=0:1:table_width-1
       original_table(i+1,j+1)=i*table_height+j;
    end
end

%�� 1-D transform ��ʽ���� look-up table
original_table_look_up=mod(key*original_table,table_height*table_width)+1;
for i = 1 : table_height
    for j = 1 : table_width
        if original_table_look_up(i,j) == (table_height*table_width)
            original_table_look_up(i,j) = 0;
        end
    end
end

%push side operation
push_side=mod(original_table_look_up(1,:),table_height);
original_table_look_up_push_side = zeros(table_height,table_width,'uint32');
% for i = 1:1:table_width
%     if push_side(i)<table_width/2
%        original_table_look_up_push_side(:,push_side(i)+(table_width/2)+1)= original_table_look_up(:,i);
%     else
%        original_table_look_up_push_side(:,push_side(i)-(table_width/2)+1)= original_table_look_up(:,i);
%     end
% end
left_index = 1;
right_index = (table_width/2)+ 1;
for i = 1:1:table_width
    if push_side(i)<table_width/2
       original_table_look_up_push_side(:,right_index)= original_table_look_up(:,i);
       right_index = right_index + 1;
    else
       original_table_look_up_push_side(:,left_index)= original_table_look_up(:,i);
       left_index = left_index + 1;
    end
end


% ָ���������ؾ���
image_data = image256x256(1 : table_height*block_height,1 : table_width*block_width);
figure('NumberTitle', 'off', 'Name', 'Image Data'); % ȷ��ͼƬ�������ʽ 
imshow(image_data);                          % ͼƬ��ʾ
% title('Image Data');

% ������������ƽ��ֵ
i_avg = 0;
j_avg = 0;
image_data_avg = zeros(table_height,table_width,'uint8');
for i = 1 : block_height : table_height*block_height
    i_avg = i_avg +1 ;
    for j = 1 : block_width : table_width*block_width
        j_avg = j_avg + 1;
        image_data_avg(i_avg,j_avg) = uint8( mean([image_data(i,j),image_data(i,j+1),image_data(i+1,j),image_data(i+1,j+1)]) );
    end
    j_avg = 0;
end

% ��� 12 Bit WaterMark �� ֱ�Ӷ�Ӧԭͼ���������
number_of_pixel_bit = 8;
watermark = zeros(table_height/2,table_width,'uint16');
for i = 1 : table_height/2
    for j = 1 : table_width
        for k = number_of_pixel_bit : -1 : number_of_pixel_bit-4
            watermark(i,j) = bitset( watermark(i,j) , k+4 , bitget(image_data_avg(i,j),k) );
            watermark(i,j) = bitset( watermark(i,j) , k-1 , bitget(image_data_avg(i+table_height/2,j),k) );       
        end
        p1 = xor(bitget(image_data_avg(i,j),number_of_pixel_bit),bitget(image_data_avg(i,j),number_of_pixel_bit-1));
        p2 = xor(bitget(image_data_avg(i,j),number_of_pixel_bit-2),bitget(image_data_avg(i,j),number_of_pixel_bit-3));
        p3 = xor(bitget(image_data_avg(i,j),number_of_pixel_bit-4),bitget(image_data_avg(i+table_height/2,j),number_of_pixel_bit));
        p4 = xor(bitget(image_data_avg(i+table_height/2,j),number_of_pixel_bit-1),bitget(image_data_avg(i+table_height/2,j),number_of_pixel_bit-2));
        p5 = xor(bitget(image_data_avg(i+table_height/2,j),number_of_pixel_bit-3),bitget(image_data_avg(i+table_height/2,j),number_of_pixel_bit-4));
        p  = xor(xor(xor(xor(p1,p2),p3),p4),p5);
        if p == 0
            v = 1;
        else
            v = 0;
        end
        watermark(i,j) = bitset( watermark(i,j) , 2 , p );%����P
        watermark(i,j) = bitset( watermark(i,j) , 1 , v );%����V
    end
end

% �� WaterMark Ƕ�뵽ԭͼ���У���ʹ��ƽ��������Image_Data_Eembed����Ƕ����ɵ����ؿ�
image_data_embed = zeros(table_height*block_height,table_width*block_width,'uint8');
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        if original_table_look_up_push_side(i,j) < (table_height*table_width/2)
            embed_data_row = uint8(floor(double(original_table_look_up_push_side(i,j))/table_width)+1);
            embed_data_col = uint8(mod(double(original_table_look_up_push_side(i,j)),table_width)+1);
        else 
            embed_data_row = uint8(floor(double( original_table_look_up_push_side(i,j)- (table_height*table_width/2))/table_width)+1);
            embed_data_col = uint8(mod(double(original_table_look_up_push_side(i,j)-(table_height*table_width/2)),table_width)+1);
        end
        image_data_embed(1+block_height*(i-1),1+block_width*(j-1)) = smooth_function(image_data(1+block_height*(i-1),1+block_width*(j-1)),bitget(watermark(embed_data_row,embed_data_col),12),bitget(watermark(embed_data_row,embed_data_col),11),bitget(watermark(embed_data_row,embed_data_col),10));
        image_data_embed(1+block_height*(i-1),1+block_width*(j-1)+1) = smooth_function(image_data(1+block_height*(i-1),1+block_width*(j-1)+1),bitget(watermark(embed_data_row,embed_data_col),9),bitget(watermark(embed_data_row,embed_data_col),8),bitget(watermark(embed_data_row,embed_data_col),7));
        image_data_embed(1+block_height*(i-1)+1,1+block_width*(j-1)) = smooth_function(image_data(1+block_height*(i-1)+1,1+block_width*(j-1)),bitget(watermark(embed_data_row,embed_data_col),6),bitget(watermark(embed_data_row,embed_data_col),5),bitget(watermark(embed_data_row,embed_data_col),4));
        image_data_embed(1+block_height*(i-1)+1,1+block_width*(j-1)+1) = smooth_function(image_data(1+block_height*(i-1)+1,1+block_width*(j-1)+1),bitget(watermark(embed_data_row,embed_data_col),3),bitget(watermark(embed_data_row,embed_data_col),2),bitget(watermark(embed_data_row,embed_data_col),1));       
    end
end

% ��� PSNR
[peak_snr,snr] = psnr(image_data,image_data_embed,255);
fprintf('\nThe Embeded Image Peak-SNR value is %0.4f', peak_snr);
fprintf('\nThe SNR value is %0.4f \n', snr);

%��ˮӡ�����ͼ�������ʾ
figure('NumberTitle', 'off', 'Name', 'Image Data Embeded'); % ȷ��ͼƬ�������ʽ 
imshow(image_data_embed);                          % ͼƬ��ʾ
% title('Image Data Embeded');

%��ͼ����в��ִ۸�
image_data_tampered = image_data_embed;
not_tamper_distance=16;
% for i=1:16
%    image_data_tampered(3+(i-1)*not_tamper_distance:3+(i-1)*not_tamper_distance+7,1:256)=0; 
% end
for i=1:16
   image_data_tampered(1:256,3+(i-1)*not_tamper_distance:3+(i-1)*not_tamper_distance+7)=0; 
end
% not_tamper_distance=14;
% for i = 1 : 18
%     for j = 1 : 18
%         image_data_tampered(5+(i-1)*not_tamper_distance:5+(i-1)*not_tamper_distance+9,5+(j-1)*not_tamper_distance:5+(j-1)*not_tamper_distance+9)=0;    
%     end
% end
% image_data_tampered(1:128,1:256)= 0;          % ָ�������� 50%����
% image_data_tampered(1:256,1:128)= 0;          % ָ�������� 50% ,��
% image_data_tampered(1:128,1:128)= 0; image_data_tampered(129:256,129:256)= 0;  % ָ�������� 50% ,��б��
% for i= 256 : -1 : 1
%     image_data_tampered(257-i,1:i)= 0;        % ָ�������� 50% ,б��
% end
% for i= 1 : 1 : 256
%     image_data_tampered(257-i,i:256)= 0;      % ָ�������� 50% ,б��
% end
% image_data_tampered(1:6,1:256)= 0;        % ָ�������� 2.4%
% image_data_tampered(109:148,109:148)= 0;      % ָ�������� 2.4%
% image_data_tampered(47:210,47:210)= 0;        % ָ�������� 40%
% image_data_tampered(26:231,26:231)= 0;        % ָ�������� 65%
% image_data_tampered(18:239,18:239)= 0;        % ָ�������� 75%
% image_data_tampered(11:246,11:246)= 0;        % ָ�������� 85%
% image_data_tampered(7:250,7:250)= 0;          % ָ�������� 90%
% image_data_tampered(4:253,4:253)= 0;          % ָ�������� 95%
% image_data_tampered(47:210,133:216) = image_data_tampered(47:210,41:124); %ƿ��������21%
% image_data_tampered(47:210,51:114) = image_data_tampered(47:210,143:206); %ƿ��������16%
% load('lena_collage_attack.mat');
% image_data_tampered(47:210,133:216) = image_data_tampered(47:210,41:124); %ƿ��������21%
image_data_recovered = image_data_tampered;
figure('NumberTitle', 'off', 'Name', 'Image Data Tampered'); % ȷ��ͼƬ�������ʽ 
imshow(image_data_tampered);                          % ͼƬ��ʾ
% title('Image Data Tampered');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ͼ��ָ�%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

block_valid_or_invalid = ones(table_height,table_width,'logical');
%�۸Ŀ�һ�����
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        bit_a7 = bitget(image_data_tampered(1+block_height*(i-1),1+block_width*(j-1)),3);
        bit_a6 = bitget(image_data_tampered(1+block_height*(i-1),1+block_width*(j-1)),2);
        bit_a5 = bitget(image_data_tampered(1+block_height*(i-1),1+block_width*(j-1)),1);   
        
        bit_a4 = bitget(image_data_tampered(1+block_height*(i-1),1+block_width*(j-1)+1),3);
        bit_a3 = bitget(image_data_tampered(1+block_height*(i-1),1+block_width*(j-1)+1),2);
        bit_b7 = bitget(image_data_tampered(1+block_height*(i-1),1+block_width*(j-1)+1),1);
        
        bit_b6 = bitget(image_data_tampered(1+block_height*(i-1)+1,1+block_width*(j-1)),3);
        bit_b5 = bitget(image_data_tampered(1+block_height*(i-1)+1,1+block_width*(j-1)),2);
        bit_b4 = bitget(image_data_tampered(1+block_height*(i-1)+1,1+block_width*(j-1)),1);
        
        bit_b3 = bitget(image_data_tampered(1+block_height*(i-1)+1,1+block_width*(j-1)+1),3);
        bit_p  = bitget(image_data_tampered(1+block_height*(i-1)+1,1+block_width*(j-1)+1),2);
        bit_v  = bitget(image_data_tampered(1+block_height*(i-1)+1,1+block_width*(j-1)+1),1); 
        
        bit_p_calculate = xor(xor(xor(xor(xor(xor(xor(xor(xor(bit_a7,bit_a6),bit_a5),bit_a4),bit_a3),bit_b7),bit_b6),bit_b5),bit_b4),bit_b3);
        if (bit_p_calculate == bit_p)&&(bit_p ~= bit_v)
            block_valid_or_invalid(i,j) = 1;
        else
            block_valid_or_invalid(i,j) = 0; 
        end
    end
end

%�۸Ŀ�������
block_valid_or_invalid_backup = block_valid_or_invalid;
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        if block_valid_or_invalid(i,j) == 1
            if i == 1 && j == 1 
                %Ԫ��(E,SE,S)
                if ( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            elseif i == 1 && j == table_width
                %Ԫ��(W,SW,S)
                if ( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            elseif i == table_height && j == table_width
                %Ԫ��(W,NW,N)
                if ( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            elseif i == table_height && j == 1
                %Ԫ��(N,NE,E)
                if ( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            elseif i > 1 && i < table_height && j == 1
                %Ԫ��(N,NE,E)(E,SE,S)
                if  ( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )||( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            elseif i == 1 && j > 1 && j < table_width
                %Ԫ��(E,SE,S)(W,SW,S)
                if  ( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )||( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            elseif i > 1 && i < table_height && j == table_width
                %Ԫ��(W,NW,N)(W,SW,S)
                if ( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )|| ( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            elseif i == table_height && j > 1 && j < table_width
                %Ԫ��(W,NW,N)(N,NE,E)
                if ( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )||( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            else
                %Ԫ��(W,NW,N)(N,NE,E)(E,SE,S)(W,SW,S)
                if ( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )||( block_valid_or_invalid(i-1,j)==0 && block_valid_or_invalid(i-1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )||( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j+1)==0 &&block_valid_or_invalid(i,j+1)==0 )||( block_valid_or_invalid(i+1,j)==0 && block_valid_or_invalid(i+1,j-1)==0 &&block_valid_or_invalid(i,j-1)==0 )
                    block_valid_or_invalid_backup(i,j) = 0;
                end
            end   
        end
    end
end
block_valid_or_invalid = block_valid_or_invalid_backup;

%�۸Ŀ��������
block_invalid_count = 0;
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        if block_valid_or_invalid(i,j) == 1
            if i == 1 && j == 1                             %1
                block_invalid_count = 0;
            elseif i == 1 && j == table_width               %2
                block_invalid_count = 0;
            elseif i == table_height && j == table_width    %3
                block_invalid_count = 0;
            elseif i == table_height && j == 1              %4
                block_invalid_count = 0;
            elseif i > 1 && i < table_height && j == 1      %5
                if block_valid_or_invalid(i-1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
            elseif i == 1 && j > 1 && j < table_width       %6
                if block_valid_or_invalid(i,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
            elseif i > 1 && i < table_height && j == table_width  %7
                if block_valid_or_invalid(i-1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
            elseif i == table_height && j > 1 && j < table_width  %8
                if block_valid_or_invalid(i,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
            else                                                   %9
                if block_valid_or_invalid(i,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i-1,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j+1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j) == 0
                    block_invalid_count = block_invalid_count + 1;
                end
                if block_valid_or_invalid(i+1,j-1) == 0
                    block_invalid_count = block_invalid_count + 1;
                end              
            end            
            if block_invalid_count>=5
                block_valid_or_invalid_backup(i,j) = 0;
                block_invalid_count = 0;
            else
                block_valid_or_invalid_backup(i,j) = 1;
                block_invalid_count = 0;
            end          
        end
    end
end
block_valid_or_invalid = block_valid_or_invalid_backup;
%������Ϊ��λ�õ��۸ļ�����
image_valid_or_invalid = zeros(table_height*block_height,table_width*block_width);
for i = 1 : table_height    
    for j = 1 : table_width
        if block_valid_or_invalid(i,j) == 0
            for i_to_configure = ((i-1)*block_height + 1) : 1 : i*block_height  
                for j_to_configure = ((j-1)*block_width + 1): 1 : j*block_width
                    image_valid_or_invalid(i_to_configure,j_to_configure) = 0;
                end
            end
        elseif block_valid_or_invalid(i,j) == 1
            for i_to_configure = ((i-1)*block_height + 1) : 1 : i*block_height  
                for j_to_configure = ((j-1)*block_width + 1): 1 : j*block_width
                    image_valid_or_invalid(i_to_configure,j_to_configure) = 1;
                end
            end
        end
    end
end

% ����۸ı���
invaild_count = 0;
for i = 1 : table_height*block_height    
    for j = 1 : table_width*block_width
        if (image_valid_or_invalid(i,j)~=1)
            invaild_count = invaild_count + 1;
        end
    end
end
tampered_percentage = invaild_count*100/(table_height*block_height*table_width*block_width);
fprintf('The percentage of tampered is %0.4f%%\n',tampered_percentage);
% ��ʾ��׼�۸�ͼ
image_valid_or_invalid_standard = zeros(table_height*block_height,table_width*block_width,'uint8');
for i = 1 : table_height*block_height    
    for j = 1 : table_width*block_width
        if (image_valid_or_invalid(i,j)==1)
            image_valid_or_invalid_standard(i,j) = 0;
        else
            image_valid_or_invalid_standard(i,j) = 255;
        end
    end
end
figure('NumberTitle', 'off', 'Name', 'Image Data Standard'); % ȷ��ͼƬ�������ʽ 
imshow(image_valid_or_invalid_standard);                          % ͼƬ��ʾ
% title('Image Data Recovered');

% ���� �����Ƿ�۸ľ��󡯣���һ���޸Ĺ����飬����Ӧ���ݾ�����1�������ͳһ��ֵ��ԭ����
% block_valid_or_invalid_backup = block_valid_or_invalid;
%ͼ��һ���ָ�
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        if block_valid_or_invalid(i,j) == 0
            % ȷ�����ϱ߿黹���±߿�
            if i > (table_height/2) 
                block_is_up = 0;
            else
                block_is_up = 1;
            end
            %���㱻�۸Ŀ�����ؿ�λ���Լ����ÿ�λ��
            table_sub_script = ((i-1)*table_width + j - 1);
            if table_sub_script >= (table_height*table_width/2)
                table_partner_sub_script = table_sub_script - (table_height*table_width/2);
            else
                table_partner_sub_script = table_sub_script + (table_height*table_width/2);
            end
            %Ѱ�ұ��۸Ŀ�����ؿ�λ���Լ����ÿ�λ��,������ָ�ͼ��
            for watermark_row = 1 : table_height
                for watermark_col = 1 : table_width
                    if (original_table_look_up_push_side(watermark_row,watermark_col) == table_sub_script) && (block_valid_or_invalid(watermark_row,watermark_col) == 1)%��ʾ�ҵ���ˮӡ���λ�ã���δ���ƻ� 
                        if block_is_up == 1
                            bit_a7 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)),3);
                            bit_a6 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)),2);
                            bit_a5 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)),1);        
                            bit_a4 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)+1),3);
                            bit_a3 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)+1),2);
                            avg_a_pixel = 128*bit_a7 + 64*bit_a6 +32*bit_a5+16*bit_a4+8*bit_a3;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)) = avg_a_pixel;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)+1) = avg_a_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)) = avg_a_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)+1) = avg_a_pixel;
                        else
                            bit_b7 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)+1),1);
                            bit_b6 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)),3);
                            bit_b5 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)),2);
                            bit_b4 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)),1);    
                            bit_b3 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)+1),3);
                            avg_b_pixel = 128*bit_b7 + 64*bit_b6 +32*bit_b5+16*bit_b4+8*bit_b3;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)) = avg_b_pixel;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)+1) = avg_b_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)) = avg_b_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)+1) = avg_b_pixel;
                        end
                        block_valid_or_invalid_backup(i,j) = 1;                                            
                    elseif (original_table_look_up_push_side(watermark_row,watermark_col) == table_partner_sub_script) && (block_valid_or_invalid(watermark_row,watermark_col) == 1)%��ʾ�ҵ���ˮӡ���λ�ã���δ���ƻ� 
                        if block_is_up == 1
                            bit_a7 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)),3);
                            bit_a6 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)),2);
                            bit_a5 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)),1);        
                            bit_a4 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)+1),3);
                            bit_a3 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)+1),2);
                            avg_a_pixel = 128*bit_a7 + 64*bit_a6 +32*bit_a5+16*bit_a4+8*bit_a3;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)) = avg_a_pixel;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)+1) = avg_a_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)) = avg_a_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)+1) = avg_a_pixel;
                        else
                            bit_b7 = bitget(image_data_tampered(1+block_height*(watermark_row-1),1+block_width*(watermark_col-1)+1),1);
                            bit_b6 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)),3);
                            bit_b5 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)),2);
                            bit_b4 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)),1);    
                            bit_b3 = bitget(image_data_tampered(1+block_height*(watermark_row-1)+1,1+block_width*(watermark_col-1)+1),3);
                            avg_b_pixel = 128*bit_b7 + 64*bit_b6 +32*bit_b5+16*bit_b4+8*bit_b3;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)) = avg_b_pixel;
                            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)+1) = avg_b_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)) = avg_b_pixel;
                            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)+1) = avg_b_pixel;
                        end
                        block_valid_or_invalid_backup(i,j) = 1;
                    end
                end
            end           
        end
    end
end


% һ���ָ���δ�ָ��İٷֱ�
block_equal_zero = 0;
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        if block_valid_or_invalid_backup(i,j) == 0
            block_equal_zero = block_equal_zero + 1;
        end
    end
end
fprintf('The percentage of blocks not recovered after stage-1 tamper recovery is %0.4f%%\n',(block_equal_zero*100)/(table_width*table_height));

% ͼ������ָ�
rate = 1.5;
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        if block_valid_or_invalid_backup(i,j) == 0   %��ʾ��ǰ�鱻�۸ģ���һ���޸�û�л�ԭ
            pixel_original_count = double(1);
            pixel_recovered_count = double(1);
            n_original = zeros(1,12); 
            n_recovered = zeros(1,12);           
            if (i > 1) && (i < table_height) && (j > 1) && (j < table_width)% 1
                % N1
                if block_valid_or_invalid_backup(i-1,j-1) == 1
                    if block_valid_or_invalid(i-1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N2
                if block_valid_or_invalid_backup(i-1,j) == 1
                    if block_valid_or_invalid(i-1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N3
                if block_valid_or_invalid_backup(i-1,j+1) == 1
                   if block_valid_or_invalid(i-1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end                
                % N4
                if block_valid_or_invalid_backup(i,j+1) == 1
                    if block_valid_or_invalid(i,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N5
                if block_valid_or_invalid_backup(i+1,j+1) == 1
                   if block_valid_or_invalid(i+1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N6
                if block_valid_or_invalid_backup(i+1,j) == 1
                    if block_valid_or_invalid(i+1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N7
                if block_valid_or_invalid_backup(i+1,j-1) == 1
                    if block_valid_or_invalid(i+1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N8
                if block_valid_or_invalid_backup(i,j-1) == 1
                    if block_valid_or_invalid(i,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end    

            elseif (i > 1) && (i < table_height) && (j==1)% 2
                % N2
                if block_valid_or_invalid_backup(i-1,j) == 1
                    if block_valid_or_invalid(i-1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N3
                if block_valid_or_invalid_backup(i-1,j+1) == 1
                   if block_valid_or_invalid(i-1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end                
                % N4
                if block_valid_or_invalid_backup(i,j+1) == 1
                    if block_valid_or_invalid(i,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N5
                if block_valid_or_invalid_backup(i+1,j+1) == 1
                   if block_valid_or_invalid(i+1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N6
                if block_valid_or_invalid_backup(i+1,j) == 1
                    if block_valid_or_invalid(i+1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end          

            elseif (i > 1) && (i < table_height) && (j==table_width)% 3
                % N1
                if block_valid_or_invalid_backup(i-1,j-1) == 1
                    if block_valid_or_invalid(i-1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N2
                if block_valid_or_invalid_backup(i-1,j) == 1
                    if block_valid_or_invalid(i-1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N6
                if block_valid_or_invalid_backup(i+1,j) == 1
                    if block_valid_or_invalid(i+1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N7
                if block_valid_or_invalid_backup(i+1,j-1) == 1
                    if block_valid_or_invalid(i+1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N8
                if block_valid_or_invalid_backup(i,j-1) == 1
                    if block_valid_or_invalid(i,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end          
            elseif (i==1)&& (j > 1) && (j < table_width)% 4              
                % N4
                if block_valid_or_invalid_backup(i,j+1) == 1
                    if block_valid_or_invalid(i,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N5
                if block_valid_or_invalid_backup(i+1,j+1) == 1
                   if block_valid_or_invalid(i+1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N6
                if block_valid_or_invalid_backup(i+1,j) == 1
                    if block_valid_or_invalid(i+1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N7
                if block_valid_or_invalid_backup(i+1,j-1) == 1
                    if block_valid_or_invalid(i+1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N8
                if block_valid_or_invalid_backup(i,j-1) == 1
                    if block_valid_or_invalid(i,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end          
            elseif (i==table_height) && (j > 1) && (j < table_width)% 5
                % N1
                if block_valid_or_invalid_backup(i-1,j-1) == 1
                    if block_valid_or_invalid(i-1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N2
                if block_valid_or_invalid_backup(i-1,j) == 1
                    if block_valid_or_invalid(i-1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N3
                if block_valid_or_invalid_backup(i-1,j+1) == 1
                   if block_valid_or_invalid(i-1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end                
                % N4
                if block_valid_or_invalid_backup(i,j+1) == 1
                    if block_valid_or_invalid(i,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N8
                if block_valid_or_invalid_backup(i,j-1) == 1
                    if block_valid_or_invalid(i,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end          
            elseif (i==1)&&(j==1)% 6             
                % N4
                if block_valid_or_invalid_backup(i,j+1) == 1
                    if block_valid_or_invalid(i,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N5
                if block_valid_or_invalid_backup(i+1,j+1) == 1
                   if block_valid_or_invalid(i+1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N6
                if block_valid_or_invalid_backup(i+1,j) == 1
                    if block_valid_or_invalid(i+1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end         
            elseif (i==1)&&(j==table_width)% 7
                % N6
                if block_valid_or_invalid_backup(i+1,j) == 1
                    if block_valid_or_invalid(i+1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N7
                if block_valid_or_invalid_backup(i+1,j-1) == 1
                    if block_valid_or_invalid(i+1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i+1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1+1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N8
                if block_valid_or_invalid_backup(i,j-1) == 1
                    if block_valid_or_invalid(i,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end          
            elseif (i==table_height)&&(j==1)% 8
                % N2
                if block_valid_or_invalid_backup(i-1,j) == 1
                    if block_valid_or_invalid(i-1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N3
                if block_valid_or_invalid_backup(i-1,j+1) == 1
                   if block_valid_or_invalid(i-1,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end                
                % N4
                if block_valid_or_invalid_backup(i,j+1) == 1
                    if block_valid_or_invalid(i,j+1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j+1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1+1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end      
            elseif (i==table_height)&&(j==table_width)% 9
                % N1
                if block_valid_or_invalid_backup(i-1,j-1) == 1
                    if block_valid_or_invalid(i-1,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N2
                if block_valid_or_invalid_backup(i-1,j) == 1
                    if block_valid_or_invalid(i-1,j) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i-1,j) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1-1)+1,1+block_width*(j-1)));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end
                % N8
                if block_valid_or_invalid_backup(i,j-1) == 1
                    if block_valid_or_invalid(i,j-1) == 1 %��ʾ����δ�۸ĵĿ�
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                        n_original(pixel_original_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_original_count = pixel_original_count + 1;
                    elseif block_valid_or_invalid(i,j-1) == 0 %��ʾ���ǻָ��Ŀ�
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1),1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                        n_recovered(pixel_recovered_count) = uint16(image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1-1)+1));
                        pixel_recovered_count = pixel_recovered_count + 1;
                    end
                end                                                     
            end
            % ��������Ӧռ��
            probability_original = rate/((pixel_original_count-1)*rate+(pixel_recovered_count-1));
            probability_recovered = 1.0/((pixel_original_count-1)*rate+(pixel_recovered_count-1));

            %Ԥ�⵱ǰ�������ֵ
            n_forecast = sum(probability_original*n_original) +  sum(probability_recovered*n_recovered);

            %��Ԥ������ֵ���뵱ǰ�飬�������ݿ���1
            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)) = n_forecast;
            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)) = n_forecast;
            image_data_recovered(1+block_height*(i-1),1+block_width*(j-1)+1) = n_forecast;
            image_data_recovered(1+block_height*(i-1)+1,1+block_width*(j-1)+1) = n_forecast;
            block_valid_or_invalid_backup(i,j) = 1;
        end
        % ����       
    end
end

% �����ָ���δ�ָ��İٷֱ�
block_valid_or_invalid = block_valid_or_invalid_backup;
block_equal_zero = 0;
for i = 1 : 1 : table_height
    for j = 1 : 1 : table_width
        if block_valid_or_invalid(i,j) == 0
            block_equal_zero = block_equal_zero + 1;
        end
    end
end
fprintf('The percentage of blocks not recovered after stage-2 tamper recovery is %0.4f%%\n',(block_equal_zero*100)/(table_width*table_height));

%��ʾ�ָ�ͼ���PSNR
[peak_snr,snr] = psnr(image_data,image_data_recovered,255);
fprintf('\nThe Recovered Image Peak-SNR value is %0.4f', peak_snr);
fprintf('\nThe SNR value is %0.4f \n', snr);
%��ͼ����лָ����
figure('NumberTitle', 'off', 'Name', 'Image Data Recovered'); % ȷ��ͼƬ�������ʽ 
imshow(image_data_recovered);                          % ͼƬ��ʾ
% title('Image Data Recovered');