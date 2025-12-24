import constants_pkg::*;

module tb;
  // Testbench signals
  reg clk, rst_n, start;
  reg [1:0] op_code;
  reg [ADDR_WIDTH-1:0] cfg_data;
  reg result_rdy;
  
  // Memory interface signals
  wire m_req_vld;
  reg m_req_rdy;
  wire [ADDR_WIDTH-1:0] m_req_addr;
  reg m_rsp_vld;
  wire m_rsp_rdy;
  reg [DATA_WIDTH-1:0] m_rsp_data;
  
  // Result signals
  wire result_vld;
  wire [ACC_WIDTH-1:0] result_data;
  wire busy;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // DUT instantiation
  gpu_top gpu_top_inst(
    .clk(clk), 
    .rst_n(rst_n),
    .start(start),
    .op_code(op_code),
    .cfg_data(cfg_data),
    // Memory interface
    .m_req_vld(m_req_vld),
    .m_req_rdy(m_req_rdy),
    .m_req_addr(m_req_addr),
    .m_rsp_vld(m_rsp_vld),
    .m_rsp_rdy(m_rsp_rdy),
    .m_rsp_data(m_rsp_data),
    // Result
    .result_vld(result_vld),
    .result_rdy(result_rdy),
    .result_data(result_data),
    .busy(busy)
  );

  // Monitor result outputs
  always @(posedge clk) begin
    if (result_vld && result_rdy) begin
      $display("[%0t] RESULT: result_data = %0d (0x%h)", $time, result_data, result_data);
    end
  end
  
  // Monitor memory transactions
  always @(posedge clk) begin
    if (m_req_vld && m_req_rdy) begin
      $display("[%0t] MEM_REQ: addr = 0x%h", $time, m_req_addr);
    end
    if (m_rsp_vld && m_rsp_rdy) begin
      $display("[%0t] MEM_RSP: data = 0x%h", $time, m_rsp_data);
    end
  end

  // Simple test sequence
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    
    $display("=== TinyGPU Testbench Start ===");
    
    // Initialize
    rst_n = 0;
    start = 0;
    op_code = 2'b00;
    cfg_data = 0;
    result_rdy = 1;
    
    // Reset
    #20 rst_n = 1;
    $display("[%0t] Released reset", $time);
    
    // Configure W_BASE
    #10 start = 1; op_code = 2'b00; cfg_data = 8'h00;
    $display("[%0t] Command: SET_W_BASE = 0x%h", $time, cfg_data);
    #10 start = 0;
    
    // Configure X_BASE
    #10 start = 1; op_code = 2'b01; cfg_data = 8'h10;
    $display("[%0t] Command: SET_X_BASE = 0x%h", $time, cfg_data);
    #10 start = 0;
    
    // Start RUN
    #10 start = 1; op_code = 2'b10;
    $display("[%0t] Command: RUN", $time);
    #10 start = 0;
    
    // Let it run
    #1000;
    
    $display("=== Testbench Complete ===");
    $finish;
  end
  
  // Memory model with actual storage
  reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];  // 256 bytes
  reg [ADDR_WIDTH-1:0] pending_addr;
  reg pending_request;
  reg [1:0] latency_counter;
  
  // Initialize memory with test data
  integer i;
  initial begin
    // Initialize all to zero first
    for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin
      memory[i] = 0;
    end
    
    // Load Weight Matrix W at addresses 0x00-0x0F (16 bytes)
    // Example: Simple incrementing pattern
    memory[8'h00] = 8'd2;  memory[8'h01] = 8'd3;  memory[8'h02] = 8'd4;  memory[8'h03] = 8'd5;
    memory[8'h04] = 8'd6;  memory[8'h05] = 8'd7;  memory[8'h06] = 8'd8;  memory[8'h07] = 8'd9;
    memory[8'h08] = 8'd10; memory[8'h09] = 8'd11; memory[8'h0A] = 8'd12; memory[8'h0B] = 8'd13;
    memory[8'h0C] = 8'd14; memory[8'h0D] = 8'd15; memory[8'h0E] = 8'd16; memory[8'h0F] = 8'd17;
    
    // Load Input Vector X at addresses 0x10-0x13 (4 bytes)
    memory[8'h10] = 8'd18;
    memory[8'h11] = 8'd19;
    memory[8'h12] = 8'd20;
    memory[8'h13] = 8'd20;
    
    $display("=== Memory Initialized ===");
    $display("Weight Matrix W (4x4):");
    $display("  [%3d %3d %3d %3d]", memory[0], memory[1], memory[2], memory[3]);
    $display("  [%3d %3d %3d %3d]", memory[4], memory[5], memory[6], memory[7]);
    $display("  [%3d %3d %3d %3d]", memory[8], memory[9], memory[10], memory[11]);
    $display("  [%3d %3d %3d %3d]", memory[12], memory[13], memory[14], memory[15]);
    $display("Input Vector X:");
    $display("  [%3d %3d %3d %3d]", memory[16], memory[17], memory[18], memory[19]);
    $display("Expected Result Y = W * X:");
    $display("  Y[0] = (2*18)+(3*19)+(4*20)+(5*20) = %d", (2*18)+(3*19)+(4*20)+(5*20));
    $display("  Y[1] = (6*18)+(7*19)+(8*20)+(9*20) = %d", (6*18)+(7*19)+(8*20)+(9*20));
    $display("  Y[2] = (10*18)+(11*19)+(12*20)+(13*20) = %d", (10*18)+(11*19)+(12*20)+(13*20));
    $display("  Y[3] = (14*18)+(15*19)+(16*20)+(17*20) = %d", (14*18)+(15*19)+(16*20)+(17*20));
  end
  
  // Simplified memory response logic (1-cycle latency)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_req_rdy <= 1;
      m_rsp_vld <= 0;
      m_rsp_data <= 0;
    end
    else begin
      // Accept request and respond in next cycle
      if (m_req_vld && m_req_rdy) begin
        m_rsp_data <= memory[m_req_addr];  // Read from memory
        m_rsp_vld <= 1;
      end
      else if (m_rsp_rdy && m_rsp_vld) begin
        m_rsp_vld <= 0;  // Clear valid after handshake
      end
    end
  end

endmodule
