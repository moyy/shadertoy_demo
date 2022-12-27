
/// ShaderToy 内置的 uniform
// 
// 绘制窗口 分辨率 iResolution.xy;
// 时间，单位：秒 float iTime;
// 鼠标位置 iMouse.xy; 是否按下左键 iMouse.z
// 距离上帧的时间间隔，单位：秒 float iTimeDelta;
// 帧数 float iFrame;
// iChannel[0-9] 放纹理

// ======================= 坐标-变换 ======================= 

// coord [0, iResolution.xy]
// 坐标 归一化，[-0.5, 0.5]^2
vec2 norm(vec2 coord) {
    // [0, 1]
    coord /= iResolution.xy;
    coord -= 0.5;
    return coord;
}

// gl_FragCoord = fragCoord
// gl_FragColor = fragColor
// uniform iResolution.xy 屏幕分辨率
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 c;

    // 预期 看到颜色 vec4(127, 0, 0, 255)
    // c = vec3(1.0, 0.0, 0.0);
    
    // 预期 看到颜色 vec4([0, 127], [0, 127], 0, 255)
    // c = vec3(norm(fragCoord), 0.0);

    c = vec3(abs(norm(fragCoord)), 0.0);


    // 预期 看到变化的颜色
    // abs 是为了 让 [-1, 0] 能看到
     c = vec3((abs(sin(iTime))) * norm(fragCoord), 0.0);

    fragColor = vec4(c, 1.0);
}