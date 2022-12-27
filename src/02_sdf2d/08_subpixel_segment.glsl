float sdSegment(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a, ba = b - a;
    
    float h = clamp(dot(pa,ba) / dot(ba, ba), 0.0, 1.0);
    
    return length(pa - ba * h);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // 线段 端点
    float t = 0.3 * iTime;
   	vec2 p1 = vec2 (300.5, 200.);
    vec2 p2 = p1 + 200.0 * vec2 (cos(t), sin(t));
    
    // 左边 第1条：无抗锯齿
    vec2 pa = p1, pb = p2;
    
    float d = sdSegment(fragCoord, pa, pb);
    vec4 colA = vec4(d < 0.5 ? 0.0 : 1.0);
    
    // 左边 第2条：sdf 当 alpha
    pa = p1 + vec2(50.0, 0.0);
    pb = p2 + vec2(50.0, 0.0);
    
    vec4 colB = vec4 (sdSegment (fragCoord, pa, pb));
    
    // 左边 第3条：rgb 亚像素 抗锯齿
    pa = p1 + vec2(100.0, 0.0);
    pb = p2 + vec2(100.0, 0.0);
    
    // 偏移 1/3 像素
    float colCr = sdSegment (fragCoord - vec2 (1./3., 0.), pa, pb);
    float colCg = sdSegment (fragCoord,                    pa, pb);
    float colCb = sdSegment (fragCoord + vec2 (1./3., 0.), pa, pb);
    
    vec4 colC = vec4(colCr, colCg, colCb, 0.0);

    // 左边 第4条：bgr 亚像素 抗锯齿
    pa = p1 + vec2(150.0, 0.0);
    pb = p2 + vec2(150.0, 0.0);
    
    float colDr = sdSegment (fragCoord + vec2 (1./3., 0.), pa, pb);
    float colDg = sdSegment (fragCoord,                    pa, pb);
    float colDb = sdSegment (fragCoord - vec2 (1./3., 0.), pa, pb);
    
    vec4 colD = vec4(colDr, colDg, colDb, 0.0);

    fragColor = min (min (colA, colB), min (colC, colD));
}