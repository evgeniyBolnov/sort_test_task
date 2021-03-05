module top #(parameter DATA_WIDTH = 8,
             parameter MAX_LENGTH      = 4)(
input snk_clock,
input snk_reset,
input snk_valid, snk_sop, snk_eop,
input [DATA_WIDTH-1:0] snk_data,
output snk_ready,

input src_clock,
input src_reset,
output src_valid, src_sop, src_eop,
output [DATA_WIDTH-1:0] src_data
);

wire [DATA_WIDTH-1:0] rdata;
wire rinc;
wire wfull, rempty;
wire hold;

assign snk_ready = (wfull||rempty)?(~wfull*rempty):snk_ready;
assign rinc = (wfull||rempty) ? (wfull*~rempty):rinc;


fifo1 #(DATA_WIDTH, MAX_LENGTH)  fifo1_inst(
.rdata(rdata),   
.wfull(wfull),
.rempty(rempty),
.wdata(snk_data),
.winc(snk_valid), .wclk(snk_clock), .wrst_n(snk_reset),   
.rinc(rinc), .rclk(src_clock), .rrst_n(src_reset)
);  

assign hold = (rdata[0]>=1'b0)?1'b0:1'b1;

Sorting_Stack #(DATA_WIDTH, 2**MAX_LENGTH) sort_inst (.clk(src_clock), .hold(hold), .is_input(rinc), .data_in(~rdata), .data_out_1(src_data),.valid(src_valid),.sop(src_sop),.eop(src_eop));

endmodule
