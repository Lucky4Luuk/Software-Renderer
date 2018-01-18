uniform sampler2D depth_tex;
uniform vec3 z_points[64];
uniform int z_point_length;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords)
{
  float pixel_depth = Texel(depth_tex, screen_coords / love_ScreenSize.xy).r;
  float depth = 0.0;
  float max_depth = z_points[0].z;
  for (int i=1; i<64; i++)
  {
    if (i>z_point_length) break;
    max_depth = max(max_depth, z_points[i].z);
  }
  for (int i=1; i<64; i++)
  {
    float d = 0.0;
  }
  return vec4(0.0,0.0,0.0,1.0);
}
