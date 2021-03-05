module Sorting_Stack #(parameter HBIT = 8,
                       parameter R_SZ = 16)(
clk, hold, is_input, data_in, data_out_1, valid,  sop, eop);

localparam _R_SZ= (R_SZ+1)/2;    

input clk;
input hold;                                                 
input is_input;                                 

input [HBIT-1:0] data_in;                 
output [HBIT-1:0] data_out_1;   
output  sop, eop, valid;           

wire [HBIT-1:0] data_out;

wire [HBIT-1:0] in_prev[_R_SZ:0];
wire [HBIT-1:0] in_next[_R_SZ:0];
wire [HBIT-1:0] out[_R_SZ:0];

reg  [R_SZ-1:0] addr;


generate
  genvar i,j;
    for (i=0; i<_R_SZ; i=i+1) 
        begin : block_name01
            Cell_Compare  #(HBIT) ribbon(.clk(clk), .hold(hold), .is_input(is_input), .in_prev(in_prev[i]), .in_next(in_next[i]), .out(out[i]) );            
            assign in_prev[i+1]= (i<_R_SZ-1)?out[i]:in_prev[i+1];
            assign in_next[i]= (i<_R_SZ-1)?out[i+1]:0;
        end
    assign in_prev[0]= data_in;
    assign data_out= out[0];

endgenerate

assign data_out_1 = (valid)? ~data_out:'h0; 

always @(posedge clk)
    begin
        addr = addr<<1;
        addr[0] = is_input;
          
    end

assign valid =addr[R_SZ-1];
assign sop= addr[0]&addr[R_SZ-1];
assign eop = (addr[R_SZ-2]|addr[R_SZ-1])&~addr[R_SZ-2];

endmodule
