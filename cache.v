module cache(
	input clock,
	input rw,
	input [4:0] addr,
	input [7:0] in,
	output reg [7:0] q,
	output reg cacheMiss,
	output reg pendingReadInidicator,
	output reg pendingWriteIndicator,
	output [4:0] ramAddr,
	output [7:0] ramOut,
	output reg [6:0] HEX0,
	output reg [6:0] HEX1,
	output reg [6:0] HEX2,
	output reg [6:0] HEX3,
	output reg [6:0] HEX4,
	output reg [6:0] HEX5,
	output reg [6:0] HEX6,
	output reg [6:0] HEX7,
	output reg [17:0] LEDR,
	output reg [8:0] LEDG
);
		
	reg valid[3:0];
	reg dirty[3:0];
	reg [1:0] lru[3:0];
	reg [4:0] tag[3:0];
	reg [7:0] value[3:0];
	
	
	reg [3:0] disp0;
	HEXto7Segment decod0(disp0, HEX0);
	
	reg [3:0] disp1;
	HEXto7Segment decod1(disp1, HEX1);
	
	reg [3:0] disp2;
	HEXto7Segment decod2(disp2, HEX2);
	
	reg [3:0] disp3;
	HEXto7Segment decod3(disp3, HEX3);
	
	reg [3:0] disp4;
	HEXto7Segment decod4(disp4, HEX4);
	
	reg [3:0] disp5;
	HEXto7Segment decod5(disp5, HEX5);
	
	reg [3:0] disp6;
	HEXto7Segment decod6(disp6, HEX6);
	
	reg [3:0] disp7;
	HEXto7Segment decod7(disp7, HEX7);
	
	
	wire cacheHit[3:0];
	assign cacheHit[0] = (tag[0] == addr) & valid[0];
	
	assign cacheHit[1] = (tag[1] == addr) & valid[1];
	
	assign cacheHit[2] = (tag[2] == addr) & valid[2];
	
	assign cacheHit[3] = (tag[3] == addr) & valid[3];
	
	
	reg [4:0] ramAddress;
	reg [7:0] ramInput;
	reg ramWren;
	wire [7:0] ramOutput;
	lpm_ram ram(ramAddress, clock, ramInput, ramWren, ramOutput);
	
	assign ramOut = ramOutput;
	assign ramAddr = ramAddress;
	
	
	reg [4:0] lastAddr;
	reg [7:0] cont;
	
	reg [7:0] pendingRead;
	reg [1:0] pendingReadDestination;
	
	reg [7:0] pendingWrite;
	
	reg [7:0] writeBufferData;
	reg [7:0] writeBufferAddr;
	
	reg [1:0] idLru2;
	reg hit1;
	
	reg [1:0] hitLru;
	
	initial begin
		valid[0]=1; valid[1]=1; valid[2]=0; valid[3]=1;
		dirty[0]=0; dirty[1]=0; dirty[2]=0; dirty[3]=0;
		lru[0]=2'h0; lru[1]=2'h1; lru[2]=2'h3; lru[3]=2'h2;
		tag[0]=5'd20; tag[1]=5'd22; tag[2]=5'd25; tag[3]=5'd21;
		value[0]=8'h6; value[1]=8'h2; value[2]=8'h6; value[3]=8'h4;
		cacheMiss = 0;
		ramAddress = 5'h0;
		ramInput = 7'h0;
		ramWren = 0;
		pendingReadInidicator = 0;
		pendingWriteIndicator = 0;
		pendingRead = 0;
		pendingWrite = 0;
		pendingReadDestination = 0;
		writeBufferAddr = 0;
		writeBufferData = 0;
		cont = 0;
		lastAddr = 5'd20;
		hit1 = 0;
		disp0 = 4'h0;
		disp1 = 4'h0;
		disp2 = 4'h0;
		disp3 = 4'h0;
		disp4 = 4'h0;
		disp5 = 4'h0;
		disp6 = 4'h0;
		disp7 = 4'h0;
		LEDR = 18'h0;
		LEDG = 9'h0;
	end
	
	always @(posedge clock) begin
		
		if((pendingRead!=8'h0) || (pendingWrite!=8'h0)) begin
			if(pendingRead != 8'h0) begin
				pendingRead = pendingRead - 8'h1;
				if(pendingRead == 8'h0) begin
					pendingReadInidicator = 0;
					value[pendingReadDestination] = ramOutput;
					valid[pendingReadDestination] = 1;
					dirty[pendingReadDestination] = 0;
					tag[pendingReadDestination] = ramAddress;
					q = ramOutput;
				end
			end
			else begin
				pendingWrite = pendingWrite - 8'h1;
				ramAddress = writeBufferAddr;
				ramInput = writeBufferData;
				ramWren = 1;
				if(pendingWrite == 8'h0) begin
					pendingWriteIndicator = 0;
					ramWren = 0;
				end
			end
		end
// --------- Executar pedidos de leitura e escrita apenas se não houver alguma operação pendente ------------		
		else begin
			cacheMiss = ~(cacheHit[0] | cacheHit[1] | cacheHit[2] | cacheHit[3]);	
			if(rw) begin
				if(cacheMiss) begin
					for(cont = 0; cont <4; cont=cont+1) begin
						if(lru[cont] == 2'd3) begin
							if(dirty[cont] == 1) begin
								writeBufferAddr = tag[cont];
								writeBufferData = value[cont];
								pendingWrite = 8'h3;
								pendingWriteIndicator = 1;
							end
						
							value[cont] = in;
							valid[cont] = 1;
							dirty[cont] = 1;
							tag[cont] = addr;
							lru[cont] = 2'd0;
							q = in;
						end
						else begin
							lru[cont] = lru[cont] + 1;
						end
					end
				end
				else begin
					for(cont = 0; cont <4; cont=cont+1) begin
					
						if(cacheHit[0]) hitLru=2'h0;
						if(cacheHit[1]) hitLru=2'h1;
						if(cacheHit[2]) hitLru=2'h2;
						if(cacheHit[3]) hitLru=2'h3;
						
						if(lru[cont] < lru[hitLru]) begin
							lru[cont] = lru[cont] + 1;								//Soma 1 ao LRU
						end
					end
					if(tag[hitLru] == addr) begin
						lru[hitLru] = 0;
						dirty[hitLru] = 1;
						value[hitLru] = in;
						q = in;
					end
				end
			end
// ---------------------------------------------- Aqui começam as leituras ------------------------
			else begin
				if(cacheMiss) begin	//-------------- Cache Miss --------------------------------------
					for(cont = 0; cont <4; cont=cont+1) begin		//Procura pelo mais antigo
						if(lru[cont] == 3)begin								//Se iteração atual = mais antigo
							lru[cont] = 2'h0;									//LRU[mais antigo] = 0 (mais atual)
							ramAddress = addr;								//Endereço da ram recebe pedido
							pendingReadDestination = cont;				//Armazenha posição destino da chache
							pendingRead = 7'd3;								//Agenda a leitura
							pendingReadInidicator = 1;

							if(dirty[cont] == 1) begin							//Se cache está com dity ativo
								pendingWrite = 7'd3;								//Agenda escrita
								writeBufferData = value[cont];				//Armazena valor e endereço
								writeBufferAddr = tag[cont];					//de escrita no write buffer
								pendingWriteIndicator = 1;
							end
						end
						else begin												//Se iteração atual != mais antigo
							lru[cont] = lru[cont] + 1;						//Somar 1 em seu LRU
						end
					end														//Fim da procura
				end
				else begin	//----------------------- Cache Hit ---------------------------------------
					for(cont = 0; cont <4; cont=cont+1) begin				//Procura pelo hit
						
						if(cacheHit[0]) hitLru=2'h0;
						if(cacheHit[1]) hitLru=2'h1;
						if(cacheHit[2]) hitLru=2'h2;
						if(cacheHit[3]) hitLru=2'h3;
						
						if(lru[cont] < lru[hitLru]) begin
							lru[cont] = lru[cont] + 1;								//Soma 1 ao LRU
						end
					end
					q = value[hitLru];										//Manda valor para a saida
					lru[hitLru] = 2'b00;										//Zera o LRU
				end
				lastAddr = addr;											//Salva tag do ultimo hit para não acontecer caso de 
			end																//multiplas posições de memoria com o mesmo LRU
		end
		disp7 = {3'b000, addr[4]};
		disp6 = addr[3:0];
		
		disp5 = q[7:4];
		disp4 = q[3:0];
		
		disp3 = lru[0];
		disp2 = lru[1];
		disp1 = lru[2];
		disp0 = lru[3];
		
		LEDR[10] = dirty[0];
		LEDR[9] = dirty[1];
		LEDR[8] = dirty[2];
		LEDR[7] = dirty[3];
		
		LEDG[7] = valid[0];
		LEDG[6] = valid[1];
		LEDG[5] = valid[2];
		LEDG[4] = valid[3];
		
		LEDR[12] = rw;
		
		LEDR[17] = cacheMiss;
		
		LEDR[2] = pendingReadInidicator;
		LEDR[0] = pendingWriteIndicator;
	end
endmodule