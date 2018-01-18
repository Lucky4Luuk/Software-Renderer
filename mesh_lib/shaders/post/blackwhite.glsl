vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
{
  vec4 pixel = Texel(tex, uv) * color;
  float b = (pixel.r + pixel.g + pixel.b) / 3.0;
  return vec4(b,b,b,pixel.a);
}