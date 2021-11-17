module ModuloProduct (
    input i_clk,
    input i_rst,
    input i_start,

    input [256:0] i_a,
    input [255:0] i_b,
    input [255:0] i_n, // a * b ( mod n )
    input [8:0] i_k, // 2^9 - 1 = 511 > 257 , k is number of bits of a 

    output [255:0] o_m,
    output o_finished
);

//reg & wire 
//----------------------------------

//data
logic [256:0] a_w ;
logic [256:0] a_r ; // note! a has 257 bits

logic [255:0] t_w ;
logic [255:0] t_r ; // replace b with t

logic [255:0] n_w ;
logic [255:0] n_r ;

logic [255:0] m_w ;
logic [255:0] m_r ; //

logic [8:0] k_w ;
logic [8:0] k_r ;

//state 
logic mission_w, mission_r ;
logic [8:0] count_w ;
logic [8:0] count_r ;
logic finished_w, finished_r ;

//wire

logic [256:0] mPlusT ;
logic [256:0] mValidA ;
logic [256:0] tPlusT ;


//
logic [256:0] t_double, m_plus_t;
logic enable_t, enable_mt;
assign t_double = t_r << 1;
assign m_plus_t = m_r + t_r;
assign enable_mt = (m_plus_t >= n_r) ? 1 : 0;
assign enable_t = (t_double >= n_r) ? 1 : 0;
 
//output
//----------------------------------

assign o_m = m_r ;
assign o_finished = finished_r ;

//combinational
//----------------------------------

assign mPlusT = ( enable_mt ) ? m_r + t_r - n_r : m_r + t_r ;
assign mValidA = ( a_r[0] ) ? mPlusT : m_r ;
assign tPlusT = ( enable_t ) ? t_double - n_r : t_double ;

always_comb begin
    
    if ( i_start ) begin
        // $display("MP");
        a_w = i_a ;
        t_w = i_b ;
        n_w = i_n ;
        m_w = 256'd0 ;
        k_w = i_k ;
        mission_w = 1'b1 ;
        count_w = 9'd0 ;
        finished_w = 1'b0 ;
    end
    else begin
		  k_w = k_r;
        if ( count_r == k_r && mission_r == 1'b1 ) begin
            // on mission and count == k, this cycle will be the last calculating cycle
            mission_w = 1'b0 ;
            count_w = 9'd0 ;
            finished_w = 1'b1 ;

            // calculation
            m_w = mValidA[255:0] ;
            t_w = tPlusT[255:0] ;

            // remain
            a_w = a_r ;
            n_w = n_r ;
            
        end 
        else begin
            // not gonna end
            mission_w = mission_r ;
            count_w = count_r + 1'b1 ;
            finished_w = 1'b0 ;

            // calculation
            m_w = mValidA[255:0] ;
            t_w = tPlusT[255:0] ;

            // remain
            // a_w = a_r ;
            a_w = a_r >> 1;
            n_w = n_r ;
        end
    end
end

//sequential
//----------------------------------
always_ff @( posedge i_clk or posedge i_rst ) begin 
    if ( i_rst ) begin
        a_r <= 257'd0 ;
        t_r <= 256'd0 ;
        n_r <= 256'd0 ;
        m_r <= 256'd0 ;
        k_r <= 9'd0 ;
        mission_r <= 1'b0 ;
        count_r <= 9'd0 ;
        finished_r <= 1'b0 ;
    end
    else begin
        a_r <= a_w ;
        t_r <= t_w ;
        n_r <= n_w ;
        m_r <= m_w ;
        k_r <= k_w ;
        mission_r <= mission_w ;
        count_r <= count_w ;
        finished_r <= finished_w ;
    end
end
endmodule
