// Part 2 skeleton

module FA
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,  						//	VGA Blue[9:0]
		LEDR, 
		HEX0,
		HEX1
		
	);
	
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [9:0] LEDR;
	output [6:0] HEX0;
	output [6:0] HEX1;
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
		 //Signals for the DAC to drive the monitor. 
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	
	// clear or go 
	wire [2:0] colour_clear;
	wire [7:0] x_clear;
	wire [6:0] y_clear;
	wire [2:0] colour_go;
	wire [7:0] x_go;
	wire [6:0] y_go;
	wire clr_go;
	wire clr_load_en;
	wire clr_end_signal;
	//====================
	wire [7:0] scores;
	wire fm;
	wire old_cur;
	wire load_en;
	wire [6:0] y_out;
	wire printEnd;
	wire moveEn_ac;
	wire moveEn_pp;
	wire jumpEn;
	wire jump_c2;
	wire is_crash;
    // Instansiate datapath
	datapath d0(.x_in(8'd78), .y_in(y_out), .load_en(load_en), .pp_move_en(moveEn_pp),
	.x_out(x_go), .y_out(y_go), .clk(CLOCK_50), .reset_n(KEY[0]), .color_output(colour_go), .old_cur(old_cur), 
	.all_end_signal(printEnd), .is_crash(is_crash), .scores(scores));

    // Instansiate FSM control
	control c0(.key1(KEY[1]), .frame(fm), .clk(CLOCK_50), .reset_n(KEY[0]), .print_end(printEnd), .is_crash(is_crash), .clear_end_signal(clr_end_signal),
	.write_en(writeEn), .old_cur(old_cur), .load_en(load_en), .move_en_ac(moveEn_ac), .move_en_pp(moveEn_pp),
	.clr_load_en(clr_load_en), .clr_go(clr_go));
	
	control_2 c1(.click(KEY[1]), .jump_en(jump_c2), .clk(CLOCK_50), .reset_n(KEY[0]));
	
	// Gravity(Position of the aircraft)
	gravity g(.move_signal(moveEn_ac), .jump_enable(jumpEn), .old_cur(old_cur), .y_out(y_out), .clk(CLOCK_50), .reset_n(KEY[0]));
	
	// FrameCounter
	FrameCounter fc(.frame(CLOCK_50), .reset_n(KEY[0]), .fm(fm));
	
	// Clear screen 
	clear_go cg(.clr_go(clr_go), .x_clear_in(x_clear), .y_clear_in(y_clear), .clear_color(colour_clear),
				.x_go_in(x_go), .y_go_in(y_go), .go_color(colour_go),
				.x_out(x), .y_out(y), .color_out(colour));
				
	datapath_clear dc(.color_input(3'b000), .load_en(clr_load_en), .x_out(x_clear), .y_out(y_clear), .clk(CLOCK_50), .reset_n(resetn), 
				.color_output(colour_clear), .end_signal(clr_end_signal));
	
	// Decoder
	decoder dec0(.in(scores[3:0]), .hex(HEX0));
	decoder dec1(.in(scores[7:4]), .hex(HEX1));
	
	assign jumpEn = jump_c2 & !is_crash;
	assign LEDR[0] = is_crash;
	
	
	
endmodule

//=================================Control===================================

module control(key1, frame, clk, reset_n, print_end, is_crash, clear_end_signal, write_en, 
			old_cur, load_en, move_en_ac, move_en_pp, clr_load_en, clr_go);
	input key1;
	input frame;
	input clk;
	input reset_n;
	input print_end;
	input is_crash;
	input clear_end_signal;
	output reg write_en;
	output reg old_cur;
	output reg load_en;
	output reg move_en_ac;
	output reg move_en_pp;
	output reg clr_load_en;
	output reg clr_go;
	
   localparam  KEEP = 4'd0,
               CLEAN_LOAD = 4'd1,
					CLEAN = 4'd2,
					PRINT_LOAD = 4'd3,
					PRINT = 4'd4,
					MOVE = 4'd5,
					CRASH_CHECK = 4'd6,
					CRASH = 4'd7,
					CLEAR = 4'd8,
					CLEAR_LOAD = 4'd9,
					FIRST_FRAME_LOAD = 4'd10,
					FIRST_FRAME = 4'd11,
					START_WAIT = 4'd12;
   
	reg [3:0] next_state;
	reg [3:0] current_state;
	
   // Next state logic aka our state table
   always@(*)
   begin: state_table 
           case (current_state)
					CLEAR_LOAD: 			next_state = CLEAR; 
					CLEAR:					next_state = clear_end_signal ? FIRST_FRAME_LOAD : CLEAR;
					FIRST_FRAME_LOAD: 	next_state = FIRST_FRAME;
					FIRST_FRAME: 			next_state = print_end ? START_WAIT : FIRST_FRAME;
					START_WAIT: 			next_state = key1 ? START_WAIT : KEEP;
					KEEP: 					next_state = frame ? CLEAN_LOAD : KEEP;
					CLEAN_LOAD: 			next_state = CLEAN;
					CLEAN: 					next_state = print_end ? PRINT_LOAD: CLEAN;
					PRINT_LOAD: 			next_state = PRINT;
               PRINT: 					next_state = print_end ? CRASH_CHECK : PRINT;
					CRASH_CHECK: 			next_state = is_crash ? CRASH : MOVE;
					MOVE: 					next_state = KEEP;
					CRASH: 					next_state = KEEP;
					default:     next_state = KEEP;
       endcase
   end // state_table
   
	// current_state registers
   always@(posedge clk)
   begin: state_FFs
		if(!reset_n)
			begin
				current_state <= CLEAR_LOAD;
			end
      else
           current_state <= next_state;
   end // state_FFS
	
	always @(*)
	begin: enable_signals
		move_en_ac = 1'b0;
		move_en_pp = 1'b0;
		clr_load_en = 1'b0;
		clr_go = 1'b1;
		write_en = 1'b0;
		load_en = 1'b0;
		old_cur = 1'b0;
		case (current_state)
			KEEP:	write_en = 1'b0;
			CLEAN_LOAD: begin
				load_en = 1'b1;
				old_cur = 1'b0;
			end
			CLEAN: begin
				load_en = 1'b0;
				write_en = 1'b1;
			end
			PRINT_LOAD: begin
				load_en = 1'b1;
				old_cur = 1'b1;
				if (is_crash)
					move_en_pp = 1'b0;
				else
					move_en_pp = 1'b1;
			end
			PRINT: begin
				load_en = 1'b0;
				write_en = 1'b1;
			end
			MOVE: begin
				move_en_ac = 1'b1;
			end
			CRASH: begin
				move_en_ac = 1'b1;
			end
			CLEAR_LOAD: begin
				clr_load_en = 1'b1;
				clr_go = 1'b0;
			end
			CLEAR: begin
				clr_load_en = 1'b0;
				clr_go = 1'b0;
				write_en = 1'b1;
			end
			FIRST_FRAME_LOAD: begin
				load_en = 1'b1;
				old_cur = 1'b1;
				move_en_pp = 1'b0;
			end
			FIRST_FRAME: begin
				load_en = 1'b0;
				write_en = 1'b1;
			end
		endcase
	end
	
endmodule


//=================================Datapath===================================

module datapath(x_in, y_in, load_en, pp_move_en, x_out, y_out, clk, reset_n, color_output, old_cur, 
		all_end_signal, is_crash, scores);
	input [7:0] x_in;
	input [6:0] y_in;
	input load_en;
	input pp_move_en;
	input clk;
	input reset_n;
	input old_cur;
	output reg [7:0] scores;
	output reg [7:0] x_out;
	output reg [6:0] y_out;
	output reg [2:0] color_output;
	output reg all_end_signal;
	output is_crash;
	reg [2:0] ac_pp;
	
	reg [7:0] x;
	reg [6:0] y;
	reg [3:0] count;
	
	reg [7:0] x_pp_1;
	reg [6:0] y_pp_1;
	reg [7:0] x_pp_2;
	reg [6:0] y_pp_2;
	reg [7:0] x_pp_3;
	reg [6:0] y_pp_3;
	
	reg [4:0] count_width;
	reg [7:0] count_height;
	reg upper_half_end;

	reg [2:0] color_ac;
	reg [2:0] color_pp;
	reg [2:0] color_coin;
	
	wire [2:0] speed;
	assign speed = 3'd1;
	wire [7:0] height;
	wire [4:0] width;
	assign height = 8'd40; // height of the gap between pipe pairs, adjustable.
	assign width = 5'd6; // width of the pipe, adjustable.
	reg [4:0] new_pipe_y;
	// ===================================check_en FSM===================================
	
	wire is_crash_1;
	wire is_crash_2;
	wire is_crash_3;
	wire is_crash_4;
	wire is_ac;
	assign is_ac = (ac_pp > 0) ? 1'b0 : 1'b1; // if is_ac == 1, ac is being printed.
	
	crash ck0(.check_en(1'b1), .craft_x(x_in), .craft_y(y_in), .pipe_x(x_pp_1), .pipe_y(y_pp_1), .clk(clk),
			.reset_n(reset_n), .height(height), .width(width), .is_crash(is_crash_1));
			
	crash ck1(.check_en(1'b1), .craft_x(x_in), .craft_y(y_in), .pipe_x(x_pp_2), .pipe_y(y_pp_2), .clk(clk),
			.reset_n(reset_n), .height(height), .width(width), .is_crash(is_crash_2));
			
	crash ck2(.check_en(1'b1), .craft_x(x_in), .craft_y(y_in), .pipe_x(x_pp_3), .pipe_y(y_pp_3), .clk(clk),
			.reset_n(reset_n), .height(height), .width(width), .is_crash(is_crash_3));
			
	crash_ground ck3(.check_en(1'b1), .craft_y(y_in), .reset_n(reset_n), .clk(clk), .is_crash(is_crash_4));
	
	assign is_crash = is_crash_1 | is_crash_2 | is_crash_3 | is_crash_4;

	// ===================================check_en FSM (the end) ===================================
	always @(posedge clk)
	begin
		// Reset, low active
		if (reset_n == 1'b0)
		begin
			x <= 8'd78;
			y <= 7'd58;
			x_out <= 8'd0;
			y_out <= 7'd0;
			x_pp_1 <= 8'd135;
			y_pp_1 <= 7'd40;
			x_pp_2 <= 8'd20;
			y_pp_2 <= 7'd60;
			x_pp_3 <= 8'd60;
			y_pp_3 <= 7'd30;
			scores <= 8'd0;
			count_width <= 5'd0;
			count_height <= 8'd0;
			upper_half_end <= 1'd0;
			color_ac <= 3'd0;
			color_pp <= 3'd0;
			count <= 4'd0;
			all_end_signal <= 1'd0;
			color_output <= 3'd0;
			
		end
		// Loading value for x and y, and set count to 0.
		else if (load_en == 1'b1)
		begin
				x <= x_in;
				x_out <= x_in;
				y <= y_in;
				x_out <= y_in;
				count <= 4'b0000;
				all_end_signal <= 1'b0;
				ac_pp = 1'b0;
				//========pipe 1 loaction=========
				if (old_cur == 1'b1)
					if (x_pp_1 - speed >= 8'd160)
					begin
						x_pp_1 <= 8'd154;
						y_pp_1 <= 7'd30 + new_pipe_y;
					end
					else
					begin
						if (!is_crash) 
						begin
							if (x_pp_1 + width >= 8'd78 && x_pp_1 + width - speed < 8'd78)
								scores <= scores + 1;
							x_pp_1 <= x_pp_1 - speed;
						end
						else
							x_pp_1 <= x_pp_1;
					end
				else
					x_pp_1 <= x_pp_1;
				//========pipe 2 loaction=========
				if (old_cur == 1'b1)
					if (x_pp_2 - speed >= 8'd160)
					begin
						x_pp_2 <= 8'd160;
						y_pp_2 <= 7'd20 + new_pipe_y;
					end
					else
					begin
						if (!is_crash)
						begin
							if (x_pp_2 + width >= 8'd78 && x_pp_2 + width - speed < 8'd78)
								scores <= scores + 1;
							x_pp_2 <= x_pp_2 - speed;
						end
						else
							x_pp_2 <= x_pp_2;
					end
				else
					x_pp_2 <= x_pp_2;

				//========pipe 3 loaction=========
				if (old_cur == 1'b1)
					if (x_pp_3 - speed >= 8'd160)
					begin
						x_pp_3 <= 8'd160;
						y_pp_3 <= 7'd40 + new_pipe_y;
					end
					else
					begin
						if (!is_crash)
						begin
							if (x_pp_3 + width >= 8'd78 && x_pp_3 + width - speed < 8'd78)
								scores <= scores + 1;
							x_pp_3 <= x_pp_3 - speed;
						end
						else
							x_pp_3 <= x_pp_3;
					end
				else
					x_pp_3 <= x_pp_3;
				
				x_out <= 8'd0;
				y_out <= 7'd0;
				count_width <= 5'd0;
				count_height <= 8'd0;
				all_end_signal <= 1'b0;
				upper_half_end <= 1'b0;
				//==================
				if (old_cur == 1'b0)
				begin
					color_ac <= 3'b000;
					color_pp <= 3'b000;
					color_coin <= 3'b000;
				end
				else
				begin
					color_ac <= 3'b100;
					color_pp <= 3'b010;
					color_coin <= 3'b110;
				end
		end
		// Count all 16 pixels
		else if (ac_pp == 3'b0)
		begin
			color_output <= color_ac;
			// counting.
			if (count != 4'b1111)
			begin
				x_out <= x + count[3:2];
				y_out <= y + count[1:0];
				count <= count + 1'b1;
			end
			// Stay on the lower right pixel.
			else
			begin
				x_out <= x + count[3:2];
				y_out <= y + count[1:0];
				ac_pp = 3'd1;
			end
		end
		// ----------------------------pipe 1------------------------------
		else if (ac_pp == 3'b1)
		begin
			color_output <= color_pp;
			if (!upper_half_end)
			// Printing upper half of the pair of the pipes.
			begin
				if (count_width != (width - 1) || y_out != 0) // Last px of the upper half.
				begin
					if (count_width < width)
					begin // Printing one row.
						color_output <= color_pp;
							
						x_out <= x_pp_1 + count_width;
						count_width <= count_width + 1'b1;
						y_out <= y_pp_1 - count_height;
					end
					else
					begin // One row of the pxs have been printed.
						count_width <= 0;
						count_height <= count_height + 1;
						x_out <= x_pp_1;
						y_out <= y_pp_1 - count_height;
					end
				end
				else
				begin // Finished printing upper half.
					x_out <= x_pp_1 + count_width;
					count_width <= 0;
					count_height <= height;
					upper_half_end <= 1'b1;
				end
			end
			// Stay on the lower right pixel.
			else
			// Printing lower half of the pair of the pipes.
			begin
				if (count_width != (width - 1) || y_out != 119) // Last px of the upper half.
				begin
					if (count_width < width)
					begin // Printing one row.
						x_out <= x_pp_1 + count_width;
						count_width <= count_width + 1'b1;
						y_out <= y_pp_1 + count_height;
					end
					else
					begin // One row of the pxs have been printed.
						count_width <= 0;
						count_height <= count_height + 1;
						x_out <= x_pp_1;
						y_out <= y_pp_1 + count_height;
					end
				end
				else
				begin // Finished printing lower half.
					x_out <= x_pp_1 + count_width;
					upper_half_end <= 1'b0;
					count_width <= 5'd0;
					count_height <= 8'd0;
					count <= 4'b0000;
					if (x_pp_1 >= 8'd82)
						ac_pp <= 3'd4;
					else
						ac_pp <= 3'd2;
				end
			end
		end
		else if (ac_pp == 3'd4)
		begin //---------------------- coin 1 ----------------------------
			color_output <= color_coin;
			// counting.
			if (count != 4'b1111)
			begin
				x_out <= x_pp_1 + count[3:2];
				y_out <= y_pp_1 + 7'd19 + count[1:0];
				count <= count + 1'b1;
			end
			// Stay on the lower right pixel.
			else
			begin
				x_out <= x_pp_1 + count[3:2];
				y_out <= y_pp_1 + 7'd19 + count[1:0];
				ac_pp <= 3'd2;
			end
		end
		// ----------------------------pipe 2-------------------------------
		else if (ac_pp == 3'd2)
		begin
			color_output <= color_pp;
			if (!upper_half_end)
			// Printing upper half of the pair of the pipes.
			begin
				if (count_width != (width - 1) || y_out != 0) // Last px of the upper half.
				begin
					if (count_width < width)
					begin // Printing one row.
						color_output <= color_pp;

						x_out <= x_pp_2 + count_width;
						count_width <= count_width + 1'b1;
						y_out <= y_pp_2 - count_height;
					end
					else
					begin // One row of the pxs have been printed.
						count_width <= 0;
						count_height <= count_height + 1;
						x_out <= x_pp_2;
						y_out <= y_pp_2 - count_height;
					end
				end
				else
				begin // Finished printing upper half.
					x_out <= x_pp_2 + count_width;
					count_width <= 0;
					count_height <= height;
					upper_half_end <= 1'b1;
				end
			end
			// Stay on the lower right pixel.
			else
			// Printing lower half of the pair of the pipes.
			begin
				if (count_width != (width - 1) || y_out != 119) // Last px of the upper half.
				begin
					if (count_width < width)
					begin // Printing one row.
						x_out <= x_pp_2 + count_width;
						count_width <= count_width + 1'b1;
						y_out <= y_pp_2 + count_height;
					end
					else
					begin // One row of the pxs have been printed.
						count_width <= 0;
						count_height <= count_height + 1;
						x_out <= x_pp_2;
						y_out <= y_pp_2 + count_height;
					end
				end
				else
				begin // Finished printing lower half.
					x_out <= x_pp_2 + count_width;	
					upper_half_end <= 1'b0;
					count_width <= 5'd0;
					count_height <= 8'd0;
					count <= 4'b0000;
					if (x_pp_2 >= 8'd82)
						ac_pp <= 3'd5;
					else
						ac_pp <= 3'd3;
				end
			end
		end
		else if (ac_pp == 3'd5)
		begin //----------------------coin 2----------------------------
			color_output <= color_coin;
			// counting.
			if (count != 4'b1111)
			begin
				x_out <= x_pp_2 + count[3:2];
				y_out <= y_pp_2 + 7'd19 + count[1:0];
				count <= count + 1'b1;
			end
			// Stay on the lower right pixel.
			else
			begin
				x_out <= x_pp_2 + count[3:2];
				y_out <= y_pp_2 + 7'd19 + count[1:0];
				ac_pp <= 3'd3;
			end
		end
		// ----------------------------pipe 3-------------------------------
		else if (ac_pp == 3'd3)
		begin
			color_output <= color_pp;
			if (!upper_half_end)
			// Printing upper half of the pair of the pipes.
			begin
				if (count_width != (width - 1) || y_out != 0) // Last px of the upper half.
				begin
					if (count_width < width)
					begin // Printing one row.
						color_output <= color_pp;

						x_out <= x_pp_3 + count_width;
						count_width <= count_width + 1'b1;
						y_out <= y_pp_3 - count_height;
					end
					else
					begin // One row of the pxs have been printed.
						count_width <= 0;
						count_height <= count_height + 1;
						x_out <= x_pp_3;
						y_out <= y_pp_3 - count_height;
					end
				end
				else
				begin // Finished printing upper half.
					x_out <= x_pp_3 + count_width;
					count_width <= 0;
					count_height <= height;
					upper_half_end <= 1'b1;
				end
			end
			// Stay on the lower right pixel.
			else
			// Printing lower half of the pair of the pipes.
			begin
				if (count_width != (width - 1) || y_out != 119) // Last px of the upper half.
				begin
					if (count_width < width)
					begin // Printing one row.
						x_out <= x_pp_3 + count_width;
						count_width <= count_width + 1'b1;
						y_out <= y_pp_3 + count_height;
					end
					else
					begin // One row of the pxs have been printed.
						count_width <= 0;
						count_height <= count_height + 1;
						x_out <= x_pp_3;
						y_out <= y_pp_3 + count_height;
					end
				end
				else
				begin // Finished printing lower half.
					x_out <= x_pp_3 + count_width;	
					upper_half_end <= 1'b0;
					count_width <= 5'd0;
					count_height <= 8'd0;
					count <= 4'b0000;
					if (x_pp_3 >= 8'd82)
						ac_pp <= 3'd6;
					else
						all_end_signal = 1'b1;
				end
			end
		end // The end of printing pipe3.
		else if (ac_pp == 3'd6)
		begin //----------------------coin 3----------------------------
			color_output <= color_coin;
			// counting.
			if (count != 4'b1111)
			begin
				x_out <= x_pp_3 + count[3:2];
				y_out <= y_pp_3 + 7'd19 + count[1:0];
				count <= count + 1'b1;
			end
			// Stay on the lower right pixel.
			else
			begin
				x_out <= x_pp_3 + count[3:2];
				y_out <= y_pp_3 + 7'd19 + count[1:0];
				all_end_signal = 1'b1;
			end
		end
	end
	
	
	// random------------------------------------------------------
	
	always @(posedge clk)
	begin
		if (!reset_n)
			new_pipe_y <= 7'd0;
		else
			new_pipe_y <= new_pipe_y + 4'd5;
	end


endmodule

//================================datapath_clear=================================
module clear_go(clr_go, x_clear_in, y_clear_in, clear_color, x_go_in, y_go_in, go_color, x_out, y_out, color_out);
	input clr_go;
	input [7:0] x_clear_in;
	input [6:0] y_clear_in;
	input [2:0] clear_color;
	input [7:0] x_go_in;
	input [6:0] y_go_in;
	input [2:0] go_color;
	output reg [7:0] x_out;
	output reg [6:0] y_out;
	output reg [2:0] color_out;
	
	always @(*)
	begin
		case (clr_go)
			1'b0:
			begin
				x_out = x_clear_in;
				y_out = y_clear_in;
				color_out = clear_color;
			end
			1'b1:
			begin
				x_out = x_go_in;
				y_out = y_go_in;
				color_out = go_color;
			end
		endcase
	end
	
endmodule

module datapath_clear(color_input, load_en, x_out, y_out, clk, reset_n, color_output, end_signal);

	input load_en;
	input clk;
	input reset_n;
	input [2:0] color_input;
	
	output reg [7:0] x_out;
	output reg [6:0] y_out;
	output reg [2:0] color_output;
	output reg end_signal;
	
	reg [7:0] x;
	reg [6:0] y;
	reg [7:0] count_x;
	reg [6:0] count_y;
	
	always @(posedge clk)
	begin
		// Reset, low active
		if (reset_n == 1'b0)
		begin
			x <= 8'd0;
			y <= 7'd0;
		end
		// Loading value for x and y, and set count to 0.
		else if (load_en == 1'b1)
		begin
			x_out <= x;
			y_out <= y;
			count_x <= 8'd0;
			count_y <= 7'd0;
			end_signal <= 1'b0;
		end
		// Count all 160 X 120 pixels
		else	
		begin
			if (count_y != 7'd120)
			begin
				if (count_x != 8'd160)
				begin
					x_out <= x + count_x;
					y_out <= y + count_y;
					count_x <= count_x + 1'd1;
					color_output <= color_input;
					
				end
				//end up printing current line, move to next line
				else if (count_x == 8'd160)
				begin
					count_x <= 8'd0;
					x_out <= x + count_x;
					y_out <= y + count_y;
					count_y <= count_y + 1'd1;
					color_output <= color_input;
				end
			end
			//reaching the button line.
			else
			begin
				x_out <= x + count_x;
				y_out <= y + count_y;
				color_output <= color_output;
				end_signal <= 1'b1;
			end
		end
	end

endmodule

//=================================Control_2===================================

module control_2(click, jump_en, clk, reset_n);
	input click;
	input clk;
	input reset_n;
	output reg jump_en;
	
	reg [4:0] current_state;
	reg [4:0] next_state;
	
	localparam JUMP = 2'd0,  JUMP_WAIT = 2'd1;
					
	always @(*)
	begin
		case (current_state)
			JUMP:			next_state = JUMP_WAIT;
			JUMP_WAIT:  next_state = click ? JUMP_WAIT : JUMP;
			default: 	next_state = JUMP_WAIT;
		endcase
	end
	
	always @(posedge clk)
   begin: state_FFs
		if(!reset_n)
			begin
				current_state <= JUMP_WAIT;
			end
      else
           current_state <= next_state;
   end

	always @(*)
	begin
		case (current_state)
			JUMP: jump_en = 1'b1;
			JUMP_WAIT: jump_en = 1'b0;
			default: jump_en = 1'b0;
		endcase
	end

endmodule



// ========================== gravity =======================================

module gravity(move_signal, jump_enable, old_cur, y_out, clk, reset_n);

	input move_signal;
	input jump_enable;
	input clk;
	input reset_n;
	input old_cur;
	output wire [6:0] y_out;
	
	reg signed [7:0] y_cur;
	reg signed [7:0] y_old;

	reg signed [6:0] velocity;
	wire [3:0] gravity;
	wire [6:0] init_v;
	
	assign y_out = old_cur ? y_cur : y_old;
	assign gravity = 4'd1;
	assign init_v = 7'd2;
	
	always @(posedge clk)
	begin
		if (!reset_n)
		begin
			y_cur <= 8'd58;
			y_old <= 8'd58;
			velocity <= init_v;
		end
		if (jump_enable)
		begin
			// Jump up.
			velocity <= init_v;
			if (move_signal)
			begin
				y_old <= y_cur;
				y_cur <= y_cur - init_v;
			end
		end	
		else if (move_signal)
			// Free fall.
			begin
				if (y_cur - velocity >= 0 && y_cur - velocity <= 116)
				begin
					y_old <= y_cur;
					y_cur <= y_cur - velocity;
					velocity <= velocity - gravity;
				end
				else if (y_cur - velocity < 0)
				begin
					if (y_cur == 8'd0)
						y_old <= 8'd0;
					else
						y_old <= y_cur;
					y_cur <= 8'd0;
					velocity <= velocity - gravity;
				end
				else if (y_cur - velocity > 116)
				begin
					if (y_cur == 8'd116)
						y_old <= 8'd116;
					else
						y_old <= y_cur;
					y_cur <= 116;
				end
			end
	end

endmodule

// ====================================Crash======================================================
module crash(check_en, craft_x, craft_y, pipe_x, pipe_y, reset_n, clk, height, width, is_crash);
	input check_en;
	input [7:0] craft_x;
	input [6:0] craft_y;
	
	input [7:0] pipe_x;
	input [6:0] pipe_y;
	input reset_n;
	input [7:0] height;
	input [4:0] width;
	input clk;
	output reg is_crash;
	
	always@(posedge clk)
	if (!reset_n)
		is_crash <= 1'b0;
	else
	begin
		if (check_en)
		begin
			if (is_crash == 0)
			begin
				if (pipe_x - 4 <= craft_x && craft_x <= pipe_x + width && craft_y <= pipe_y + 1)
					is_crash <= 1'b1;
				else if (pipe_x - 4 <= craft_x && craft_x <= pipe_x + width && craft_y >= pipe_y + height - 4)
					is_crash <= 1'b1;
				else
					is_crash <= 1'b0;
			end
			else
				is_crash <= 1'b1;
		end
	end
	
endmodule

// ====================================Crash======================================================
module crash_ground(check_en, craft_y, reset_n, clk, is_crash);
	input check_en;
	input [6:0] craft_y;

	input reset_n;
	input clk;
	output reg is_crash;
	
	always@(posedge clk)
	if (!reset_n)
		is_crash <= 1'b0;
	else
	begin
		if (check_en)
		begin
			if (is_crash == 0)
			begin
				if (craft_y >= 7'd116)
					is_crash <= 1'b1;
				else
					is_crash <= 1'b0;
			end
			else
				is_crash <= 1'b1;
		end
	end
	
endmodule
//=================================FrameCounter===================================

module FrameCounter(frame, reset_n, fm);
	input frame;
	input reset_n;
	output fm;
	
	reg [40:0] q;
	always @(posedge frame, negedge reset_n)
	begin
		if (reset_n == 1'b0)
			q <= 0;
		else
		begin
			if (q == 0)
					q <= 833333 * 3;//833333
			else
				q <= q - 1'b1;
		end
	end

	assign fm = (q == 0) ? 1 : 0;

endmodule


//==============================HEX==================================
module decoder(in, hex);
	input [3:0] in;
   	output [6:0] hex;
	
	assign hex[0] = ~((in[3] | in[2] | in[1] | ~in[0]) & (in[3] | ~in[2] | in[1] | in[0])
		& (~in[3] | ~in[2] | in[1] | ~in[0]) & (~in[3] | in[2] | ~in[1] | ~in[0]));

	assign hex[1] = ~((in[3] | ~in[2] | in[1] | ~in[0]) & (~in[3] | ~in[2] | in[1] | in[0]) 
		& (~in[3] | ~in[1] | ~in[0]) & (~in[2] | ~in[1] | in[0]));

	assign hex[2] = ~((~in[3] | ~in[2] | in[1] | in[0]) & (in[3] | in[2] | ~in[1] | in[0]) 
		& (~in[3] | ~in[2] | ~in[1]));

	assign hex[3] = ~((in[3] | ~in[2] | in[1] | in[0]) & (in[3] | in[2] | in[1] | ~in[0]) 
		& (~in[2] | ~in[1] | ~in[0]) & (~in[3] | in[2] | ~in[1] | in[0]));

	assign hex[4] = ~((in[3] | ~in[2] | in[1]) & (in[2] | in[1] | ~in[0]) & (in[3] | ~in[0]));

	assign hex[5] = ~((~in[3] | ~in[2] | in[1] | ~in[0]) & (in[3] | in[2] | ~in[0]) 
		& (in[3] | in[2] | ~in[1]) & (in[3] | ~in[1] | ~in[0]));

	assign hex[6] = ~((in[3] | in[2] | in[1]) & (in[3] | ~in[2] | ~in[1] | ~in[0]) 
		& (~in[3] | ~in[2] | in[1] | in[0]));

endmodule


