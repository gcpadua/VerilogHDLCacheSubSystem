module memory(
	input [4:0] address,
	input clock,
	input [7:0] data,
	input wren,
	output reg [7:0] q
);

	
	reg [7:0] mem[31:0];
	
	initial begin
		$readmemh("D:/MEGAsync/CEFET-Universidade/LAOC2/Pratica1/CacheQ3/init.txt", mem);
	end
	
	always @(posedge clock) begin
		q = mem[address];
	end
	
	always @(negedge clock) begin
		if(wren == 1) mem[address] = data;
	end

endmodule