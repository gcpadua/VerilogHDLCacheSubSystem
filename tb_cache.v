module tb_cache();
	reg clock;
	reg rw;
	reg [4:0] addr;
	reg [7:0] in;
	wire [7:0] q;
	wire cacheMiss;
	wire ramRead;
	wire ramWrite;
	wire [4:0] ramAddr;
	wire [7:0] ramOut;
	
	cache teste(clock, rw, addr, in, q, cacheMiss, ramRead, ramWrite, ramAddr, ramOut);
	
	initial begin
		clock<=0; rw <=0; addr<=5'd20; in<=8'h0;
		
		#10 addr<=5'd21;
		
		#10 addr<=5'd22;
		
		#10 addr<=5'd25;
		
		#10 addr<=5'd28;
		
		#10 rw<=1; in<=8'hff;
		
		#10 rw<=1; addr<=5'd00; in<=8'd10;
		#10 rw<=1; addr<=5'd01; in<=8'd11;
		#10 rw<=1; addr<=5'd02; in<=8'd12;
		#10 rw<=1; addr<=5'd03; in<=8'd13;
		#10 rw<=1; addr<=5'd04; in<=8'd14;
		
		#50 $finish;
	end
	
	always #1 clock=~clock;
	
endmodule