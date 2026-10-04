shader_type canvas_item;

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    vec2 offset = uv - center;
    float radius = length(offset);
    float angle = atan(offset.y, offset.x);
    angle += radius * 3.0 - TIME * 0.35;
    vec2 warped = center + vec2(cos(angle), sin(angle)) * radius;
    COLOR = texture(TEXTURE, warped) * COLOR;
}
