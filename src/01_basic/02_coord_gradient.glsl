/// 演示 坐标 的 梯度

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // 坐标 对 x-偏导数，返回 (-1.0, 0.0)
    vec2 dx = dFdx(-fragCoord);
    
    
    // 坐标 对 y-偏导数，返回 (0.0, -1.0)
    vec2 dy = dFdy(fragCoord);

    // fwidth = abs(dFdx) + abs(dFdy), 返回 (1.0, 1.0)
    vec2 fw = fwidth(fragCoord);
    
    vec3 c;
    
    // 预期 看到颜色 vec4(127, 127, 0, 255)
    c = vec3(0.5 * (-dx - dy), 0.0);
    
    // 预期 看到颜色 vec4(127, 127, 0, 255)
    // c = vec3(0.5 * fw, 0.0);

    fragColor = vec4(c, 1.0);
}