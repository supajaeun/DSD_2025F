/*******************************************************************
  - Project          : FIR_Filter_TeamProject
  - File name        : FSM.v
  - Description      : FSM
  - Owner            : JMT
  - Revision         : 1) 2024.11.14
  		       2) 2024.11.24 Read structure Revision
*******************************************************************/


module FSM (
	// Clk12MHz & Reset
	input			iClk12M,
	input			iRsn,
	
	// Sample enable 600kHz
	input			iEnSample600k,

	// Flag
	input			iCoeffUpdateFlag,

	// SRAM Control
	input		[5:0]	iAddrRam,
	input		[15:0]	iWrDtRam,
	input		[5:0]	iNumOfCoeff,
	input		[2:0]	iFirIn,

	// SRAM Chip select
	output	wire		wCsnRam1,
	output	wire		wCsnRam2,
	output	wire		wCsnRam3,
	output	wire		wCsnRam4,

	// SRAM Write/Read select 
	output	wire		wWrnRam1,
	output	wire		wWrnRam2,
	output	wire		wWrnRam3,
	output	wire		wWrnRam4,

	// SRAM Address
	output	wire	[3:0]	wAddrRam1,
	output	wire	[3:0]	wAddrRam2,
	output	wire	[3:0]	wAddrRam3,
	output	wire	[3:0]	wAddrRam4,

	// SRAM WRITE Data
	output	wire	[15:0]	wWrDtRam1,
	output	wire	[15:0]	wWrDtRam2,
	output	wire	[15:0]	wWrDtRam3,
	output	wire	[15:0]	wWrDtRam4,

	// Multi Enable
	output	wire		wEnMul1,
	output	wire		wEnMul2,
	output	wire		wEnMul3,
	output	wire		wEnMul4,

	// Add Enable
	output	wire		wEnAdd1,
	output	wire		wEnAdd2,
	output	wire		wEnAdd3,
	output	wire		wEnAdd4,

	// Accum Enable
	output	wire		wEnAcc1,
	output	wire		wEnAcc2,
	output	wire		wEnAcc3,
	output	wire		wEnAcc4,

	// Delay Enable
	output	wire		wEnDelay
  );

/*----------------------------------------------------------------------*
 * 			   State Parameter				*
 *----------------------------------------------------------------------*/

  	localparam	IDLE		= 0;
  	localparam	SRAMWR		= 1;
  	localparam	SRAMWREND	= 2;
  	localparam	SRAMRD1		= 3;
  	localparam	SRAMRD2		= 4;
  	localparam	SRAMRD3		= 5;
	localparam	COMPLETEMAC	= 6;
	localparam	EOC		= 7;
	localparam	END		= 8;
	
/*----------------------------------------------------------------------*
 * 				Integer					*
 *----------------------------------------------------------------------*/
	integer		i;

/*----------------------------------------------------------------------*
 * 				Register				*
 *----------------------------------------------------------------------*/

	// State
	reg		[3:0]	state, next_state;

	reg		[5:0]	rNumOfCoeff;
	reg		[5:0]	rCoeff_cnt, rCoeff_cnt_next;
	reg		[2:0]	rSel, rSel_next;

	reg		[3:0]	rAddrRam	[4:1];
	reg		[3:0]	rAddrRam_next;
	// Write Data
	reg		[15:0]	rWrDtRam	[4:1];
	reg		[15:0]	rWrDtRam_next;

/*----------------------------------------------------------------------*
 * 				Assign					*
 *----------------------------------------------------------------------*/

	assign	wCsnRam1	= (rSel == 1) ? 1'b0:1'b1;
	assign	wCsnRam2	= (rSel == 2) ? 1'b0:1'b1;
	assign	wCsnRam3	= (rSel == 3) ? 1'b0:1'b1;
	assign	wCsnRam4	= (rSel == 4) ? 1'b0:1'b1;
	assign	wWrnRam1	= ((state == SRAMWR) && (rSel == 1)) ? 1'b1:1'b0;
	assign	wWrnRam2	= ((state == SRAMWR) && (rSel == 2)) ? 1'b1:1'b0;
	assign	wWrnRam3	= ((state == SRAMWR) && (rSel == 3)) ? 1'b1:1'b0;
	assign	wWrnRam4	= ((state == SRAMWR) && (rSel == 4)) ? 1'b1:1'b0;
	assign	wAddrRam1	= rAddrRam[1][3:0];
	assign	wAddrRam2	= rAddrRam[2][3:0];
	assign	wAddrRam3	= rAddrRam[3][3:0];
	assign	wAddrRam4	= rAddrRam[4][3:0];
	assign	wWrDtRam1	= rWrDtRam[1][15:0];
	assign	wWrDtRam2	= rWrDtRam[2][15:0];
	assign	wWrDtRam3	= rWrDtRam[3][15:0];
	assign	wWrDtRam4	= rWrDtRam[4][15:0];
	assign	wEnMul1	= (state == SRAMRD3 || state == SRAMRD2 || state == COMPLETEMAC || state == EOC) ? (rCoeff_cnt > 0 && rCoeff_cnt <= 10):1'b0;
	assign	wEnMul2	= (state == SRAMRD3 || state == SRAMRD2 || state == COMPLETEMAC || state == EOC) ? (rCoeff_cnt > 10 && rCoeff_cnt <= 20):1'b0;
	assign	wEnMul3	= (state == SRAMRD3 || state == SRAMRD2 || state == COMPLETEMAC || state == EOC) ? (rCoeff_cnt > 20 && rCoeff_cnt <= 30):1'b0;
	assign	wEnMul4	= (state == SRAMRD3 || state == SRAMRD2 || state == COMPLETEMAC || state == EOC) ? (rCoeff_cnt > 30 && rCoeff_cnt <= 40):1'b0;
	assign	wEnAdd1	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC ) ? 1'b1:1'b0;
	assign	wEnAdd2	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC ) ? 1'b1:1'b0;
	assign	wEnAdd3	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC ) ? 1'b1:1'b0;
	assign	wEnAdd4	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC ) ? 1'b1:1'b0;
	assign	wEnAcc1	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC || state == EOC) ? 1'b1:1'b0;
	assign	wEnAcc2	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC || state == EOC) ? 1'b1:1'b0;
	assign	wEnAcc3	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC || state == EOC) ? 1'b1:1'b0;
	assign	wEnAcc4	= (state == SRAMRD2 || state == SRAMRD3 || state == COMPLETEMAC || state == EOC) ? 1'b1:1'b0;
	assign	wEnDelay= (state == EOC || state == SRAMRD1) ? 1'b1:1'b0;

/*----------------------------------------------------------------------*
 * 				FSM					*
 *----------------------------------------------------------------------*/

	always @ (posedge iClk12M or negedge iRsn) begin
		if(!iRsn) begin
			state		<= IDLE;
			next_state	<= IDLE;
			rNumOfCoeff	<= 0;
			rCoeff_cnt	<= 0;
			rCoeff_cnt_next	<= 0;
			rAddrRam_next	<= 0;
			rWrDtRam_next	<= 0;
			rSel_next	<= 0;
			rSel		<= 0;
			for (i=1; i<5; i=i+1) begin
				rAddrRam[i][3:0]	<= 0;
				rWrDtRam[i][15:0]	<= 0;
			end
		end
		else begin
			state		<= next_state;
			rCoeff_cnt 	<= rCoeff_cnt_next;
			rSel		<= rSel_next;
			rAddrRam[rSel_next][3:0]	<= rAddrRam_next;
			rWrDtRam[rSel_next][15:0]	<= rWrDtRam_next;
		end
	end

 
/*----------------------------------------------------------------------*
 * 			FSM Control Output				*
 *----------------------------------------------------------------------*/

	always @ (*) begin
		case(state)
			IDLE	: begin
				if(iCoeffUpdateFlag == 1'b1) begin
					next_state	= SRAMWR;
					rNumOfCoeff	= iNumOfCoeff;
					rCoeff_cnt_next	= 0;
					rAddrRam_next	= iAddrRam;
					rWrDtRam_next	= iWrDtRam;
				end
				else begin
					next_state	= IDLE;
				end
			end
			SRAMWR	: begin
				if(iCoeffUpdateFlag == 1'b0) begin
					next_state	= SRAMWREND;
					rCoeff_cnt_next = 0;
					rAddrRam_next	= 4'h0;
					rWrDtRam_next	= 0;
				end
				else if(rNumOfCoeff == rCoeff_cnt) begin
				end
				else begin
					rCoeff_cnt_next	= rCoeff_cnt + 1;
					rAddrRam_next	= iAddrRam % 10;
					rWrDtRam_next	= iWrDtRam;
				end
			end
			SRAMWREND : begin
				if(iFirIn != 3'b000) begin
					next_state	= SRAMRD1;
				end
				else if(iCoeffUpdateFlag == 1'b1) begin
					next_state	= SRAMWR;
					rNumOfCoeff	= iNumOfCoeff;
					rCoeff_cnt_next	= 0;
					rAddrRam_next	= iAddrRam;
					rWrDtRam_next	= iWrDtRam;
				end
			end
			SRAMRD1	: begin
				next_state	= SRAMRD2;
				rCoeff_cnt_next	= 0;
				rAddrRam_next	= 4'h0;
			end
			SRAMRD2	: begin
				if(rCoeff_cnt == rNumOfCoeff) begin
					next_state = SRAMRD3;
					rCoeff_cnt_next = rCoeff_cnt + 1;
					rAddrRam_next	= rCoeff_cnt_next %10;
				end
				else begin
					rCoeff_cnt_next = rCoeff_cnt + 1;
					rAddrRam_next	= rCoeff_cnt_next %10;
				end
			end
			SRAMRD3 : begin
				next_state = COMPLETEMAC;
				rCoeff_cnt_next = 0;
			end
			COMPLETEMAC : begin
				if (iEnSample600k == 1'b1) begin
					next_state = EOC;
				end
			end
			EOC : begin
				next_state = END;

			end
			END : begin
				if(iCoeffUpdateFlag == 1'b1) begin
					next_state	= SRAMWR;
					rNumOfCoeff	= iNumOfCoeff;
					rCoeff_cnt_next	= 0;
					rAddrRam_next	= iAddrRam;
					rWrDtRam_next	= iWrDtRam;
				end
				else if (iFirIn != 3'b000) begin
					next_state = SRAMRD1;
				end
			end

		endcase
		if (state == IDLE || state == END || state == SRAMWREND) begin
			if(iCoeffUpdateFlag == 1'b1) begin
				rSel_next = iAddrRam/10 +1;
			end
			else begin
				rSel_next = 0;
			end
		end
		else if (state == SRAMWR) begin
			rSel_next = iAddrRam/10 +1;
		end
		else if (state == SRAMRD1) begin
			rSel_next = 1;
		end
		else begin
			rSel_next = (rCoeff_cnt_next)/10+1;
		end
	end
			
 
endmodule
