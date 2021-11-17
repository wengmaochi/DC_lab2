module Montegomery (
    input i_clk,
    input i_rst,
    input i_start,

    input [255:0] i_a,
    input [255:0] i_b,
    input [255:0] i_n, // a * b ( mod n )

    output [255:0] o_m,
    output o_finished
);


//reg & wire 
//----------------------------------

//data
logic [255:0] a_w ;
logic [255:0] a_r ;

logic [255:0] b_w ;
logic [255:0] b_r ;

logic [255:0] n_w ;
logic [255:0] n_r ;

logic [257:0] m_w ;
logic [257:0] m_r ; // note! m has 257 bits  // 10.27 -> fix to 258 bits

//state 
logic mission_w, mission_r ;
logic [7:0] count_w ;
logic [7:0] count_r ;
logic finished_w, finished_r ;

//wire
logic [257:0] mPlusB ;
logic [257:0] mPlusN ;
logic [257:0] mHalf ;



//output
//----------------------------------

assign o_m = m_r[255:0] ;
assign o_finished = finished_r ;

//combinational
//----------------------------------

assign mPlusB = ( a_r[0] ) ? ( m_r + b_r ) : m_r ;
assign mPlusN = ( mPlusB[0] ) ? ( mPlusB + n_r ) : mPlusB ;
assign mHalf = mPlusN >> 1 ;

always_comb begin
    
    if ( i_start ) begin
        // $display("MT");
        a_w = i_a ;
        b_w = i_b ;
        n_w = i_n ;
        m_w = 258'd0 ;
        mission_w = 1'b1 ;
        count_w = 8'd0 ;
        finished_w = 1'b0 ;
    end
    else begin
        // state determination
        if ( count_r == 8'b1111_1111 && mission_r == 1'b1 ) begin
            // on mission and count == 255, this cycle will be the last calculating cycle
            mission_w = 1'b0 ;
            count_w = 8'd0 ;
            finished_w = 1'b1 ;

            // calculation
            if(mHalf >= n_r) m_w = mHalf - n_r;
            else m_w = mHalf;

            // remain
            a_w = a_r ;
            b_w = b_r ;
            n_w = n_r ;
            
        end 
        else begin
            // not gonna end
            mission_w = mission_r ;
            
            finished_w = 1'b0 ;

            // calculation
            m_w = mHalf ;
            a_w = a_r >> 1;
            // remain
            // a_w = a_r ;
            count_w = count_r + 1'b1 ;
            b_w = b_r ;
            n_w = n_r ;
        end

    end

    
end

//sequential
//----------------------------------
always_ff @( posedge i_clk or posedge i_rst ) begin 
    if ( i_rst ) begin
        a_r <= 256'd0 ;
        b_r <= 256'd0 ;
        n_r <= 256'd0 ;
        m_r <= 258'd0 ;
        mission_r <= 1'b0 ;
        count_r <= 8'd0 ;
        finished_r <= 1'b0 ;
    end
    else begin
        a_r <= a_w ;
        b_r <= b_w ;
        n_r <= n_w ;
        m_r <= m_w ;
        mission_r <= mission_w ;
        count_r <= count_w ;
        finished_r <= finished_w ;
    end
end
endmodule