// ======================= 实用方法 ======================= 

// 2D 叉乘，正数 逆时针
float cross2d(vec2 u, vec2 v) {
    return u.x * v.y - u.y * v.x;
}
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

vec2 rotate(vec2 pt, float rad) {
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, -s, s, c) * pt;
}

// ======================= SDF ======================= 

float sdfCircle(vec2 coord, float r) {
    return length(coord) - r;
}

float sdfCircle(vec2 coord, vec2 center, float r) {
    
    coord = translate(coord, center);
    
    return sdfCircle(coord, r);
}

// r 半径
// 返回：圆 sdf，里面为负数，外面为正数
float sdfCircle(vec2 coord, vec2 center, vec2 s, float r) {
    
    coord = translate(coord, center);
    
    coord = scale(coord, s);

    float d = length(coord) - r;

    // 缩放比例 要 乘回去
    d *= min(s.x, s.y);
    
    // webrender 做法
    // float ds = sqrt(2.0) / length(fwidth(coord));
    // d *= ds;

    return d;
}

// ======================= 可视化 方法 ======================= 

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

// 画 坐标轴 网格
vec3 showGrid(vec2 coord, float row, float column) {
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

// ================ Demo

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 coord = fragCoord;

    // 平移 到 屏幕中心
    vec2 center = 0.5 * iResolution.xy;
    
    float r, a;
    vec2 s;

    r = 5.0;
    s = vec2(1.0 * 30.0, 1.0 * 30.0);

    // d < 0 表示 在里面
    // 在 uv 坐标系下的 sdf
    float d = sdfCircle(coord, center, s, r);

    // 单位是像素，天然抗锯齿
    a = -d;
    
    vec3 bg = vec3(1.0, 0.0, 0.0);
    vec3 fg = vec3(1.0, 1.0, 1.0);
    
    vec3 color = mix(bg, fg, a);

    // 等高线
    // color = isovalue(d);
    // showClickSdf(color, coord, center, s, r);

    fragColor = vec4(color, 1.0);
}