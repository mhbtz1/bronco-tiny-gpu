package constants_pkg;
    parameter int DATA_WIDTH = 8;
    parameter int ACC_WIDTH = 32;
    parameter int ADDR_WIDTH = 8;
    parameter int MAT_DIM = 4;
    parameter int W_DEPTH = 16;
    parameter int X_DEPTH = 4;
    parameter int REG_W_BASE_ID = 0;
    parameter int REG_X_BASE_ID = 1;

    parameter int FETCH_ENGINE_OPCODE_LENGTH = 2;
    // Fetch Engine Constants
    parameter int SET_W_BASE = 2'b00;
    parameter int SET_X_BASE = 2'b01;
    parameter int RUN = 2'b10;
    parameter int RES = 2'b11;

    // Matrix Core Constants
    parameter int LOAD_W   = 2'b00;
    parameter int LOAD_X   = 2'b01;
    parameter int COMPUTE  = 2'b10;
    parameter int FLUSH    = 2'b11;
endpackage

module skid_buffer(
	//inputs 
	clk,
	rst_n,
	src_rdy,
	m_rsp_vld,
	m_rsp_data,
	//outputs
	src_vld,
	src_data
);

	input wire clk, rst_n;
	input wire src_rdy;
	input wire m_rsp_vld;
	input wire [DATA_WIDTH-1:0] m_rsp_data;
	
	output reg src_vld;
	output reg [DATA_WIDTH-1:0] src_data;

	reg [DATA_WIDTH-1:0] skid_reg;
	reg skid_valid;

	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			src_vld <= 0;
			src_data <= 0;
			skid_reg <= 0;
			skid_valid <= 0;
		end
		else begin
			if (src_rdy) begin
				if (skid_valid) begin
					$display("[%0t] SKID_BUFFER: Passing through buffered data = 0x%h", $time, skid_reg);
					src_data <= skid_reg;    
					src_vld <= 1;            
					skid_valid <= 0;         
				end
				else if (m_rsp_vld) begin
					$display("[%0t] SKID_BUFFER: Passing through new data from memory = 0x%h", $time, m_rsp_data);
					src_data <= m_rsp_data;  
					src_vld <= 1;            
				end
				else begin
					src_vld <= 0; 
				end
			end
			else if (m_rsp_vld && !skid_valid) begin
				skid_reg <= m_rsp_data; 
				skid_valid <= 1;
			end
		end
	end

endmodule


// internal communication between the fetch_engine and the matrix_core is done via AXI-stream lite protocol

module fetch_engine(
	// System
	clk, 
	rst_n, 
	// Control Signals
	start,
	op_code,
	cfg_data,
	// Mem Req
	m_req_vld,
	m_req_rdy,
	m_req_addr,
	// Mem Resp
	m_rsp_vld,
	m_rsp_rdy,
	m_rsp_data,
	// Core Src
	src_vld,
	src_rdy,
	src_data
);
	
	input wire clk, rst_n, start;
	input wire [1:0] op_code;
	input wire [ADDR_WIDTH-1:0] cfg_data;
	input wire m_req_rdy;
	input wire m_rsp_vld;
	input wire src_rdy;
	input wire [DATA_WIDTH-1:0] m_rsp_data;

	output reg m_req_vld;
	output reg [ADDR_WIDTH-1:0] m_req_addr;
	output wire src_vld;
	output wire [DATA_WIDTH-1:0] src_data;
	output wire m_rsp_rdy;

	reg [ADDR_WIDTH-1:0] REG_W_BASE;
	reg [ADDR_WIDTH-1:0] REG_X_BASE;

	skid_buffer skid_buffer_inst(
		.clk(clk),
		.rst_n(rst_n),
		.src_rdy(src_rdy),
		.m_rsp_vld(m_rsp_vld),
		.m_rsp_data(m_rsp_data),
		.src_vld(src_vld),
		.src_data(src_data)
	);

	localparam IDLE     = 2'b00;
	localparam FETCH_W  = 2'b01;
	localparam FETCH_X  = 2'b10;
	localparam DONE     = 2'b11;
	
	reg [1:0] state;
	reg [4:0] fetch_cnt;

	always @ (posedge clk or negedge rst_n) 
	begin
		if (!rst_n) begin
			state <= IDLE;
			m_req_vld <= 0;
			m_req_addr <= 0;
			fetch_cnt <= 0;
			REG_W_BASE <= 0;
			REG_X_BASE <= 0;
		end
		else begin
			case (state)
				IDLE: begin
					if (start) begin
						case (op_code)
							SET_W_BASE: REG_W_BASE <= cfg_data; 
							SET_X_BASE: REG_X_BASE <= cfg_data;
							RUN: begin
								state <= FETCH_W;
								fetch_cnt <= 0;
								m_req_vld <= 1;
								m_req_addr <= REG_W_BASE;
							end
						endcase
					end
				end
				
				FETCH_W: begin
					if (m_req_vld && m_req_rdy) begin
						if (fetch_cnt == W_DEPTH - 1) begin
							state <= FETCH_X;
							fetch_cnt <= 0;
							m_req_addr <= REG_X_BASE;
						end
						else begin
							fetch_cnt <= fetch_cnt + 1;
							m_req_addr <= m_req_addr + 1;
						end
					end
				end
				
				FETCH_X: begin
					if (m_req_vld && m_req_rdy) begin
						if (fetch_cnt == X_DEPTH - 1) begin
							state <= DONE;
							m_req_vld <= 0;
						end
						else begin
							fetch_cnt <= fetch_cnt + 1;
							m_req_addr <= m_req_addr + 1;
						end
					end
				end
				
				DONE: begin
					state <= IDLE;
				end
			endcase
		end
	end

	assign m_rsp_rdy = src_rdy;

endmodule


import constants_pkg::*;

module matrix_core(
    //inputs
    clk, rst_n, snk_vld, snk_data, src_rdy,
    //outputs
    snk_rdy, src_vld, src_data
);
    input wire clk, rst_n, snk_vld, src_rdy;
    input wire [DATA_WIDTH-1:0] snk_data;
    output reg snk_rdy;
    output reg src_vld;
    output reg [ACC_WIDTH-1:0] src_data;

    // Internal memories
    reg [DATA_WIDTH-1:0] w_mem [0:W_DEPTH-1];
    reg [DATA_WIDTH-1:0] x_mem [0:X_DEPTH-1];
    reg [ACC_WIDTH-1:0] acc_mem [0:X_DEPTH-1];

    reg [1:0] state;
    reg [4:0] cnt;

    // Computation counter for rows (needs to count to 4)
    reg [2:0] row_idx;
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= LOAD_W;
            cnt <= 0;
            row_idx <= 0;
            snk_rdy <= 1;
            src_vld <= 0;
            src_data <= 0;
        end
        else begin
            case (state)
                LOAD_W: begin
                    snk_rdy <= 1;
                    if (snk_vld && snk_rdy) begin
                        w_mem[cnt] <= snk_data;
                        $display("[%0t] MATRIX_CORE: LOAD_W[%0d] = 0x%h", $time, cnt, snk_data);
                        if (cnt == W_DEPTH-1) begin
                            cnt <= 0;
                            state <= LOAD_X;
                            $display("[%0t] MATRIX_CORE: State -> LOAD_X", $time);
                        end
                        else begin
                            cnt <= cnt + 1;
                        end
                    end
                end
                
                LOAD_X: begin
                    snk_rdy <= 1;
                    if (snk_vld && snk_rdy) begin
                        x_mem[cnt] <= snk_data;
                        $display("[%0t] MATRIX_CORE: LOAD_X[%0d] = 0x%h", $time, cnt, snk_data);
                        if (cnt == X_DEPTH-1) begin
                            cnt <= 0;
                            row_idx <= 0;
                            state <= COMPUTE;
                            snk_rdy <= 0;
                            $display("[%0t] MATRIX_CORE: State -> COMPUTE", $time);
                        end
                        else begin
                            cnt <= cnt + 1;
                        end
                    end
                end
                
                COMPUTE: begin
                    // Matrix-vector multiplication: y[row] = sum(W[row][col] * x[col])
                    // For 4x4 matrix: each row has 4 elements
                    // W is stored row-major: [W00, W01, W02, W03, W10, W11, W12, W13, ...]
                    
                    if (row_idx < MAT_DIM) begin
                        // Compute dot product for current row
                        acc_mem[row_idx] <= (w_mem[row_idx*MAT_DIM + 0] * x_mem[0]) +
                                           (w_mem[row_idx*MAT_DIM + 1] * x_mem[1]) +
                                           (w_mem[row_idx*MAT_DIM + 2] * x_mem[2]) +
                                           (w_mem[row_idx*MAT_DIM + 3] * x_mem[3]);
                        $display("[%0t] MATRIX_CORE: COMPUTE row %0d", $time, row_idx);
                        row_idx <= row_idx + 1;
                    end
                    else begin
                        // All rows computed, move to flush
                        state <= FLUSH;
                        cnt <= 0;
                        $display("[%0t] MATRIX_CORE: State -> FLUSH", $time);
                    end
                end
                
                FLUSH: begin
                    src_vld <= 1;
                    src_data <= acc_mem[cnt];
                    $display("[%0t] MATRIX_CORE: FLUSH acc_mem[%0d] = %0d", $time, cnt, acc_mem[cnt]);
                    if (src_rdy) begin
                        if (cnt == X_DEPTH-1) begin
                            src_vld <= 0;
                            state <= LOAD_W;
                            cnt <= 0;
                            $display("[%0t] MATRIX_CORE: State -> LOAD_W (done)", $time);
                        end
                        else begin
                            cnt <= cnt + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule


module gpu_top(
    // System
    clk,
    rst_n,
    
    // Control Interface
    start,
    op_code,
    cfg_data,
    
    // Memory Request Interface (to external SRAM)
    m_req_vld,
    m_req_rdy,
    m_req_addr,
    
    // Memory Response Interface (from external SRAM)
    m_rsp_vld,
    m_rsp_rdy,
    m_rsp_data,
    
    // Result Output Interface
    result_vld,
    result_rdy,
    result_data,
    
    // Status
    busy
);
    input wire clk, rst_n, start;
    input wire [1:0] op_code;
    input wire [ADDR_WIDTH-1:0] cfg_data;
    
    output wire m_req_vld;
    input wire m_req_rdy;
    output wire [ADDR_WIDTH-1:0] m_req_addr;
    
    input wire m_rsp_vld;
    output wire m_rsp_rdy;
    input wire [DATA_WIDTH-1:0] m_rsp_data;
    
    output wire result_vld;
    input wire result_rdy;
    output wire [ACC_WIDTH-1:0] result_data;
    
    output wire busy;

    wire core_snk_vld;
    wire core_snk_rdy;
    wire [DATA_WIDTH-1:0] core_snk_data;
    
    fetch_engine fetch_engine_inst(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .op_code(op_code),
        .cfg_data(cfg_data),
        .m_req_vld(m_req_vld),
        .m_req_rdy(m_req_rdy),
        .m_req_addr(m_req_addr),
        .m_rsp_vld(m_rsp_vld),
        .m_rsp_rdy(m_rsp_rdy),
        .m_rsp_data(m_rsp_data),
        .src_vld(core_snk_vld),
        .src_rdy(core_snk_rdy),
        .src_data(core_snk_data)
    );

    matrix_core matrix_core_inst(
        .clk(clk),
        .rst_n(rst_n),
        .snk_vld(core_snk_vld),
        .snk_rdy(core_snk_rdy),
        .snk_data(core_snk_data),
        .src_vld(result_vld),
        .src_rdy(result_rdy),
        .src_data(result_data)
    );

    assign busy = (m_req_vld || result_vld);

endmodule