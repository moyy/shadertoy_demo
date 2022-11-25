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

vec2 translate(vec2 coord, vec2 center) {
    return coord - center;
}

// ======================= 组合子 ======================= 

// ======================= SDF ======================= 

// r 半径
// 返回：圆 sdf，里面为负数，外面为正数
float sdfCircle(vec2 coord, float r) {
    return length(coord) - r;
}

// ======================= 抗锯齿 ======================= 

// 抗锯齿 方法 1
// 0.5 像素 的 smoothstep
// smoothstep 说明：smoothstep(a, b, x) x<a 返回0，x>b 返回1，否则在[0,1] 平滑插值
float aa_1(float d) {
    // 这时候，一个像素大小就是 宽高最小值 的 倒数，1像素 = 1 / 768
    float pixel = 1.0 / min(iResolution.x, iResolution.y);
    
    return smoothstep(0.5 * pixel, -0.5 * pixel, d);
}

// 抗锯齿 方法 2
// fwidth 的 smoothstep
float aa_2(float d) {

    // 用 fwidth 确定 1像素 对应 的 sdf-变化 值
    float dd = fwidth(d);
    
    return smoothstep(dd, -dd, d);
}

// 抗锯齿 方法 3
// 0.5 像素 + clamp
float aa_3(float d) {
    // 这时候，一个像素大小就是 宽高最小值 的 倒数，1像素 = 1 / 768
    float pixel = 1.0 / min(iResolution.x, iResolution.y);

    // d / pixel = d * min(iResolution.x, iResolution.y)，将 d 映射到 绝对像素的 范围
    // d 在 [-0.5, 0.5] 之间才会截取 到 [0.0, 1.0]
    return clamp(0.5 - d / pixel, 0.0, 1.0);
}

// ======================= Demo ======================= 

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 coord = norm(fragCoord);

    // 平移 到 屏幕中心
    vec2 center = vec2(0.5, 0.5);
    coord = translate(coord, center);

    // 必须 将 原点 平移到中心，再整体缩放，参考 相机的视图变换
    // 比如 (1024, 768), 乘以 1 / 1024，宽高都变成 768大小的 参考系
    
    // 如果没有这一步，那么画出来的就是椭圆
    // coord *= iResolution.xy / max(iResolution.x, iResolution.y);

    float r = 0.1;

    // d < 0 表示 在里面
    float d = sdfCircle(coord, r);

    float a = -d;

    // 边界清晰，有锯齿
    // step(x, s) x < s 返回 1，否则 返回 0.0
    
    // a = step(d, r);
    
    // a = aa_1(d);
    
    // a = aa_2(d);
    
    // a = aa_3(d);
    
    vec3 bg = vec3(0.0, 0.0, 0.0);
    vec3 fg = vec3(1.0, 0.0, 0.0);
 
    // mix(a, b, t) t = 0 返回 a; t = 1 返回 b
    fragColor = vec4(mix(bg, fg, a), 1.0);
}