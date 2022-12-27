/// 演示
/// 
/// + 圆 SDF
/// + 抗锯齿 的 基本方法: clamp, smoothstep
/// 

// ======================= 坐标-变换 ======================= 

// 1像素 对应的 uv 坐标
float uv1() {
    return 1.0 / max(iResolution.x, iResolution.y);
}

// pixel --> uv
float uv(float pixel) {
    return pixel * uv1();
}

// pixel --> uv
vec2 uv(vec2 coord) {
    return coord * uv1();
}

// uv --> pixel
float pixel(float uv) {
    return uv / uv1();
}

// uv -> pixel
vec2 pixel(vec2 coord) {
    return coord / uv1();
}

vec2 translate(vec2 coord, vec2 offset) {
    return coord - offset;
}

// ======================= SDF ======================= 

// r 半径
// 返回：圆 sdf，里面为负数，外面为正数
float sdfCircle(vec2 coord, vec2 center, float r) {
   
    coord = translate(coord, center);
   
    return length(coord) - r;
}

// ======================= 可视化 方法 ======================= 

// 等值线
vec3 isovalue(float d) {
    // 外 红 内 绿
    vec3 col = (d > 0.0) ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);

    col *= 1.0 - exp(-6.0 * abs(d));
	
    col *= 0.8 + 0.2 * cos(150.0 * d);
	
    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)) );

    return col;
}

// 按鼠标左键，能显示 该点的 sdf 圆
void showClickSdf(out vec3 color, vec2 coord, vec2 center, float r) {
    if ( iMouse.z > 0.001 ) {
        vec2 m = uv(iMouse.xy);
        float d = sdfCircle(m, center, r);
    
        float len = length(coord - m);

        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, abs(len - abs(d)) - 0.0025));
        
        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, len - 0.015));
    }
}

// ======================= 抗锯齿 ======================= 

// 抗锯齿 方法 1
float aa_1(float d) {
    // 0.5 像素 的 smoothstep
    
    // smoothstep 说明：smoothstep(a, b, x) x<a 返回0，x>b 返回1，否则在[0,1] 平滑插值
    
    return smoothstep(uv(0.5), -uv(0.5), d);
}

// 抗锯齿 方法 2
float aa_2(float d) {

    // 用 fwidth 确定 1像素 对应 的 sdf-变化 值
    float dd = fwidth(d);
    
    // fwidth 的 smoothstep
    return smoothstep(dd, -dd, d);
}

// 抗锯齿 方法 3
// 0.5 像素 + clamp
float aa_3(float d) {
    // 像素 pixel(p) 在 [-0.5, 0.5] 之间才会截取 到 [0.0, 1.0]
    return clamp(0.5 - pixel(d), 0.0, 1.0);
}

// ======================= Demo ======================= 

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 coord = uv(fragCoord);

    // 平移 到 屏幕中心
    vec2 center = uv(0.5 * iResolution.xy);
    
    float r = uv(50.0);

    // d < 0 表示 在里面
    // 在 uv 坐标系下的 sdf
    float d = sdfCircle(coord, center, r);

    float a = d;

    // a = step(d, r);
    
    a = aa_1(d);
    
    // a = aa_2(d);
    
    // a = aa_3(d);
    
    vec3 bg = vec3(1.0, 0.0, 0.0);
    vec3 fg = vec3(0.0, 1.0, 0.0);
    
    // mix(a, b, t) t = 0 返回 a; t = 1 返回 b
    vec3 color = mix(bg, fg, a);

    // color = isovalue(d);
    // showClickSdf(color, coord, center, r);

    fragColor = vec4(color, 1.0);
}