module src
#(
    parameter DATA_WIDTH = 8,
    parameter MAX_LENGTH = 16
)
(
    input                               clk, 
    input                               reset,
    input                               enable,
    input   [MAX_LENGTH*DATA_WIDTH-1:0] data_in,    // parallel data in
    output wire                         valid,
    output wire                         sop,
    output wire                         eop,
    output wire        [DATA_WIDTH-1:0] data_out    // parallel data out
);

reg [DATA_WIDTH-1:0] data_reg, data_next;
reg [MAX_LENGTH:0] count_reg, count_next;
reg valid_reg, valid_next;
reg sop_reg, sop_next;
reg eop_reg, eop_next;

assign data_out = data_reg;
assign valid = valid_reg;
assign sop = sop_reg;
assign eop = eop_reg;   

// save initial and next value in register
always @(posedge clk or posedge reset) begin
    if(reset) begin
        data_reg <= 0;
        count_reg <= MAX_LENGTH;
        valid_reg <= 0;
        sop_reg <= 0;
        eop_reg <= 0;
    end
    else begin
        data_reg <= data_next;
        count_reg <= count_next;
        valid_reg <= valid_next;
        sop_reg <= sop_next;
        eop_reg <= eop_next;
    end
end

always @* begin
    data_next = data_in[count_reg*DATA_WIDTH +: DATA_WIDTH];
    count_next = count_reg;
    valid_next = valid_reg;
    sop_next = sop_reg;
    eop_next = eop_reg;
    
    if (enable) begin
        if (count_reg == 0) begin
            count_next = MAX_LENGTH; 
            valid_next = 1;
            sop_next = 0;
            eop_next = 1;      
        end
        else if (count_reg == MAX_LENGTH) begin 
            count_next = count_reg-1;
            valid_next = 0;
            sop_next = 0;
            eop_next = 0;
        end
        else if (count_reg == MAX_LENGTH-1) begin 
            count_next = count_reg-1;
            valid_next = 1;
            sop_next = 1;
            eop_next = 0;
        end
        else begin 
            count_next = count_reg-1;
            valid_next = 1;
            sop_next = 0;
            eop_next = 0;
        end
    end
end

endmodule 