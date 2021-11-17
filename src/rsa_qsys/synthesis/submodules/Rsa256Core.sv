// `include "Montegomery.sv"
// `include "ModuloProduct.sv"
module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x(m)
	output         o_finished
);




//reg & wire 
//----------------------------------

// for Montegomery
	// m = a * b ( mod n )
//=================================
// MT for t
logic i_MT_start_w_T, i_MT_start_r_T;
logic [255:0] i_MT_a_T, i_MT_b_T;

logic [255:0] o_MT_w_T ;
logic [255:0] o_MT_r_T ;

logic o_MT_finished_w_T ;
logic o_MT_finished_r_T ;
//======================================
//MT for m
logic i_MT_start_w_M, i_MT_start_r_M ;
logic [255:0] i_MT_a_M, i_MT_b_M;

logic [255:0] o_MT_w_M ;
logic [255:0] o_MT_r_M ;

logic o_MT_finished_w_M ;
logic o_MT_finished_r_M ;

//============================
// for ModuloProduct
	// m = a * b ( mod n )

logic i_MP_start_w, i_MP_start_r ;

logic [256:0] i_MP_a; //MP input are const
logic [255:0] i_MP_b;
logic [255:0] o_MP_m_w ;
logic [255:0] o_MP_m_r ;


logic o_MP_finished_w ;
logic o_MP_finished_r ;



// for this module


	// replace i_a with y 
logic [255:0] y_w ;
logic [255:0] y_r ;

logic [255:0] d_w ;
logic [255:0] d_r ;
logic [255:0] d_shift;
logic [255:0] n_w ;
logic [255:0] n_r ;
	// replace o_a_pow_d with m
// logic [255:0] x_w ;
// logic [255:0] x_r ;

logic finished_w ;
logic finished_r ;

//  =================== mao7===================
logic [8:0] counter_w, counter_r; 
logic [2:0] state_w, state_r;

logic [255:0] t_w, t_r;
logic [255:0] m_w, m_r;

assign i_MP_b = y_r;
assign i_MP_a[256] = 1'b1;
assign i_MP_a[255:0] = 256'd0; 
assign i_MT_a_M = m_r;
assign i_MT_b_M = t_r;
assign i_MT_a_T = t_r;
assign i_MT_b_T = t_r;

//output ports
assign o_finished = finished_r;
assign o_a_pow_d = m_r;
// modules
//----------------------------------
Montegomery MT_m (
	.i_clk(i_clk),
	.i_start(i_MT_start_r_M),
	.i_a(i_MT_a_M),
	.i_b(i_MT_b_M),
	.i_n(n_r),
	.i_rst(i_rst),
	.o_m(o_MT_w_M), 
	.o_finished(o_MT_finished_w_M)
) ;


Montegomery MT_t (
	.i_clk(i_clk),
	.i_start(i_MT_start_r_T),
	.i_a(i_MT_a_T),
	.i_b(i_MT_b_T),
	.i_n(n_r),
	.i_rst(i_rst),
	.o_m(o_MT_w_T), 
	.o_finished(o_MT_finished_w_T)
) ;

ModuloProduct MP (
	.i_clk(i_clk),
	.i_start(i_MP_start_r),
	.i_rst(i_rst),
	.i_a(i_MP_a),
	.i_b(i_MP_b),
	.i_n(n_r),
	.i_k(9'd257),

	.o_m(o_MP_m_w),
	.o_finished(o_MP_finished_w)

) ;

//output
//----------------------------------

//combinational
//----------------------------------
	// m = Montegomery( a, b, N) ;

always_comb begin  //d 被移到下面的fsm
	if ( i_start ) begin
		y_w = i_a ;
		n_w = i_n ;
	end
	else begin
		y_w = y_r ;
		n_w = n_r ;
	end
	
end

// x is m
always_comb begin : core_FSM

	// $display("piyan");
	case (state_r)
		3'd0: begin
			// $display("0");
			d_w = d_r ;
			counter_w = counter_r;
			t_w = t_r;
			m_w = m_r;
			state_w = state_r;
			i_MP_start_w = i_MP_start_r;	
			i_MT_start_w_T = i_MT_start_r_T;		
			i_MT_start_w_M = i_MT_start_r_M;	
			finished_w = finished_r;	
			if( i_start ) begin
				d_w = i_d ;
				i_MP_start_w = 1'd1;
				m_w = 256'd1;
				state_w = 3'd1;
			end 

		end 


		3'd1: begin
			// $display("1");
			d_w = d_r ;
			counter_w = counter_r;
			t_w = t_r;
			m_w = m_r;
			state_w = state_r;
			i_MP_start_w = 0;
			finished_w = finished_r;
			i_MT_start_w_T = i_MT_start_r_T;		
			i_MT_start_w_M = i_MT_start_r_M;		
			if(o_MP_finished_r) begin
				t_w = o_MP_m_r;
				state_w = 3'd2;
			end
		

		end

		3'd2: begin
			// $display("2");
			d_w = d_r;
			t_w = t_r;
			m_w = m_r;
			state_w = state_r;
			counter_w = counter_r;
			finished_w = finished_r;
			i_MP_start_w = i_MP_start_r;
			if( counter_r == 9'd256) begin
				state_w = 3'd5;
				i_MT_start_w_T = i_MT_start_r_T;
				i_MT_start_w_M = i_MT_start_r_M;
				finished_w = 1;
			end
			else begin
				if(d_r[0] == 1) begin
					i_MT_start_w_M = 1;
					i_MT_start_w_T = 1;				
					state_w = 3'd3;
				end
				else begin
					i_MT_start_w_M = 0;
					i_MT_start_w_T = 1;				
					state_w = 3'd4;

				end
			end
			



		end



		3'd3: begin  // i-th bit of d is 1
			// $display("3");
			d_w = d_r;
			t_w = t_r;		
			m_w = m_r;	
			state_w = state_r;
			i_MP_start_w = i_MP_start_r;
			i_MT_start_w_M = 0;
			i_MT_start_w_T = 0;
			counter_w = counter_r;
			finished_w = finished_r;
			if(o_MT_finished_r_T) begin  //Assume that o_MT_finished_r_T and o_MT_finished_r_M is the same
				t_w = o_MT_r_T;
				m_w = o_MT_r_M;				
				counter_w = counter_r + 1;
				d_w = d_r >> 1;
				state_w = 3'd2;
			end
		end


		3'd4: begin  // i-th bit of d is 0
			// $display("4");
			d_w = d_r;
			t_w = t_r;		
			m_w = m_r;	
			state_w = state_r;
			i_MT_start_w_M = 0;
			i_MT_start_w_T = 0;
			i_MP_start_w = i_MP_start_r;
			counter_w = counter_r;
			finished_w = finished_r;
			if(o_MT_finished_r_T) begin
				t_w = o_MT_r_T;				
				counter_w = counter_r + 1;
				d_w = d_r >> 1;
				state_w = 3'd2;
			end
		end

		3'd5: begin    //state5 can be used to satisfied bonus (decode multiple cipher with pressing reset)
			// $display("5");
			d_w = 0;
			t_w = 0;
			m_w = 0;
			i_MT_start_w_M = 0;
			i_MT_start_w_T = 0;
			i_MP_start_w = 0;
			counter_w = 0;
			finished_w = 0 ;
			state_w = 0;
		end
		default:  begin
			d_w = d_r ;
			counter_w = counter_r;
			t_w = t_r;
			m_w = m_r;
			state_w = state_r;
			i_MP_start_w = i_MP_start_r;	
			i_MT_start_w_T = i_MT_start_r_T;		
			i_MT_start_w_M = i_MT_start_r_M;		

		end 



	endcase



end


//sequential
//----------------------------------

always_ff @( posedge i_clk or posedge i_rst ) begin
	if( i_rst ) begin
		//MP
		i_MP_start_r <= 1'b0 ;
		o_MP_m_r <= 256'd0 ;
		o_MP_finished_r <= 1'b0 ;

		//MT_T
		i_MT_start_r_T <= 1'b0 ;
		o_MT_r_T <= 256'd0 ;
		o_MT_finished_r_T<= 1'b0 ;
		//MT_m
		i_MT_start_r_M <= 1'b0 ;
		o_MT_r_M <= 256'd0 ;
		o_MT_finished_r_T <= 1'b0 ;
		//this
		y_r <= 256'd0 ;
		d_r <= 256'd0 ;
		n_r <= 256'd0 ;
		finished_r <= 1'b0 ;



		state_r <= 0;
		counter_r <= 0;
		t_r <= 0;
		m_r <= 0;
		
	end
	else begin
		//MP
		i_MP_start_r <= i_MP_start_w ;
		o_MP_m_r <= o_MP_m_w ;
		o_MP_finished_r <= o_MP_finished_w ;

		//MT_T
		i_MT_start_r_T <= i_MT_start_w_T ;
		o_MT_r_T <= o_MT_w_T ;
		o_MT_finished_r_T <= o_MT_finished_w_T ;
		//MT_m
		i_MT_start_r_M <= i_MT_start_w_M;
		o_MT_r_M <= o_MT_w_M ;
		o_MT_finished_r_M <= o_MT_finished_w_M ;
		//this
		y_r <= y_w ;
		d_r <= d_w ;
		n_r <= n_w ;
		finished_r <= finished_w ;

		counter_r <= counter_w ;
		state_r <= state_w;
		t_r <= t_w;
		m_r <= m_w;
	end
end

endmodule
