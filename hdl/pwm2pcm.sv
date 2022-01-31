module pwm2pcm #(
    // Frequency (KHz) when clkFreq is low
    real clkFreq0,
    // Frequency (KHz) when clkFreq is high
    real clkFreq1,
    // Output sample rate (KHz)
    real sampleFreq,
    // Attenuate samples by 2^-atten from full scale
    int atten,
    // Upsample factor (multiplies *output* rate)
    int upsample,
    // IIR filter (alpha = 2^-filter)
    int filter
) (
    // Input PWM left channel
    input logic pwmInL,
    // Input PWM right channel
    input logic pwmInR,
    // Clock
    input logic clk,
    // Reset
    input logic rst,
    // Indicates current frequency of clk
    input logic clkFreq,
    // Output sample clock
    output logic sampleClkOut,
    // Left channel PCM output
    output logic [15:0] datOutL,
    // Right channel PCM output
    output logic [15:0] datOutR
);

localparam real gbaMinSampleRate = 32.768;
localparam real clkFreqMax = clkFreq0 > clkFreq1 ? clkFreq0 : clkFreq1;
// Output clock counter periods (in terms of input clock)
localparam int periodOut0 = clkFreq0 / sampleFreq;
localparam int periodOut1 = clkFreq1 / sampleFreq;
localparam int periodOutMax = $ceil(clkFreqMax / sampleFreq);
// Upsample clock counter periods
localparam int periodUpsample0 = clkFreq0 / (sampleFreq * upsample);
localparam int periodUpsample1 = clkFreq1 / (sampleFreq * upsample);
// Maximum expected input clock cycles per GBA sample
localparam int periodSampleMax = $ceil(clkFreqMax / gbaMinSampleRate);

// Holds a PWM counter value
typedef logic [$clog2(periodSampleMax) - 1:0] counter_t;
// Holds a clock counter value
typedef logic [$clog2(periodOutMax) - 1:0] clock_t;
// Holds a PCM sample
typedef logic signed [$bits(datOutL) - 1:0] sample_t;
// Holds an extended-precision sample for filtering
typedef logic signed [$bits(sample_t) + filter - 1:0] extend_t;

// First-order IIR low-pass filter for resampling
function sample_t iir(sample_t prev, sample_t in);
    localparam logic [filter - 1:0] pad = 0;
    // Extend inputs for more precision
    extend_t prevExt = {prev, pad};
    extend_t inExt = {in, pad};
    // next = (1 - 2^-filter) * prev + (2^-filter) * in
    extend_t next = prevExt + ((inExt - prevExt) >>> filter);
    // Truncate extra precision
    return next[$bits(next) - 1:$bits(pad)];
endfunction

// Generate sample from PWM counts
function sample_t pwm_to_pcm(counter_t num, counter_t denom);
    localparam logic [$bits(sample_t) - $bits(counter_t) - atten - 1:0] pad = 0;
    return signed'({num - (denom >> 1), pad});
endfunction

// Simple inline sanity tests
if (!(pwm_to_pcm(periodSampleMax/2 - 10, periodSampleMax-1) < 0))
    $error("pwm_to_pcm has broken signed conversion");
if (!(pwm_to_pcm(periodSampleMax/2 + 10, periodSampleMax-1) > 0))
    $error("pwm_to_pcm has broken signed conversion");

// Sample a PWM signal, output PCM samples
module sampler(
    input logic clk,
    input logic rst,
    input logic pwm,
    output sample_t pcm
);
    // Numerator, denominator of PWM output period
    // (cycles spent low, total cycles)
    counter_t num, denom;
    // Counter values to normalize before output
    counter_t normNum, normDenom;
    // Do normalization?
    logic norm;
    // Last PWM level
    logic last;

    always_ff @(posedge clk) begin
        if (rst) begin
            num <= 0;
            denom <= 0;
            normNum <= 0;
            normDenom <= 0;
            norm <= 0;
            pcm <= 0;
            last <= 0;
        end else begin
            last <= pwm;
            // Stop counters at positive edge of PWM signal
            if (!last && pwm) begin
                if (!norm) begin
                    normNum <= num;
                    normDenom <= denom;
                    // Don't try to normalize 0
                    norm <= denom != 0;
                end
                num <= 1;
                denom <= 1;
            end else if (denom == periodSampleMax - 1) begin
                // We aren't guaranteed edges, so overflow is possible.
                // Make the best of it by dropping LSB
                num <= (num >> 1) + pwm;
                denom <= (denom >> 1) + 1;
            end else begin
                num <= num + pwm;
                denom <= denom + 1; 
            end
            // If we have counter values to normalize, process or output them
            if (norm) begin
                if (normDenom[$bits(normDenom)-1]) begin
                    // Normalization complete, update sample
                    pcm <= pwm_to_pcm(normNum, normDenom);
                    normNum <= 0;
                    normDenom <= 0;
                    norm <= 0;
                end else begin
                    // Can still shift
                    normNum <= normNum << 1;
                    normDenom <= normDenom << 1;
                end
            end
        end
    end
endmodule

// Upsample and filter a PCM stream at a multiple of the output frequency
module upsampler(
    input logic clk,
    input logic rst,
    input clock_t max,
    input sample_t in,
    output sample_t out
);
    clock_t count;
    sample_t pcm;

    assign out = pcm;

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
            pcm <= 0;
        end else begin
            if (count >= max) begin
                count <= 0;
                pcm <= iir(pcm, in);
            end else
                count <= count + 1;
        end
    end
endmodule

// Combined sampler + upsampler
module channel(
    input logic clk,
    input logic rst,
    input logic pwm,
    input clock_t max,
    output sample_t pcm
);
    sample_t sample;
    sampler sampler(
        .clk(clk),
        .rst(rst),
        .pwm(pwm),
        .pcm(sample)
    );
    upsampler up(
        .clk(clk),
        .rst(rst),
        .in(sample),
        .out(pcm)
    );
endmodule

// Current maximum value of output clock counter
clock_t outStop = (clkFreq ? periodOut1 : periodOut0) - 1;
// Current maximum value of upsample clock counter
clock_t upsampleStop = (clkFreq ? periodUpsample1 : periodUpsample0) - 1;

clock_t outCount;

// Latched PWM inputs
logic pwmL, pwmR;

// Channel outputs at upsampled rate
sample_t pcmL, pcmR;

// Left and right channel generators
channel left(
    .clk(clk),
    .rst(rst),
    .pwm(pwmL),
    .max(upsampleStop),
    .pcm(pcmL)
);

channel right(
    .clk(clk),
    .rst(rst),
    .pwm(pwmR),
    .max(upsampleStop),
    .pcm(pcmR)
);

always_ff @(posedge clk) begin
    if (rst) begin
        sampleClkOut <= 0;
        outCount <= outStop;
        pwmL <= 0;
        pwmR <= 0;
    end else begin
        // Latch PWM inputs for stability since they change at a fractional
        // multiple of our clock
        pwmL <= pwmInL;
        pwmR <= pwmInR;

        // Update output counter
        if (outCount >= outStop)
            outCount <= 0;
        else
            outCount <= outCount + 1;

        // Decimate and clock output
        if (outCount == outStop)
            sampleClkOut <= 1;
        else if (outCount >= outStop >> 1) begin
            sampleClkOut <= 0;
            // Latch samples at negative edge of output clock
            datOutL <= pcmL;
            datOutR <= pcmR;
        end
    end
end
endmodule
