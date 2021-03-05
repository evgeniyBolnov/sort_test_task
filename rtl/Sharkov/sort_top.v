`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:				Protei 
// Engineer: 			Sharkov Mikhail
// 
// Create Date:			    	 
// Design Name: 
// Module Name:    		sort_top 
// Project Name: 		sort_test
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

module sort_top
#(	
	parameter DATA_WIDTH = 8,					// for example 
	parameter MAX_LENGTH = 16					// for example
) 
(
	// Input streaming interface
	input						 snk_clock, 	// 50 MHz
	input						 snk_reset, 	// asynchronous
	input						 snk_valid,	
	input						 snk_sop, 	
	input						 snk_eop,
	input	    [DATA_WIDTH-1:0] snk_data,
	output wire    	        	 snk_ready,
	
	// Output streaming interface
	input						 src_clock, 	// 133 MHz
	input						 src_reset, 	// asynchronous
	output wire					 src_valid,	
	output wire					 src_sop, 	
	output wire					 src_eop,
	output wire [DATA_WIDTH-1:0] src_data
);

	localparam ADDR_WIDTH = clogb2(MAX_LENGTH);

	// Define the clogb2 function
	function integer clogb2 (input integer bit_depth);
    begin
      for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
  	endfunction

	//----------------------------------------------------------------------------------
	//-- Reg/Wire Declarations
	//----------------------------------------------------------------------------------
	wire snk_reset_sync;
	wire src_reset_sync;
	wire src_ready;
	wire src_ready_sync;
	wire snk_done;
	wire snk_done_sync;
	wire fifo_we;
	wire fifo_rd;
	wire [DATA_WIDTH-1:0] fifo_data;
	wire fifo_full;
	wire fifo_empty;

	//----------------------------------------------------------------------------------
	//-- Syncronizing of asynchronous resets
	//----------------------------------------------------------------------------------
	sync sync_inst_1 
	(
		.SignalIn	 			( snk_reset		 ), 
		.clkB	    			( snk_clock		 ), 
		.SignalOut_clkB			( snk_reset_sync ) 
	);

	sync sync_inst_2 
	(
		.SignalIn	 			( src_reset		 ), 
		.clkB	    			( src_clock		 ), 
		.SignalOut_clkB			( src_reset_sync ) 
	);

	//----------------------------------------------------------------------------------
	//-- Writing to FIFO Finite State Machine (Input streaming interface)
	//----------------------------------------------------------------------------------
	write_fifo_fsm write_fifo_fsm_inst 
	(
		.snk_clock	 			( snk_clock		 ), 
		.snk_reset    			( snk_reset_sync ), 
		.snk_valid				( snk_valid 	 ),
		.snk_sop				( snk_sop 	 	 ),
		.snk_eop				( snk_eop	 	 ),
		.src_ready				( src_ready_sync ),
		.fifo_full				( fifo_full		 ),
		.snk_ready				( snk_ready 	 ),
		.snk_done				( snk_done	 	 ),
		.we_fifo				( fifo_we 	 	 )
	);

	//----------------------------------------------------------------------------------
	//-- Crossing Clock Domain
	//----------------------------------------------------------------------------------
	sync sync_inst_3 
	(
		.SignalIn	 			( snk_done		 ), 
		.clkB	    			( src_clock		 ), 
		.SignalOut_clkB			( snk_done_sync  ) 
	);

	//----------------------------------------------------------------------------------
	//-- Simple Dual Clocks FIFO 
	//----------------------------------------------------------------------------------
	fifo #(.DATA_WIDTH(DATA_WIDTH),.MAX_LENGTH(MAX_LENGTH),.ADDR_WIDTH(ADDR_WIDTH)) fifo_inst
	(            
		.wclk					( snk_clock		 ),
		.wrst					( snk_reset_sync ),
		.we						( fifo_we		 ),
		.data					( snk_data		 ),

		.rclk             		( src_clock		 ),
		.rrst					( src_reset_sync ), 
		.rd               		( fifo_rd		 ), 
		.q			            ( fifo_data		 ),
		 
		.ffull            		( fifo_full		 ), 
		.fempty			        ( fifo_empty	 ),
		.fifo_count				( 				 ),
		.wack					( 				 ),
		.rack					( 				 )     
	); 
	
	//----------------------------------------------------------------------------------
	//-- Reading from FIFO Finite State Machine (Output streaming interface)
	//----------------------------------------------------------------------------------
	read_fifo_fsm #(.DATA_WIDTH(DATA_WIDTH),.MAX_LENGTH(MAX_LENGTH)) read_fifo_fsm_inst 
	(
		.src_clock	 			( src_clock		 ), 
		.src_reset    			( src_reset_sync ), 
		.snk_done				( snk_done_sync	 ),
		.fifo_data				( fifo_data		 ),
		.fifo_empty				( fifo_empty	 ),
		.src_ready				( src_ready 	 ),
		.rd_fifo				( fifo_rd 	 	 ),
		.src_valid				( src_valid 	 ),
		.src_sop				( src_sop	 	 ),
		.src_eop				( src_eop	 	 ),
		.src_data				( src_data	 	 )
	);

	//----------------------------------------------------------------------------------
	//-- Crossing Clock Domain
	//----------------------------------------------------------------------------------
	sync sync_inst_4 
	(
		.SignalIn	 			( src_ready		 ), 
		.clkB	    			( snk_clock		 ), 
		.SignalOut_clkB			( src_ready_sync ) 
	);

endmodule