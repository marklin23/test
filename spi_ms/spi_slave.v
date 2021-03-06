//================================================
//SPI SLVAE TX RX MODULE
//Auther: Mark
//Data: 2017/03/07
//parameterize DATA_WIDTH
//spi clk speed clk  (system_clock/sclk)<=4;
//tx sent ivREADDATA MSB first
//rx store data shift from LSB to MSB
//================================================
module	spi_slave#(
	parameter	DATA_WIDTH	=	46
)(

//cpld clock & reset
	input  iClk,
	input  iRstn,

// spi signal

	input  iSCLK,	 // SPI clock
	input  iSSn ,	// Slave select lines
	input  iMOSI,	 // Master out slave in
	output oMISO,	 // Master in slave out 	
	
// Local Bus Signal
	output reg[DATA_WIDTH-1:0] ovWRITEDATA,
	input     [DATA_WIDTH-1:0] ivREADDATA        
);

reg [1:0]            rvsclk_temp;
reg [1:0]            rvmosi_temp;
reg [1:0]            rvssn_temp;
reg [2:0]            rvstate;
reg [31:0]           rvcnt;
reg                  rload;
reg                  rvalid;
reg                  rMISO;
reg [DATA_WIDTH-1:0] rvrx_temp;
reg [DATA_WIDTH-1:0] rvtx_temp;

parameter IDLE_ST		='d0;
parameter TXRX_ST		='d1;
parameter WAIT_ST		='d2;
parameter COMMAND_ST	='d0;
parameter ADDRESS_ST	='d0;
parameter DATA_ST		='d0;
parameter STOP_ST		='d0;



always@(posedge iClk or negedge iRstn)
	begin
		rvsclk_temp	<=	!iRstn	?	'd0	:	{rvsclk_temp[0],iSCLK};
		rvmosi_temp	<=	!iRstn	?	'd0	:	{rvmosi_temp[0],iMOSI};
		rvssn_temp	<=	!iRstn	?	'd0	:	{rvssn_temp[0],iSSn};
	end

always@(posedge iClk or negedge iRstn)
	begin
		if(!iRstn)
			begin
				rvstate			<=	IDLE_ST;
				rvrx_temp		<=	'd0;
				rload			<=	1'b0;
				rvalid			<=	1'b0;
				rMISO			<=	1'd0;
				rvcnt			<=	'd0;
			end
/* 		 else if(rvssn_temp=='b11|rvssn_temp=='b01)
			begin
				rvstate			<=	IDLE_ST;
				rvrx_temp	<=	'd0;
			end  */
		else 
			begin
				case(rvstate)
					IDLE_ST:begin
								rvstate			<=	 (rvssn_temp=='b10) /*!iSSn*/	?	TXRX_ST	:	IDLE_ST	;
								rvrx_temp		<=	rvrx_temp;
								rload			<=	1'b1;
								rvalid			<=	1'b0;
								rMISO			<=	1'd0;
								rvcnt			<=	'd0;
							end
					TXRX_ST:begin
								rvstate			<=	(rvssn_temp=='b01) /*iSSn*/	?	WAIT_ST					:	TXRX_ST;
								rvrx_temp		<=	(rvsclk_temp=='b01)	?	{rvrx_temp[DATA_WIDTH-2:0],	iMOSI} 	:	rvrx_temp ;
								rload			<=	1'b0;
								rvalid			<=	1'b0;
								rMISO			<=	(rvsclk_temp=='b01)	?	rvtx_temp[DATA_WIDTH-1-rvcnt]		 :	rMISO ;
								rvcnt			<=	(rvsclk_temp=='b01)	?	rvcnt	+	1'b1					 :	rvcnt ;
							end
					WAIT_ST:begin
								rvstate			<=	IDLE_ST;
								rvrx_temp		<=	rvrx_temp;
								rload			<=	1'b0;
								rvalid			<=	1'b1;
								rMISO			<=	1'd0;
								rvcnt			<=	'd0;
							end					
					
				endcase
			end
	end
always@( negedge iRstn  or posedge iClk )
	begin
		ovWRITEDATA	<=	!iRstn	?	'd0	:	(rvalid	?	rvrx_temp	:	ovWRITEDATA	);
		rvtx_temp	<=	!iRstn	?	'd0	:	(rload	?	ivREADDATA	:	rvtx_temp	);
	end
assign	oMISO	=	rMISO;

endmodule
