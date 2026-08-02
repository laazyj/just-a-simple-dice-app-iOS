#include <metal_stdlib>
using namespace metal;

// Subtle two-octave hash noise that darkens/lightens the felt green a few
// percent per cell, giving the background a fabric-like grain. `scale` is
// the cell size in points (2 ≈ fine felt at any screen density).
[[ stitchable ]] half4 feltTexture(float2 position, half4 color, float scale) {
    // fmod keeps the sin() argument small; fast-math sin loses precision on
    // large values, which shows up as banding on tall screens.
    float2 cell = fmod(floor(position / scale), 289.0);
    float noiseA = fract(sin(dot(cell, float2(127.1, 311.7))) * 43758.5453);
    float noiseB = fract(sin(dot(cell + 57.0, float2(269.5, 183.3))) * 28001.8384);
    half grain = half(noiseA * 0.65 + noiseB * 0.35 - 0.5);
    return half4(color.rgb * (1.0h + grain * 0.10h), color.a);
}
