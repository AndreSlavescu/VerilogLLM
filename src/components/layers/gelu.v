// GeLU implementation

module gelu #(
    parameter INPUT_DIM = 4,
    parameter OUTPUT_DIM = 4,
    parameter WIDTH = 16,
    parameter FRACTIONAL_BITS = 8
) (
    input wire clk, // clock pin
    input wire rst, // reset pin
    input wire enable, // enable pin

    // input.shape: [input_dim]
    input wire [WIDTH-1:0] input_tensor[INPUT_DIM-1:0],

    // output.shape: [output_dim]
    output reg [WIDTH-1:0] output_tensor[OUTPUT_DIM-1:0],
    output reg valid_out // flag for output validity 
);

    // Constants for GELU approximation
    // GELU(x) ≈ 0.5x * (1 + tanh(sqrt(2/π) * (x + 0.044715x^3)))
    reg [WIDTH-1:0] SQRT_2_PI = 16'h00CD;  // sqrt(2/π) ≈ 0.797885 in fixed point
    reg [WIDTH-1:0] COEFF_A = 16'h000B;    // 0.044715 in fixed point
    reg [WIDTH-1:0] HALF = 16'h0080;       // 0.5 in fixed point
    reg [WIDTH-1:0] ONE = 16'h0100;        // 1.0 in fixed point
    
    reg [2*WIDTH-1:0] temp_mul;
    reg [2*WIDTH-1:0] cube_term;
    reg [WIDTH-1:0] tanh_input;
    reg [WIDTH-1:0] temp_result;
    reg computing;
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_out <= 0;
            computing <= 0;
            for (i = 0; i < OUTPUT_DIM; i = i + 1) begin
                output_tensor[i] <= 0;
            end
        end
        else if (enable && !computing) begin
            computing <= 1;
            valid_out <= 0;
            
            for (i = 0; i < INPUT_DIM; i = i + 1) begin
                // multiply input by 0.5 to prevent overflow
                temp_mul = ($signed(input_tensor[i]) * $signed(HALF)) >>> FRACTIONAL_BITS;
                temp_result = temp_mul[WIDTH-1:0];
                
                // compute x^2 then x^3
                temp_mul = ($signed(input_tensor[i]) * $signed(input_tensor[i])) >>> FRACTIONAL_BITS;
                cube_term = ($signed(temp_mul[WIDTH-1:0]) * $signed(input_tensor[i])) >>> FRACTIONAL_BITS;
                
                // compute 0.044715x^3
                temp_mul = ($signed(cube_term[WIDTH-1:0]) * $signed(COEFF_A)) >>> FRACTIONAL_BITS;
                
                // compute x + 0.044715x^3
                tanh_input = $signed(input_tensor[i]) + $signed(temp_mul[WIDTH-1:0]);
                
                // multiply by sqrt(2/π)
                temp_mul = ($signed(tanh_input) * $signed(SQRT_2_PI)) >>> FRACTIONAL_BITS;
                
                // tanh approximation
                if ($signed(temp_mul[WIDTH-1:0]) > 16'h0180) begin  // > 1.5
                    tanh_input = ONE;
                end
                else if ($signed(temp_mul[WIDTH-1:0]) < -16'h0180) begin  // < -1.5
                    tanh_input = -ONE;
                end
                else begin
                    // linear approximation in middle region with better scaling
                    temp_mul = ($signed(temp_mul[WIDTH-1:0]) * 16'h00B5) >>> FRACTIONAL_BITS; // scale by ~0.707
                    tanh_input = temp_mul[WIDTH-1:0];
                end
                
                tanh_input = $signed(ONE) + $signed(tanh_input);
                temp_mul = ($signed(temp_result) * $signed(tanh_input)) >>> FRACTIONAL_BITS;
                output_tensor[i] <= temp_mul[WIDTH-1:0];
            end
            
            computing <= 0;
            valid_out <= 1;
        end
    end
endmodule