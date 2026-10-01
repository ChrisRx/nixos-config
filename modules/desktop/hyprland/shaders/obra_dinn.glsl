#version 300 es

precision mediump float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// 4x4 Ordered Dithering Matrix (Bayer Matrix)
const int bayerMatrix[16] = int[](
    0,  8,  2,  10,
    12, 4,  14, 6,
    3,  11, 1,  9,
    15, 7,  13, 5
);

void main() {
    // Get the base pixel color from the screen texture
    vec4 pixColor = texture2D(tex, v_texcoord);
    
    // Convert to grayscale using standard luminance weights
    float grayscale = dot(pixColor.rgb, vec3(0.299, 0.187, 0.114));
    // float grayscale = dot(pixColor.rgb, vec3(0.499, 0.587, 0.114));
    
    // Map screen coordinates to the 4x4 grid matrix
    // Adjust gl_FragCoord.xy scaling if you want coarser/chunkier pixels
    int x = int(mod(gl_FragCoord.x, 12.0));
    int y = int(mod(gl_FragCoord.y, 12.0));
    int index = x + y * 2;
    
    // Calculate the threshold based on the Bayer matrix value (0 to 15 mapped to 0-1 range)
    float threshold = float(bayerMatrix[index]) / 16.0;
    
    // Obra Dinn specific color palette: Macintosh Sharp Monochrome (Greenish/Yellow tint)
    // Dark: #11140e  |  Light: #cbe6a3 
    vec3 colorDark  = vec3(0.066, 0.078, 0.055); 
    vec3 colorLight = vec3(0.796, 0.902, 0.639);

    // Apply the threshold comparison for the 1-bit binary toggle
    vec3 finalColor = (grayscale > threshold) ? colorLight : colorDark;
    
    fragColor = vec4(finalColor, pixColor.a);
}
