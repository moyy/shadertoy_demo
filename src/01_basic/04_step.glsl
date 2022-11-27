/// 演示
/// 
/// + if, step
/// + mix 和 blend
/// + 分辨率 处理
/// 

// ======================= 坐标-变换 ======================= 

// 1像素 对应的 uv 坐标
float uv1() {
    return 1.0 / max(iResolution.x, iResolution.y);
}

// 
float uv(float pixel) {
    return pixel * uv1();
}

// 1 像素 对应的 uv 比例
vec2 uv(vec2 coord) {
    return coord * uv1();
}

// ======================= Demo ======================= 

// if 太多，不提倡
float quadWithIf(vec2 coord, vec2 center, float extent)
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
float quadWithExpr(vec2 coord, vec2 center, float extent)
{
    float d = (coord.x < center.x - extent) ? 0.0 : ((coord.x > center.x + extent) ? 0.0 : 1.0);
    
    d *= (coord.y < center.y - extent) ? 0.0 : ((coord.y > center.y + extent) ? 0.0 : 1.0);
    
    return d;
}

// 太复杂，不提倡
float quadWithStep(vec2 coord, vec2 center, float extent)
{
    // 0.2 小于 x 返回 1，否则 返回 0
    float d = step(center.x - extent, coord.x);
    
    d *= step(coord.x, center.x + extent);
    
    d *= step(center.y - extent, coord.y);
    d *= step(coord.y, center.y + extent);
    
    return d;
}

// 差不多 就是 这种
float quadWithAbs(vec2 coord, vec2 center, float extent)
{
    vec2 d = step(abs(coord - center), vec2(extent));
    
    return d.x * d.y;
}

// 知识点1：像素 和 uv值的 转换
// 知识点2：if 和 step
// 知识点3：模拟 混合
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 coord, center;
    float r, extent;

    // 问题：会随着 屏幕 变化，宽高比 会 产生变化

    // [0, 1]
    coord = fragCoord / iResolution.xy;
    
    center = vec2(0.5);
    extent = 0.05;

    // 问题 的 解答
    
    // [0, 1]
    // coord = uv(fragCoord);
    
    // center = uv(vec2(0.5 * iResolution.xy));
    // extent = uv(30.0);

    r = quadWithIf(coord, center, extent);
    
    // r = quadWithExpr(coord, center, extent);
    
    // r = quadWithStep(coord, center, extent);
    
    // r = quadWithAbs(coord, center, extent);

    // 模拟 blend
    vec3 bg = vec3(1.0, 0.0, 0.0);
    vec3 fg = vec3(0.0, 1.0, 1.0);

    // mix(a, b, t) = 从 a -> b 线性过渡
    vec3 c = mix(bg, fg, r);

    fragColor = vec4(c, 1.0);
}