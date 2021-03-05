module fifo 
#(	
  parameter DATA_WIDTH = 8,				 
	parameter MAX_LENGTH = 16,				
  parameter ADDR_WIDTH = 4			
)  
(  
  input                        wclk,            // Input write clock signal
  input                        wrst,            // Input write reset signal
  input                        we,              // Write enable input signal
  input       [DATA_WIDTH-1:0] data,            // Input data

  input                        rclk,            // Input read clock signal
  input                        rrst,            // Input read reset signal
  input                        rd,              // Read memory signal
  output reg  [DATA_WIDTH-1:0] q,               // Output data

  output                       ffull,           // FIFO full output signal: 1 - FULL, 0 - NOT FULL 
  output                       fempty,          // FIFO empty output signal: 1 - EMPTY, 0 - NOT EMPTY
  output reg  [ADDR_WIDTH-1:0] fifo_count,      // Number of words in FIFO   
  output reg                   wack,            // Write acknowledge handshake signal
  output reg                   rack             // Read acknowledge signal
);
 
 // Internal wires and registers 
  reg [DATA_WIDTH-1:0] rfifo [0:MAX_LENGTH-1];  // Rx FIFO 
  reg   [ADDR_WIDTH:0] adrr;                    // Read address, one extra bit for full/empty detection
  reg   [ADDR_WIDTH:0] adrr_s;                  // Synchronized read pointer
  reg   [ADDR_WIDTH:0] adrw;                    // Write address, one extra bit for full/empty detection
  reg   [ADDR_WIDTH:0] adrw_s;                  // Synchronized write pointer
  reg                  rfifo_full;              // Flag that FIFO is full
  reg                  rfifo_empty;             // Flag that FIFO is empty
  
  assign ffull = rfifo_full;
  assign fempty = rfifo_empty;
   
  always @(posedge wclk or posedge wrst)       // Write FIFO logic
    begin
      if (wrst)                      
        begin
          adrw <= {ADDR_WIDTH+1{1'b0}}; 
          wack <= 1'b0;
        end
      else if (we & ~rfifo_full)
        begin
          rfifo[adrw[ADDR_WIDTH-1:0]] <= data;
          adrw <= adrw + 1'b1;
          wack <= 1'b1;
        end
      else
        begin
          wack <= 1'b0;
        end
      adrr_s <= adrr;                           // Synchronized read pointer
    end
  
  always @(posedge wclk or posedge wrst)
    begin
      if (wrst)
        begin
          rfifo_full <= 1'b0;
        end
      else
        begin
          if ({~adrw[ADDR_WIDTH],adrw[ADDR_WIDTH-1:0]} == adrr_s[ADDR_WIDTH:0])
            rfifo_full <= 1'b1;
          else
            rfifo_full <= 1'b0;
        end
		  fifo_count <= (adrw[ADDR_WIDTH-1:0] - adrr_s[ADDR_WIDTH-1:0]);
    end
  
  always @(negedge rclk or posedge rrst)    // Read FIFO logic
    begin
      if (rrst)
        begin
          adrr <= {ADDR_WIDTH+1{1'b0}};
          rack <= 1'b0;
        end	  
      else if (rd & ~rfifo_empty)
        begin
          adrr <= adrr + 1'b1;
          rack <= 1'b1;
        end
      else
        begin
          rack <= 1'b0;
        end
		  q <= rfifo[adrr[ADDR_WIDTH-1:0]];  
      adrw_s <= adrw;                       // Synchronized write pointer   
    end

  always @(posedge rclk or posedge rrst)
    begin
      if (rrst)
        begin
          rfifo_empty <= 1'b1;     
        end
      else
        begin
          if (adrr == adrw_s)
            rfifo_empty <= 1'b1;
          else
            rfifo_empty <= 1'b0; 
        end
    end     
  
endmodule