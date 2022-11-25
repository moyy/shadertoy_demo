/// 演示
/// 
/// + 圆 SDF
/// + 分辨率 处理，1像素 表示
/// + 抗锯齿 的 基本方法
/// + glsl 基本函数: mix, step, clamp, smoothstep

// ======================= 坐标-变换 ======================= 

// 坐标 归一化，值域 [0, 1]^2
vec2 norm(vec2 coord) {
    return coord / iResolution.xy;
}

// ======================= Demo ======================= 

// if 太多，不提倡
float rectWithIf(vec2 coord, vec2 center, float extent)
{
    float d = 1.0;

    if (coord.x < center.x - extent || coord.x > center.x + extent) {
        d = 0.0;
    }

    if (coord.y < center.y - extent || coord.y > center.y + extent) {
        d = 0.0;
    }
    
    return d;
} 

// if 太多，不提倡
float rectWithExpr(vec2 coord, vec2 center, float extent)
{
    float d = (coord.x < center.x - extent) ? 0.0 : ((coord.x > center.x + extent) ? 0.0 : 1.0);
    
    d *= (coord.y < center.y - extent) ? 0.0 : ((coord.y > center.y + extent) ? 0.0 : 1.0);
    
    return d;
}

// 太复杂，不提倡
float rectWithStep(vec2 coord, vec2 center, float extent)
{
    // 0.2 小于 x 返回 1，否则 返回 0
    float d = step(center.x - extent, coord.x);
    
    d *= step(coord.x, center.x + extent);
    
    d *= step(center.y - extent, coord.y);
    d *= step(coord.y, center.y + extent);
    
    return d;
}

// 差不多 就是 这种
float rectWithAbs(vec2 coord, vec2 center, float extent)
{
    vec2 d = step(abs(coord - center), vec2(extent));
    
    return d.x * d.y;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 coord = norm(fragCoord);

    float r;

    // 问题：会随着 屏幕 变化，宽高比 会 产生变化，解决方式 看 下一节

    r = rectWithIf(coord, vec2(0.5), 0.2);
    
    // r = rectWithExpr(coord, vec2(0.4), 0.2);
    
    // r = rectWithStep(coord, vec2(0.3), 0.2);
    
    // r = rectWithAbs(coord, vec2(0.5, 0.25), 0.2);

    fragColor = vec4(r, 0.0, 0.0, 1.0);
}