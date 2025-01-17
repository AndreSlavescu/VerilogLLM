module linear_tb;
    // test parameters
    parameter INPUT_DIM = 4;
    parameter OUTPUT_DIM = 3;
    parameter WIDTH = 16;
    parameter FRACTIONAL_BITS = 8;
    
    // DUT signals
    reg clk;
    reg rst;
    reg enable;
    reg [WIDTH-1:0] input_tensor[INPUT_DIM-1:0];
    reg [WIDTH-1:0] weights[OUTPUT_DIM-1:0][INPUT_DIM-1:0];
    reg [WIDTH-1:0] bias[OUTPUT_DIM-1:0];
    wire [WIDTH-1:0] output_tensor[OUTPUT_DIM-1:0];
    wire valid_out;
    
    // init the linear module
    linear #(
        .INPUT_DIM(INPUT_DIM),
        .OUTPUT_DIM(OUTPUT_DIM),
        .WIDTH(WIDTH),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .input_tensor(input_tensor),
        .weights(weights),
        .bias(bias),
        .output_tensor(output_tensor),
        .valid_out(valid_out)
    );
    
    // clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // test stimulus
    initial begin
`ifdef VCD_DUMP_PATH
        $dumpfile(`VCD_DUMP_PATH);
`else
        $dumpfile("linear_tb.vcd");
`endif
        $dumpvars(0, linear_tb);
        
        // init signals
        rst = 1;
        enable = 0;
        
        // init input tensor (fixed point: 1.0, 2.0, 3.0, 4.0)
        input_tensor[0] = 16'h0100;  // 1.0
        input_tensor[1] = 16'h0200;  // 2.0
        input_tensor[2] = 16'h0300;  // 3.0
        input_tensor[3] = 16'h0400;  // 4.0
        
        // simple identity matrix weight tensor
        for (integer i = 0; i < OUTPUT_DIM; i = i + 1) begin
            for (integer j = 0; j < INPUT_DIM; j = j + 1) begin
                weights[i][j] = (i == j) ? 16'h0100 : 16'h0000;  // 1.0 or 0.0
            end
        end
        
        // Initialize bias
        bias[0] = 16'h0080;  // 0.5
        bias[1] = 16'h0080;  // 0.5
        bias[2] = 16'h0080;  // 0.5
        
        // enable 
        #10 rst = 0;
        #10 enable = 1;
        
        @(posedge valid_out);
        
        $display("Test Results:");
        $display("Input tensor:");
        for (integer i = 0; i < INPUT_DIM; i = i + 1) begin
            $display("  input[%0d] = %h", i, input_tensor[i]);
        end
        
        $display("Output tensor:");
        for (integer i = 0; i < OUTPUT_DIM; i = i + 1) begin
            $display("  output[%0d] = %h", i, output_tensor[i]);
        end
        
        // delay
        #100 $finish;
    end
endmodule