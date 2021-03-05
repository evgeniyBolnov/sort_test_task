module write_fifo_fsm
(
    input                       snk_clock,                     
    input                       snk_reset,
    input			            snk_valid,	
	input			            snk_sop, 	
	input			            snk_eop,
    input			            src_ready,  // 1 - ready, 0 - busy
    input                       fifo_full, 
    output wire    	            snk_ready,
    output wire    	            snk_done,   // 1 - done, 0 - busy
    output wire    	            we_fifo           
);

    parameter [1:0] IDLE    = 2'b00,
                    WRITE   = 2'b01,
                    DONE    = 2'b10;
    
    reg  [1:0] state = IDLE, next_state;
    
    always @(posedge snk_clock or posedge snk_reset) begin
        if (snk_reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        next_state = state;
        
        case (state)
           
            IDLE:   if (snk_sop && snk_valid && src_ready && !fifo_full)
                        next_state = WRITE;
                    else
                        next_state = IDLE;

            WRITE:  if (snk_eop)
                        next_state = DONE;
                    else
                        next_state = WRITE;

            DONE:       next_state = IDLE;
            
            default:    next_state = IDLE;

        endcase
    end

    assign snk_ready = src_ready;
    assign we_fifo = (next_state == WRITE) || (next_state == DONE);
    assign snk_done = (next_state == DONE);

endmodule
