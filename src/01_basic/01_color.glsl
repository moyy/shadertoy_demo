
// uniform vec3 iResolution;
// uniform float iTime;
// uniform vec4 iMouse;
// uniform float iTimeDelta;
// uniform float iFrame;

// ======================= 坐标-变换 ======================= 

// 坐标 归一化，值域 [0, 1]^2
vec2 norm(vec2 coord) {
    return coord / iResolution.xy;
}

// gl_FragCoord = fragCoord
// gl_FragColor = fragColor
// uniform iResolution.xy 屏幕分辨率
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 c;

    // 预期 看到颜色 vec4(127, 0, 0, 255)
    c = vec3(1.0, 0.0, 0.0);
    
    // 预期 看到颜色 vec4([0, 255], [0, 255], 0, 255)
    // c = vec3(norm(fragCoord), 0.0);

    fragColor = vec4(c, 1.0);
}