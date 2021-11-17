1. 10/26 17:43 謝
    寫了兩個module, MP, MT，基本上都寫完了，使用方式是丟給他start 的訊號跟 data， 他算完，會丟給你 finished 的訊號。

2. 10/26 22:25 mao7
    1. 完成rsa256core.sv，寫了它的FSM，圖在群組。使用方式是丟給他start 的訊號跟 data， 他算完，會丟給你 finished 的訊號。
    2. 若要進行下一筆測資必須給reset才行
    3. 從上版改了許多東西
        1. MP: 由於 input的N, 2^256,y,256都是定值，就不用flip-flop了，直接用wire接。
            a. N接到n_r
            b. 2^256 我給了一個257bits常數叫，
            c. y 接到y_r，但是bits數待確認。(MT吃到y的input應該是256bits而不是257? 待確認)  
            d. 用了兩個MP，一個算m一個算t，輸入的flip-flop也都拿掉了，直接接到t_r跟m_r
    4. 簡單說一下FSM
        3'd0 : idle，吃到i_start後把MP的start拉高、去state 1
        3'd1 : 正在算MP，finish拉高時去state 2 ,
        3'd2 : 開始算MT，看這時d[0]的bit決定去state 3 or state 4，並把MT控制訊號拉高。每次到這裡都會檢查counter，若counter == 256 代表for迴圈已經算完了，finish拉高去state 5
        3'd3 : 正在算MP，算完counter ++, d >> 1, 去state 2
        3'd4 : 正在算MP，算完counter ++, d >> 1, 去state 2
        3'd5 : 沒幹嘛，就是finish state，若要做bounus不按reset連續解碼可能會用這個state

3. 10/27 10:10 - 17:00
    寫了wrapper，可能可以跑？
    把input依序幹進去 應該就可以跑？
    FSM在群組。

4. 10/27 22:25 mao7 
    1. Modified tb.sv, MP, MT, Core.
    2. Core is done.
    3. Now state 5 will go to automatically go to idle in order to solve sequential tasks 

5. 10/27 13:30 楊翔淳
    1. state_r, state_w bit不夠==
    2.

