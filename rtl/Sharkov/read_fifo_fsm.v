module read_fifo_fsm
#(	
    parameter DATA_WIDTH = 8,				 
	parameter MAX_LENGTH = 16			
)  
(
    input                        src_clock,                     
    input                        src_reset,
    input			             snk_done,	// 1 - done, 0 - busy
	input       [DATA_WIDTH-1:0] fifo_data,
    input                        fifo_empty, 	
	output wire		             src_ready, // 1 - ready, 0 - busy 
    output wire		             rd_fifo, 
    output wire    	             src_valid,
    output wire    	             src_sop,
    output wire    	             src_eop,
    output wire [DATA_WIDTH-1:0] src_data             
);

    parameter [1:0] IDLE     = 2'b00,
                    READ     = 2'b01,
                    SORT     = 2'b10,
                    SRC      = 2'b11;
    
    reg  [1:0] state = IDLE, next_state;
    wire enable_sort, enable_src;
    
    always @(posedge src_clock or posedge src_reset) begin
        if (src_reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        next_state = state;
        
        case (state)
           
            IDLE:   if (snk_done)
                        next_state = READ;
                    else
                        next_state = IDLE;

            READ:   if (fifo_empty)
                        next_state = SORT;
                    else
                        next_state = READ;
            
            SORT:       next_state = SRC;

            SRC:   if (src_eop)
                        next_state = IDLE;
                    else
                        next_state = SRC;
            
            default:    next_state = IDLE;

        endcase
    end

    assign src_ready = (state == IDLE);
    assign rd_fifo = (state == READ);
    assign enable_sort = (next_state == SORT);
    assign enable_src = (state == SRC);

    //----------------------------------------------------------------------------------
	//-- Sorting
	//----------------------------------------------------------------------------------
	reg [MAX_LENGTH*DATA_WIDTH-1:0] sort_in;
	wire [MAX_LENGTH*DATA_WIDTH-1:0] sort_out;

    always @(posedge src_clock or posedge src_reset) begin
        if (src_reset) 
            sort_in <= {MAX_LENGTH*DATA_WIDTH{1'b0}};
        else begin
            case(state)

            IDLE: 
                sort_in <= {MAX_LENGTH*DATA_WIDTH{1'b0}}; 

            SORT, SRC:
                sort_in <= sort_in;

            READ:
                sort_in <= {sort_in[MAX_LENGTH*DATA_WIDTH-DATA_WIDTH-1:0], fifo_data};

            endcase
        end    
    end

    sort #(.DATA_WIDTH(DATA_WIDTH),.MAX_LENGTH(MAX_LENGTH)) sort_inst
	( 									
		.clk					( src_clock		),
        .enable                 ( enable_sort	),
		.in						( sort_in		),
		.out					( sort_out		)
	);

    src #(.DATA_WIDTH(DATA_WIDTH),.MAX_LENGTH(MAX_LENGTH)) src_inst
	( 									
		.clk					( src_clock		),
		.reset					( src_reset		),
        .enable                 ( enable_src	),
		.data_in				( sort_out		),
        .valid                  ( src_valid		),
        .sop                    ( src_sop		),
        .eop                    ( src_eop		),
        .data_out               ( src_data		)
	);

endmodule
