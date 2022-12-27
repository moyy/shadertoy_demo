/// 演示 表达式 的 梯度

// dFdx
vec2 exprDfdx(vec2 coord)
{
    float x = coord.x;

    // x-偏导数 是 x^2 = 2 * x
    float c = dFdx(x * x);
    
    return vec2(0.5 * c / iResolution.x, 0.0);
}

// dFdy
vec2 exprDfdy(vec2 coord)
{
    float x = coord.x;
    float y = coord.y;
    
    // y-偏导数 = 上面 - 下面
    // 返回 vec2(2, x)
    vec2 kx = dFdy(vec2(3.0 * x + 2.0 * y, x * y));
    
    return vec2(kx / vec2(4.0, iResolution.x));
}

// fwidth
vec2 exprFwidth(vec2 coord)
{
    float x = coord.x;
    float y = coord.y;
    
    // x-偏导数 vec2(3, y)
    // y-偏导数 vec2(2, x)
    // (3, y) + (2, x) = (5, x + y)
    vec2 k = fwidth(vec2(3.0 * x + 2.0 * y, x * y));
    
    return vec2((k.y - y)/ iResolution.x, (k.y - x)/ iResolution.y);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 c;
    
    // 预期：看到颜色 ([0, 255], 0, 0, 255)   
    c = exprDfdx(fragCoord);
    
    // 预期：看到颜色 (127, [0, 255], 0, 255)
    // c = exprDfdy(fragCoord);
    
    // 预期：看到颜色 (127, [0, 255], 0, 255)
    // c = exprFwidth(fragCoord);

    fragColor = vec4(c, 0.0, 1.0);
}