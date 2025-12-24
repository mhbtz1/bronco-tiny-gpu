import constants_pkg::*;

module SRAMMemory (clk, read_enable, write_enable, src_vld, src_rdy, src_addr, src_data, load_state, output_rdy, output_vld, output_data);
    input wire clk, src_vld, read_enable, write_enable;
    
    input reg [DATA_WIDTH-1:0] src_data;
    input reg [DATA_WIDTH-1:0] src_addr;
    input reg [FETCH_ENGINE_OPCODE_LENGTH-1:0] load_state;

    output reg output_rdy, src_rdy, output_vld;
    output reg [DATA_WIDTH-1:0] output_data;

    output reg [MAT_DIM * MAT_DIM * DATA_WIDTH-1:0] w_memory; // stores a 4 * 4 matrix
    output reg [X_DEPTH * DATA_WIDTH-1:0] x_memory; // stores a 4 * 1 vector
    output reg [X_DEPTH * DATA_WIDTH-1:0] acc_memory; // stores partial computations

    always @ (posedge clk) begin
        if (write_enable && src_vld && src_rdy && load_state == MATRIX_CORE_LOAD_W) begin
            output_vld <= 1;
            if (load_state == MATRIX_CORE_LOAD_W) begin
                w_memory[src_data+:DATA_WIDTH] <= src_data;
                output_data <= w_memory[src_data+:DATA_WIDTH];
                output_rdy <= 1;
            end
            if (load_state== MATRIX_CORE_LOAD_X) begin
                x_memory[src_data+:DATA_WIDTH] <= src_data;
                output_data <= x_memory[src_data+:DATA_WIDTH];
                output_rdy <= 1;
            end
            if (load_state == MATRIX_CORE_COMPUTE) begin
                // this isn't right, but will edit later
                output_data <= w_memory[src_data+:DATA_WIDTH] * x_memory[src_data+:DATA_WIDTH];
                output_rdy <= 1;
            end
        end

        if (read_enable && src_vld && src_rdy) begin
            if (load_state == MATRIX_CORE_LOAD_W) begin
                output_data <= w_memory[src_addr+:DATA_WIDTH];
                output_rdy <= 1;
            end
            if (load_state == MATRIX_CORE_LOAD_X) begin
                output_data <= x_memory[src_addr+:DATA_WIDTH];
                output_rdy <= 1;
            end
        end
    end

endmodule