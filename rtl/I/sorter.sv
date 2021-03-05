module sorter
#
(
	parameter DATA_WIDTH = 1, 
	parameter MAX_LENGTH = 2
)
(
	//input interface
	input 	logic 						snk_reset,
	input 	logic 						snk_clock, //50 MHz
	output 	logic 						snk_ready,
	input 	logic 						snk_valid,
	input 	logic 						snk_sop,
	input 	logic 						snk_eop,
	input 	logic 	[DATA_WIDTH - 1:0] 	snk_data,
	
	//output interface
	input	logic						src_reset,
	input	logic						src_clock, //133 MHz
	output	logic						src_valid,
	output	logic						src_sop,
	output	logic						src_eop,
	output	logic	[DATA_WIDTH - 1:0] 	src_data
);
initial
begin
	src_sop <= 0;
	src_eop <= 0;
	snk_ready <= 0;
	src_data <= 0;
	src_valid <= 0;
end


logic flag_input_transaction = 0;
logic flag_output_transaction = 0;
logic flag_sorting = 0;
logic flag_data_sorted = 0;

logic [DATA_WIDTH - 1:0] mem_snk [MAX_LENGTH-1:0];
logic [$clog2(MAX_LENGTH) - 1:0] cnt_size_input = 0;
logic [$clog2(MAX_LENGTH) - 1:0] cnt_size_output = 0;
logic [$clog2(MAX_LENGTH) - 1:0] not_sort_size = 0;
logic [$clog2(MAX_LENGTH) - 1:0] cnt_sort = 0;
logic [$clog2(MAX_LENGTH) - 1:0] cnt_output = 0;
logic [$clog2(MAX_LENGTH) - 1:0] index = 0;
logic [DATA_WIDTH - 1:0] acamulate = 0;

//cnt_size_input
always @ (posedge snk_clock or snk_reset or src_reset)
begin
	if(snk_reset | src_reset)
	begin
		flag_input_transaction <= 0;
		cnt_size_input <= 0;
	end
	else
	begin
		if(snk_sop)
			flag_input_transaction <= 1;
		if(snk_eop)
			flag_input_transaction <= 0;
			
		if(flag_input_transaction & snk_valid)
			cnt_size_input = cnt_size_input + 1;
		if(flag_data_sorted)
			cnt_size_input <= 0;
		
	end
end

//take data
always @(posedge snk_clock)
begin
	if((flag_input_transaction | snk_sop) & snk_valid)
		mem_snk[cnt_size_input] <= snk_data;
end

//sorting
always @(posedge src_clock or snk_reset or src_reset)
begin
	if(snk_reset | src_reset)
	begin
		flag_sorting <= 0;
		flag_data_sorted <= 0;
		flag_output_transaction <= 0;
		cnt_size_output <= 0;
		cnt_sort <= 0;
		index <= 0;
		not_sort_size <= 0;
		acamulate <= 0;
	end
	else
	begin
		if(snk_eop)
		begin
			flag_sorting <= 1;
			not_sort_size <= cnt_size_input;
			cnt_sort <= 0;
		end
		
		if(mem_snk[cnt_sort] > acamulate)
		begin
			acamulate = mem_snk[cnt_sort];
			index = cnt_sort;
		end
			
		if(flag_sorting & ~snk_eop)
		begin
			if(cnt_sort != not_sort_size)
			begin
				cnt_sort <= cnt_sort + 1;
			end
			else
			begin
				cnt_sort <= 0;
				not_sort_size <= not_sort_size - 1;
				mem_snk[index] <= mem_snk[cnt_sort];
				mem_snk[cnt_sort] <= acamulate;
				acamulate <= 0;
				if(not_sort_size == 0)
				begin
					flag_sorting <= 0;
					flag_data_sorted <= 1;
					flag_output_transaction <= 1;
					cnt_size_output <= cnt_size_input;
				end
			end
		end
	end
end

//send data 
always @(posedge src_clock or snk_reset or src_reset)
	begin
		if(snk_reset | src_reset)
			begin
				src_valid               <= 0;
				src_sop                 <= 0;
				cnt_output              <= 0;
				src_data                <= 0;
				src_eop                 <= 0;
				flag_data_sorted        <= 0;
				flag_output_transaction <= 0;
			end
		else
			begin
				if(flag_data_sorted)
					begin
						src_valid <= 1;
						if(flag_output_transaction)
							begin
								flag_output_transaction <= 0;
								src_sop                 <= 1;
							end
						else
							begin
								src_sop <= 0;
							end

						if(cnt_output != cnt_size_output)
							begin
								cnt_output <= cnt_output + 1;
								src_data   <= mem_snk[cnt_output];
								if(cnt_output == cnt_size_output - 1)
									src_eop <= 1;
							end
						else
							begin
								src_eop          <= 0;
								cnt_output       <= 0;
								flag_data_sorted <= 0;
								src_valid        <= 0;
							end
					end
				else
					begin
						src_valid <= 0;
					end
			end
	end

//snk_ready
always @(posedge src_clock or snk_reset or src_reset)
	begin
		if(snk_reset | src_reset)
			begin
				snk_ready <= 0;
			end
		else
			begin
				if(flag_data_sorted)
					begin
						snk_ready <= 0;
					end
				else
					begin
						if(flag_sorting)
							snk_ready <= 0;
						else if (~flag_output_transaction)
							snk_ready <= 1;
					end
			end
	end

endmodule