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

// 坐标 平移 变换
vec2 translate(vec2 coord, vec2 offset) {
    return coord - offset;
}

// 坐标 缩放 变换
// 注：非均匀 缩放 会 扭曲 sdf
float scale(float d, float s) {
    return d / s;
}

// 坐标 缩放 变换
// 注：非均匀 缩放 会 扭曲 sdf
vec2 scale(vec2 coord, vec2 s) {
    return coord / s;
}

// ======================= SDF ======================= 

// r 半径
// 返回：圆 sdf，里面为负数，外面为正数
float sdfCircle(vec2 coord, vec2 center, vec2 s, float r) {
    
    coord = translate(coord, center);
    coord = scale(coord, s);

    // webrender 做法
    float ds = sqrt(2.0) / length(fwidth(coord));

    float d = length(coord) - r;

    // 缩放比例 要 乘回去
    d *= min(s.x, s.y);
    // d *= ds;

    return d;
}

// ======================= 可视化 方法 ======================= 

// 画 坐标轴 网格
vec3 showGridUV(vec2 coord, float row, float column) {
    coord = uv(coord);
    coord = vec2(row, column) * coord;
    
    vec2 cell;
    
    // 每像素 的 宽度
    vec2 ps = fwidth(coord);

    cell = fract(coord);
    cell = 1.0 - 2.0 * abs(cell - 0.5);
    
    vec3 color = vec3(0.0);
    if (cell.x < 2.0 * ps.x || cell.y < ps.y) {
        color = vec3(1.0);
    }

    if (abs(coord.x) < ps.x) {
        color = vec3(1.0, 0.0, 0.0);
    }
    if (abs(coord.y) < ps.y) {
        color = vec3(0.0, 1.0, 0.0);
    }

    return color;
}

// 画 坐标轴 网格
vec3 showGrid(vec2 coord, float row, float column) {
    // 1个 单元格 的 边长
    vec2 extent = iResolution.xy / vec2(row, column);
    
    coord /= extent;

    // 当前位置 所在的 格子
    vec2 cell = fract(coord);

    // 每像素 的 宽度
    vec2 width_pixel = fwidth(coord);

    vec3 color = vec3(0.0);
    
    // 判断 整数
    if (cell.x < width_pixel.x || cell.y < width_pixel.y) {
        color = vec3(1.0);
    }

    // x, y 轴 画 颜色
    if (abs(coord.x) < width_pixel.x) {
        color = vec3(1.0, 0.0, 0.0);
    }
    if (abs(coord.y) < width_pixel.y) {
        color = vec3(0.0, 1.0, 0.0);
    }

    return color;
}

// 等值线
vec3 isovalue(float d) {
    // 画成 uv
    d = uv(d);

    // 外 红 内 绿
    vec3 col = (d > 0.0) ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);

    col *= 1.0 - exp(-6.0 * abs(d));
	
    col *= 0.8 + 0.2 * cos(150.0 * d);
	
    col = mix(col, vec3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)) );

    return col;
}

// 按鼠标左键，能显示 该点的 sdf 圆
void showClickSdf(out vec3 color, vec2 coord, vec2 center, vec2 s, float r) {
    if ( iMouse.z > 0.001 ) {
        vec2 m = iMouse.xy;
        float d = sdfCircle(m, center, s, r);

        float len = length(coord - m);
        
        len = uv(len);
        d = uv(d);

        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, abs(len - abs(d)) - 0.0025));
        
        color = mix(color, vec3(1.0, 1.0, 0.0), 1.0 - smoothstep(0.0, 0.005, len - 0.015));
    }
}

// ======================= 抗锯齿 ======================= 

// 抗锯齿 方法 1
float aa_1(float d) {
    // 0.5 像素 的 smoothstep
    
    // smoothstep 说明：smoothstep(a, b, x) x<a 返回0，x>b 返回1，否则在[0,1] 平滑插值
    
    return smoothstep(0.5, -0.5, d);
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
    // 像素 d 在 [-0.5, 0.5] 之间才会截取 到 [0.0, 1.0]
    return clamp(0.5 - d, 0.0, 1.0);
}

// 抗锯齿 方法 4
// 1 像素 + clamp
float aa_4(float d) {
    // 像素 d 在 [-1, 1] 之间才会截取 到 [0.0, 1.0]
    return clamp(0.5 - 0.5 * d, 0.0, 1.0);
}

// ======================= Demo ======================= 

// 知识点：坐标系
// 知识点：1-像素 对应的 表达
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // 以 中心点 为 坐标系
    vec2 coord = fragCoord - 0.5 * iResolution.xy;

    vec3 c;
    
    float row = 8.0, column = 8.0;
    c = showGrid(coord, row, column);
    
    c = showGridUV(coord, row, column);
    
    fragColor = vec4(c, 1.0);
}