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
    parameter int FETCH_ENGINE_SET_W_BASE = 2'b00;
    parameter int FETCH_ENGINE_SET_X_BASE = 2'b01;
    parameter int FETCH_ENGINE_RUN = 2'b10;
    parameter int FETCH_ENGINE_NOOP = 2'b11;

    // Matrix Core Constants
    parameter int MATRIX_CORE_LOAD_W = 2'b00;
    parameter int MATRIX_CORE_LOAD_X = 2'b01;   
    parameter int MATRIX_CORE_COMPUTE = 2'b10;
    parameter int MATRIX_CORE_FLUSH = 2'b11;
endpackage