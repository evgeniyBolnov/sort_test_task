module sort 
#(
    parameter DATA_WIDTH = 8,
    parameter MAX_LENGTH = 16
)
(   input                                   clk,
    input                                   enable,
    input       [MAX_LENGTH*DATA_WIDTH-1:0] in,
    output reg  [MAX_LENGTH*DATA_WIDTH-1:0] out
);
    reg [MAX_LENGTH*DATA_WIDTH-1:0] sorted_bus;
    always @(posedge clk) begin
        if (enable)
            out <= sorted_bus;
    end

    integer i, j;
    reg [DATA_WIDTH-1:0] temp;
    reg [DATA_WIDTH-1:0] array [1:MAX_LENGTH];
    always @* begin
        for (i = 0; i < MAX_LENGTH; i = i + 1) begin
            array[i+1] = in[i*DATA_WIDTH +: DATA_WIDTH];
        end

        for (i = MAX_LENGTH; i > 0; i = i - 1) begin
            for (j = 1 ; j < i; j = j + 1) begin
                if (array[j] < array[j + 1]) begin
                    temp         = array[j];
                    array[j]     = array[j + 1];
                    array[j + 1] = temp;
                end 
            end
        end

        for (i = 0; i < MAX_LENGTH; i = i + 1) begin
            sorted_bus[i*DATA_WIDTH +: DATA_WIDTH] = array[i+1];
        end
    end
endmodule