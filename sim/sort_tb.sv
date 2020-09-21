`timescale 10ps/10ps

module sort_tb ();

	localparam DATA_WIDTH = 16;
	localparam MAX_LENGTH = 128;

	logic [DATA_WIDTH-1:0] tx_queue[$];
	logic [DATA_WIDTH-1:0] rx_queue[$];

	logic snk_clock = 0;
	logic src_clock = 0;
	
	logic snk_reset = 0;
	logic src_reset = 0;

	logic                  snk_ready;
	logic                  snk_valid = 0;
	logic                  snk_sop   = 0;
	logic                  snk_eop   = 0;
	logic [DATA_WIDTH-1:0] snk_data  = 0;

	logic                  src_valid;
	logic                  src_sop  ;
	logic                  src_eop  ;
	logic [DATA_WIDTH-1:0] src_data ;

	event rx_complete;

	int len;

	initial
		fork
			forever #375 src_clock = ~src_clock;
			forever #1000 snk_clock = ~snk_clock;
		join

	default clocking snk @( posedge snk_clock );
	endclocking

	initial
		begin
			##2  snk_reset = 1;
			src_reset = 1;
			##2 snk_reset = 0;
			src_reset = 0;
			##2;
			for (int j = 0; j < 10; j++) 
				begin
					len = $urandom_range(2, MAX_LENGTH);
					$display("======test(%0d)======", len);
					for( int i = 0; i < len; i++ )
						tx_queue.push_back($random());
					send_queue(tx_queue);
					tx_queue.sort();
					@(rx_complete);
					##1;
				end
			$display("======Long test======");
			for( int i = 0; i < MAX_LENGTH+2; i++ ) 
					tx_queue.push_back($random());
			send_queue(tx_queue);
			tx_queue.sort();
			@(negedge snk_eop);
			##5;
			tx_queue.delete();
			rx_queue.delete();
			$display("======Simple test======");
			for( int i = 0; i < 5; i++ ) 
					tx_queue.push_back($random());
			##2 send_queue(tx_queue);
			tx_queue.sort();
			@(rx_complete);
			##10;
			$finish;
		end

	always @(rx_complete)
		begin
			static logic eq = 0;
			assert(tx_queue.size() == rx_queue.size())
				begin
					$display("Size is equal");
					for (int i = 0; i < rx_queue.size(); i++)
						begin
							eq |= ( rx_queue[i] == tx_queue[i] );
							assert( rx_queue[i] == tx_queue[i] ) else $display("[%0d] rx:%d tx:%d", i, rx_queue[i], tx_queue[i]);
						end
				end
			else $error("Size is not equal(%0d,%0d)",tx_queue.size(), rx_queue.size());
			assert( eq ) $display("data correct!"); else $error("Data is broken!");
			tx_queue.delete();
			rx_queue.delete();
		end

	always_ff @( posedge src_clock )
		begin
			if(src_valid)
				rx_queue.push_back(src_data);
			if ( src_eop )
				->rx_complete;
		end


	sort #(
		.DATA_WIDTH( DATA_WIDTH ),
		.MAX_LENGTH( MAX_LENGTH )
	) sort_inst (
		.snk_reset( snk_reset ),
		.snk_clock( snk_clock ),
		.snk_ready( snk_ready ),
		.snk_valid( snk_valid ),
		.snk_sop  ( snk_sop   ),
		.snk_eop  ( snk_eop   ),
		.snk_data ( snk_data  ),
		.src_reset( src_reset ),
		.src_clock( src_clock ),
		.src_valid( src_valid ),
		.src_sop  ( src_sop   ),
		.src_eop  ( src_eop   ),
		.src_data ( src_data  )
	);


/*
	RAM2SPEED #(
		.DATA_WIDTH(DATA_WIDTH),
		.MAX_LENGTH(MAX_LENGTH)
	) RAM2SPEED_inst (
		.snk_res  (snk_reset),
		.snk_clock(snk_clock),
		.snk_ready(snk_ready),
		.snk_valid(snk_valid),
		.snk_sop  (snk_sop  ),
		.snk_eop  (snk_eop  ),
		.snk_data (snk_data ),
		.src_res  (src_reset),
		.src_clock(src_clock),
		.src_valid(src_valid),
		.src_sop  (src_sop  ),
		.src_eop  (src_eop  ),
		.src_data (src_data )
	);
*/

	task print_queue(logic [DATA_WIDTH-1:0] queue[$], string text);
		$display(text);
		for (int i = 0; i < queue.size(); i++) begin
			$display("\t", queue[i]);
		end
		
	endtask

	task automatic send_queue(logic [DATA_WIDTH-1:0] queue[$]);
		int i = 0;
		while ( i < queue.size() )
			begin
				if( snk_ready )
					begin
						snk_valid <= 1;
						snk_sop <= ( i == 0);
						snk_eop <= ( i == queue.size()-1);
						snk_data <= queue[i];
						i++;
					end
				@( posedge snk_clock );
			end
		snk_valid <= 0;
		snk_eop   <= 0;
	endtask

endmodule