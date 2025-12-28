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