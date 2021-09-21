

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:48:30 09/09/2021 
// Design Name: 
// Module Name:    FSM 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module FSM(
	input clk, rst,sw,test_signal,
	output tx,
	output reg [7:0]txbyte,
	output clk_50, tx_busy
    );
// Instantiate the module

reg [27:0]cnt = 28'd0;
reg tx_ena = 1'b0;
//reg [7:0] txbyte;
wire[15:0] Dout;

Frequency_counter FC (
    .ref_clk(clk), 
    .test_signal(test_signal), 
    .start(sw), 
    .reset(rst), 
    .done(done), 
    .Dout(Dout)
    );

uart instance_name (
    .clk(clk), 
    .reset_n(1'b1), 
    .tx_ena(tx_ena), 
    .tx_data(txbyte), 
    .rx(1'b0),  
    .tx_busy(tx_busy), 
    .tx(tx)
    );
reg [2:0]state, next_state = 2'd0; 
//reg[2:0] state = 3'b00;
parameter idle        = 3'd0,
			 tx_init     = 3'd1,
			 wait2finish = 3'd2,
			 toggle      = 3'd3,
			 load        = 3'd4,
			 branch      = 3'd5,
			 delay       = 3'd6;
			 
parameter word = 16'hABCD;
parameter txlen = 2;
always@(posedge clk)begin
	if(rst == 1'b0)state <= idle;
	else state <= next_state;
end
reg timeout = 1'b0;
always@(state, sw, BSR, tx_busy, timeout)begin
tx_ena = 1'b0;
case(state)

	idle :begin 
			if(done) next_state = load;
			else next_state = idle;
			end			
	load : next_state = tx_init;
	tx_init : begin
				 tx_ena = 1'b1;
				 next_state = wait2finish;
				 end			 
	wait2finish : begin
					  if(tx_busy == 1'b0)next_state = toggle;
					  else next_state = wait2finish;
					  end
	toggle : begin
				if(BSR <= txlen-1)next_state = delay;
				else next_state = idle;
				end
	delay : begin
			  if(timeout)next_state = load;
			  else next_state = delay;
			  end
	default : next_state = idle;
endcase
end

reg[2:0] BSR = 3'd0;
reg[26:0]timer = 16'd0;

always@(negedge clk)begin
	if(rst == 1'b0)begin
		BSR <= 3'd0;
		timer <= 16'd0;
		txbyte <= 8'd0;
		end
	else
		case(state)
		//Reset all registers
		idle :begin
					BSR <= 3'd0;
					timer <= 16'd0;
					txbyte <= 8'd0;
				end
		
		//Load data in tx register based on BSR Value
		load : begin
					case(BSR[1:0])
						2'd0 : txbyte <= Dout[15:8];
						2'd1 : txbyte <= Dout[7:0];
//						2'd2 : txbyte <= 8'd0;
//						2'd3 : txbyte <= 8'd64;
					endcase
				 end
		/*
			Here Increment BSR to point to next byte to be sent
			if BSR equals to byte to be sent goto idle else keep transmitting number of bytes 
			specified
		*/
		toggle : if(BSR < txlen) BSR <= BSR + 3'd1;

		delay : begin 
					if(timer < 27'd99_999_999)begin
						timer <= timer + 1'd1;
						timeout <= 1'b0;
					end
					else begin 
						timeout <= 1'd1;
						timer <= 16'd0;
					end
				  end
		endcase;
end

endmodule
